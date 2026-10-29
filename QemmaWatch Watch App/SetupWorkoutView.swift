//
//  SetupWorkoutView.swift
//  QemmaWatch Watch App
//
//  Created by Leen Alharbi on 18/05/1448 AH.
//
import SwiftUI

struct SetupWorkoutView: View {
    @Binding var isPresented: Bool
    var weight: Int = 0

    // Each number is the reps of one set. Starts with 3 sets like your iOS example.
    @State private var repsPerSet = [10, 9, 8]
    @State private var showCountdown = false

    private let minReps = 1
    private let maxReps = 50
    private let maxSets = 10

    private let rowColor = Color(white: 0.12)
    private let buttonColor = Color(white: 0.2)

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header
                VStack(alignment: .leading, spacing: 0) {
                    Text("Sets")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Reps for each set")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)

                // One row per set
                ForEach(repsPerSet.indices, id: \.self) { index in
                    setRow(index: index)
                }

                // Add set
                Button {
                    repsPerSet.append(repsPerSet.last ?? 10)
                } label: {
                    Label("Add set", systemImage: "plus")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("QGold"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .overlay(Capsule().stroke(Color("QGold"), lineWidth: 2))
                }
                .buttonStyle(.plain)
                .disabled(repsPerSet.count >= maxSets)
                .opacity(repsPerSet.count >= maxSets ? 0.4 : 1)

                // Start workout
                Button {
                    showCountdown = true
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 40)
                        .background(Color("QGold"), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .accessibilityLabel("Start workout")
            }
            .padding(.horizontal, 4)
        }
        .navigationDestination(isPresented: $showCountdown) {
            CountdownView(isPresented: $isPresented, weight: weight, repsPerSet: repsPerSet)
        }
    }

    // MARK: - One set row
    private func setRow(index: Int) -> some View {
        HStack(spacing: 6) {
            Text("Set \(index + 1)")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.gray)

            Spacer(minLength: 0)

            roundButton(icon: "minus", disabled: repsPerSet[index] <= minReps) {
                repsPerSet[index] -= 1
            }

            Text("\(repsPerSet[index])")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(minWidth: 26)

            roundButton(icon: "plus", disabled: repsPerSet[index] >= maxReps) {
                repsPerSet[index] += 1
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(rowColor, in: RoundedRectangle(cornerRadius: 18))
    }

    private func roundButton(icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(buttonColor, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }
}

#Preview {
    SetupWorkoutView(isPresented: .constant(true))
}
