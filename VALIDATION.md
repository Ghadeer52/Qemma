# Test the speed BEFORE the levels depend on it

Other apps validated the Watch on squats (a long, straight movement). A biceps curl is a small arc, so we must check it ourselves.
We cannot trust any speed number until this passes.

## What to compare
Watch speed (deg/s) against a reference you trust:
- Film the side of the arm at 240 fps (iPhone slow-motion), with a ruler or a known marker length in view.
- Track the dumbbell with the free app Kinovea (or Tracker) to get hand speed in m/s and the forearm angle.

## Protocol (30 minutes, 3 people, both wrists)
1. Weight: light, medium, heavy (e.g. 5, 10, 15 kg).
2. Tempo: slow (3 s up), normal (1.5 s up), fast (0.8 s up). 8 reps each.
3. Log for every rep: Watch mean speed and rep count; video mean speed and rep count.

## Pass marks (suggested, set them before you look at the data)
| Check | How | Pass |
|---|---|---|
| Rep count | Watch reps vs video reps | within 1 rep in 95% of sets |
| Speed order | Is slow < normal < fast on the Watch? | always |
| Agreement | Pearson r, Watch vs video | r >= 0.90 |
| Error | mean absolute % error | <= 10% |
| Repeatability | same person, same tempo, two days | difference <= 10% |

## If it fails
Use speed only as a coarse "slower / same / faster than your usual" signal (readiness), never as a number shown to the user, and never to set levels.

## Second test: "how many reps were left?" (before the Watch decides weight increases)
1. A person does sets of a known weight to FAILURE, 3 times on different days.
2. Same weight, another day: stop at 60%, 75% and 90% of that person's failure reps. Let the Watch estimate the reps left.
3. Compare the Watch estimate with the truth (failure reps minus reps done).
Pass mark (set it first): the estimate is within 2 reps in at least 80% of sets.
Without a "test set to failure" the app assumes 50% speed loss at failure, which is a bench-press number.
