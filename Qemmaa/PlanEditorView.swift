import SwiftUI

/// "Start workout" screen on the iPhone. The user edits weight, rest and the reps of EACH set
/// (for example 10, 9, 8) and then sends the plan to the Watch.
/// Needs: Colors.swift + the color assets in the iPhone target, and PhoneConnectivityManager.
struct PlanEditorView: View {
    @Binding var plan: WorkoutPlan
    var onStart: () -> Void = {}

    private let maxSets = 8
    private let maxReps = 30

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Start workout")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.qText)

                exerciseCard

                StepperRow(label: "Weight", value: "\(Int(plan.weightKg.rounded())) kg",
                           onMinus: { plan.weightKg = max(1, plan.weightKg - 1) },
                           onPlus: { plan.weightKg += 1 })

                StepperRow(label: "Rest time", value: restText,
                           onMinus: { plan.restSeconds = max(15, plan.restSeconds - 15) },
                           onPlus: { plan.restSeconds = min(300, plan.restSeconds + 15) })

                Toggle(isOn: $plan.calibrate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Test set to failure").foregroundStyle(Color.qText)
                        Text("One hard set, once in a while. Helps the Watch judge when to add weight.")
                            .font(.footnote).foregroundStyle(Color.qMuted)
                    }
                }
                .tint(Color.qGold)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Color.qCard, in: RoundedRectangle(cornerRadius: 22))

                setsHeader

                ForEach(plan.repsPerSet.indices, id: \.self) { i in
                    StepperRow(label: "Set \(i + 1)", value: "\(plan.repsPerSet[i])",
                               onMinus: { plan.repsPerSet[i] = max(1, plan.repsPerSet[i] - 1) },
                               onPlus: { plan.repsPerSet[i] = min(maxReps, plan.repsPerSet[i] + 1) })
                        .contextMenu {
                            if plan.repsPerSet.count > 1 {
                                Button("Remove set", role: .destructive) { plan.repsPerSet.remove(at: i) }
                            }
                        }
                }

                shortcuts

                Text("Press and hold a set to remove it.")
                    .font(.footnote)
                    .foregroundStyle(Color.qMuted)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .background(Color.qBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                plan.updatedAt = .now
                onStart()
            } label: {
                Text("Start on Watch")
                    .font(.headline)
                    .foregroundStyle(Color.qBackground)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color.qGold, in: Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.qBackground)
        }
    }

    private var restText: String {
        String(format: "%d:%02d", plan.restSeconds / 60, plan.restSeconds % 60)
    }

    private var exerciseCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.title3)
                .foregroundStyle(Color.qGold)
                .frame(width: 44, height: 44)
                .background(Color.qIconCircle, in: Circle())
            Text("Biceps Curl").font(.title3.weight(.semibold)).foregroundStyle(Color.qText)
            Spacer()
        }
        .padding(14)
        .background(Color.qCard, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.qGold, lineWidth: 2))
    }

    private var setsHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sets").font(.title3.bold()).foregroundStyle(Color.qText)
                Text("Reps for each set").font(.footnote).foregroundStyle(Color.qMuted)
            }
            Spacer()
            Button {
                // New set starts from the last set's reps (10, 9, 8 -> 8).
                plan.repsPerSet.append(plan.repsPerSet.last ?? 10)
            } label: {
                Label("Add set", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.qGold)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .overlay(Capsule().stroke(Color.qGold, lineWidth: 2))
            }
            .disabled(plan.repsPerSet.count >= maxSets)
        }
        .padding(.top, 8)
    }

    private var shortcuts: some View {
        HStack {
            chip("Same for all") {
                let first = plan.repsPerSet.first ?? 10
                plan.repsPerSet = Array(repeating: first, count: plan.repsPerSet.count)
            }
            chip("-1 each set") {
                let first = plan.repsPerSet.first ?? 10
                plan.repsPerSet = plan.repsPerSet.indices.map { max(1, first - $0) }
            }
            Spacer()
            Text("\(plan.totalReps) reps total").font(.footnote).foregroundStyle(Color.qMuted)
        }
        .padding(.top, 4)
    }

    private func chip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(Color.qText)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.qIconCircle, in: Capsule())
        }
    }
}

struct StepperRow: View {
    let label: String
    let value: String
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(Color.qMuted)
            Spacer()
            roundButton("minus", "Decrease \(label)", onMinus)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.qText)
                .monospacedDigit()
                .frame(minWidth: 64)
            roundButton("plus", "Increase \(label)", onPlus)
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 58)
        .background(Color.qCard, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private func roundButton(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.qText)
                .frame(width: 36, height: 36)
                .background(Color.qIconCircle, in: Circle())
        }
        .accessibilityLabel(label)
    }
}

#Preview {
    @Previewable @State var plan = WorkoutPlan(repsPerSet: [10, 9, 8])
    PlanEditorView(plan: $plan)
}

// How to use it on the iPhone:
//
// struct PhoneHome: View {
//     @StateObject private var connectivity = PhoneConnectivityManager()
//     @State private var plan = WorkoutPlan(repsPerSet: [10, 9, 8])
//     var body: some View {
//         PlanEditorView(plan: $plan) { connectivity.send(plan: plan) }
//             // After a workout the Watch suggests the next goal (more reps, or a heavier weight).
//             .onReceive(connectivity.$suggestedPlan.compactMap { $0 }) { plan = $0 }
//     }
// }
