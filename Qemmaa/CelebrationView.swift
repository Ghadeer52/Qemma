import SwiftUI

/// Fireworks and confetti for a few seconds. Shown on the map when the user reaches the next level.
/// It ignores touches, so it never blocks the screen under it.
struct CelebrationView: View {
    private struct Spark { let burst: Int; let angle: Double; let speed: Double; let color: Int }
    private struct Piece { let x: Double; let delay: Double; let fall: Double; let spin: Double; let sway: Double; let color: Int; let size: Double }

    private let palette: [Color] = [.qGold, .qGoldLight, .qViolet, .qVioletLight, .white]
    private let duration = 4.5
    // Where and when each firework opens (x, y as fractions of the screen, start second).
    private let bursts: [(x: Double, y: Double, at: Double)] = [(0.30, 0.28, 0.0), (0.72, 0.22, 0.5), (0.50, 0.40, 1.1), (0.20, 0.50, 1.7), (0.80, 0.45, 2.2)]
    private let sparks: [Spark]
    private let pieces: [Piece]
    @State private var start = Date()

    init() {
        var s: [Spark] = []
        for b in 0..<5 {
            for i in 0..<32 {
                s.append(Spark(burst: b, angle: Double(i) / 32 * 2 * .pi + Double.random(in: -0.08...0.08),
                               speed: Double.random(in: 70...150), color: Int.random(in: 0..<5)))
            }
        }
        sparks = s
        pieces = (0..<70).map { _ in
            Piece(x: .random(in: 0...1), delay: .random(in: 0...1.5), fall: .random(in: 180...320),
                  spin: .random(in: 2...8), sway: .random(in: 10...30), color: .random(in: 0..<5), size: .random(in: 6...10))
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                // Fireworks
                for spark in sparks {
                    let b = bursts[spark.burst]
                    let age = t - b.at
                    guard age > 0, age < 1.6 else { continue }
                    let dist = spark.speed * (1 - exp(-3 * age)) / 3 * 3
                    let x = b.x * size.width + cos(spark.angle) * dist
                    let y = b.y * size.height + sin(spark.angle) * dist + 40 * age * age   // a little gravity
                    let fade = max(0, 1 - age / 1.6)
                    let r = 3.2 * fade + 0.6
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(palette[spark.color].opacity(fade)))
                }
                // Confetti
                for p in pieces {
                    let age = t - p.delay
                    guard age > 0 else { continue }
                    let y = -20 + p.fall * age
                    guard y < size.height + 20 else { continue }
                    let x = p.x * size.width + sin(age * 3) * p.sway
                    let fade = min(1, max(0, (duration - t) / 1.0))
                    var piece = ctx
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(age * p.spin))
                    piece.fill(Path(CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)),
                               with: .color(palette[p.color].opacity(fade)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { start = Date() }
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack { Color.qBackground.ignoresSafeArea(); CelebrationView() }
}
