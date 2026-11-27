# Results summary

Analysis of the 32 laps (64 app readings) collected on 6–13 November 2026 at the Rashpal Dhillon Track & Field Oval, UBC, following the plan in `proposal_v2.md`. All numbers come from `code/02_analysis.R` and `code/03_absolute_error.R`; tables are in `results/` and plots in `figures/`.

Response: signed percentage error $e = 100 \times (d_{recorded} - d_{true}) / d_{true}$, with $d_{true}$ = 400.00 m (lane 1) or 453.03 m (lane 8). Positive $e$ means the app over-records.

## Aim 1: do the apps over- or under-record?

- Averaged over all phones and settings, the apps **over-record by 1.90%** (95% CI 1.12% to 2.68%), about 8 m on a 400 m lap.
- Averaged over the four phones, Keep over-records by 1.17% (0.23% to 2.11%) and Strava by 2.63% (1.69% to 3.57%).
- But the app difference **depends on the phone** (next section), so "Strava records more than Keep" is not true for every phone.
- These intervals treat block as fixed, so they describe **our four phones**. Treating the phones as a random sample (see "Sensitivity: blocks as a random sample of phones" below), the 95% CI for a typical phone is −2.2% to 6.0%: four phones are too few to generalize.

## Model check: is the app effect the same on every phone? (review comment 7)

The planned model had an additive block effect:

```r
lmer(e ~ block + app * lane * placement * pace + (1 | lap_id))
```

The paired Strava − Keep differences plotted by block (`figures/02_app_difference_by_block.png`) show that the app effect is not consistent:

| Block | Strava − Keep (percentage points) | 95% CI |
|---|---|---|
| Phoebe | +3.02 | 0.73 to 5.30 |
| Boyi | +4.01 | 1.72 to 6.30 |
| Jenny | −2.63 | −4.92 to −0.34 |
| Darren | +1.45 | −0.83 to 3.74 |

Adding an app × block interaction improves the model clearly (likelihood-ratio χ² = 22.4 on 3 df, p < 0.001; F test p = 0.002). The final model is therefore

```r
lmer(e ~ block * app + app * lane * placement * pace + (1 | lap_id))
```

Lap-to-lap SD 1.45, residual SD 2.20 (percentage points).

## Aim 2: which factors and interactions matter? (final model)

| Effect | F test p-value |
|---|---|
| Block (member and phone) | < 0.001 |
| App × block | 0.002 |
| App (averaged over phones) | 0.015 |
| Placement (pocket 2.59% vs hand 1.21%) | 0.08 |
| Lane (lane 8 2.16% vs lane 1 1.64%) | 0.50 |
| Pace (walk 1.88% vs jog 1.92%) | 0.95 |
| All 11 two-, three- and four-factor treatment interactions | all ≥ 0.13 (smallest: app × lane × pace) |

- The phone (block) and the app-on-that-phone combination explain most of the variation.
- Lane, placement and pace have no clear effect on the signed error. Pocket tends to over-record slightly more than hand (about 1.4 percentage points), but the evidence is weak.
- None of the interactions of primary interest (lane × pace, app × lane, app × pace, placement × pace) is detectable with this sample size.

## Model checking

- Residuals vs fitted: no pattern or funnel shape.
- Normal Q–Q: close to the line (Shapiro–Wilk p = 0.67); slightly stepped because readings are in 10 m steps.
- Residuals vs lap order: no trend over the session (correlation −0.05, p = 0.71).
- Equal spread across blocks: Bartlett p = 0.96.
- True lap length shifted by ±1 m: overall mean error moves from 1.90% to 1.66%–2.14%; all test results unchanged.

## Sensitivity: blocks as a random sample of phones

The final model treats block as fixed, so its intervals describe only our four phones. To ask what the data say about a typical phone, `code/02_analysis.R` (section 8) refits the model with the phones as a random sample:

```r
lmer(e ~ app * lane * placement * pace + (1 | block) + (1 | block:app) + (1 | lap_id))
```

| Quantity | Estimate | 95% CI (3 df) |
|---|---|---|
| Overall mean error | 1.90% | −2.15% to 5.95% |
| Strava − Keep | 1.46 points | −3.19 to 6.11 |

- Phone-to-phone SD 2.02, phone-to-phone SD of the app difference 1.92, lap-to-lap SD 1.45, residual SD 2.20 (percentage points).
- The overall mean and the app effect are now tested against phone-to-phone variation with only 4 − 1 = 3 df, so the intervals are much wider and the app effect is no longer detectable (p = 0.39).
- Lane, placement, pace and their interactions are compared within phones, so their tests are the same as in the final model.
- So the over-recording is clear on our four phones, but four phones are too few to say how a typical phone behaves.

## Aim 3: which setting is most accurate? (review comment 5)

Absolute error $|e|$ and MAPE = mean of $|e|$:

| | MAPE | 95% bootstrap CI |
|---|---|---|
| Keep | 2.71% | 1.97% to 3.53% |
| Strava | 3.58% | 2.95% to 4.22% |
| Strava − Keep | 0.87 points | −0.11 to 1.76 |

- The bootstrap resamples whole laps within each block (5000 resamples).
- Keep has the smaller MAPE, but the interval for the difference includes 0, and the log-scale model agrees (app p = 0.14, robust to the constant 0.25, 0.5 or 1).
- MAPE again depends on the phone: Strava's MAPE is 5.5% and 6.1% on Phoebe's and Boyi's phones but 1.0% and 1.8% on Jenny's and Darren's (app × block p = 0.03 on the log scale).
- Exploratory: the log-scale model shows an app × lane × pace interaction (p < 0.001); for example Keep was very accurate when jogging in lane 1. With 16 tests and 4 readings per cell this is treated as a lead for future work, not a conclusion.
- The 95% intervals for the 16 combinations overlap widely (`figures/06_typical_abs_error_by_treatment.png`), so **no single best combination** is declared.

## Conclusions

1. On our four phones the apps over-recorded a 400 m track lap by about 2% on average (95% CI 1.1% to 2.7%). Treating the phones as a random sample, the interval for a typical phone is −2.2% to 6.0%, so more phones are needed to generalize.
2. Which app reads longer depends on the phone: Strava read longer on three phones and shorter on one. The phone matters more than the app.
3. Lane, placement and pace had no clear effect on the signed error at this sample size.
4. Keep was slightly more accurate on average (MAPE 2.7% vs 3.6%), but the difference is not statistically clear.

## Limitations

- 10 m display resolution: each reading has up to ±5 m (±1.1%–1.25%) rounding error, similar in size to several effects.
- Four phones, one track, mostly one day per member: day and weather were not blocked separately and are confounded with block (Darren's whole block was in light rain; Jenny's three rainy laps were all walking).
- Phone position and pace were left to each member (see `proposal_v2.md`), so placement and pace effects are averages over personal habits.
- Four readings per app × combination, so combination-level comparisons have low power.
