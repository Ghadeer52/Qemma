# Evidence for every number in the progression (and what is only an assumption)

Labels: **Supported** = a study or position stand backs it. **Partly** = the range is backed, the exact number is not.
**Assumption** = our design choice, no study. Test it with real users.

| # | Number / rule in the app | Label | What the research says |
|---|---|---|---|
| 1 | Rep range 8 to 12 (was 20, which was only an assumption) | Supported | Muscle growth was similar from about 6 to 35 reps **when sets were taken close to failure** (Schoenfeld 2015: 8-12 vs 25-35 reps in trained men; Schoenfeld 2017 meta-analysis). ACSM 2009 gives 8-12RM for novices, so 12 is the ceiling. 1RM equations are only reliable up to about 10-12 reps, which also fits. Heavier loads were better for **strength**. |
| 2 | Weight goes up 2-10% | Supported | ACSM 2009: apply a 2-10% load increase when the lifter can do the current workload for 1-2 reps over the target. |
| 3 | 3.5% increase | Partly | Inside ACSM's 2-10%. The exact 3.5 came from the friend's AI-generated notes, not a study. **Catch:** on a 10 kg dumbbell the smallest step (1 kg) is 10%, the top of the range. Consider 0.5 kg steps. |
| 4 | 2 good sessions in a row | Partly | The "2-for-2" idea is a widely taught heuristic (sessions in a row), described by one NSCA study guide as a rule of thumb, not a published cut-score. |
| 5 | +1 rep per step | Assumption | No study. |
| 6 | "Good reps only" must be near failure to work | Supported (important) | Hypertrophy improves when sets end close to failure, usually 0-2 reps in reserve (Robinson 2024, Sports Medicine). A set that felt easy is a weak stimulus. The Watch now estimates the reps left from the speed loss, which is not yet tested on curls. |
| 7 | Epley to turn 12 reps into fewer reps at the new weight | Partly | Epley came from a poundage chart, not a peer-reviewed study. Prediction equations are accurate up to about 10 reps and get worse above it (Mayhew 1995; recent review). At 12 reps it is inside the range where Epley is considered acceptable. |
| 8 | Rep tempo limit (0.25-4 s lifting) | Partly | Whole reps of 0.5-8 s gave similar hypertrophy; very slow reps (>10 s) were worse (Schoenfeld, Ogborn, Krieger 2015). Our limit assumes lowering takes as long as lifting. |
| 9 | Range of motion must be 80% of normal | Assumption | Full vs partial ROM: overall effect trivial, favouring full ROM (SMD 0.12, 2023 meta-analysis). Upper-body evidence is limited and conflicting (Schoenfeld and Grgic 2020). We use 80% only to keep reps comparable. |
| 10 | Level drop after 28 days idle (was 14) | Supported | Strength is generally kept for up to 4 weeks without training (Mujika and Padilla 2000). Trained people lost about 7.5% of max isometric force after 8 weeks. We changed 14 days to 28. |
| 11 | Weight -5% per level lost | Assumption | Consistent with the 7.5% loss at 8 weeks, but it is our choice. |
| 12 | Rep counting from a wrist sensor | Partly | One Apple Watch study had about 1% error counting reps, but with **one** person. A wrist band recognised dumbbell curls 97.5% of the time on the **left** wrist and far worse on the right. Test both wrists. |
| 13 | Speed as a level driver | Not used | A smartwatch study found Watch speed readings not accurate enough to predict 1RM. We only record speed for information. |

