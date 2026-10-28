import Foundation

/// What the user set on the iPhone (or Watch) before training.
struct WorkoutPlan: Codable, Equatable {
    var weightKg: Double = 10
    /// Reps for each set, in order. [10, 9, 8] means 3 sets: 10, then 9, then 8.
    var repsPerSet: [Int] = [10, 10, 10]
    var restSeconds: Int = 90
    var updatedAt: Date = .now
    var calibrate = false      // one test set to failure, to learn this person's speed loss at failure

    var sets: Int { repsPerSet.count }
    var totalReps: Int { repsPerSet.reduce(0, +) }

    /// Target for a 1-based set number. Safe if the number is out of range.
    func targetReps(forSet set: Int) -> Int {
        guard !repsPerSet.isEmpty else { return 10 }
        return repsPerSet[min(max(set, 1), repsPerSet.count) - 1]
    }
}

/// The user's place on the journey. The Watch is the source of truth.
struct JourneyProgress: Codable, Equatable {
    var level = 1
    var weightKg = 10.0
    var goalReps = Progression.repFloor     // reps for the biggest set today's plan should aim for
    var streak = 0                          // successful sessions in a row at this goal
    var referenceROM: Double?               // the user's normal range of motion (degrees)
    var bodyWeightKg: Double?               // from the Health app
    var sex: Sex?                           // from the Health app
    var e1RM = 0.0                          // best estimated 1RM of the last workout
    var lightStreak = 0                     // sessions in a row where the sensors said "too light"
    var failureLoss: Double?                // this person's speed loss at failure (from a test set)
    var heightM: Double?                    // from the Health app (used to turn angle speed into m/s)
    var baselineVelocity: [Int: Double] = [:]   // user's usual first-rep speed (m/s) per working weight (kg)
    var lastActivity = Date.now

    var ladderFraction: Double { Progression.ladderFraction(goalReps: goalReps, streak: streak) }
}

struct SetResult: Codable, Identifiable, Equatable {
    var id = UUID()
    var index: Int
    var weightKg: Double
    var reps: Int               // GOOD reps only
    var rejectedReps: Int       // too short, too fast or swung
    var targetReps: Int
    var meanSpeed: Double       // degrees per second (information only)
    var velocityLoss: Double    // 0...1, first reps vs last reps (information only)
    var e1RM: Double
    var meanVelocity = 0.0      // m/s, average of the reps (mean concentric velocity)
    var peakVelocity = 0.0      // m/s, fastest rep
    var repsInReserve: Double?  // estimated reps left, from the speed loss (nil if too few reps)
}

struct WorkoutSummary: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var durationSeconds: Double
    var sets: [SetResult]
    var weightBefore: Double
    var weightAfter: Double
    var levelBefore: Int
    var levelAfter: Int
    var goalRepsAfter: Int
    var streakAfter: Int
    var qualified: Bool
    var leveledUp: Bool
    var averageHeartRate: Double?
    var e1RM = 0.0
    var relativeStrength: Double?       // e1RM / body weight, nil if body weight is unknown
    var readiness: Double?              // today's opening speed / usual speed at this weight (1.0 = normal)
    var totalReps: Int { sets.reduce(0) { $0 + $1.reps } }
}

/// Journey levels, ordered by height. VERIFY the names and heights with your team.
struct Mountain: Equatable {
    let name: String
    let heightM: Int
    static let all: [Mountain] = [
        Mountain(name: "Mount Uhud", heightM: 1_077),
        Mountain(name: "Jabal Al-Lawz", heightM: 2_580),
        Mountain(name: "Jabal Sawda", heightM: 3_133)
    ]
    static func forLevel(_ level: Int) -> Mountain {
        all[max(0, min(level, all.count) - 1)]
    }
}
