import Foundation

/// Uses the Watch sensors to answer "how many more reps could he have done?" (reps in reserve, RIR).
///
/// Research: in a set, speed falls rep after rep, and the loss of speed tracks how close the muscle is
/// to failure. Bench press and squat: R2 = 0.97 and 0.93 (Rodriguez-Rosell et al. 2020, J Strength Cond Res
/// 34(9):2537-2547; Gonzalez-Badillo et al. 2017). One study found velocity loss NOT accurate for the prone
/// bench pull, so it depends on the exercise. Nobody has shown it for biceps curls: see VALIDATION.md.
///
/// Method: fit a straight line to the rep speeds, then see after how many reps the speed would have
/// fallen by `failureLoss` (the speed loss at which this person fails). More reps than he did = reps in reserve.
enum EffortEstimator {

    /// Speed loss at the last rep of a set to failure. About 0.5 for bench press at 50-70% 1RM (prior,
    /// NOT measured for curls). A "test set to failure" replaces it with the user's own value.
    static let priorFailureLoss = 0.50

    struct Estimate: Equatable {
        var maxReps: Double
        var repsInReserve: Double
    }

    /// Needs at least 4 good reps. Returns nil when there is not enough data.
    static func estimate(velocities: [Double], failureLoss: Double = priorFailureLoss) -> Estimate? {
        let n = velocities.count
        guard n >= 4, failureLoss > 0 else { return nil }

        // Least-squares line: v = a + b * index
        let count = Double(n)
        let meanX = (count - 1) / 2
        let meanY = velocities.reduce(0, +) / count
        var num = 0.0, den = 0.0
        for (i, v) in velocities.enumerated() {
            num += (Double(i) - meanX) * (v - meanY)
            den += (Double(i) - meanX) * (Double(i) - meanX)
        }
        let slope = num / den
        let start = meanY - slope * meanX
        guard start > 0 else { return nil }

        // Speed not falling at all: very far from failure. Capped at 10 reps in reserve.
        guard slope < -0.0001 else { return Estimate(maxReps: count + 10, repsInReserve: 10) }

        let failureSpeed = (1 - failureLoss) * start
        let maxReps = (failureSpeed - start) / slope + 1
        return Estimate(maxReps: maxReps, repsInReserve: min(max(maxReps - count, 0), 10))
    }

    /// From a set taken to failure: the speed loss of its last rep versus its fastest rep,
    /// kept inside 0.30...0.70 so one odd set cannot break the estimate.
    static func failureLoss(fromSetToFailure velocities: [Double]) -> Double? {
        guard velocities.count >= 5 else { return nil }
        return min(max(Velocity.setLoss(velocities), 0.30), 0.70)
    }
}
