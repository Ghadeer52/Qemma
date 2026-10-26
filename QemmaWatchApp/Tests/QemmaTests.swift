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
        // 10 kg x 20 reps ~ 16.7 kg max. At 11 kg that is about 15 reps.
        XCTAssertEqual(StrengthMath.repsToMatch(oldWeight: 10, oldReps: 20, newWeight: 11), 15)
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
        let o = session([20, 19, 18], [20, 19, 18], goal: 20, streak: 1)
        XCTAssertTrue(o.leveledUp)
        XCTAssertEqual(o.weightKg, 11)
        XCTAssertEqual(o.goalReps, 15)
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
