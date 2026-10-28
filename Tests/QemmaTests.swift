import XCTest
// Add this file to a unit-test target that includes RepDetector.swift and StrengthMath.swift.

final class QemmaTests: XCTestCase {

    func testRepsPerSet() {
        let plan = WorkoutPlan(repsPerSet: [10, 9, 8])
        XCTAssertEqual(plan.sets, 3)
        XCTAssertEqual(plan.targetReps(forSet: 2), 9)
        XCTAssertEqual(plan.targetReps(forSet: 99), 8)   // out of range uses the last set
        XCTAssertEqual(plan.totalReps, 27)
    }

    func testLevelFromRelativeStrength() {
        // 80 kg man: 25 kg max = 0.31x -> mountain 1; 32 kg = 0.40x -> mountain 2; 42 kg = 0.52x -> mountain 3.
        XCTAssertEqual(StrengthStandards.level(e1RM: 25, bodyWeightKg: 80, sex: .male, mountains: 3), 1)
        XCTAssertEqual(StrengthStandards.level(e1RM: 32, bodyWeightKg: 80, sex: .male, mountains: 3), 2)
        XCTAssertEqual(StrengthStandards.level(e1RM: 42, bodyWeightKg: 80, sex: .male, mountains: 3), 3)
        XCTAssertNil(StrengthStandards.level(e1RM: 30, bodyWeightKg: nil, sex: .male, mountains: 3))
    }

    func testLongSetsAreCappedAt12ForTheEstimate() {
        XCTAssertEqual(StrengthMath.estimated1RM(weight: 10, reps: 20),
                       StrengthMath.epley1RM(weight: 10, reps: 12), accuracy: 0.001)
    }

    /// One real curl with a wobble while lowering (110 -> 70 -> 95 -> 0) must count ONCE.
    func testWobbleWhileLoweringCountsOnce() {
        var detector = RepDetector()
        let keys: [(Double, Double)] = [(0, 0), (1, 0), (2, 110), (2.5, 110), (3.2, 70), (3.6, 95), (4.8, 0), (6, 0)]
        var count = 0
        for i in 0..<300 {
            let t = Double(i) * 0.02
            let k = keys.firstIndex { $0.0 >= t } ?? keys.count - 1
            let (t0, a0) = keys[max(k - 1, 0)], (t1, a1) = keys[k]
            let a = t1 > t0 ? a0 + (a1 - a0) * (t - t0) / (t1 - t0) : a1
            if detector.process(time: t, angle: a) != nil { count += 1 }
        }
        XCTAssertEqual(count, 1)
    }

    func testAngleSpeedToMetresPerSecond() {
        // forearm turning 110 degrees in 1 s, weight 0.34 m from the elbow: 1.92 rad/s x 0.34 = 0.65 m/s
        XCTAssertEqual(Velocity.linear(degPerSec: 110, radiusM: 0.34), 0.653, accuracy: 0.01)
        XCTAssertEqual(Velocity.handRadius(heightM: 1.70), 0.34, accuracy: 0.001)
    }

    func testVelocityLoss() {
        XCTAssertEqual(Velocity.setLoss([0.60, 0.58, 0.50, 0.42]), 0.30, accuracy: 0.001)   // best 0.60, last 0.42
        XCTAssertEqual(Velocity.loss(current: 0.7, best: 0.6), 0)                          // never negative
    }

    func testReadinessAndBaseline() {
        XCTAssertEqual(Velocity.readiness(today: 0.54, baseline: 0.60)!, 0.9, accuracy: 0.001)
        XCTAssertNil(Velocity.readiness(today: 0.54, baseline: nil))
        XCTAssertEqual(Velocity.updatedBaseline(old: 0.60, new: 0.50), 0.57, accuracy: 0.001)
    }

    func testProgressToNextMountain() {
        // 80 kg man, mountain 1 spans 0 to 0.37x: a 15 kg max is 0.1875x = about 51% of the way.
        let p = StrengthStandards.progressToNext(e1RM: 15, bodyWeightKg: 80, sex: .male, level: 1, mountains: 3)!
        XCTAssertEqual(p, 0.507, accuracy: 0.01)
    }

    // MARK: Sensor-based weight decision

    func testReservesFromSpeedLoss() {
        // A set with capacity 15 reps: speed falls from 0.60 to 0.30 (50% loss) over reps 1...15.
        // We only watched 10 reps, so about 5 reps were left in reserve.
        let speeds = (0..<10).map { 0.60 - 0.30 * Double($0) / 14 }
        let e = EffortEstimator.estimate(velocities: speeds)!
        XCTAssertEqual(e.repsInReserve, 5, accuracy: 0.1)
        XCTAssertNil(EffortEstimator.estimate(velocities: [0.6, 0.58, 0.55]))   // too few reps
    }

    func testSpeedThatDoesNotFallMeansVeryLight() {
        XCTAssertEqual(EffortEstimator.estimate(velocities: [0.6, 0.6, 0.6, 0.6, 0.6])!.repsInReserve, 10)
    }

