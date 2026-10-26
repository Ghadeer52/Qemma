import WatchConnectivity

/// Watch side. Rules of thumb:
/// - updateApplicationContext: "latest state wins" (plan, progress). Old values are dropped.
/// - transferUserInfo: every message arrives, in order, even if the iPhone is off (workout summaries).
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var receivedPlan: WorkoutPlan?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(summary: WorkoutSummary) {
        guard let data = try? JSONEncoder().encode(summary) else { return }
        WCSession.default.transferUserInfo(["type": "summary", "payload": data])
    }

    func publish(progress: JourneyProgress, plan: WorkoutPlan) {
        guard WCSession.default.activationState == .activated,
              let p = try? JSONEncoder().encode(progress),
              let w = try? JSONEncoder().encode(plan) else { return }
        try? WCSession.default.updateApplicationContext(["type": "state", "progress": p, "plan": w])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard applicationContext["type"] as? String == "plan",
              let data = applicationContext["plan"] as? Data,
              let plan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) else { return }
        DispatchQueue.main.async { self.receivedPlan = plan }
    }
}
