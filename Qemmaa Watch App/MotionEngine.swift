import CoreMotion
import simd
import Foundation
import WatchKit

/// Reads CMDeviceMotion (gravity already separated from user movement) at 50 Hz and turns it
/// into rep events. Device motion keeps running only while an HKWorkoutSession is active.
/// All mutable state is touched only on `queue`.
///
/// Angle = how far the forearm is from hanging straight down (0 = down, 90 = horizontal, 180 = up).
/// It uses only gravity along the forearm. The strap wraps around the wrist at 12 and 6 o'clock, so the forearm
/// runs along the Watch's x axis (3 to 9 o'clock, the crown axis). Rolling the wrist turns the Watch around
/// that axis and leaves it unchanged, so a roll cannot look like a curl,
/// and it does NOT depend on where the arm was when the set started.
final class MotionEngine {
    private let manager = CMMotionManager()      // create exactly one per app
    private let queue = OperationQueue()
    private var detector = RepDetector()
    private var recentGravity: [SIMD3<Double>] = []
    private var smoothed: Double?
    private var detecting = false
    private var sampleCount = 0
    private var lastTraced = -999.0
    // Shake (tremor) measurement: the wrist rotation rate minus its slow part = the fast wobble.
    private var slowRot = SIMD3<Double>.zero
    private var shakeSum = 0.0
    private var shakeCount = 0
    // Failed-attempt logger (log only, does not touch counting): the arm rises 20+ deg and comes back
    // without becoming a full rep. A real failed rep at the end of a set should look like this.
    private var attInit = false, attRising = false
    private var attTrough = 0.0, attPeak = 0.0
    private let slowAlpha = 0.31          // one-pole low-pass at about 3.5 Hz when sampling at 50 Hz
    /// Debug: print the forearm angle 5 times a second while a set is active (filter the console with [Qemma]).
    var traceAngles = true

    /// +1 or -1: which way the Watch's x axis points along the forearm (depends on how it is worn).
    /// Learned the first time the arm hangs still, then remembered.
    private var sign: Double
    private let signKey = "qemma.forearmSign3"   // new key: a wrong sign learned on 30 Oct is forgotten
    private var poseCalibration = false      // true during countdown and rest: the arm is hanging then
    private var stillWindow: [SIMD3<Double>] = []   // last 2 s of gravity, for the slow, careful pose learning
    private var poseCalStart: Double?
    private var flipVotes = 0
    private var lastVoteTime = -100.0               // when this calibration window opened

    /// The view model turns this on between sets. While on, a still, vertical arm teaches the app which end is "down".
    func setPoseCalibration(_ on: Bool) { queue.addOperation { [self] in poseCalibration = on; poseCalStart = nil } }

    /// Called on the motion queue. Hop to the main actor before touching UI.
    var onRep: ((RepMetrics) -> Void)?

