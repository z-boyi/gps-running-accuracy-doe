# STAT 404 Group Project Proposal

<p class="subtitle">Revised after reviewer comments; data collection completed 6–13 November 2026</p>

## Research Question:

- How do running apps, lane, phone placement, and pace affect GPS distance accuracy, and do these factors interact?

## Components of an experiment:

- Treatments:
    - Four two-level factors:
        - App: Strava vs. Keep.
        - Lane: 1 vs. 8.
        - Placement: hand vs. front pocket (as carried in practice; see protocol and limitations).
        - Pace: walking vs. jogging (self-selected: each member's normal walk and an easy jog).
    - $2^4 = 16$ treatment combinations; both apps record simultaneously.
- Experimental units:
    - Each separately recorded lap is a unit for lane, placement, and pace.
    - The two app readings within a lap are paired measurements.
- Blocking:
    - Four owner–phone pairs form four blocks.
    - Each person uses the same phone and completes all eight lap conditions.
- Randomization:
    - Independently randomize the eight lane–placement–pace combinations within each block using R.
- Replication:
    - Each treatment combination is observed in four blocks.
    - Total: 8 laps per person, 32 laps, and 64 app readings.
    - No within-block replication of the same treatment combination.

## Objectives:

- Measurement of the response (data collection):\
  Distance percentage error = (recorded distance - true distance) / true distance,
  $$e_r = \frac{d_{recorded} - d_{true}}{d_{true}},$$
  one value per app per lap.
    - True distance: lane 1 = 400 m, lane 8 ≈ 453 m.
    - Data collection protocol:
        - Open both apps and wait 60 s for a GPS lock before starting.
        - Phone position: each member carried their own phone in their usual way, in the hand or in a front trouser pocket. No written rule fixed the hand side, screen orientation or pocket, and these were not recorded.
        - Pace: no target speeds were set and lap times were not logged on the sheet. Lap durations will be taken from the saved app activities where available, to report the speed actually achieved in each lap.
        - Start both apps at the finish line, walk or jog one lap in the assigned lane, walk as close to the inner line of the lane as practical, and stop both apps when crossing the same line.
        - Record each app's distance at its finest available resolution (exported activity data where possible), and screenshot the summary.
        - Log block, lap order, lane, placement, pace, start time and weather on a shared sheet.
- Aims:
    - Estimate whether the apps systematically over- or under-record distance.
    - Identify which factors and interactions (e.g., lane × pace) influence the error.
    - Identify the tested combination with the smallest typical absolute error.

## Design:

- Type of design:
    - A $2^4$ factorial treatment structure in four complete blocks, with paired app measurements within laps.
- Efficiency of data collection:
    - Each person covers 4 × 400 m + 4 × 453 m ≈ 3.4 km, should finish measurement within 1 hour including GPS setup time.
    - Materials: our own phones, two free apps and public access to the track.
- Randomization of treatments to units:\
  Each member runs all 8 lane × placement × pace combinations in an order randomized separately within their block, generated in R with code:

```
set.seed(404)
design <- expand.grid(lane = c(1, 8), pace = c("walk", "jog"),
                      placement = c("hand", "pocket"))
members <- c("Phoebe", "Boyi", "Jenny", "Darren")
for (m in members) {
  cat(m, "\n")
  print(design[sample(8), ])
}
```

<div class="schedules">
<pre>
Phoebe
  lane pace placement
3    1  jog      hand
1    1 walk      hand
2    8 walk      hand
8    8  jog    pocket
4    8  jog      hand
6    8 walk    pocket
5    1 walk    pocket
7    1  jog    pocket
</pre>
<pre>
Boyi
  lane pace placement
2    8 walk      hand
1    1 walk      hand
3    1  jog      hand
8    8  jog    pocket
5    1 walk    pocket
7    1  jog    pocket
4    8  jog      hand
6    8 walk    pocket
</pre>
<pre>
Jenny
  lane pace placement
5    1 walk    pocket
6    8 walk    pocket
7    1  jog    pocket
2    8 walk      hand
8    8  jog    pocket
1    1 walk      hand
4    8  jog      hand
3    1  jog      hand
</pre>
<pre>
Darren
  lane pace placement
1    1 walk      hand
5    1 walk    pocket
4    8  jog      hand
8    8  jog    pocket
3    1  jog      hand
6    8 walk    pocket
7    1  jog    pocket
2    8 walk      hand
</pre>
</div>

## Data collected:

- All 32 laps and 64 app readings were recorded (`data/gps_track_data_log.csv`).
- Every block followed its randomized run order exactly.
- Dates and weather: Phoebe (partly cloudy) and Boyi (sunny) ran all laps on 12 November, and Darren ran all laps on 13 November (light rain). Jenny ran laps 1, 2 and 6 on 6 November (light rain) and the other five laps on 12 November (partly cloudy).
    - Because each block was mostly run on a single day, day and weather are confounded with block and are absorbed by the block effect.
    - Jenny's 6 November laps were all walking laps, so within her block, day and weather are partly confounded with pace.
- Both apps display distance to 0.01 km (10 m). Each reading therefore carries a rounding error of up to ±5 m (±1.25% of 400 m, ±1.10% of 453 m), and the error takes only a few discrete values.
- Start times were not logged, so run-order diagnostics use lap order.

## Tentative analysis:

- Named statistical model(s):
    - A factorial linear mixed-effects model:
        - Fixed effects: owner–phone block, four treatment factors, and their interactions.
        - Random effect: lap nested within block, accounting for paired app readings.
- Specific methods, tables and plots:
    - Test factorial effects and report estimates with 95% confidence intervals.
    - Summarize treatment means, standard deviations, and absolute percentage errors.
    - Present main-effect, interaction, and paired app comparison plots.
    - Check residual-versus-fitted, normal Q–Q, and residual-versus-lap-order plots. Because the error is discrete (10 m display resolution), the Q–Q plot will be stepped; we judge it for gross departures only.

## Limitations:

- Phone position within a placement level was not standardized. Each member's habitual way of carrying the phone is partly absorbed by the block, but any lap-to-lap inconsistency adds noise to the placement comparison. A future study should fix, within each block, the hand used, the phone orientation (upright, screen up in the hand; screen facing the body in the pocket) and the pocket, and record them.
- Pace levels were self-selected, so achieved speeds may differ between members. The block effect absorbs each member's average speed, but the size of the walk–jog contrast may differ between blocks. A future study should give target ranges, for example walking at 4.5–5.5 km/h (about 4:20–5:20 per lap in lane 1) and jogging at 8–10 km/h (about 2:25–3:00 per lap in lane 1), and time every lap.
