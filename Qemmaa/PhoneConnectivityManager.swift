import WatchConnectivity
import Combine   // ObservableObject and @Published live here

/// iPhone side. Add this file to the iOS target (plus Shared/Models.swift).
final class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var progress = JourneyProgress()
    @Published var summaries: [WorkoutSummary] = []
    /// What the Watch suggests for the next workout (new goal reps / new weight).
    @Published var suggestedPlan: WorkoutPlan?

    private let summariesURL = URL.documentsDirectory.appending(path: "summaries.json")

    override init() {
        super.init()
        if let data = try? Data(contentsOf: summariesURL),
           let saved = try? JSONDecoder().decode([WorkoutSummary].self, from: data) {
            summaries = saved
        }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Call when the user changes weight / sets / reps / rest on the Start Workout screen.
    func send(plan: WorkoutPlan) {
        guard WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(plan) else { return }
        try? WCSession.default.updateApplicationContext(["type": "plan", "plan": data])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard userInfo["type"] as? String == "summary",
              let data = userInfo["payload"] as? Data,
              let summary = try? JSONDecoder().decode(WorkoutSummary.self, from: data) else { return }
        DispatchQueue.main.async {
            self.summaries.append(summary)
            if let encoded = try? JSONEncoder().encode(self.summaries) {
                try? encoded.write(to: self.summariesURL)
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard applicationContext["type"] as? String == "state",
              let data = applicationContext["progress"] as? Data,
              let progress = try? JSONDecoder().decode(JourneyProgress.self, from: data) else { return }
        let plan = (applicationContext["plan"] as? Data).flatMap { try? JSONDecoder().decode(WorkoutPlan.self, from: $0) }
        DispatchQueue.main.async {
            self.progress = progress          // drives the journey map
            self.suggestedPlan = plan         // pre-fills the Start Workout screen
        }
    }
}
