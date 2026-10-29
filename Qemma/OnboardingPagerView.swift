import SwiftUI

struct OnboardingPagerView: View {
    @AppStorage("startingWeightKg") private var weightKg = 10
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        TabView {
            // Skip: finishes onboarding without saving a weight (default stays 10),
            // so MyApp switches to JourneyMap.
            WelcomeView(onSkip: {
                hasSeenOnboarding = true
            })

            HowItWorksView()

            SetWeightView(onContinue: { kg in
                weightKg = kg              // PlanEditorView reads the same key
                hasSeenOnboarding = true
            })
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.qBackground.ignoresSafeArea())
    }
}

#Preview {
    OnboardingPagerView()
}
