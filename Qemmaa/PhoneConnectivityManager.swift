import WatchConnectivity
import Combine   // ObservableObject and @Published live here
import HealthKit

/// iPhone side. Add this file to the iOS target (plus Shared/Models.swift).
final class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var progress = JourneyProgress()
    @Published var summaries: [WorkoutSummary] = []
    /// What the Watch suggests for the next workout (new goal reps / new weight).
    @Published var suggestedPlan: WorkoutPlan?
    /// Shown under the Start button so the user sees what happened.
    @Published var status = ""

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

    /// Reads body weight, height and sex from the Health app (the data lives on the iPhone) and sends them
    /// to the Watch. Needs the HealthKit capability and NSHealthShareUsageDescription in the iPhone target.
    func sendHealthProfile() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let store = HKHealthStore()
        let read: Set<HKObjectType> = [HKQuantityType(.bodyMass), HKQuantityType(.height),
                                       HKCharacteristicType(.biologicalSex)]
        Task {
            do { try await store.requestAuthorization(toShare: [], read: read) } catch { return }
            func latest(_ id: HKQuantityTypeIdentifier, _ unit: HKUnit) async -> Double? {
                await withCheckedContinuation { cont in
                    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                    let q = HKSampleQuery(sampleType: HKQuantityType(id), predicate: nil, limit: 1,
                                          sortDescriptors: [sort]) { _, s, _ in
                        cont.resume(returning: (s?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
                    }
                    store.execute(q)
                }
            }
            var profile = HealthProfile()
            profile.bodyWeightKg = await latest(.bodyMass, .gramUnit(with: .kilo))
            profile.heightM = await latest(.height, .meter())
            switch try? store.biologicalSex().biologicalSex {
            case .male: profile.sex = .male
            case .female: profile.sex = .female
            default: break
            }
            guard let data = try? JSONEncoder().encode(profile) else { return }
            WCSession.default.transferUserInfo(["type": "profile", "profile": data])
        }
    }

    /// Sends the plan and starts the workout on the Watch.
    func startOnWatch(plan: WorkoutPlan) {
        let session = WCSession.default
        guard session.activationState == .activated else { status = "Connecting... try again in a moment."; return }
        guard session.isPaired else { status = "No Apple Watch is paired with this iPhone."; return }
        guard session.isWatchAppInstalled else { status = "Install the Qemma app on your Watch first."; return }
        sendHealthProfile()
        guard let data = try? JSONEncoder().encode(plan) else { return }
        let payload: [String: Any] = ["type": "start", "plan": data]

        // 1. Wake the Watch app (it opens even if it was closed).
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        HKHealthStore().startWatchApp(with: config) { _, _ in }

        // 2. Deliver the plan: instantly if the Watch app is open, otherwise queued until it opens.
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                session.transferUserInfo(payload)
                DispatchQueue.main.async { self?.status = "Queued. Open Qemma on your Watch." }
            }
            status = "Sent. Your workout is starting on the Watch."
        } else {
            session.transferUserInfo(payload)
            status = "Sent. Open Qemma on your Watch to begin."
        }
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
