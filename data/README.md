# Data

| File | Description |
|---|---|
| `gps_track_data_log.csv` | Lap log as recorded: one row per lap, both apps side by side. Raw data, never edited by hand. |
| `randomization_schedule.csv` | Run order for each block, produced by `code/01_randomization.R` (seed 404). |
| `data_collection_template.csv` | Column layout for logging laps (one row per app per lap). |
| `raw/` | Raw app exports and screenshots. **Not committed** (may contain GPS traces). |
| `processed/gps_runs.csv` | Analysis data: one row per app reading (64 rows), produced from the lap log by `code/00_clean_data.R`. |

## Variables in `processed/gps_runs.csv`

| Column | Values |
|---|---|
| `block` | Owner–phone pair (Phoebe, Boyi, Jenny, Darren) |
| `lap_order` | 1–8, order within block |
| `lap_id` | Block and lap order, e.g. `Boyi_3`; the two app readings of a lap share it |
| `lane` | 1 or 8 |
| `placement` | hand / pocket |
| `pace` | walk / jog |
| `app` | Strava / Keep |
| `true_distance_m` | 400.00 (lane 1) or 453.03 (lane 8), this track's lap lengths |
| `recorded_distance_m` | Distance shown by the app, converted from km to m (10 m resolution) |
| `error_pct` | Signed percentage error, 100 × (recorded − true) / true; positive = over-recording |
| `date`, `weather`, `notes` | Logged conditions (start times were not logged) |
