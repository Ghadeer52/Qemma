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
3. At 20 good reps in 2 workouts in a row: new mountain, weight goes up (about 3.5%, at least one step) and the reps drop to match (Epley).
4. Missing a set resets the 2-in-a-row count. Training below the goal changes nothing.
All the numbers are constants at the top of Progression.swift.
