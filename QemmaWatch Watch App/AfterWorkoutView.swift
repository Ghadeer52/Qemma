//
//  SwiftUIView.swift
//  QemmaWatch Watch App
//
//  Created by Leen Alharbi on 16/05/1448 AH.
//
import SwiftUI

struct AfterWorkoutView: View {
    var weight: Int = 9
    var xpBefore: Int = 950      // XP before the workout
    var xpAfter: Int = 1000       // XP after the workout
    var xpGoal: Int = 1000
    var onDone: () -> Void = {}

    @State private var showNewXP = false
    @State private var showNextLevel = false

    // Replace with the exact hex values from Sketch
    private let purple = Color(red: 0.55, green: 0.43, blue: 0.67)
    private let barTrack = Color(red: 0.29, green: 0.23, blue: 0.16)

    private var levelUp: Bool { xpAfter >= xpGoal }
    private var shownXP: Int { min(showNewXP ? xpAfter : xpBefore, xpGoal) }
    private var fraction: Double { Double(shownXP) / Double(max(xpGoal, 1)) }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // Background mountains + character
            GeometryReader { geo in
                let scale = geo.size.width / 208

                Image("Mountains2")
                    .resizable()
                    .frame(width: 300 * scale, height: 219.84 * scale)
                    .position(x: 71.69 * scale, y: 168.92 * scale)
            }
            .ignoresSafeArea()

            // Texts and XP bar
            GeometryReader { geo in
                let scale = geo.size.width / 208
                let barWidth = 153 * scale

                Text("Well Done !")
                    .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                    .position(x: 104 * scale, y: 39 * scale)

                Text("\(weight) Kg")
                    .font(.system(size: 21 * scale, weight: .bold, design: .rounded))
                    .position(x: 47 * scale, y: 182 * scale)

                // XP bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(barTrack)
                    Capsule()
                        .fill(purple)
                        .frame(width: barWidth * min(fraction, 1))
                }
                .frame(width: barWidth, height: 7 * scale)
                .position(x: 103.3 * scale, y: 205.7 * scale)

                Text("\(shownXP.formatted()) / \(xpGoal.formatted()) XP")
                    .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .position(x: 140 * scale, y: 219 * scale)
            }
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
        .onTapGesture {
            if !levelUp { onDone() }
        }
        .navigationDestination(isPresented: $showNextLevel) {
            NextLevelView(weight: weight, onAccept: onDone)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1.2)) {
                showNewXP = true
            }

            if levelUp {
                // Keep the full bar on screen for a second, then show Level Up
                try? await Task.sleep(for: .seconds(2.2))
                guard !Task.isCancelled else { return }
                showNextLevel = true
            }
        }
    }
}

#Preview {
    AfterWorkoutView()
}
