# Data

| File | Description |
|---|---|
| `randomization_schedule.csv` | Run order for each block, produced by `code/01_randomization.R` (seed 404). |
| `data_collection_template.csv` | Column layout for logging laps (one row per app per lap). |
| `raw/` | Raw app exports and screenshots. **Not committed** (may contain GPS traces). |
| `processed/` | Cleaned, de-identified data used for analysis (`gps_runs.csv`). |

## Variables

| Column | Values |
|---|---|
| `block` | Owner–phone pair (Phoebe, Boyi, Jenny, Darren) |
| `lap_order` | 1–8, order within block |
| `lane` | 1 or 8 |
| `pace` | walk / jog |
| `placement` | hand / pocket |
| `app` | Strava / Keep |
| `true_distance_m` | 400 (lane 1) or 453 (lane 8) |
| `recorded_distance_m` | Distance reported by the app, finest available resolution |
| `start_time`, `weather`, `notes` | Logged conditions |
