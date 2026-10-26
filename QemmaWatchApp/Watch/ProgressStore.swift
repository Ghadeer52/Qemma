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

    /// Saves the result of a workout.
    func record(_ outcome: Progression.Outcome, referenceROM: Double?) {
        if outcome.leveledUp { progress.level = min(progress.level + 1, Mountain.all.count) }
        progress.weightKg = outcome.weightKg
        progress.goalReps = outcome.goalReps
        progress.streak = outcome.streak
        progress.referenceROM = referenceROM ?? progress.referenceROM
        progress.lastActivity = .now
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
