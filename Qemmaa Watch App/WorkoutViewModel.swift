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
    private var rejected = 0
    private var results: [SetResult] = []
    private var startedAt = Date()
    private var flowTask: Task<Void, Never>?
    private var idleTask: Task<Void, Never>?
    private var phaseBeforePause: Phase = .activeSet

    // Rep quality ("good rep"): full range of motion and a controlled tempo.
    private var referenceROM: Double?
    private var calibrationROMs: [Double] = []
    private let minROMFraction = 0.8   // consistency check, NOT from a study (see EVIDENCE.md)
    // Research: whole reps of 0.5-8 s give similar hypertrophy (Schoenfeld 2015). We only time the
    // lifting half, so 0.25-4 s assumes the lowering takes about as long. This is an assumption.
    private let tempoRange: ClosedRange<Double> = 0.25...4.0

    init() {
        journey = store.progress
        referenceROM = journey.referenceROM
        plan.weightKg = journey.weightKg
        plan.repsPerSet = Array(repeating: journey.goalReps, count: plan.repsPerSet.count)
        motion.onRep = { [weak self] metrics in
            Task { @MainActor in self?.handleRep(metrics) }
        }
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
        repSpeeds = []
        repVelocities = []
        alertedThisSet = false
        phase = .activeSet
        motion.beginSet()            // captures "arm hanging" as 0 degrees
        WKInterfaceDevice.current().play(.start)
    }

    /// A rep only counts when the range of motion is close to the user's normal and the tempo is
    /// controlled (no swinging). The first 3 reps ever recorded set the normal range.
    private func isGood(_ m: RepMetrics) -> Bool {
        guard tempoRange.contains(m.concentricDuration) else { return false }
        guard let ref = referenceROM else { return true }
        return m.rangeOfMotion >= minROMFraction * ref
    }

    private func handleRep(_ m: RepMetrics) {
        guard phase == .activeSet else { return }
        guard isGood(m) else {
            rejected += 1
            WKInterfaceDevice.current().play(.retry)      // different buzz: "that one did not count"
            return
        }
        if referenceROM == nil {
            calibrationROMs.append(m.rangeOfMotion)
            if calibrationROMs.count >= 3 { referenceROM = calibrationROMs.sorted()[1] }   // median of 3
        }
        reps += 1
        repSpeeds.append(m.meanConcentricSpeed)
        let velocity = Velocity.linear(degPerSec: m.meanConcentricSpeed,
                                       radiusM: Velocity.handRadius(heightM: journey.heightM))
        repVelocities.append(velocity)
        WKInterfaceDevice.current().play(.click)
        // Fatigue alert: this rep is much slower than the fastest rep of the set.
        if !alertedThisSet, reps >= 3, Velocity.loss(current: velocity, best: repVelocities.max() ?? velocity) >= Velocity.alertLoss {
            alertedThisSet = true
            WKInterfaceDevice.current().play(.directionDown)
        }

        idleTask?.cancel()
        // The set does NOT stop at the target: more reps tell us the weight is too light, and stopping
        // early would hide how hard the set really was. It ends by itself 5 s after the last rep.
        if reps == targetReps { WKInterfaceDevice.current().play(.directionUp) }   // "target reached"
        let wait: Double = reps >= 40 ? 0.5 : 5
        idleTask = Task {
            try? await Task.sleep(for: .seconds(wait))
            if !Task.isCancelled { finishSet() }
        }
    }

    private func finishSet() {
        guard phase == .activeSet, reps > 0 else { return }
        idleTask?.cancel()
        motion.endSet()
        WKInterfaceDevice.current().play(.success)

        results.append(SetResult(index: currentSet, weightKg: plan.weightKg, reps: reps,
                                 rejectedReps: rejected, targetReps: targetReps,
                                 meanSpeed: vDSP.mean(repSpeeds),
                                 velocityLoss: Velocity.setLoss(repVelocities),
                                 e1RM: StrengthMath.estimated1RM(weight: plan.weightKg, reps: reps),
                                 meanVelocity: vDSP.mean(repVelocities),
                                 peakVelocity: repVelocities.max() ?? 0,
                                 repsInReserve: EffortEstimator.estimate(
                                    velocities: repVelocities,
                                    failureLoss: journey.failureLoss ?? EffortEstimator.priorFailureLoss)?.repsInReserve))

        if currentSet >= plan.sets || plan.calibrate {
            Task { await finishWorkout() }
        } else {
            currentSet += 1
            startRest(from: plan.restSeconds)
        }
    }

    private func startRest(from seconds: Int) {
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
            beginCountdown()       // the interrupted set restarts from 0 reps
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

        result = WorkoutResult(summary: summary, outcome: outcome, level: journey.level,
                               weightFrom: before.weightKg, weightTo: outcome.weightKg,
                               goodReps: summary.totalReps)
        phase = .result
    }

    func dismissResult() {
        result = nil
        phase = .home
    }
}
