import SwiftUI

struct OnboardingPagerView: View {
    @AppStorage("startingWeightKg") private var weightKg = 10
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        TabView {
            WelcomeView()
            HowItWorksView()
            SetWeightView(onContinue: { kg in
                weightKg = kg
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
