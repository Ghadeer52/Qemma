import Foundation

/// Pure functions from your friend's research document. No frameworks, easy to unit test.
enum StrengthMath {

    // MARK: 1RM estimates

    /// Epley: 1RM = w * (1 + r/30). Holds up better for 10-12 reps than Brzycki.
    static func epley1RM(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    /// The 1RM we actually use. The research document warns that equations are "less accurate if reps
    /// exceed 10-12", so sets longer than 12 reps are treated as 12 (this under-estimates, on purpose).
    static func estimated1RM(weight: Double, reps: Int) -> Double {
        epley1RM(weight: weight, reps: min(reps, 12))
    }

    /// Brzycki: 1RM = w * 36 / (37 - r). Very accurate for 1-5 reps. Undefined at 37+.
    static func brzycki1RM(weight: Double, reps: Int) -> Double? {
        guard reps >= 1, reps < 37 else { return nil }
        return weight * 36 / Double(37 - reps)
    }

    /// Document: 0.37x-0.50x bodyweight is "intermediate" for free-weight curls (males).
    static func relativeStrength(e1RM: Double, bodyWeightKg: Double) -> Double {
        bodyWeightKg > 0 ? e1RM / bodyWeightKg : 0
    }

    // MARK: Progression helpers

    static func roundToIncrement(_ value: Double, increment: Double) -> Double {
        (value / increment).rounded() * increment
    }

    /// Document: New Weight = RoundToNearestIncrement(Current * 1.035).
    /// CATCH: for light dumbbells that rounds back to the SAME weight (10 * 1.035 = 10.35 -> 10),
    /// so we always move up at least one increment.
    static func nextWeight(current: Double, increment: Double = 1.0, factor: Double = 1.035) -> Double {
        max(roundToIncrement(current * factor, increment: increment), current + increment)
    }

    /// How many reps at the NEW weight feel like the old weight x old reps.
    /// Keeps the estimated 1RM equal (Epley), rounded DOWN to stay on the safe side.
    /// WARNING: prediction equations are reliable only up to about 10 reps and tend to over-predict
    /// above that. Above 12 reps it is a rough guess, not a validated number.
    static func repsToMatch(oldWeight: Double, oldReps: Int, newWeight: Double) -> Int {
        guard newWeight > 0 else { return oldReps }
        let oneRM = epley1RM(weight: oldWeight, reps: oldReps)
        return max(1, Int((30 * (oneRM / newWeight - 1)).rounded(.down)))
    }

    /// How much slower the last reps were than the first (information, shown in the iPhone summary).
    static func velocityLoss(first: Double, last: Double) -> Double {
        guard first > 0 else { return 0 }
        return max(0, (first - last) / first)
    }
}
