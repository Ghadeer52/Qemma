import SwiftUI
import WatchKit
import Combine
import Accelerate

struct WorkoutResult {
    var summary: WorkoutSummary
    var outcome: Progression.Outcome
    var level: Int
    var weightFrom: Double
    var weightTo: Double
    var goodReps: Int
    var advice: Progression.Advice = .keep
}

/// Prints to the Xcode console. Filter the console with "[Qemma]".
func qlog(_ message: String) {
    #if DEBUG
    print("[Qemma] \(message)")
    #endif
}

/// Runs one workout: countdown -> set -> rest -> ... -> result.
@MainActor
final class WorkoutViewModel: ObservableObject {
    enum Phase: Equatable { case home, countdown(Int), activeSet, rest, paused, result }

    @Published var phase: Phase = .home
    @Published var plan = WorkoutPlan()
    @Published private(set) var journey = JourneyProgress()
    @Published var currentSet = 1
    @Published var reps = 0                 // GOOD reps in the current set
    @Published var holding = false          // set is waiting (wrist flip, rest between reps); reps are kept
    @Published var restRemaining = 0
    @Published var result: WorkoutResult?

    /// The bar on the Watch: progress to the next mountain, from strength (falls back to the rep ladder).
    var levelProgress: Double {
        StrengthStandards.progressToNext(e1RM: journey.e1RM, bodyWeightKg: journey.bodyWeightKg,
                                         sex: journey.sex, level: journey.level,
                                         mountains: Mountain.all.count) ?? journey.ladderFraction
    }

    /// Target reps for the set in progress (sets can differ: 10, 9, 8).
    var targetReps: Int { plan.targetReps(forSet: currentSet) }

    let workout = WorkoutManager()
    let connectivity = WatchConnectivityManager()
    private let store = ProgressStore()
    private let motion = MotionEngine()
    private var cancellables = Set<AnyCancellable>()

    private var repSpeeds: [Double] = []        // deg/s
    private var repVelocities: [Double] = []    // m/s
    private var alertedThisSet = false
    private var repDurations: [Double] = []
    private var afterHold = false           // set was held; next rep must match the set's rhythm
    private var rejected = 0
    private var results: [SetResult] = []
    private var startedAt = Date()
    private var flowTask: Task<Void, Never>?
    private var idleTask: Task<Void, Never>?
    private var phaseBeforePause: Phase = .activeSet

    // Rep quality ("good rep"): full range of motion and a controlled tempo.
    private var referenceROM: Double?
    private var calibrationROMs: [Double] = []
    private let minROMFraction = 0.6   // consistency check, NOT from a study (see EVIDENCE.md)
    // Research: whole reps of 0.5-8 s give similar hypertrophy (Schoenfeld 2015). We only time the
    // lifting half, so 0.25-4 s assumes the lowering takes about as long. This is an assumption.
    // A full curl swings the forearm about 120-150 deg. Looking at the Watch only raises it to about 90 deg
    // (from the hanging pose), so requiring a swing of at least this separates them. The number is an
    // assumption tuned on one person's curls: validate it with others (see VALIDATION.md).
    private let minSwing = 80.0   // was 90: real curls of 85-90 deg were rejected (log 29 Oct)
    /// Up-time allowed for a rep. Up to 10 s so that the SLOW last reps of a hard set (grinding) still count:
    /// they are exactly the "close to failure" signal. Assumption, not from a study.
    private let tempoRange: ClosedRange<Double> = 0.25...10.0
    /// True when a rep started but stalled (too small) after the set had already slowed down: muscle failure.
    private var stalledAtFailure = false
    /// Shake (fast wrist wobble) of each counted rep. Measurement only for now: it does not change any decision.
    private var repShakes: [Double] = []

