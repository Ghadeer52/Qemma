import Foundation

enum Sex: String, Codable { case male, female }

/// Turns "how strong is this person?" into a mountain level.
/// relative strength = estimated 1RM / body weight   (the formula from the research document)
enum StrengthStandards {

    /// Lowest relative strength for mountain 1, 2, 3 ...
    ///
    /// MALE: the research document says 0.37x-0.50x bodyweight is "intermediate" for free-weight
    ///       curls, so mountain 2 starts at 0.37 and mountain 3 at 0.50.
    /// FEMALE: DERIVED, not sourced: male values x 0.77, the ratio of the female and male
    ///       "intermediate" strict-curl standards on Strength Level (0.50 / 0.65).
    ///       Replace these with a sourced table before you rely on them.
    /// Add more mountains by adding more bounds (keep Mountain.all the same length).
    static func lowerBounds(for sex: Sex) -> [Double] {
        switch sex {
        case .male:   return [0, 0.37, 0.50]
        case .female: return [0, 0.28, 0.38]
        }
    }

    /// 0...1: how far the user is between the start of their mountain and the start of the next one.
    /// This is the bar that fills on the Watch. nil if body weight or sex is unknown.
    static func progressToNext(e1RM: Double, bodyWeightKg: Double?, sex: Sex?, level: Int, mountains: Int) -> Double? {
        guard let bw = bodyWeightKg, bw > 0, let sex else { return nil }
        let bounds = lowerBounds(for: sex)
        guard level >= 1, level < min(bounds.count, mountains) else { return 1 }
        let ratio = StrengthMath.relativeStrength(e1RM: e1RM, bodyWeightKg: bw)
        let lower = bounds[level - 1], upper = bounds[level]
        return min(max((ratio - lower) / (upper - lower), 0), 1)
    }

    /// 1-based mountain level, or nil if we don't know the body weight or sex yet.
    static func level(e1RM: Double, bodyWeightKg: Double?, sex: Sex?, mountains: Int) -> Int? {
        guard let bw = bodyWeightKg, bw > 0, let sex else { return nil }
        let ratio = StrengthMath.relativeStrength(e1RM: e1RM, bodyWeightKg: bw)
        let reached = lowerBounds(for: sex).filter { ratio >= $0 }.count
        return min(max(reached, 1), mountains)
    }
}
