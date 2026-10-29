import SwiftUI

@main struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.qGold
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.qGold.withAlphaComponent(0.3)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                
                if hasSeenOnboarding {
                    JourneyMap()
                        .transition(.opacity)
                } else {
                    OnboardingPagerView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: hasSeenOnboarding)
        }
    }
}
