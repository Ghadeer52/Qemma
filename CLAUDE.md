# Qemma – context for Claude in Xcode

Apple Watch (watchOS 10+) + iPhone (iOS 17+) app for former gym-goers who quit. Exercise: biceps curl only.
Watch sensors measure reps and speed; progress = climbing Saudi mountains (levels). Fully offline, no data entry after a workout.
Owner: Ghadeer (Apple Developer Academy). Keep answers short and in plain language.

## Layout
- Shared/ (both targets): Models, Progression, StrengthMath, StrengthStandards, Velocity, EffortEstimator
- Watch/: RepDetector, MotionEngine (CoreMotion 50 Hz), WorkoutManager (HealthKit), ProgressStore, WorkoutViewModel (main flow), WatchConnectivityManager, screens
- iOS/: PhoneConnectivityManager (startOnWatch), PlanEditorView (Start workout screen)
- Tests/QemmaTests.swift belongs in a Unit Testing Bundle target only.
- EVIDENCE.md = research behind every number. VALIDATION.md = how to test curl speed.

## Rules
- Do NOT change progression constants (rep range 8-12, 2 sessions, +3.5% weight) or the rep detector thresholds without asking. They are backed by research or tuned on real data.
- Colors come from Xcode's generated asset symbols (Color.qGold etc.). Never add a manual `extension Color` (causes "Invalid redeclaration").
- Every Shared file must be ticked for BOTH targets.
- Set behaviour: no auto-rest on a pause. After 3 s without a rep the set is "held" (reps kept); ends via Done button or 12 s (target reached) / 90 s idle.
- Haptics: double click per counted rep, .retry for rejected rep.
- iPhone "Start on Watch": PhoneConnectivityManager.startOnWatch(plan:) wakes the Watch (startWatchApp) and sends type "start"; Watch starts via WatchConnectivityManager.startRequest.
- The "test set to failure" toggle was removed from the UI; Plan.calibrate stays false.
- Console noise (CSLSSnapshotService, "cannot add handler", "Application context data is nil", gesture gate, kCFRunLoopCommonModes) is system noise, ignore.
