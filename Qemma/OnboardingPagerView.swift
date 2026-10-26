import SwiftUI

struct OnboardingPagerView: View {
    var body: some View {
        // 1. Place your three custom views inside the TabView
        TabView {
            WelcomeView()
            
            HowItWorksView()
            
            SetWeightView()
        }
        // 2. This applies the horizontal swiping behavior and displays the navigation dots
        .tabViewStyle(.page(indexDisplayMode: .always))
        
        // 3. (Optional) Force the background to black to match your screenshot layout
        .background(Color.black)
        .ignoresSafeArea()
    }
}

// Global configuration to match your screenshot colors (White active dot, Gray inactive dots)
#Preview {
    OnboardingPagerView()
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = .white
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        }
}
