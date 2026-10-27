import SwiftUI

// Colors come from Colors.swift (Asset Catalog).

// MARK: - Data
// The four cards are the same layout with different content,
// so we describe them as data and loop over them.
struct Step: Identifiable {
    let id = UUID()
    let icon: String      // SF Symbol name
    let title: String
    let detail: String
}

extension Step {
    static let all: [Step] = [
        Step(icon: "applewatch",
             title: "Lift with your Watch",
             detail: "Your Watch measures how fast you lift."),
        Step(icon: "chart.line.uptrend.xyaxis",
             title: "Get faster, fill the bar",
             detail: "Reach the target speed to finish a level."),
        Step(icon: "mountain.2.fill",
             title: "Climb new mountains",
             detail: "Every level is a new peak, from low to high."),
        Step(icon: "clock",
             title: "Keep lifting",
             detail: "Stop for a while and you drop back a level.")
    ]
}

// MARK: - One card (reused four times)
struct StepCard: View {
    let step: Step

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.qIconCircle)
                Image(systemName: step.icon)
                    .font(.title3)
                    .foregroundStyle(Color.qGold)
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)   // the text next to it says the same thing

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(Color.qText)
                Text(step.detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.qMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.qCard, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Page dots
struct PageDots: View {
    let count: Int
    let current: Int   // starts at 0

    var body: some View {
        /*HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.qGold : Color.qDot)
                    .frame(width: index == current ? 20 : 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")*/
    }
}

// MARK: - The page
struct HowItWorksView: View {
    var onNext: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.qText)
                Text("Four simple steps.")
                    .font(.subheadline)
                    .foregroundStyle(Color.qMuted)

                VStack(spacing: 16) {
                    ForEach(Step.all) { step in
                        StepCard(step: step)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .background(Color.qBackground.ignoresSafeArea())
        // Dots and button stay at the bottom, the cards scroll behind them.
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                PageDots(count: 3, current: 1)

               /* Button(action: onNext) {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(Color.qBackground)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.qGold, in: Capsule())
                }*/
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.qBackground)
        }
    }
}

#Preview {
    HowItWorksView()
}

// MARK: - First launch only (use this later in your App file)
//
// @main
// struct QemmaApp: App {
//     @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
//
//     var body: some Scene {
//         WindowGroup {
//             if hasSeenOnboarding {
//                 HomeView()
//             } else {
//                 // Welcome -> HowItWorksView -> SetWeightView,
//                 // then set hasSeenOnboarding = true on the last screen.
//                 HowItWorksView()
//             }
//         }
//     }
// }