    init() {
        let saved = UserDefaults.standard.double(forKey: signKey)
        if saved != 0 {
            sign = saved
        } else {
            // First guess from the Watch settings: +1 when the crown points toward the hand.
            // Corrected below whenever the arm is seen hanging still between sets.
            let d = WKInterfaceDevice.current()
            let crownTowardHand = (d.wristLocation == .left && d.crownOrientation == .right)
                               || (d.wristLocation == .right && d.crownOrientation == .left)
            sign = crownTowardHand ? 1 : -1
        }
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
    }

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start(hz: Double = 50) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / hz
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.handle(motion)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        queue.addOperation { [weak self] in self?.detecting = false }
    }

    /// Call when the countdown ends. Counting starts right away; no starting pose is needed.
    func beginSet() {
        queue.addOperation { [self] in
            // If the arm is hanging still as the set starts, that tells us which end of the axis is "down".
            if recentGravity.count == 25 {
                let mean = recentGravity.reduce(.zero, +) / 25
                if abs(mean.x) > 0.9, recentGravity.allSatisfy({ simd_length($0 - mean) < 0.10 }) {
                    let learned: Double = mean.x > 0 ? 1 : -1
                    if learned != sign {
                        sign = learned
                        UserDefaults.standard.set(learned, forKey: signKey)
                        qlog("Forearm direction learned at set start: \(learned > 0 ? "+" : "-")")
                    }
                }
            }
            detector = RepDetector()
            smoothed = nil
            slowRot = .zero; shakeSum = 0; shakeCount = 0
            attInit = false; attRising = false
            detecting = true
        }
    }

    func endSet() {
        queue.addOperation { [self] in detecting = false }
    }

    private func handle(_ m: CMDeviceMotion) {
        let g = SIMD3(m.gravity.x, m.gravity.y, m.gravity.z)
        recentGravity.append(g)
        if recentGravity.count > 25 { recentGravity.removeFirst() }   // about 0.5 s

        stillWindow.append(g)
        if stillWindow.count > 100 { stillWindow.removeFirst() }
        if poseCalibration, poseCalStart == nil { poseCalStart = m.timestamp }

        // Between sets the arm hangs: learn (and remember) which way the forearm axis points.
        // Careful: right after a set the arm is often still at the TOP of the curl while the user taps Done
        // (that taught the wrong direction on 30 Oct and measured the lowering instead of the lifting).
        // So: wait 5 s into the rest, and need 2 s of complete stillness.
        if poseCalibration, let start = poseCalStart, m.timestamp - start > 5, stillWindow.count == 100 {
            let mean = stillWindow.reduce(.zero, +) / 100
            if abs(mean.x) > 0.85, stillWindow.allSatisfy({ simd_length($0 - mean) < 0.08 }) {
                let learned: Double = mean.x > 0 ? 1 : -1
                // Looking at the Watch during rest also gives a "still" pose, but with the forearm raised.
                // So the saved direction only flips after 3 disagreeing windows, each 3 s apart.
                if learned == sign {
                    flipVotes = 0
                } else if m.timestamp - lastVoteTime > 3 {
                    flipVotes += 1
                    lastVoteTime = m.timestamp
                    qlog("Forearm direction doubt \(flipVotes)/3 (\(learned > 0 ? "+" : "-"))")
                    if flipVotes >= 3 {
                        sign = learned
                        flipVotes = 0
                        UserDefaults.standard.set(learned, forKey: signKey)
                        qlog("Forearm direction learned: \(learned > 0 ? "+" : "-")")
                    }
                }
            }
        }
        guard detecting else { return }

        let angle = acos(max(-1, min(1, sign * g.x))) * 180 / .pi
        sampleCount += 1
        if traceAngles, sampleCount % 12 == 0 {
            qlog(String(format: "RAW angle %3.0f | g %+.2f %+.2f %+.2f | rot %+.1f %+.1f %+.1f rad/s",
                        angle, g.x, g.y, g.z, m.rotationRate.x, m.rotationRate.y, m.rotationRate.z))
        }
        // Shake: energy of the rotation rate above about 3.5 Hz (a curl itself moves at about 1 Hz).
        let rot = SIMD3(m.rotationRate.x, m.rotationRate.y, m.rotationRate.z)
        slowRot += slowAlpha * (rot - slowRot)
        let fast = rot - slowRot
        shakeSum += simd_length_squared(fast)
        shakeCount += 1
        let s = smoothed.map { $0 + 0.35 * (angle - $0) } ?? angle   // one-pole low-pass
        smoothed = s

        if !attInit { attInit = true; attTrough = s; attPeak = s }
        if !attRising {
            if s < attTrough { attTrough = s }
            else if s - attTrough >= 20 { attRising = true; attPeak = s }
        } else if s > attPeak {
            attPeak = s
        } else if attPeak - s >= 12 {
            let rise = attPeak - attTrough
            if rise < 45 {
                qlog(String(format: "ATTEMPT: arm rose %.0f deg (to %.0f) and came back, not a full curl. Possible failed rep or a small movement.", rise, attPeak))
            }
            attRising = false; attTrough = s
        }

        if var rep = detector.process(time: m.timestamp, angle: s) {
            rep.shake = shakeCount > 0 ? (shakeSum / Double(shakeCount)).squareRoot() : 0
            shakeSum = 0; shakeCount = 0
            onRep?(rep)
        }
    }
}
