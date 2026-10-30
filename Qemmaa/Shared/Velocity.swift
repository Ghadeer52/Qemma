import Foundation

/// Velocity-based training (VBT) logic: the standard method behind apps like Spleeft and AccelIntel.
/// (Their source code is not public. This is the published method, written from scratch.)
///
/// 1. Mean concentric velocity (MCV) = average speed of the weight while it is being lifted.
/// 2. Velocity loss = how much slower a rep is than the fastest rep of the set. It tracks fatigue.
/// 3. Readiness = today's first-rep speed compared with the user's own earlier speed at the same weight.
///
/// The Watch measures the FOREARM ANGLE, so speed starts in degrees per second. The weight in the hand
/// moves on a circle around the elbow, so  speed (m/s) = angular speed (rad/s) x radius (m).
enum Velocity {

    /// Velocity loss at which the Watch buzzes ("this rep was 30% slower than your best").
    /// Studies compared stopping sets at 20% and 40% loss (Pareja-Blanco 2017). 30% is a starting value.
    static let alertLoss = 0.30

    /// Distance from the elbow to the centre of a dumbbell in the hand, from body proportions:
    /// forearm about 0.146 x height plus half a hand (about 0.054 x height)  =  about 0.20 x height
    /// (Drillis and Contini 1966, quoted from memory: VERIFY before you rely on it).
    /// 1.70 m is used when the Health app has no height.
    static func handRadius(heightM: Double?) -> Double {
        0.20 * (heightM ?? 1.70)
    }

    static func linear(degPerSec: Double, radiusM: Double) -> Double {
        degPerSec * .pi / 180 * radiusM
    }

    /// 0...1. How much slower `current` is than `best`.
    static func loss(current: Double, best: Double) -> Double {
        guard best > 0 else { return 0 }
        return min(max((best - current) / best, 0), 1)
    }

    /// Speed loss of a whole set: the MEDIAN of the first 3 reps versus the MEDIAN of the last 3 reps
    /// (2 and 2 for short sets). Medians, because one fast or odd rep (a jerk, a wrist flip) must not decide
    /// the set: "fastest rep" was inflated by single fast reps in the 30 Oct failure sets.
    static func setLoss(_ repVelocities: [Double]) -> Double {
        let n = repVelocities.count
        guard n >= 2 else { return 0 }
        let k = min(3, n / 2)
        func median(_ a: ArraySlice<Double>) -> Double { let s = a.sorted(); return s[s.count / 2] }
        return loss(current: median(repVelocities.suffix(k)), best: median(repVelocities.prefix(k)))
    }

    /// Fastest of the first two reps (one slow first rep should not fool us).
    static func openingVelocity(_ repVelocities: [Double]) -> Double {
        repVelocities.prefix(2).max() ?? 0
    }

    /// Today vs the user's own baseline at this weight. 1.0 = normal, 0.9 = 10% slower than usual.
    static func readiness(today: Double, baseline: Double?) -> Double? {
        guard let baseline, baseline > 0 else { return nil }
        return today / baseline
    }

    /// Slowly moving average, so one bad day does not rewrite the baseline.
    static func updatedBaseline(old: Double?, new: Double, alpha: Double = 0.3) -> Double {
        guard let old else { return new }
        return old + alpha * (new - old)
    }

    /// Baselines are kept per working weight (rounded to whole kg).
    static func key(forWeight kg: Double) -> Int { Int(kg.rounded()) }
}
