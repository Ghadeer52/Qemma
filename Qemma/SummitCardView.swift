import SwiftUI

struct SummitCardView: View {
    var imageName: String = "photo3"
    var title: String = "Summit reached!"
    var mountain: String = "Mount Uhud"
    var elevation: String = "1,077 m"
    var level: Int = 1
    var weight: String = "9 kg"
    var duration: String = "12 days"
    var workoutTime: String = "3 h 40 min"
    var buttonTitle: String = "Continue to Level 2"
    var onContinue: () -> Void = {}

    var currentXP: Int = 1000
    var targetXP: Int = 1000

    private var progress: Double { Double(currentXP) / Double(targetXP) }
    private var xpText: String { "\(currentXP.formatted()) / \(targetXP.formatted()) XP" }

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()

            lockedTrail
            DimOverlay()

            VStack(alignment: .leading, spacing: 0) {
                StatusBarView()

                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                card
                    .padding(.horizontal, 2)     // الأطراف قريبة من حافة الجوال
            }
            .ignoresSafeArea(edges: .bottom)     // الكارد ينزل لين آخر الجوال
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("YOUR CLIMB")
                .font(.system(size: 13))
                .tracking(0.4)
                .foregroundColor(.qDot)

            HStack(alignment: .lastTextBaseline) {
                Text("Level \(level)")
                    .font(.system(size: 46))
                    .foregroundColor(.qDot)
                Spacer()
                Text(xpText)
                    .font(.system(size: 14))
                    .foregroundColor(.qDot)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.qRingTrack.opacity(0.6))
                    Capsule()
                        .fill(Color.qViolet.opacity(0.45))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
            .padding(.top, 10)
        }
    }

    // MARK: - Background lock
    private var lockedTrail: some View {
        GeometryReader { geo in
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.qDot)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Color.qBackground))
                .overlay(Circle().stroke(Color.qIconCircle, lineWidth: 1.5))
                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.34)
        }
    }

    // MARK: - Card
    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {

            Capsule()
                .fill(Color.qDot)
                .frame(width: 60, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(title)
                .font(.system(size: 30))
                .foregroundColor(.qText)
                .padding(.top, 14)

            Text("\(mountain) · \(elevation) · Level \(level)")
                .font(.system(size: 14))
                .foregroundColor(.qGold)
                .padding(.top, 2)

            VStack(spacing: 0) {
                Divider().overlay(Color.qIconCircle)
                StatRow(icon: "dumbbell", label: "Weight", value: weight)
                Divider().overlay(Color.qIconCircle)
                StatRow(icon: "calendar", label: "Duration", value: duration)
                Divider().overlay(Color.qIconCircle)
                StatRow(icon: "timer", label: "Workout time", value: workoutTime)
            }
            .padding(.top, 14)

            Button(action: onContinue) {
                Text(buttonTitle)
                    .font(.system(size: 17))
                    .foregroundColor(.qBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56 )
                    .background(Color.qGold)
                    .clipShape(Capsule())
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 44)
        .background(
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color.qCard)
        )
    }
}

#Preview {
    SummitCardView()
}
