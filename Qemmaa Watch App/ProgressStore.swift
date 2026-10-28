import Foundation

/// Saves progress on the Watch (UserDefaults is enough for v1; move to SwiftData later).
final class ProgressStore {
    private let key = "qemma.progress.v2"
    private(set) var progress: JourneyProgress
    /// Strength is generally kept for up to ~4 weeks without training (Mujika & Padilla), so no penalty before that.
    static let inactivityDaysPerLevelLost = 28

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(JourneyProgress.self, from: data) {
            progress = saved
        } else {
            progress = JourneyProgress()
        }
        applyInactivityDecay()
    }

    /// "The user drops back a level after a while without lifting."
    /// Each lost level also lowers the weight about 5% and restarts the rep ladder.
    /// The 5% is a DESIGN CHOICE: trained people lost about 7.5% of max force after 8 weeks off.
    func applyInactivityDecay(now: Date = .now) {
        let days = Calendar.current.dateComponents([.day], from: progress.lastActivity, to: now).day ?? 0
        let lost = days / Self.inactivityDaysPerLevelLost
        guard lost > 0 else { return }
        progress.level = max(1, progress.level - lost)
        let reduced = progress.weightKg * pow(0.95, Double(lost))
        progress.weightKg = max(1, StrengthMath.roundToIncrement(reduced, increment: Progression.weightIncrement))
        progress.goalReps = Progression.repFloor
        progress.streak = 0
        progress.lastActivity = now      // so it doesn't drop again on every launch
        save()
    }

    func setWeight(_ kg: Double) {
        progress.weightKg = kg
        save()
    }

    func setProfile(bodyWeightKg: Double?, sex: Sex?, heightM: Double?) {
        if let bodyWeightKg { progress.bodyWeightKg = bodyWeightKg }
        if let heightM { progress.heightM = heightM }
        if let sex { progress.sex = sex }
        save()
    }

    /// Saves the result of a workout.
    /// - strengthLevel: the mountain the user's strength has reached (nil if body weight is unknown).
    ///   Levels only go up from training; they go down only through inactivity.
    func record(_ outcome: Progression.Outcome, referenceROM: Double?, e1RM: Double, strengthLevel: Int?, lightStreak: Int) {
        progress.lightStreak = lightStreak
        if let strengthLevel {
            progress.level = max(progress.level, min(strengthLevel, Mountain.all.count))
        } else if outcome.leveledUp {
            progress.level = min(progress.level + 1, Mountain.all.count)   // fallback without body weight
        }
        progress.e1RM = e1RM
        progress.weightKg = outcome.weightKg
        progress.goalReps = outcome.goalReps
        progress.streak = outcome.streak
        progress.referenceROM = referenceROM ?? progress.referenceROM
        progress.lastActivity = .now
        save()
    }

    /// Learned from a test set to failure (smoothed with the previous value).
    func setFailureLoss(_ value: Double) {
        progress.failureLoss = progress.failureLoss.map { $0 + 0.5 * (value - $0) } ?? value
        save()
    }

    /// Remembers the user's usual opening speed at this weight (m/s).
    func updateBaseline(weightKg: Double, openingVelocity: Double) {
        let key = Velocity.key(forWeight: weightKg)
        progress.baselineVelocity[key] = Velocity.updatedBaseline(old: progress.baselineVelocity[key],
                                                                  new: openingVelocity)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
