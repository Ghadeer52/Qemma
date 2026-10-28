import Foundation

/// Double progression: first add REPS, then (at the top of the rep range) add WEIGHT and drop the reps.
///
/// Evidence and its limits are listed in EVIDENCE.md. In short:
/// - Supported: a 2-10% load increase (ACSM 2009), and similar muscle growth from about 6-35 reps
///   WHEN sets finish close to failure (Schoenfeld 2015/2017, Robinson 2024).
/// - 8-12 reps is the range ACSM gives for novices, and Epley is only reliable up to about 10-12 reps,
///   so the ceiling is 12.
/// - NOT supported by a study: +1 rep per step and exactly 2 sessions.
///
/// The numbers below are starting values. Change them in ONE place.
enum Progression {
    static let repFloor = 8          // goal after a level-up never goes below this
    static let repCeiling = 12       // top of the 8-12 range: time for a heavier weight (ACSM: 8-12RM for novices)
    static let repStep = 1           // reps added each time
    static let sessionsNeeded = 2    // consecutive successful sessions before moving up
    static let weightFactor = 1.035  // inside ACSM's 2-10% (also from the research document)
    static let weightIncrement = 1.0 // kg, smallest dumbbell step

    struct Outcome: Equatable {
        var goalReps: Int
        var streak: Int
        var weightKg: Double
        var qualified: Bool     // this session counted toward moving up
        var leveledUp: Bool     // new mountain: heavier weight, fewer reps
    }

    /// - goodReps: good reps done in each set (same order as `targets`)
    /// - targets: the reps planned for each set
    /// - plannedSets: how many sets the plan had (an unfinished workout never counts)
    static func evaluate(goodReps: [Int], targets: [Int], plannedSets: Int,
                         goalReps: Int, streak: Int, weightKg: Double,
                         increment: Double = weightIncrement) -> Outcome {
        var out = Outcome(goalReps: goalReps, streak: streak, weightKg: weightKg,
                          qualified: false, leveledUp: false)

        // Trained easier than the goal, or stopped early: no change at all.
        guard goodReps.count == targets.count, targets.count >= plannedSets,
              (targets.max() ?? 0) >= goalReps else { return out }

        // Missed a set: the "consecutive" streak starts again.
        guard zip(goodReps, targets).allSatisfy({ $0 >= $1 }) else {
            out.streak = 0
            return out
        }

        out.qualified = true
        out.streak = streak + 1
        guard out.streak >= sessionsNeeded else { return out }
        out.streak = 0

        if goalReps >= repCeiling {
            let newWeight = StrengthMath.nextWeight(current: weightKg, increment: increment, factor: weightFactor)
            let matched = StrengthMath.repsToMatch(oldWeight: weightKg, oldReps: repCeiling, newWeight: newWeight)
            out.weightKg = newWeight
            out.goalReps = max(repFloor, min(repCeiling - 1, matched))
            out.leveledUp = true
        } else {
            out.goalReps = min(repCeiling, goalReps + repStep)
        }
        return out
    }

    // MARK: Sensor-based weight decision

    /// "Too light" = the sensors say he could do at least this many more reps after hitting every target.
    /// ACSM's rule raises the load when the lifter can do 1-2 reps over the target.
    static let minRIRToProgress = 2.0

    struct LoadDecision: Equatable {
        var lightStreak: Int
        var increase: Bool
    }

    /// Weight goes up when, in 2 workouts in a row, every set hit its target AND the speed loss says
    /// he still had about 2+ reps left. This can happen BEFORE the 12-rep top of the ladder.
    static func evaluateLoad(goodReps: [Int], targets: [Int], plannedSets: Int,
                             repsInReserve: [Double?], lightStreak: Int) -> LoadDecision {
        guard goodReps.count == targets.count, targets.count >= plannedSets else {
            return LoadDecision(lightStreak: lightStreak, increase: false)   // unfinished workout
        }
        let hitAll = zip(goodReps, targets).allSatisfy { $0 >= $1 }
        let known = repsInReserve.compactMap { $0 }.sorted()
        guard hitAll, known.count * 2 >= targets.count else {
            return LoadDecision(lightStreak: 0, increase: false)
        }
        let median = known[known.count / 2]
        guard median >= minRIRToProgress else { return LoadDecision(lightStreak: 0, increase: false) }
        let streak = lightStreak + 1
        return streak >= sessionsNeeded ? LoadDecision(lightStreak: 0, increase: true)
                                        : LoadDecision(lightStreak: streak, increase: false)
    }

    /// 0...1 progress from the first goal to the top of the ladder (drives the Watch ring).
    static func ladderFraction(goalReps: Int, streak: Int) -> Double {
        let steps = Double((goalReps - repFloor) * sessionsNeeded + streak)
        let total = Double((repCeiling - repFloor + 1) * sessionsNeeded)
        return min(max(steps / total, 0), 1)
    }

    /// Keeps the user's shape (10, 9, 8) but moves it so the biggest set equals the new goal.
    static func suggestedReps(for current: [Int], goal: Int) -> [Int] {
        guard let top = current.max() else { return [goal] }
        let shift = goal - top
        return current.map { max(1, min(repCeiling, $0 + shift)) }
    }
}
