import SwiftUI

// ملاحظة: Stage و XPProgress و XPBar موجودين في Stage.swift

struct StageDetailSheet: View {
    let stage: Stage

    var body: some View {
        VStack(spacing: 0) {
            // مقبض السحب
            Capsule()
                .fill(Color.qDot)
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            Group {
                if stage.state == .locked {
                    lockedContent
                } else {
                    unlockedContent
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.fraction(detentFraction)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.qCard)
        .presentationCornerRadius(32)
    }

    // ارتفاع الكرت حسب حالة المرحلة
    private var detentFraction: CGFloat {
        switch stage.state {
        case .locked:    return 0.50
        case .current:   return 0.60
        case .completed: return 0.55
        }
    }

    // MARK: - مرحلة مقفلة

    private var lockedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            stageImage(height: 175, radius: 18)

            Text(stage.name)
                .font(.system(size: 34))
                .foregroundStyle(Color.qText)
                .padding(.top, 14)

            Text("Level \(stage.level)")
                .font(.system(size: 17))
                .foregroundStyle(Color.qMuted)
                .padding(.top, 2)

            Text(stage.lockedMessage)
                .font(.system(size: 17))
                .foregroundStyle(Color.qMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            Spacer(minLength: 0)
        }
    }

    // MARK: - مرحلة منجزة أو جارية

    private var unlockedContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // الصورة + وسم المنطقة
            ZStack(alignment: .bottomLeading) {
                stageImage(height: 150, radius: 24)

                Text(stage.region)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.qText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.qBackground.opacity(0.6), in: Capsule())
                    .padding(12)
            }

            // الاسم
            Text(stage.name)
                .font(.system(size: 28))
                .foregroundStyle(Color.qText)
                .padding(.top, 20)

            // الارتفاع · المستوى · الحالة
            Text(stage.summaryLine)
                .font(.system(size: 14))
                .foregroundStyle(stage.accent)
                .padding(.top, 4)

            // البروغرس بار (للمرحلة الجارية فقط)
            if let xp = stage.xp {
                VStack(alignment: .trailing, spacing: 8) {
                    Text(xp.label)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.qVioletLight)
                    XPBar(fraction: xp.fraction)
                }
                .padding(.top, 8)
            }

            // الصفوف
            VStack(spacing: 0) {
                divider
                InfoRow(icon: "dumbbell", title: "Weight", value: stage.weight)
                divider
                InfoRow(icon: "calendar", title: stage.durationTitle, value: stage.duration)
                divider
                InfoRow(icon: "timer", title: "Workout time", value: stage.workoutTime)
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
    }

    // MARK: - عناصر مساعدة

    /// التدرج يكون في الخلف دايماً والصورة فوقه.
    /// إذا الصورة مو موجودة في Assets يبقى التدرج ظاهر (بدون استخدام UIImage).
    private func stageImage(height: CGFloat, radius: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.qMountain, Color.qCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(stage.imageName)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.qText.opacity(0.1))
            .frame(height: 1)
    }
}

// MARK: - Row

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.qGold)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(Color.qMuted)

            Spacer()

            Text(value)
                .font(.system(size: 22))
                .foregroundStyle(Color.qText)
        }
        .frame(height: 52)
    }
}

// MARK: - Previews

#Preview("Completed") {
    Color.qBackground.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) { StageDetailSheet(stage: .uhud) }
}

#Preview("Current") {
    Color.qBackground.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) { StageDetailSheet(stage: .lawz) }
}

#Preview("Locked") {
    Color.qBackground.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) { StageDetailSheet(stage: .locked1) }
}
