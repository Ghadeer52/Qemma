import SwiftUI

@main struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.qGold
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.qGold.withAlphaComponent(0.3)
    }

    var body: some Scene {
        WindowGroup {

           // JourneyMap()

            if hasSeenOnboarding {
                Text("Home")   // replace with your HomeView()
            } else {
                OnboardingPagerView()
            }

        }
    }
}
