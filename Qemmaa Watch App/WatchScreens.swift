import SwiftUI

// Qemma Watch screens (biceps curl only).
// Needs: Colors.swift + WatchColors.swift, and the color assets in the Watch target.

// MARK: - Reusable pieces

/// Ring that fills from the top. progress is 0...1.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var gradient: LinearGradient = .qGoldGradient

    var body: some View {
        ZStack {
            Circle().stroke(Color.qRingTrack, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// Capsule button used for OK / Play / Skip.
struct PillButton<Label: View>: View {
    var fill: AnyShapeStyle = AnyShapeStyle(LinearGradient.qGoldGradient)
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Mountain drawn from points in a 208 x 248 box, scaled to fit.
struct MountainShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / 208, sy = rect.height / 248
        for (i, p) in points.enumerated() {
            let point = CGPoint(x: rect.minX + p.x * sx, y: rect.minY + p.y * sy)
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    static let back = MountainShape(points: [
        .init(x: 0, y: 150), .init(x: 40, y: 105), .init(x: 62, y: 128), .init(x: 104, y: 62),
        .init(x: 134, y: 100), .init(x: 158, y: 84), .init(x: 208, y: 130),
        .init(x: 208, y: 248), .init(x: 0, y: 248)])

    static let front = MountainShape(points: [
        .init(x: 0, y: 190), .init(x: 50, y: 150), .init(x: 88, y: 178), .init(x: 132, y: 124),
        .init(x: 170, y: 165), .init(x: 208, y: 150), .init(x: 208, y: 248), .init(x: 0, y: 248)])
}

struct Mountains: View {
    var body: some View {
        ZStack {
            MountainShape.back.fill(Color.qMountain)
            MountainShape.front.fill(
                LinearGradient(colors: [.qGoldLight, .qGoldDeep], startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: - 1. Welcome
struct WelcomeWatchView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Mountains().padding(.top, 60).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Welcome to").foregroundStyle(Color.qText)
                Text("Qemma").foregroundStyle(Color.qGold)
            }
            .font(.title3.bold())
        }
    }
}

// MARK: - 2. Set weight (Digital Crown scrolls the wheel)
struct SetWeightWatchView: View {
    @State private var weight = 10
    var onDone: (Int) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 6) {
            Text("Weight").font(.subheadline.weight(.semibold)).foregroundStyle(Color.qGoldDeep)
            Picker("Weight", selection: $weight) {
                ForEach(1...100, id: \.self) { kg in
                    Text("\(kg) kg").tag(kg)
                }
            }
            .pickerStyle(.wheel)
            PillButton(action: { onDone(weight) }) {
                Text("OK").font(.headline).foregroundStyle(Color.qBackground)
            }
        }
    }
}

// MARK: - 3. Level start
struct LevelStartWatchView: View {
    var level = 2
    var weight = 10
    var progress = 0.38
    var onPlay: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            Text("Level \(level)").font(.subheadline.weight(.semibold)).foregroundStyle(Color.qGoldDeep)
            ZStack {
                ProgressRing(progress: progress)
                VStack(spacing: 2) {
                    Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(Color.qGold)
                    Text("\(weight) kg").font(.headline).foregroundStyle(Color.qText)
                }
            }
            PillButton(fill: AnyShapeStyle(LinearGradient.qVioletGradient), action: onPlay) {
                Image(systemName: "play.fill").foregroundStyle(.white)
            }
            .accessibilityLabel("Start")
        }
    }
}

// MARK: - 4. Active set (almost no text, nothing to distract)
struct ActiveSetWatchView: View {
    var set = 2, totalSets = 3
    var reps = 7, totalReps = 10
    var holding = false

    var body: some View {
        ZStack {
            ProgressRing(progress: Double(reps) / Double(totalReps),
                         lineWidth: 12, gradient: .qVioletGradient)
                .padding(8)
            VStack(spacing: 0) {
                Text("\(reps)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qText)
                    .contentTransition(.numericText())
                Text("/ \(totalReps)").font(.subheadline).foregroundStyle(Color.qMuted)
            }
        }
        .overlay(alignment: .topLeading) {
            Text("Set \(set)/\(totalSets)").font(.caption.weight(.semibold)).foregroundStyle(Color.qMuted)
        }
        .overlay(alignment: .top) {
            if holding {
                Image(systemName: "pause.circle.fill").foregroundStyle(Color.qGold)   // set is held, keep going
            }
        }
    }
}

// MARK: - 5. Rest (driven by the view model, which owns the timer)
struct RestWatchView: View {
    let total: Int
    let remaining: Int
    var onSkip: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            Text("Rest").font(.subheadline.weight(.semibold)).foregroundStyle(Color.qGoldDeep)
            ZStack {
                ProgressRing(progress: total > 0 ? Double(remaining) / Double(total) : 0)
                Text(String(format: "%d:%02d", remaining / 60, remaining % 60))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qText)
                    .monospacedDigit()
            }
            PillButton(fill: AnyShapeStyle(Color.qRingTrack), action: onSkip) {
                Text("Skip").font(.headline).foregroundStyle(Color.qText)
            }
        }
    }
}

// MARK: - 6. Pause
struct PauseWatchView: View {
    var onResume: () -> Void = {}
    var onEnd: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onResume) {
                VStack(spacing: 4) {
                    Image(systemName: "play.fill").font(.title2).foregroundStyle(Color.qBackground)
                        .frame(width: 64, height: 64)
                        .background(LinearGradient.qGoldGradient, in: Circle())
                    Text("Resume").font(.caption.weight(.semibold)).foregroundStyle(Color.qText)
                }
            }
            Button(action: onEnd) {
                VStack(spacing: 4) {
                    Image(systemName: "xmark").font(.title2).foregroundStyle(Color.qText)
                        .frame(width: 64, height: 64)
                        .background(Color.qRingTrack, in: Circle())
                    Text("End").font(.caption.weight(.semibold)).foregroundStyle(Color.qText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 7. Level up
struct LevelUpWatchView: View {
    var level = 3
    var from = 10, to = 12

    var body: some View {
        ZStack(alignment: .top) {
            Mountains().padding(.top, 36).ignoresSafeArea()
            Text("Level \(level)").font(.title3.bold()).foregroundStyle(Color.qGold)
        }
        .overlay(alignment: .bottom) {
            Text("\(from) → \(to) kg")
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(LinearGradient.qVioletGradient, in: Capsule())
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Previews (the Watch app background is black by default)
#Preview("1 Welcome")   { WelcomeWatchView() }
#Preview("2 Weight")    { SetWeightWatchView() }
#Preview("3 Level")     { LevelStartWatchView() }
#Preview("4 Active")    { ActiveSetWatchView() }
#Preview("5 Rest")      { RestWatchView(total: 90, remaining: 72) }
#Preview("6 Pause")     { PauseWatchView() }
#Preview("7 Level up")  { LevelUpWatchView() }
