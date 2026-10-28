# Qemma Watch app: setup

## Targets
| Folder | Add to |
|---|---|
| Shared/ | iPhone target AND Watch target |
| Watch/ | Watch target only (delete the template ContentView and App file) |
| iOS/ | iPhone target only |
| Tests/ | a unit-test target that also includes RepDetector.swift + StrengthMath.swift |
| Qemma_Watch_Colors_Assets.zip | unzip, drag the `Colors` folder into the Watch Assets.xcassets (and the iPhone one) |

## Capabilities and Info.plist (Watch target)
1. Signing & Capabilities -> **HealthKit**.
2. Signing & Capabilities -> **Background Modes** -> **Workout processing**.
3. Info: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `NSMotionUsageDescription` (short, honest sentences).
4. Test on a REAL Apple Watch. The simulator has no real motion data.

## Test order
1. Run the unit tests (formulas + rep detector on fake data).
2. Run on the Watch, do one set of 5 slow curls with the arm hanging at the start. Check the rep count.
3. Do 10 reps at a fast and a slow tempo. Check that "speed" differs. Write the numbers down: they set the level targets.

## How progression works (Shared/Progression.swift)
1. Every workout starts at the user's goal reps (8 at first). A rep only counts if the range of motion and tempo are good.
2. All sets reach their target with good reps, in 2 workouts in a row: the goal goes up by 1 rep.
3. At 12 good reps in 2 workouts in a row: weight goes up (about 3.5%, at least one step) and the reps drop to match (Epley). The sensors can trigger the weight increase earlier (see below).
4. Missing a set resets the 2-in-a-row count. Training below the goal changes nothing.
All the numbers are constants at the top of Progression.swift.

## Colors and "Invalid redeclaration"
Xcode makes `Color.qGold`, `Color.qCard`, ... by itself from the asset names (needs iOS 17 / watchOS 10+).
`Colors.swift` and `WatchColors.swift` therefore do not declare them. If your deployment target is older than that,
either raise it, or add `extension Color { static let qGold = Color("QGold") ... }` and turn OFF
Build Settings > "Generate Asset Symbol Extensions".

## The test file
`XCTest` only exists in a Unit Testing Bundle target. If you created `a.swift` inside the app target, delete it
(tests are optional) or move it into a test target (File > New > Target > Unit Testing Bundle).

## Levels now come from strength (Shared/StrengthStandards.swift)
level = estimated 1RM / body weight, from the research document. Body weight and sex are read from the Health app
(the Watch asks permission on the first workout). If they are missing, the old rule applies (a new mountain when the rep ladder tops out).
Sets no longer stop at the target reps: they end 5 s after the last rep, so a too-light weight shows up as extra reps.

## Speed (Shared/Velocity.swift)
Mean concentric velocity, velocity loss (buzz at 30%), readiness vs the user's own baseline, all measured offline.
Run VALIDATION.md before trusting any speed number.

## Sensor-based weight decision (Shared/EffortEstimator.swift)
The Watch fits a line to the rep speeds of each set and estimates how many reps were left. Weight goes up when, in 2
workouts in a row, every set hit its target and about 2+ reps were left. It can fire before the 12-rep top of the ladder.
Phone toggle "Test set to failure" teaches the Watch this person's speed loss at failure.
