import SwiftUI

struct MountainCardView: View {
    var imageName: String = "Image 1"      // اسم صورتك في Assets
    var province: String = "Tabuk Province"
    var title: String = "Jabal Al-Lawz"
    var elevation: String = "2,580 m"
    var level: Int = 2
    var currentXP: Int = 380
    var targetXP: Int = 1000
    var weight: String = "10 kg"
    var climbingFor: String = "5 days"
    var workoutTime: String = "1 h 20 min"

    private var progress: Double { Double(currentXP) / Double(targetXP) }
    private var xpText: String { "\(currentXP) / \(targetXP.formatted()) XP" }

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
                    .padding(.horizontal, 6)     // الأطراف قريبة من حافة الجوال
            }
            .ignoresSafeArea(edges: .bottom)     // الكارد ينزل لين آخر الجوال
        }
    }
    // MARK: - Header (YOUR CLIMB / Level 2)
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

            // شريط خافت
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

    // MARK: - Locked icons in background
    private var lockedTrail: some View {
        GeometryReader { geo in
            lockCircle.position(x: geo.size.width * 0.5, y: geo.size.height * 0.46)
            lockCircle.position(x: geo.size.width * 0.28, y: geo.size.height * 0.62)
        }
    }

    private var lockCircle: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 14))
            .foregroundColor(.qDot)
            .frame(width: 46, height: 46)
            .background(Circle().fill(Color.qBackground))
            .overlay(Circle().stroke(Color.qIconCircle, lineWidth: 1.5))
    }

    // MARK: - Card
    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Handle
            Capsule()
                .fill(Color.qDot)
                .frame(width: 60, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

            // Image + province tag
            ZStack(alignment: .bottomLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 175)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(province)
                    .font(.system(size: 12))
                    .foregroundColor(.qText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.qIconCircle.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(10)
            }

            // Title
            Text(title)
                .font(.system(size: 30))
                .foregroundColor(.qText)
                .padding(.top, 14)

            Text("\(elevation) · Level \(level) · In progress")
                .font(.system(size: 14))
                .foregroundColor(.qText.opacity(0.9))
                .padding(.top, 2)

            // XP
            HStack {
                Spacer()
                Text(xpText)
                    .font(.system(size: 13))
                    .foregroundColor(.qText.opacity(0.9))
            }
            .padding(.top, 6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.qRingTrack)
                    Capsule()
                        .fill(Color.qViolet)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
            .padding(.top, 4)

            // Stats
            VStack(spacing: 0) {
                Divider().overlay(Color.qIconCircle)
                StatRow(icon: "dumbbell", label: "Weight", value: weight)
                Divider().overlay(Color.qIconCircle)
                StatRow(icon: "calendar", label: "Climbing for", value: climbingFor)
                Divider().overlay(Color.qIconCircle)
                StatRow(icon: "timer", label: "Workout time", value: workoutTime)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.qCard)
        )
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(.qGold)
                .frame(width: 26)

            Text(label)
                .font(.system(size: 17))
                .foregroundColor(.qMuted)

            Spacer()

            Text(value)
                .font(.system(size: 24))
                .foregroundColor(.qText)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    MountainCardView()
}