| 14 | Level = relative strength (1RM / body weight) | Partly | The formula and the male "intermediate = 0.37x-0.50x bodyweight" band come from the research document (itself a web summary, no study cited). Female bands are DERIVED (male x 0.77 from Strength Level's strict-curl standards), not sourced. Strength Level standards are lifter-logged data, not a peer-reviewed study. Only 3 mountains = 3 bands. |
| 15 | 1RM from sets longer than 12 reps counted as 12 | Supported | The research document: 1RM equations are "less accurate if reps exceed 10-12". This under-estimates on purpose. |
| 16 | One rep never counts twice | Test only | The arm must lower below 60% of the last peak before the next rep can count (checked on 7 synthetic movement patterns, not on real people yet). |
| 17 | Speed (m/s) = forearm angle speed x 0.20 x height | Assumption | Body-proportion tables put elbow-to-wrist at about 0.146 x height; adding half a hand gives about 0.20. I quoted this from memory, so check it. |
| 18 | Alert at 30% velocity loss | Partly | Studies compared stopping at 20% and 40% velocity loss (Pareja-Blanco 2017, from memory: verify). 30% is a starting value. |
| 19 | Speed accuracy on a biceps curl | Unknown | Validated on squats by other studies, not on curls. See VALIDATION.md. |
| 20 | Reps left (RIR) estimated from how much slower the reps get | Partly | Speed loss tracked the percentage of reps completed with R2 = 0.97 (bench press) and 0.93 (squat) (Rodriguez-Rosell 2020, J Strength Cond Res 34(9):2537-2547). One study found it NOT accurate for the prone bench pull, and nobody has tested biceps curls. |
| 21 | Failure at 50% speed loss | Assumption | About 50% is the figure for bench press at 50-70% 1RM, not for curls. In my simulation, if the true value is 40% or 60% the estimate is off by about 3 reps. The "test set to failure" measures each user's own value. |
| 22 | Raise the weight when he could do 2+ more reps, 2 workouts in a row | Partly | ACSM 2009: raise the load when the lifter can do 1-2 reps over the target. We use speed loss to find "reps over the target", and 2 workouts in a row from the 2-for-2 idea. |

## Sources
- ACSM position stand, Progression Models in Resistance Training for Healthy Adults (2009): https://www.sportgeneeskunde.com/wp-content/uploads/ACSM-Position-Stand-Progression-Models-in-Resistance-Training-for-Healthy-Adults.pdf
- Schoenfeld et al. 2015, low vs high load in well-trained men: https://www.bisp-surf.de/Record/PU201510008067
- Schoenfeld et al. 2017, J Strength Cond Res 31(12):3508-3523, low vs high load meta-analysis
- Robinson et al. 2024, Sports Medicine 54(9):2209-2231, proximity to failure: https://doi.org/10.1007/s40279-024-02069-2
- Schoenfeld, Ogborn, Krieger 2015, repetition duration: https://pubmed.ncbi.nlm.nih.gov/25601394/
- Schoenfeld and Grgic 2020, range of motion: https://pmc.ncbi.nlm.nih.gov/articles/PMC6977096
- Partial vs full ROM meta-analysis 2023: https://doaj.org/article/99e86b317bec40f5abc2f0008358737e
- Mayhew et al. 1995, endurance repetitions to predict bench press 1RM: https://acnpsearch.tweb-dev.unibo.it/singlejournalindex/597985
- Rodriguez-Rosell et al. 2020, relationship between velocity loss and repetitions in reserve (bench press, squat): https://www.uloyola.es/en/research-transfer/publications/relationship-between-velocity-loss-and-repetitions-in-reserve-in-the-bench-press-and-back-squat-exercises-article
- Gonzalez-Badillo et al. 2017, velocity loss as a variable for monitoring resistance exercise: https://www.uloyola.es/en/research-transfer/publications/velocity-loss-as-a-variable-for-monitoring-resistance-exercise-article
- Review of 1RM equations and their limits: https://arxiv.org/pdf/2603.17495
- Mujika and Padilla, Muscular characteristics of detraining: https://paulogentil.com/pdf/Muscular%20characteristics%20of%20detraining%20in%20humans.pdf
- Detraining review (Frontiers 2020): https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7593778/
- Smartwatch workout app validation (rep count, speed): https://pmc.ncbi.nlm.nih.gov/articles/PMC8471343
- Wrist band for resistance exercises: https://lida.sport-iat.de/ta/Record/4066446

## Still to verify yourselves
I read abstracts and summaries, not every full paper. Before presenting this to a mentor, open the sources above and check the numbers.