    init() {
        journey = store.progress
        referenceROM = journey.referenceROM
        // The angle is measured differently since version 2, so the old saved range no longer applies:
        // forget it once. The first 3 good curls set the new one.
        if UserDefaults.standard.integer(forKey: "qemma.angleVersion") < 4 {
            referenceROM = nil
            UserDefaults.standard.set(4, forKey: "qemma.angleVersion")
            store.resetBaselines()
            journey = store.progress
            qlog("Range and usual speeds reset: the next 3 curls set your normal range")
        }
        workout.onSystemPause = { [weak self] in
            guard let self, self.phase == .activeSet || self.phase == .rest else { return }
            self.pause()
        }
        workout.onSystemResume = { [weak self] in
            guard let self, self.phase == .paused else { return }
            self.resume()
        }
        connectivity.$receivedProfile
            .compactMap { $0 }
            .sink { [weak self] p in
                guard let self else { return }
                self.store.setProfile(bodyWeightKg: p.bodyWeightKg, sex: p.sex, heightM: p.heightM)
                self.journey = self.store.progress
                qlog("HEALTH from iPhone: weight \(p.bodyWeightKg.map { String($0) } ?? "none")  height \(p.heightM.map { String($0) } ?? "none")  sex \(p.sex.map { $0.rawValue } ?? "none")")
            }
            .store(in: &cancellables)
        plan.weightKg = journey.weightKg
        plan.repsPerSet = Array(repeating: journey.goalReps, count: plan.repsPerSet.count)
        motion.onRep = { [weak self] metrics in
            Task { @MainActor in self?.handleRep(metrics) }
        }
        connectivity.$startRequest
            .compactMap { $0 }
            .sink { [weak self] plan in self?.startFromPhone(plan) }
            .store(in: &cancellables)
        // Plan changes from the iPhone only apply while idle.
        connectivity.$receivedPlan
            .compactMap { $0 }
            .sink { [weak self] incoming in
                guard let self, self.phase == .home, incoming.updatedAt > self.plan.updatedAt else { return }
                self.plan = incoming
                self.store.setWeight(incoming.weightKg)
                self.journey = self.store.progress
            }
            .store(in: &cancellables)
    }

    /// iPhone pressed "Start on Watch".
    func startFromPhone(_ incoming: WorkoutPlan) {
        guard phase == .home else { return }
        plan = incoming
        store.setWeight(incoming.weightKg)
        journey = store.progress
        startWorkout()
    }

    func setStartingWeight(_ kg: Double) {
        plan.weightKg = kg
        plan.updatedAt = .now
        store.setWeight(kg)
        journey = store.progress
    }

    // MARK: Flow

    func startWorkout() {
        guard phase == .home else { return }
        flowTask = Task {
            guard await workout.requestAuthorization() else { return }
            let profile = await workout.loadProfile()
            store.setProfile(bodyWeightKg: profile.bodyWeightKg, sex: profile.sex, heightM: profile.heightM)
            journey = store.progress
            do { try await workout.start() } catch { return }
            startedAt = .now
            results = []
            currentSet = 1
            motion.start()
            beginCountdown()
        }
    }

