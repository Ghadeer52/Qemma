import SwiftUI




// MARK: - Colors

private extension Color {
    static let welcomeBackground = Color(red: 0.067, green: 0.055, blue: 0.043)   // near-black brown
    static let welcomeFarMountain = Color(red: 0.165, green: 0.133, blue: 0.110)  // dark brown
    static let welcomeGold = Color(red: 0.831, green: 0.659, blue: 0.416)         // sand gold
    static let welcomeSubtitle = Color(red: 0.78, green: 0.72, blue: 0.64).opacity(0.85)
    static let welcomeMarker = Color(red: 0.72, green: 0.60, blue: 0.88)          // lavender ring
}

// MARK: - Welcome View

struct WelcomeView: View {
    var onGetStarted: () -> Void = {}
    var onSkip: () -> Void = {}
    
    
    
    //@State var path = navpath()
    //@State var onGetStarted = false
    var body: some View {
        ZStack {
            Color.welcomeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                WelcomeMountainIllustration()
                    .aspectRatio(335.0 / 415.0, contentMode: .fit)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 12) {
                    Text("Welcome to Qemma")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(red: 0.96, green: 0.93, blue: 0.88))

                    Text("Climb the mountains of Saudi Arabia,\none lift at a time.")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .foregroundStyle(Color.welcomeSubtitle)
                    
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.welcomeGold)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 10)
                            .overlay(
                                Capsule()
                                    .stroke(Color.welcomeGold, lineWidth: 1.5)
                            )
                    }
                    .padding(.top, 12)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                Spacer(minLength: 16)

                WelcomePageDots(count: 3, current: 0)
                    .padding(.bottom, 28)

                /*Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.welcomeBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.welcomeGold, in: Capsule())
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)*/
                
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Page Dots

private struct WelcomePageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        /*HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.welcomeGold : Color.white.opacity(0.22))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }*/
    }
}

// MARK: - Illustration

/// Coordinates are designed on a 335 x 415 canvas and scaled to fit.
private struct WelcomeMountainIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let sx = geo.size.width / 335
            let sy = geo.size.height / 415
            let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: x * sx, y: y * sy) }

            ZStack(alignment: .topLeading) {
                // Far (dark) mountains
                Path { path in
                    path.move(to: p(0, 290))
                    path.addLine(to: p(57, 233))
                    path.addLine(to: p(92, 265))
                    path.addLine(to: p(166, 133))
                    path.addLine(to: p(208, 190))
                    path.addLine(to: p(243, 167))
                    path.addLine(to: p(300, 235))
                    path.addLine(to: p(335, 215))
                    path.addLine(to: p(335, 415))
                    path.addLine(to: p(0, 415))
                    path.closeSubpath()
                }
                .fill(Color.welcomeFarMountain)

                // Near (gold) mountains
                Path { path in
                    path.move(to: p(0, 350))
                    path.addLine(to: p(72, 292))
                    path.addLine(to: p(135, 332))
                    path.addLine(to: p(215, 242))
                    path.addLine(to: p(275, 305))
                    path.addLine(to: p(312, 283))
                    path.addLine(to: p(335, 295))
                    path.addLine(to: p(335, 415))
                    path.addLine(to: p(0, 415))
                    path.closeSubpath()
                }
                .fill(Color.welcomeGold)
                
                
                
                // Character standing on the gold peak
                let charWidth: CGFloat = 76 * sx
                let charHeight = charWidth * 528 / 560          // keeps the SVG's aspect ratio
                let feetY: CGFloat = 270                       // peak height on the 335x415 canvas
                let feetX: CGFloat = 240                         // peak position on the canvas

                Image("climp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: charWidth, height: charHeight)
                    .position(x: feetX * sx,
                              y: feetY * sy - charHeight * 0.405)   // puts the feet on the peak

                // Flag on the summit
                Path { path in
                    path.move(to: p(166, 133))
                    path.addLine(to: p(166, 108))
                }
                .stroke(Color.welcomeGold, lineWidth: 2)

                Path { path in
                    path.move(to: p(167, 108))
                    path.addLine(to: p(190, 112))
                    path.addLine(to: p(167, 120))
                    path.closeSubpath()
                }
                .fill(Color.welcomeGold)

                // Dotted route
                Path { path in
                    path.move(to: p(50, 392))
                    path.addCurve(to: p(135, 330),
                                  control1: p(80, 360),
                                  control2: p(100, 332))
                    path.addCurve(to: p(250, 258),
                                  control1: p(190, 328),
                                  control2: p(235, 310))
                }
                .stroke(Color.white.opacity(0.9),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, 5]))
                .offset(x: -25, y: 45)

                // Position marker
                Circle()
                    .stroke(Color.welcomeMarker, lineWidth: 2.5)
                    .frame(width: 16 * sx, height: 16 * sx)
                    .position(p(230, 290))

                // Fade into the background
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.welcomeBackground.opacity(0.95), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100 * sy)
                .offset(y: 315 * sy)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
}
