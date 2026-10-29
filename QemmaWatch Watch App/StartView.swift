//
//  StartView.swift
//  QemmaWatch Watch App
//
//  Created by Leen Alharbi on 15/05/1448 AH.
//
import SwiftUI

struct StartView: View {
    @AppStorage("currentLevel") private var level = 1
    @AppStorage("currentWeight") private var weight = 8
    var progress: Double = 0.12   // 0.0 = empty, 1.0 = full
    

    // Replace with the exact hex values from Sketch
    private let purple = Color(red: 0.55, green: 0.43, blue: 0.67)
    private let ringTrack = Color(white: 0.8)
    @State private var showSetup = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Level \(level) ")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            ZStack {
                // Gray background ring
                Circle()
                    .stroke(ringTrack, lineWidth: 10)

                // Purple progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(purple, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    //.scaleEffect(x: -1, y: 1) // fills counter-clockwise "our desigen in Sketch

                // Character and weight
                VStack(spacing: 0) {
                    Image("Character2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)          // was 85

                    Text("\(weight) kg")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)
                        .offset(y: 8)               // moves the weight down
                }
            }
            .frame(width: 135, height: 135)         // was 120

            Button {
                // Start the workout
                showSetup = true
                //showCountdown = true
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 40)
                    .background(Color("QGold"), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .accessibilityLabel("Start workout")
        }
        .padding(.horizontal)
        .padding(.horizontal)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showSetup) {
            SetupWorkoutView(isPresented: $showSetup, weight: weight)
        }
    }
}

#Preview {
    StartView()
}
