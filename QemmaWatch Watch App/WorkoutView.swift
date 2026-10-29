//
//  WorkoutView.swift
//  QemmaWatch Watch App
//
//  Created by Leen Alharbi on 15/05/1448 AH.
//
import SwiftUI

// MARK: - Container with the two swipeable pages
struct WorkoutView: View {
    
    var weight: Int = 0
    var repsPerSet: [Int] = [10]
    var onEnd: () -> Void = {}
    

    @State private var isPaused = false
    @State private var showSummary = false

    var body: some View {
        TabView {
            WorkoutProgressPage(isPaused: isPaused,
                                repsGoal: repsPerSet.first ?? 10,
                                setsGoal: repsPerSet.count)
            WorkoutControlsPage(isPaused: $isPaused, onEnd: { showSummary = true })
        }
        .tabViewStyle(.page)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showSummary) {
            AfterWorkoutView(weight: weight, onDone: onEnd)
        }
    }
}

// MARK: - Left page: rings
struct WorkoutProgressPage: View {
    var isPaused: Bool = false

    // Placeholder data. Later these will come from the watch sensors.
    var reps: Int = 11
    var repsGoal: Int = 12
    var sets: Int = 2
    var setsGoal: Int = 3

    private let lineWidth: CGFloat = 12
    private let purple = Color(red: 0.55, green: 0.43, blue: 0.67) // replace with Sketch hex

    var body: some View {
        ZStack {
            // Outer ring = sets
            ring(size: 150,
                 progress: Double(sets) / Double(max(setsGoal, 1)),
                 color: Color("QGold"),
                 icon: "arrow.up")

            // Inner ring = reps
            ring(size: 110,
                 progress: Double(reps) / Double(max(repsGoal, 1)),
                 color: purple,
                 icon: "chevron.forward.2")

            Text("\(reps)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .opacity(isPaused ? 0.5 : 1)
        }
    }

    private func ring(size: CGFloat, progress: Double, color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
        .padding(lineWidth / 2)
        .frame(width: size, height: size)
        .overlay(alignment: .top) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .frame(width: lineWidth, height: lineWidth)
        }
    }
}

// MARK: - Right page: Pause/Resume and End Workout
struct WorkoutControlsPage: View {
    @Binding var isPaused: Bool
    var onEnd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            controlButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                title: isPaused ? "Resume" : "Pause"
            ) {
                isPaused.toggle()
            }

            controlButton(icon: "xmark", title: "End Workout") {
                onEnd()
            }
        }
    }

    private func controlButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 48, height: 48)
                    .background(Color(white: 0.2), in: Circle())

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorkoutView()
}
