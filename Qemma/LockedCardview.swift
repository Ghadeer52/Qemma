import SwiftUI

struct LockedCardView: View {
    var title: String = "Locked"
    var level: Int = 3
    var message: String = "Reach the summit of Jabal Al-Lawz\nto reveal this mountain."

    // header (نفس Current)
    var headerLevel: Int = 2
    var currentXP: Int = 380
    var targetXP: Int = 1000

    // الموقع الحالي على الخريطة
    var hereTitle: String = "Jabal Al-Lawz"
    var hereSubtitle: String = "2,580 m · you are here"

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
    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("YOUR CLIMB")
                .font(.system(size: 13))
                .tracking(0.4)
                .foregroundColor(.qDot)

            HStack(alignment: .lastTextBaseline) {
                Text("Level \(headerLevel)")
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

    // MARK: - Background (locks + "you are here")
    private var lockedTrail: some View {
        GeometryReader { geo in
            lockCircle.position(x: geo.size.width * 0.5, y: geo.size.height * 0.34)
            lockCircle.position(x: geo.size.width * 0.28, y: geo.size.height * 0.5)

            // you are here
            VStack(spacing: 2) {
                Text(hereTitle)
                    .font(.system(size: 15))
                    .foregroundColor(.qDot)
                Text(hereSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.qDot)
            }
            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.64)

            Circle()
                .stroke(Color.qDot, lineWidth: 3)
                .frame(width: 30, height: 30)
                .position(x: geo.size.width * 0.78, y: geo.size.height * 0.64)
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

            Capsule()
                .fill(Color.qDot)
                .frame(width: 60, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

            // Locked mountain image
            ZStack {
                Image("LockedMountain")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 175)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(height: 175)

            Text(title)
                .font(.system(size: 34))
                .foregroundColor(.qText)
                .padding(.top, 14)

            Text("Level \(level)")
                .font(.system(size: 17))
                .foregroundColor(.qMuted)
                .padding(.top, 2)

            Text(message)
                .font(.system(size: 17))
                .foregroundColor(.qMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 36)
        //.padding()
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.qCard)
        )
    }
}

#Preview {
    LockedCardView()
}
