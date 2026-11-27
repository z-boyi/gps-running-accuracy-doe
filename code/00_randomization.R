# 00_randomization.R
# Randomize the run order of the 8 lane x pace x placement combinations
# independently within each block (owner-phone pair).
# One seed (404) is set once; the four blocks then get four consecutive,
# independent draws of sample(8), so each block has its own random order.
# This is the exact code from the project proposal; it also writes
# the resulting schedule to data/randomization_schedule.csv.

set.seed(404)

design <- expand.grid(
  lane      = c(1, 8),
  pace      = c("walk", "jog"),
  placement = c("hand", "pocket")
)

members <- c("Phoebe", "Boyi", "Jenny", "Darren")

schedule <- list()
for (m in members) {
  cat(m, "\n")
  idx <- sample(8)
  print(design[idx, ])
  schedule[[m]] <- data.frame(
    block      = m,
    lap_order  = 1:8,
    design_row = idx,
    design[idx, ],
    row.names  = NULL
  )
}

schedule <- do.call(rbind, schedule)
write.csv(schedule, "data/randomization_schedule.csv", row.names = FALSE)
