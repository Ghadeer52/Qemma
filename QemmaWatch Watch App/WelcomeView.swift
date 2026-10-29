import SwiftUI

struct WelcomeView: View {
    @State private var showWeight = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                GeometryReader { geo in
                    let scale = geo.size.width / 208   // 208 = your Sketch artboard width

                    Image("Mountains")
                        .resizable()
                        .frame(width: 230 * scale, height: 235.39 * scale)
                        .position(x: 96 * scale, y: 168.695 * scale)
                }
                .ignoresSafeArea()

                GeometryReader { geo in
                    let scale = geo.size.width / 208

                    Text("Welcome to\nQemma")
                        .font(.system(size: 25 * scale, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 2, x: 0, y: 2)
                        .fixedSize()
                        .position(x: 104 * scale, y: 116 * scale)
                }
                .ignoresSafeArea()
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height < -40 {   // finger moved up
                            showWeight = true
                        }
                    }
            )
            .navigationDestination(isPresented: $showWeight) {
                SetWeightView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    WelcomeView()
}
