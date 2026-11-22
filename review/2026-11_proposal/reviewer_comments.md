# Reviewer comments on the project proposal

- **Reviewer:** gsiii
- **Document reviewed:** `report/proposal.pdf`
- **Received:** November 2026
- **Form:** seven highlight comments on the proposal PDF, transcribed verbatim below.

| # | Location in proposal | Comment |
|---|---|---|
| 1 | Treatments → Placement: hand vs. front pocket | Standardize the hand position, phone orientation, and pocket as far as practical within each owner-phone block. |
| 2 | Treatments → Pace: walking vs. jogging | Specify practical walking and jogging instructions or target pace ranges. |
| 3 | Objectives → response formula | The displayed formula gives signed relative error. Multiply by 100 to report percentage error, or keep the formula and label it relative error throughout. Positive values indicate over-recording and negative values indicate under-recording. Keep this signed response distinct from absolute error. |
| 4 | Objectives → True distance: lane 1 = 400 m, lane 8 ≈ 453 m | Verify the distance for this specific track and route rather than treating an approximate lane length as exact ground truth. |
| 5 | Aims → smallest typical absolute error | A mean signed error near zero can hide large positive and negative errors. Define typical absolute error explicitly, such as mean absolute percentage error, and state how you will estimate it and its uncertainty. The signed-error model addresses over/under-recording and does not automatically identify the setting with the smallest absolute error. Avoid declaring a unique best combination from point estimates alone. |
| 6 | Tentative analysis → "and their interactions" | which interactions? |
| 7 | Tentative analysis → fixed effects: owner–phone block | The proposed mixed model is a reasonable starting point for the paired app readings. However, an additive owner–phone block assumes the app effects are consistent across phones. Plot the app comparisons separately by block to assess this assumption. |

Our assessment of each comment and the planned changes are in [`response.md`](response.md).