    private func beginCountdown() {
        motion.setPoseCalibration(true)      // arm hangs during the countdown
        flowTask?.cancel()
        flowTask = Task {
            for n in stride(from: 3, through: 1, by: -1) {
                phase = .countdown(n)
                WKInterfaceDevice.current().play(.click)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            startSet()
        }
    }

    private func startSet() {
        reps = 0
        rejected = 0
        stalledAtFailure = false
        repShakes = []
        repSpeeds = []
        repVelocities = []
        repDurations = []
        afterHold = false
        alertedThisSet = false
        phase = .activeSet
        motion.setPoseCalibration(false)
        motion.beginSet()
        WKInterfaceDevice.current().play(.start)
    }

    /// A rep only counts when the range of motion is close to the user's normal and the tempo is
    /// controlled (no swinging). The first 3 reps ever recorded set the normal range.
    private func isGood(_ m: RepMetrics) -> Bool {
        guard tempoRange.contains(m.concentricDuration) else { return false }
        // Before the user's normal range is known, use a fixed minimum. After that, only the relative check:
        // real slow curls of 76-79 deg were rejected by the fixed 80 (log 30 Oct).
        guard let ref = referenceROM else { return m.rangeOfMotion >= minSwing }
        return m.rangeOfMotion >= minROMFraction * ref
    }

    private func handleRep(_ m: RepMetrics) {
        guard phase == .activeSet else { return }
        guard isGood(m) else {
            rejected += 1
            qlog(String(format: "REP REJECTED  swing %.0f deg (needs >= %.0f, and >= %.0f vs your usual)  up-time %.2f s (allowed %.2f-%.2f)",
                        m.rangeOfMotion, minSwing, (referenceROM ?? 0) * minROMFraction, m.concentricDuration,
                        tempoRange.lowerBound, tempoRange.upperBound))
            WKInterfaceDevice.current().play(.retry)      // different buzz: "that one did not count"
            // A rep that starts and stalls right after the reps slowed down = the muscle gave out.
            if reps >= 3, !afterHold, let best = repVelocities.max(), let last = repVelocities.last,
               Velocity.loss(current: last, best: best) >= 0.30,
               m.rangeOfMotion < 0.7 * (referenceROM ?? 100) {      // a real stall, not a slightly short rep
                stalledAtFailure = true
                qlog("FAILURE: a rep stalled after the set had slowed down. Counted as reaching muscle failure.")
            }
            return
        }
        // Lifting the arm to look at the Watch looks like a curl but is slower. After a pause, the first
        // rep must be about as fast as the reps before it.
        if afterHold, !repDurations.isEmpty {
            let medDur = median(Array(repDurations.suffix(3))), medSpeed = median(Array(repSpeeds.suffix(3)))   // recent reps: tired reps are slower
            if m.concentricDuration > 2.5 * medDur || m.meanConcentricSpeed < 0.4 * medSpeed {
                qlog(String(format: "NOT A REP (looks like moving the arm): up-time %.2f s vs usual %.2f s, speed %.0f vs usual %.0f deg/s",
                            m.concentricDuration, medDur, m.meanConcentricSpeed, medSpeed))
                return
            }
        }
        afterHold = false
        repDurations.append(m.concentricDuration)
        if referenceROM == nil {
            calibrationROMs.append(m.rangeOfMotion)
            if calibrationROMs.count >= 3 { referenceROM = calibrationROMs.sorted()[1] }   // median of 3
        }
        reps += 1
        repSpeeds.append(m.meanConcentricSpeed)
        let velocity = Velocity.linear(degPerSec: m.meanConcentricSpeed,
                                       radiusM: Velocity.handRadius(heightM: journey.heightM))
        repVelocities.append(velocity)
        repShakes.append(m.shake)
        qlog(String(format: "      shake %.2f rad/s  (first 3 reps of this set: %.2f)", m.shake, repShakes.prefix(3).reduce(0, +) / Double(min(3, repShakes.count))))
        buzzRep()
        qlog(String(format: "REP %d/%d  top %.0f deg  ROM %.0f deg  up-time %.2f s  speed %.0f deg/s = %.2f m/s  loss vs fastest %.0f%%",
                    reps, targetReps, m.peakAngle, m.rangeOfMotion, m.concentricDuration, m.meanConcentricSpeed, velocity,
                    Velocity.loss(current: velocity, best: repVelocities.max() ?? velocity) * 100))
        // Fatigue alert: this rep is much slower than the fastest rep of the set.
        if !alertedThisSet, reps >= 3, Velocity.loss(current: velocity, best: repVelocities.max() ?? velocity) >= Velocity.alertLoss {
            alertedThisSet = true
            WKInterfaceDevice.current().play(.directionDown)
        }

        holding = false
        // The set does NOT stop at the target (more reps = the weight is too light). A pause in motion,
        // like flipping the wrist to look at the Watch, only HOLDS the set: reps are kept and the next
        // rep continues it. The set ends with the Done button, or after a long pause.
        if reps == targetReps { WKInterfaceDevice.current().play(.directionUp) }   // "target reached"
        armIdleTimer()
    }

    private func armIdleTimer() {
        idleTask?.cancel()
        idleTask = Task {
            try? await Task.sleep(for: .seconds(4.5))
            if Task.isCancelled { return }
            qlog("SET HELD at \(reps) reps (no rep for 4.5 s). Next rep continues it.")
            afterHold = true
            holding = true                                   // shows "Keep going or tap Done"
            let longWait: Double = reps >= targetReps ? 12 : 90
            try? await Task.sleep(for: .seconds(longWait))
            if !Task.isCancelled { finishSet() }
        }
    }

    private func median(_ values: [Double]) -> Double {
        let v = values.sorted()
        return v.isEmpty ? 0 : v[v.count / 2]
    }

    private func buzzRep() {
        let d = WKInterfaceDevice.current()
        d.play(.click)
        Task { try? await Task.sleep(for: .milliseconds(90)); d.play(.click) }
    }

    /// Done button on the Watch.
    func doneSet() { finishSet() }

    private func finishSet() {
        guard phase == .activeSet, reps > 0 else { return }
        idleTask?.cancel()
        holding = false
        motion.endSet()
        WKInterfaceDevice.current().play(.success)

        results.append(SetResult(index: currentSet, weightKg: plan.weightKg, reps: reps,
                                 rejectedReps: rejected, targetReps: targetReps,
                                 meanSpeed: vDSP.mean(repSpeeds),
                                 velocityLoss: Velocity.setLoss(repVelocities),
                                 e1RM: StrengthMath.estimated1RM(weight: plan.weightKg, reps: reps),
                                 meanVelocity: vDSP.mean(repVelocities),
                                 peakVelocity: repVelocities.max() ?? 0,
                                 repsInReserve: stalledAtFailure ? 0 : EffortEstimator.estimate(
                                    velocities: repVelocities,
                                    failureLoss: journey.failureLoss ?? EffortEstimator.priorFailureLoss)?.repsInReserve))

        if repShakes.count >= 6 {
            let first = repShakes.prefix(3).reduce(0, +) / 3, last = repShakes.suffix(3).reduce(0, +) / 3
            qlog(String(format: "SHAKE set %d: first 3 reps %.2f, last 3 reps %.2f rad/s  -> last is %.1fx the first", currentSet, first, last, first > 0 ? last / first : 0))
        }
        if let r = results.last {
            qlog(String(format: "SET %d DONE  good reps %d (target %d, rejected %d)  weight %.1f kg  e1RM %.1f kg  mean speed %.2f m/s  speed loss %.0f%%  reps left (estimate) %@",
                        r.index, r.reps, r.targetReps, r.rejectedReps, r.weightKg, r.e1RM, r.meanVelocity, r.velocityLoss * 100,
                        r.repsInReserve.map { String(format: "%.1f", $0) } ?? "unknown (fewer than 4 reps, or speed did not slow down)"))
        }
        if currentSet >= plan.sets || plan.calibrate {
            Task { await finishWorkout() }
        } else {
            currentSet += 1
            startRest(from: plan.restSeconds)
        }
    }

    private func startRest(from seconds: Int) {
        motion.setPoseCalibration(true)      // arm hangs while resting
        restRemaining = seconds
        phase = .rest
        flowTask?.cancel()
        flowTask = Task {
            while restRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                restRemaining -= 1
            }
            WKInterfaceDevice.current().play(.notification)
            beginCountdown()
        }
    }

