import SwiftUI

@main
struct QemmaWatchApp: App {
    var body: some Scene {
        WindowGroup { QemmaWatchRoot() }
    }
}

struct QemmaWatchRoot: View {
    @StateObject private var vm = WorkoutViewModel()
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var onboardingStep = 0

    var body: some View {
        NavigationStack {
            Group {
                if hasOnboarded { flow } else { onboarding }
            }
        }
    }

    // First launch only: Welcome -> Set weight.
    @ViewBuilder private var onboarding: some View {
        if onboardingStep == 0 {
            WelcomeWatchView().onTapGesture { onboardingStep = 1 }
        } else {
            SetWeightWatchView { kg in
                vm.setStartingWeight(Double(kg))
                hasOnboarded = true
            }
        }
    }

    @ViewBuilder private var flow: some View {
        switch vm.phase {
        case .home:
            LevelStartWatchView(level: vm.journey.level,
                                weight: Int(vm.plan.weightKg.rounded()),
                                progress: vm.journey.ladderFraction,
                                onPlay: vm.startWorkout)
        case .countdown(let n):
            CountdownWatchView(number: n)
        case .activeSet:
            ActiveSetWatchView(set: vm.currentSet, totalSets: vm.plan.sets,
                               reps: vm.reps, totalReps: vm.targetReps)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: vm.pause) { Image(systemName: "pause.fill") }
                            .accessibilityLabel("Pause")
                    }
                }
        case .rest:
            RestWatchView(total: vm.plan.restSeconds, remaining: vm.restRemaining, onSkip: vm.skipRest)
        case .paused:
            PauseWatchView(onResume: vm.resume, onEnd: { Task { await vm.finishWorkout() } })
        case .result:
            if let r = vm.result {
                Group {
                    if r.outcome.leveledUp {
                        LevelUpWatchView(level: r.level, from: Int(r.weightFrom.rounded()), to: Int(r.weightTo.rounded()))
                    } else {
                        WellDoneWatchView(goodReps: r.goodReps, progress: vm.journey.ladderFraction)
                    }
                }
                .onTapGesture(perform: vm.dismissResult)
            }
        }
    }
}

struct CountdownWatchView: View {
    let number: Int
    var body: some View {
        VStack(spacing: 6) {
            Text("Let's GO!").font(.subheadline.weight(.semibold)).foregroundStyle(Color.qGoldDeep)
            ZStack {
                ProgressRing(progress: Double(4 - number) / 3)
                Text("\(number)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qText)
                    .contentTransition(.numericText())
            }
        }
        .padding(.bottom, 8)
    }
}

struct WellDoneWatchView: View {
    let goodReps: Int
    let progress: Double
    var body: some View {
        ZStack(alignment: .top) {
            Mountains().padding(.top, 50).ignoresSafeArea()
            Text("Well done!").font(.title3.bold()).foregroundStyle(Color.qText)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 4) {
                Text("\(goodReps) good reps").font(.caption.weight(.semibold)).foregroundStyle(Color.qText)
                ProgressView(value: progress).tint(Color.qVioletLight)
            }
            .padding(.horizontal, 24).padding(.bottom, 8)
        }
    }
}
