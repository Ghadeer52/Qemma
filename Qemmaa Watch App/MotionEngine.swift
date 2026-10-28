import CoreMotion
import simd

/// Reads CMDeviceMotion (gravity already separated from user movement) at 50 Hz and turns it
/// into rep events. Device motion keeps running only while an HKWorkoutSession is active.
/// All mutable state is touched only on `queue`.
final class MotionEngine {
    private let manager = CMMotionManager()      // create exactly one per app
    private let queue = OperationQueue()
    private var detector = RepDetector()
    private var recentGravity: [SIMD3<Double>] = []
    private var reference: SIMD3<Double>?
    private var smoothed: Double?
    private var detecting = false

    /// Called on the motion queue. Hop to the main actor before touching UI.
    var onRep: ((RepMetrics) -> Void)?

    init() {
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

    /// Call when the countdown ends. The arm should be hanging; that pose is "0 degrees".
    func beginSet() {
        queue.addOperation { [self] in
            if !recentGravity.isEmpty {
                reference = recentGravity.reduce(.zero, +) / Double(recentGravity.count)
            }
            detector = RepDetector()
            smoothed = nil
            detecting = reference != nil
        }
    }

    func endSet() {
        queue.addOperation { [self] in detecting = false }
    }

    private func handle(_ m: CMDeviceMotion) {
        let g = SIMD3(m.gravity.x, m.gravity.y, m.gravity.z)
        recentGravity.append(g)
        if recentGravity.count > 25 { recentGravity.removeFirst() }   // about 0.5 s
        guard detecting, let ref = reference else { return }

        let cosine = max(-1, min(1, simd_dot(simd_normalize(g), simd_normalize(ref))))
        let angle = acos(cosine) * 180 / .pi
        let s = smoothed.map { $0 + 0.35 * (angle - $0) } ?? angle   // one-pole low-pass
        smoothed = s

        if let rep = detector.process(time: m.timestamp, angle: s) {
            onRep?(rep)
        }
    }
}
