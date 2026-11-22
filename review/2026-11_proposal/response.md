# Response to reviewer comments

The comments arrived after data collection had finished (6–13 November 2026), so they are handled in two ways:

- **Analysis and reporting** (comments 3, 5, 6, 7): applied fully in the revised proposal.
- **Data collection protocol** (comments 1, 2, 4): the laps cannot be re-run, so the revised proposal records what was actually done, adds what can still be done afterwards (for example measuring the track), and lists the rest as limitations.

The original proposal is kept unchanged in `report/proposal.pdf`. The revision is `report/proposal_v2.md`, rendered to `report/proposal_v2.pdf`. Each comment is addressed in its own commit, so the history shows how every change maps to a comment.

| # | Topic | Accepted? | Status |
|---|---|---|---|
| 1 | Standardize phone position within blocks | Yes | Addressed in proposal v2 |
| 2 | Walking and jogging instructions | Yes | Addressed in proposal v2 |
| 3 | Definition of the signed response | Yes | Addressed in proposal v2 |
| 4 | Verified true distance | Yes | Planned |
| 5 | Absolute error measure and its uncertainty | Yes | Planned |
| 6 | Which interactions | Yes | Planned |
| 7 | Additive block assumption for app effects | Yes | Planned |

## 1. Standardize phone position within blocks

**Assessment.** Reasonable. Placement is a treatment factor, but variation *within* a level (switching hands, screen facing in or out, different pockets) adds noise and weakens the test of the placement effect.

**Change.** Describe how the phone was carried in each placement during data collection, and state that hand side, orientation and pocket were not formally fixed or recorded. Report this as a limitation.

## 2. Walking and jogging instructions

**Assessment.** Reasonable. "Walk" and "jog" mean different speeds for different people, so differences between members could be as large as the difference between the two levels.

**Change.** State that pace was self-selected (each member's normal walk and easy jog), that lap times were not recorded, and that block absorbs each member's typical speed. Report this as a limitation and give the target ranges a future study should use.

## 3. Definition of the signed response

**Assessment.** Reasonable. The displayed formula is a signed relative error, not a percentage.

**Change.** Define the response as signed percentage error, e = 100 × (d_recorded − d_true) / d_true, state that positive values mean over-recording and negative values mean under-recording, and use "absolute percentage error" only for |e|. Note that both apps report distance to 0.01 km, which limits the precision of e.

## 4. Verified true distance

**Assessment.** Reasonable. 400 m is the length of the measurement line in lane 1, and 453 m for lane 8 depends on the lane width. A bias in d_true passes into every error value and is confounded with the lane effect.

**Change.** Check the lap lengths of lanes 1 and 8 on this track (official markings or track documentation, and a measuring-wheel check of the walked line), recompute e with the verified lengths, and report a sensitivity analysis over the plausible range of d_true.

## 5. Absolute error measure and its uncertainty

**Assessment.** Reasonable, and the most important comment. Errors of +5 % and −5 % average to zero. The signed-error model answers "over or under?", not "which setting is most accurate?". With only four readings per app × combination, a ranking of point estimates is unstable.

**Change.** Define absolute percentage error |e| and mean absolute percentage error (MAPE). Estimate MAPE by app, by factor level and by combination with 95 % confidence intervals from a mixed model fitted to log(|e| + 0.5), checked against bootstrap intervals that resample laps within blocks. Rewrite the third aim so that no unique best combination is declared from point estimates.

## 6. Which interactions

**Assessment.** Reasonable. "Their interactions" does not say which terms are in the model or which ones we care about.

**Change.** State that the model contains the full app × lane × placement × pace factorial, show that the degrees of freedom allow it, and name the two-factor interactions of primary interest. Higher-order interactions are reported as exploratory.

## 7. Additive block assumption for app effects

**Assessment.** Reasonable. Phones differ in GPS hardware and software, so one app could perform differently on one phone only. An additive block term would average this away.

**Change.** Plot the paired Strava − Keep differences separately for each block, and fit a sensitivity model that adds an app × block interaction. If the interaction is important, interpret app effects block by block.