    func testTooLightTwiceInARowIncreasesWeight() {
        var d = Progression.evaluateLoad(goodReps: [8, 8, 8], targets: [8, 8, 8], plannedSets: 3,
                                         repsInReserve: [4, 3, 3], lightStreak: 0)
        XCTAssertEqual(d.lightStreak, 1); XCTAssertFalse(d.increase)
        d = Progression.evaluateLoad(goodReps: [8, 8, 8], targets: [8, 8, 8], plannedSets: 3,
                                     repsInReserve: [4, 3, 3], lightStreak: 1)
        XCTAssertTrue(d.increase)
    }

    func testHardSetOrMissedTargetResetsLightStreak() {
        let hard = Progression.evaluateLoad(goodReps: [8, 8, 8], targets: [8, 8, 8], plannedSets: 3,
                                            repsInReserve: [0.5, 1, 1], lightStreak: 1)
        XCTAssertEqual(hard.lightStreak, 0); XCTAssertFalse(hard.increase)
    }

    func testEpley() {
        XCTAssertEqual(StrengthMath.epley1RM(weight: 10, reps: 10), 13.333, accuracy: 0.01)
    }

    func testBrzycki() {
        XCTAssertEqual(StrengthMath.brzycki1RM(weight: 10, reps: 10)!, 13.333, accuracy: 0.01)
        XCTAssertNil(StrengthMath.brzycki1RM(weight: 10, reps: 37))
    }

    func testNextWeightAlwaysMovesUp() {
        XCTAssertEqual(StrengthMath.nextWeight(current: 10, increment: 1), 11)   // 10.35 rounds to 10, so +1
        XCTAssertEqual(StrengthMath.nextWeight(current: 40, increment: 1), 41)   // 41.4 -> 41
    }

    func testRepsToMatchKeepsEstimatedMax() {
        // 10 kg x 12 reps ~ 14 kg max. At 11 kg that is about 8 reps.
        XCTAssertEqual(StrengthMath.repsToMatch(oldWeight: 10, oldReps: 12, newWeight: 11), 8)
    }

    // MARK: Progression (double progression, 2 sessions in a row)

    private func session(_ good: [Int], _ targets: [Int], goal: Int, streak: Int = 0, weight: Double = 10) -> Progression.Outcome {
        Progression.evaluate(goodReps: good, targets: targets, plannedSets: targets.count,
                             goalReps: goal, streak: streak, weightKg: weight)
    }

    func testOneGoodSessionIsNotEnough() {
        let o = session([8, 8, 8], [8, 8, 8], goal: 8)
        XCTAssertTrue(o.qualified); XCTAssertEqual(o.streak, 1); XCTAssertEqual(o.goalReps, 8)
    }

    func testTwoGoodSessionsAddOneRep() {
        let o = session([8, 8, 8], [8, 8, 8], goal: 8, streak: 1)
        XCTAssertEqual(o.goalReps, 9); XCTAssertEqual(o.streak, 0); XCTAssertFalse(o.leveledUp)
    }

    func testMissedSetResetsStreak() {
        let o = session([8, 8, 7], [8, 8, 8], goal: 8, streak: 1)
        XCTAssertEqual(o.streak, 0); XCTAssertEqual(o.goalReps, 8)
    }

    func testTrainingBelowGoalChangesNothing() {
        let o = session([6, 6, 6], [6, 6, 6], goal: 8, streak: 1)
        XCTAssertEqual(o.streak, 1); XCTAssertEqual(o.goalReps, 8); XCTAssertFalse(o.qualified)
    }

    func testTopOfLadderLevelsUpAndDropsReps() {
        let o = session([12, 11, 10], [12, 11, 10], goal: 12, streak: 1)
        XCTAssertTrue(o.leveledUp)
        XCTAssertEqual(o.weightKg, 11)
        XCTAssertEqual(o.goalReps, 8)
    }

    func testUnfinishedWorkoutNeverCounts() {
        let o = Progression.evaluate(goodReps: [8], targets: [8], plannedSets: 3,
                                     goalReps: 8, streak: 1, weightKg: 10)
        XCTAssertEqual(o.streak, 1); XCTAssertFalse(o.qualified)
    }

    func testSuggestedRepsKeepTheShape() {
        XCTAssertEqual(Progression.suggestedReps(for: [10, 9, 8], goal: 11), [11, 10, 9])
    }

    /// Ten smooth curls (0 -> 110 -> 0 degrees, 2.5 s each, 50 Hz) must give exactly 10 reps.
    func testCountsTenReps() {
        var detector = RepDetector()
        var count = 0, t = 0.0
        for _ in 0..<10 {
            for i in 0..<125 {
                let angle = 110 * (0.5 - 0.5 * cos(2 * .pi * Double(i) / 125))
                if detector.process(time: t, angle: angle) != nil { count += 1 }
                t += 0.02
            }
        }
        XCTAssertEqual(count, 10)
    }

    func testIgnoresSmallMovements() {
        var detector = RepDetector()
        var count = 0, t = 0.0
        for _ in 0..<8 {
            for i in 0..<125 {
                let angle = 35 * (0.5 - 0.5 * cos(2 * .pi * Double(i) / 125))
                if detector.process(time: t, angle: angle) != nil { count += 1 }
                t += 0.02
            }
        }
        XCTAssertEqual(count, 0)
    }
}
