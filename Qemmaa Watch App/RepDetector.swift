import Foundation

struct RepMetrics: Codable, Equatable {
    var meanConcentricSpeed: Double   // deg/s from the bottom to the top of the curl
    var peakSpeed: Double             // deg/s, highest instantaneous speed
    var rangeOfMotion: Double         // degrees
    var concentricDuration: Double    // seconds
}

/// Counts biceps curls from ONE number: the angle between gravity now and gravity at the
/// start of the set (arm hanging). Curling the forearm rotates gravity in the Watch's frame,
/// so the angle rises and falls once per rep. This works for any strap position and avoids
/// integrating acceleration, which drifts.
///
/// Pure logic (no CoreMotion), so it can be unit tested with synthetic data.
struct RepDetector {
    struct Config {
        var reversal = 15.0        // degrees of drop that confirms a peak
        var minROM = 50.0          // degrees; smaller movements are not reps
        var minRepInterval = 0.9   // seconds between reps (a real curl takes longer than this)
        var rearmFraction = 0.6    // after a rep the arm must come back below 60% of that peak
    }

    private enum Phase { case findingPeak, findingTrough }

    var config: Config
    private var phase = Phase.findingPeak
    private var started = false
    private var trough = 0.0, tTrough = 0.0
    private var peak = 0.0, tPeak = 0.0
    private var maxSpeed = 0.0
    private var lastRepTime = -Double.infinity
    private var needsRearm = false       // true right after a rep, until the arm has lowered again
    private var lastPeak = 0.0
    private var previous: (t: Double, a: Double)?

    init(config: Config = Config()) { self.config = config }

    /// Feed one smoothed sample. Returns metrics when a rep is confirmed at the top.
    mutating func process(time t: Double, angle a: Double) -> RepMetrics? {
        defer { previous = (t, a) }
        guard started else {
            started = true
            trough = a; tTrough = t; peak = a; tPeak = t
            return nil
        }
        switch phase {
        case .findingPeak:
            if a <= trough {
                trough = a; tTrough = t; peak = a; tPeak = t; maxSpeed = 0
            } else {
                if let p = previous, t > p.t { maxSpeed = max(maxSpeed, (a - p.a) / (t - p.t)) }
                if a > peak {
                    peak = a; tPeak = t
                } else if peak - a >= config.reversal,
                          peak - trough >= config.minROM,
                          tPeak - lastRepTime >= config.minRepInterval {
                    let duration = tPeak - tTrough
                    guard duration > 0 else { return nil }
                    let metrics = RepMetrics(meanConcentricSpeed: (peak - trough) / duration,
                                             peakSpeed: maxSpeed,
                                             rangeOfMotion: peak - trough,
                                             concentricDuration: duration)
                    lastRepTime = tPeak
                    lastPeak = peak
                    needsRearm = true
                    phase = .findingTrough
                    trough = a; tTrough = t
                    return metrics
                }
            }
        case .findingTrough:
            if a < trough { trough = a; tTrough = t }
            if needsRearm, a <= config.rearmFraction * lastPeak { needsRearm = false }
            if !needsRearm, a - trough >= config.reversal {
                phase = .findingPeak
                peak = a; tPeak = t; maxSpeed = 0
            }
        }
        return nil
    }
}
