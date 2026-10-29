import SwiftUI

struct CountdownView: View {
    @Binding var isPresented: Bool
    var weight: Int = 0
    var repsPerSet: [Int] = [10]

    @State private var showWorkout = false
    @State private var isReady = true     // true while "Ready!" is showing
    @State private var count = 3
    @State private var remaining = 1.0   // 1.0 = full ring, 0.0 = empty

    private let trackColor = Color(white: 0.17)

    var body: some View {
        Group {
            if showWorkout {
                WorkoutView(weight: weight,
                            repsPerSet: repsPerSet,
                            onEnd: { isPresented = false })
            } else {
                countdown
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // 1. Show "Ready!" with a full ring
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }

            // 2. Switch to 3 and start emptying the ring over 3 seconds
            withAnimation { isReady = false }
            withAnimation(.linear(duration: 3)) {
                remaining = 0
            }

            // 3. The number changes once per second
            for number in [2, 1] {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                withAnimation { count = number }
            }

            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            showWorkout = true
        }
    }

    private var countdown: some View {
        VStack(spacing: 20) {
            //Text("Let’s GO !")
               // .font(.system(size: 20, weight: .bold, design: .rounded))

            ZStack {
                Circle()
                    .stroke(trackColor, lineWidth: 10)

                Circle()
                    .trim(from: 0, to: remaining)
                    .stroke(Color("QGold"), lineWidth: 10)
                    .rotationEffect(.degrees(-90))

                if isReady {
                    Text("Ready!")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.8))
                        .transition(.opacity)
                } else {
                    Text("\(count)")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.8))
                        .contentTransition(.numericText(countsDown: true))
                        .transition(.opacity)
                }
            }
            .frame(width: 140, height: 140)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CountdownView(isPresented: .constant(true))
}