    func skipRest() {
        guard phase == .rest else { return }
        beginCountdown()
    }

    func pause() {
        guard phase == .activeSet || phase == .rest else { return }
        phaseBeforePause = phase
        holding = false
        flowTask?.cancel()
        idleTask?.cancel()
        motion.endSet()
        workout.pause()
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        workout.resume()
        if phaseBeforePause == .rest {
            startRest(from: restRemaining)
        } else {
            // Continue the same set where he stopped: reps are kept.
            phase = .activeSet
            motion.beginSet()
            holding = false
            armIdleTimer()
        }
    }

    func finishWorkout() async {
        flowTask?.cancel()
        idleTask?.cancel()
        motion.stop()
        let avgHR = workout.averageHeartRate
        await workout.end()
        guard !results.isEmpty else { phase = .home; return }

        let before = store.progress

        // Test set to failure: learn this person's speed loss at failure, then stop. No progression.
        if plan.calibrate {
            if let last = results.last, last.reps >= 5 {
                store.setFailureLoss(min(max(last.velocityLoss, 0.30), 0.70))
            }
            plan.calibrate = false
            journey = store.progress
            phase = .home
            return
        }
        var outcome = Progression.evaluate(goodReps: results.map(\.reps),
                                           targets: results.map(\.targetReps),
                                           plannedSets: plan.sets,
                                           goalReps: before.goalReps, streak: before.streak,
                                           weightKg: before.weightKg)

        // The sensors can also say "this weight is too light" before the 12-rep top of the ladder.
        let load = Progression.evaluateLoad(goodReps: results.map(\.reps), targets: results.map(\.targetReps),
                                            plannedSets: plan.sets, repsInReserve: results.map(\.repsInReserve),
                                            lightStreak: before.lightStreak)
        qlog("RULE rep ladder: qualified=\(outcome.qualified) streak \(before.streak)->\(outcome.streak) goal reps \(before.goalReps)->\(outcome.goalReps) weight \(before.weightKg)->\(outcome.weightKg)")
        qlog("RULE sensor 'too light': increase=\(load.increase) lightStreak \(before.lightStreak)->\(load.lightStreak)  reps left per set \(results.map { $0.repsInReserve.map { String(format: "%.1f", $0) } ?? "n/a" })  (LAST set needs >= \(Progression.minRIRToProgress) reps left OR \(Progression.overTargetReps)+ reps over target, \(Progression.sessionsNeeded) sessions in a row)")
        if load.increase && !outcome.leveledUp {
            let bestReps = results.map(\.reps).max() ?? before.goalReps
            let newWeight = StrengthMath.nextWeight(current: before.weightKg, increment: Progression.weightIncrement,
                                                    factor: Progression.weightFactor)
            outcome.weightKg = newWeight
            outcome.goalReps = max(Progression.repFloor, min(Progression.repCeiling - 1,
                StrengthMath.repsToMatch(oldWeight: before.weightKg, oldReps: bestReps, newWeight: newWeight)))
            outcome.streak = 0
            outcome.leveledUp = true
        }
        // Readiness: first set's opening speed vs the user's usual speed at this weight.
        let opening = results.first.map { $0.peakVelocity } ?? 0
        let baseline = before.baselineVelocity[Velocity.key(forWeight: before.weightKg)]
        let readiness = Velocity.readiness(today: opening, baseline: baseline)
        if opening > 0 { store.updateBaseline(weightKg: before.weightKg, openingVelocity: opening) }
        let best = results.map { StrengthMath.estimated1RM(weight: $0.weightKg, reps: $0.reps) }.max() ?? 0
        let strengthLevel = StrengthStandards.level(e1RM: best, bodyWeightKg: before.bodyWeightKg,
                                                    sex: before.sex, mountains: Mountain.all.count)
        qlog(String(format: "STRENGTH best e1RM %.1f kg  body %@ kg  relative %@  strength level %@",
                    best, before.bodyWeightKg.map { String(format: "%.0f", $0) } ?? "unknown",
                    before.bodyWeightKg.map { String(format: "%.2f", StrengthMath.relativeStrength(e1RM: best, bodyWeightKg: $0)) } ?? "n/a",
                    strengthLevel.map { String($0) } ?? "n/a"))
        qlog(String(format: "READINESS opening speed %.2f m/s vs usual %@  -> %@", opening,
                    baseline.map { String(format: "%.2f", $0) } ?? "none yet", String(describing: readiness)))
        store.record(outcome, referenceROM: referenceROM, e1RM: best, strengthLevel: strengthLevel, lightStreak: load.lightStreak)
        journey = store.progress

        // Next workout starts from the new goal (same shape, e.g. 10-9-8 becomes 11-10-9).
        if outcome.goalReps != before.goalReps || outcome.leveledUp {
            plan.repsPerSet = Progression.suggestedReps(for: plan.repsPerSet, goal: outcome.goalReps)
        }
        plan.weightKg = outcome.weightKg
        plan.updatedAt = .now

        let summary = WorkoutSummary(date: startedAt, durationSeconds: Date().timeIntervalSince(startedAt),
                                     sets: results, weightBefore: before.weightKg, weightAfter: outcome.weightKg,
                                     levelBefore: before.level, levelAfter: journey.level,
                                     goalRepsAfter: outcome.goalReps, streakAfter: outcome.streak,
                                     qualified: outcome.qualified, leveledUp: journey.level > before.level,
                                     averageHeartRate: avgHR, e1RM: best,
                                     relativeStrength: before.bodyWeightKg.map {
                                         StrengthMath.relativeStrength(e1RM: best, bodyWeightKg: $0) },
                                     readiness: readiness)
        connectivity.send(summary: summary)
        connectivity.publish(progress: journey, plan: plan)

        var advice = Progression.Advice.keep
        if let last = results.last {
            advice = Progression.advice(reps: last.reps, target: last.targetReps,
                                        speedLoss: last.velocityLoss, stalled: last.repsInReserve == 0)
            let firstSpeed = Velocity.openingVelocity(last.peakVelocity > 0 ? [last.peakVelocity] : [0])
            qlog(String(format: "ADVICE: %@  (last set: %d reps vs target %d, fastest rep %.2f m/s, speed loss at the end %.0f%%, stalled %@)",
                        advice.rawValue, last.reps, last.targetReps, firstSpeed, last.velocityLoss * 100,
                        last.repsInReserve == 0 ? "yes" : "no"))
        }
        result = WorkoutResult(summary: summary, outcome: outcome, level: journey.level,
                               weightFrom: before.weightKg, weightTo: outcome.weightKg,
                               goodReps: summary.totalReps, advice: advice)
        phase = .result
    }

    func dismissResult() {
        result = nil
        phase = .home
    }
}
