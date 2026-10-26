import SwiftUI

struct StatusBarView: View {
    private let tint = Color.white.opacity(0.35)   // رمادي مثل التصميم

    var body: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(tint)

            Spacer()

            HStack(spacing: 7) {
                SignalBars(color: tint)
                Image(systemName: "wifi")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(tint)
                BatteryView(color: tint)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 0)
        .padding(.bottom, 8)
    }
}

// أربع أعمدة بأحجام متدرجة
struct SignalBars: View {
    var color: Color
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 3.5, height: CGFloat(5 + i * 3))
            }
        }
        .frame(height: 14)
    }
}

// بطارية مصمتة مع زر صغير
struct BatteryView: View {
    var color: Color
    var body: some View {
        HStack(spacing: 1.5) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 26, height: 13)

            Capsule()
                .fill(color)
                .frame(width: 1.8, height: 4.5)
        }
    }
}
struct HomeIndicator: View {
    var body: some View {
        Capsule()
            .fill(Color.white)
            .frame(width: 134, height: 5)
            .padding(.bottom, 8)
    }
}

struct DimOverlay: View {
    var opacity: Double = 0.65
    var body: some View {
        Color.black.opacity(opacity).ignoresSafeArea()
    }
}
