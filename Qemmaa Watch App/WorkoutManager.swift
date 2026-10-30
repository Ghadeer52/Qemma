import HealthKit
import Combine   // ObservableObject and @Published live here

/// HealthKit workout session. This is what keeps the app (and Core Motion) running in the
/// background while the wrist is down, and it saves the workout to the Health app.
final class WorkoutManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var heartRates: [Double] = []

    @Published var heartRate: Double = 0
    /// Called when the user pauses / resumes from the system (Dock, Control Center, Now Playing card).
    var onSystemPause: (() -> Void)?
    var onSystemResume: (() -> Void)?

    var averageHeartRate: Double? {
        heartRates.isEmpty ? nil : heartRates.reduce(0, +) / Double(heartRates.count)
    }

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned),
                                       HKQuantityType(.bodyMass), HKQuantityType(.height),
                                       HKCharacteristicType(.biologicalSex)]
        do {
            try await healthStore.requestAuthorization(toShare: share, read: read)
            return true
        } catch {
            qlog("HEALTH authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Body weight, sex and height from the Health app. Any of them can be nil.
    func loadProfile() async -> (bodyWeightKg: Double?, sex: Sex?, heightM: Double?) {
        var sex: Sex?
        if let value = try? healthStore.biologicalSex().biologicalSex {
            switch value {
            case .male: sex = .male
            case .female: sex = .female
            default: sex = nil
            }
        }
        let weight = await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        let height = await latestQuantity(.height, unit: .meter())
        qlog("HEALTH on Watch: weight \(weight.map { String($0) } ?? "none")  height \(height.map { String($0) } ?? "none")  sex \(sex.map { $0.rawValue } ?? "none")")
        return (weight, sex, height)
    }

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: HKQuantityType(id), predicate: nil, limit: 1,
                                      sortDescriptors: [sort]) { _, samples, error in
                if let error { qlog("HEALTH read error (\(id.rawValue)): \(error.localizedDescription)") }
                continuation.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    func start() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
        session.delegate = self
        builder.delegate = self
        self.session = session
        self.builder = builder
        heartRates = []

        let startDate = Date()
        session.startActivity(with: startDate)
        try await builder.beginCollection(at: startDate)
    }

    func pause() { if session?.state == .running { session?.pause() } }
    func resume() { if session?.state == .paused { session?.resume() } }

    func end() async {
        session?.end()
        do {
            try await builder?.endCollection(at: Date())
            _ = try await builder?.finishWorkout()
        } catch {
            // The workout still ends. Saving to Health can fail if permission was denied.
        }
        session = nil
        builder = nil
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        // The system buttons (Dock, Control Center) pause the session without telling the app: follow them.
        qlog("WORKOUT SESSION state: \(fromState.rawValue) -> \(toState.rawValue)  (1 not started, 2 running, 3 ended, 4 paused)")
        DispatchQueue.main.async {
            if toState == .paused { self.onSystemPause?() }
            if toState == .running, fromState == .paused { self.onSystemResume?() }
        }
    }
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        qlog("WORKOUT SESSION failed: \(error.localizedDescription)")
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let type = HKQuantityType(.heartRate)
        guard collectedTypes.contains(type) else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        guard let bpm = workoutBuilder.statistics(for: type)?.mostRecentQuantity()?.doubleValue(for: unit) else { return }
        DispatchQueue.main.async {
            self.heartRate = bpm
            self.heartRates.append(bpm)
        }
    }
}
