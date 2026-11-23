# How Accurate Is Your Running App? A Designed Experiment on GPS Distance Error

![Language](https://img.shields.io/badge/language-R-276DC3)
![Course](https://img.shields.io/badge/STAT%20404-Design%20of%20Experiments-blue)

A blocked 2⁴ factorial experiment measuring how **app choice, track lane, phone placement and pace** affect the distance error of consumer GPS running apps (Strava vs. Keep), and whether these factors interact.

📖 **[Read the step-by-step guide to this experiment (English / 中文)](https://z-boyi.github.io/gps-running-accuracy-doe/docs/)**: how the design, data, model and conclusions fit together, with the figures and tables next to each explanation.

📊 **[Final presentation slides (PDF)](report/presentation_slides.pdf)**

## Research question

> How do running apps, lane, phone placement, and pace affect GPS distance accuracy, and do these factors interact?

Specifically, we aim to:

1. Estimate whether each app systematically **over- or under-records** distance.
2. Identify which **factors and interactions** (e.g. lane × pace) drive the error.
3. Compare the **typical absolute error** (MAPE) of the apps and the tested combinations, with 95% confidence intervals.

## Experimental design

| Component | Details |
|---|---|
| **Factors** (2 levels each) | App: Strava / Keep · Lane: 1 / 8 · Placement: hand / front pocket · Pace: walk / jog |
| **Treatment structure** | 2⁴ = 16 combinations; both apps record **simultaneously** on the same lap |
| **Site** | Rashpal Dhillon Track & Field Oval, University of British Columbia (outdoor 400 m track, 1.22 m lanes) |
| **Blocking** | 4 blocks = 4 owner–phone pairs; each person uses their own phone for all laps |
| **Experimental unit** | One lap (for lane, placement, pace); the two app readings within a lap are **paired** |
| **Randomization** | 8 lane × placement × pace combinations randomized independently within each block in R (`set.seed(404)`) |
| **Replication** | Each combination observed once per block → 8 laps/person, 32 laps, **64 app readings** |

**Response:** signed percentage distance error (positive = the app over-records)

$$e = 100 \times \frac{d_{\text{recorded}} - d_{\text{true}}}{d_{\text{true}}}, \qquad d_{\text{true}} = 400.00\text{ m (lane 1)},\ 453.03\text{ m (lane 8)}$$

**Protocol:** open both apps and wait 60 s for GPS lock; start both apps at the finish line; complete one lap on the inside of the assigned lane; stop both at the same line; record distance at the finest available resolution and screenshot the summary; log block, lap order, conditions, start time and weather.

## Analysis

- **Factorial linear mixed-effects model** for the signed error (`lme4` / `lmerTest`), with a random intercept for each lap (the two app readings in a lap are paired). The planned additive block model was extended with an **app × block** interaction after the by-block check showed that the app difference changes between phones:

  ```r
  lmer(error_pct ~ block * app + app * lane * placement * pace + (1 | lap_id), data = dat)
  ```
- **Why `(1 | lap_id)`:** both apps record the same lap at the same time, so their two readings share that lap's conditions. `lap_id` (e.g. `Boyi_3`, 32 laps) gives each lap a random intercept. This is a split-plot structure: laps are whole plots for lane, placement and pace, and app readings are sub-plots, compared within laps as in a paired test. Treating the 64 readings as independent (`lm`) would be pseudo-replication.
- Estimated means and effects with 95% CIs (`emmeans`), main-effect and interaction plots
- Diagnostics: residuals vs. fitted, normal Q–Q, residuals vs. lap order; sensitivity to the true lap length (±1 m)
- **Accuracy:** MAPE by app with a bootstrap that resamples laps within blocks, and a mixed model for log(|e| + 0.5)

## Key results

- The apps **over-record by about 1.9%** on average (95% CI 1.1% to 2.7%).
- **The app effect depends on the phone:** Strava read 1.5 to 4 percentage points longer than Keep on three phones and 2.6 points shorter on the fourth (app × block p = 0.002).
- Lane, placement and pace had **no clear effect** at this sample size.
- Keep had the lower MAPE (2.7% vs 3.6%), but the difference is not statistically clear; no single best combination is declared.

## Limitations

- The apps show distance in 0.01 km steps, so each reading has up to ±5 m (about ±1.2%) of rounding error, similar in size to several of the effects.
- Four phones on one track, mostly one day per member: day and weather cannot be separated from the block.
- Phone position and pace were left to each member's habit, so those effects are averages over personal styles.

Full results: [`report/results_summary.md`](report/results_summary.md).

## Repository structure

```
.
├── code/
│   ├── 00_clean_data.R      # lap log -> data/processed/gps_runs.csv
│   ├── 01_randomization.R   # generates the within-block run order (seed 404)
│   ├── 02_analysis.R        # signed error: mixed model, block check, diagnostics, effects
│   └── 03_absolute_error.R  # accuracy: MAPE, bootstrap, log(|e|) model
├── data/
│   ├── README.md            # what each data file contains
│   ├── gps_track_data_log.csv     # collected lap data (32 laps, both apps)
│   ├── randomization_schedule.csv
│   ├── data_collection_template.csv
│   ├── raw/                 # raw app exports (not committed)
│   └── processed/           # cleaned analysis data (gps_runs.csv)
├── docs/                    # bilingual study guide website (GitHub Pages)
│   ├── index.html           # built page; do not edit by hand
│   ├── build.py             # rebuilds index.html from src/ (needs pandoc)
│   └── src/                 # guide text (guide_en.md, guide_zh.md), template, style
├── figures/                 # plots generated by the analysis
├── results/                 # tables generated by the analysis
├── report/
│   ├── proposal.pdf         # original proposal (unchanged)
│   ├── proposal_v2.md       # revised proposal after review and data collection
│   ├── proposal_v2.pdf      # built with build_proposal_v2.sh
│   ├── proposal.css
│   ├── build_proposal_v2.sh
│   ├── results_summary.md   # results and conclusions
│   └── presentation_slides.pdf  # final class presentation (5 slides)
└── review/
    └── 2026-11_proposal/
        ├── reviewer_comments.md   # reviewer comments on the proposal, verbatim
        └── response.md            # assessment and change for each comment
```

## Review history

The original proposal is kept unchanged. Reviewer comments and our response live in `review/`, and the revised proposal is `report/proposal_v2.md`. Each reviewer comment is addressed in its own commit, so `git log -- report/proposal_v2.md` shows how every change maps to a comment.

## Reproducing

```r
# from the repository root
source("code/01_randomization.R")   # regenerate the randomized schedule
source("code/00_clean_data.R")      # lap log -> data/processed/gps_runs.csv
source("code/02_analysis.R")        # signed-error analysis
source("code/03_absolute_error.R")  # accuracy (MAPE) analysis
```

Requires R ≥ 4.2. `00_clean_data.R` installs any missing packages (`lme4`, `lmerTest`, `emmeans`, `pbkrtest`, `ggplot2`).

## Team

Group project for **STAT 404 (Design and Analysis of Experiments)** by Phoebe Yu, Boyi Zhang, Jenny Zhang and Darren Axellian Hartono. Each member ran their own block of 8 laps. This repository is maintained by Boyi Zhang and shared with the agreement of all group members.
