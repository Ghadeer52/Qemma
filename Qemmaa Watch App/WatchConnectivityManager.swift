import WatchConnectivity
import Combine   // ObservableObject and @Published live here

/// Watch side. Rules of thumb:
/// - updateApplicationContext: "latest state wins" (plan, progress). Old values are dropped.
/// - transferUserInfo: every message arrives, in order, even if the iPhone is off (workout summaries).
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var receivedPlan: WorkoutPlan?
    /// Set when the iPhone presses "Start on Watch".
    @Published var startRequest: WorkoutPlan?
    /// Body weight, height and sex that the iPhone read from the Health app.
    @Published var receivedProfile: HealthProfile?

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
        handle(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handle(userInfo)
    }

    private func handle(_ dict: [String: Any]) {
        if dict["type"] as? String == "profile", let data = dict["profile"] as? Data,
           let profile = try? JSONDecoder().decode(HealthProfile.self, from: data) {
            DispatchQueue.main.async { self.receivedProfile = profile }
            return
        }
        guard let type = dict["type"] as? String, type == "plan" || type == "start",
              let data = dict["plan"] as? Data,
              let plan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) else { return }
        DispatchQueue.main.async {
            self.receivedPlan = plan
            if type == "start" { self.startRequest = plan; self.startRequest = nil }
        }
    }
}
