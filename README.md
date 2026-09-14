# Chemicals and Red Wine Quality: A Multiple Linear Regression Model

Building on the 
[Red Wine Quality Regression Project](https://github.com/MarwanHegab/red-wine-quality-regression) by
using all 11 physicochemical variables (instead of alcohol alone) to model
red wine quality, with best subset selection to find a parsimonious final
model. Uses the UCI Machine Learning Repository's
[Wine Quality dataset](https://archive.ics.uci.edu/dataset/186/wine+quality)
(red wine subset, n = 1,599).

**Authors:** Shreyes Balaji, Marwan Hegab, Mazin Hussein, Mikael Rotberg,
Roberto Rubio, Jordan Woda

## Summary

- 70/30 train/test split (1,119 / 480 observations), `set.seed(456)` for reproducibility.
- Full 11-predictor model: R² = 0.374, adjusted R² = 0.367.
- Best subset selection (adjusted R², Mallows' Cp, BIC) preferred a 6-predictor
  model: volatile acidity, chlorides, total sulfur dioxide, pH, sulphates, alcohol.
- All retained predictors have VIF between ~1.05 and 1.31 — multicollinearity is not a concern.
- 70 influential training points (Cook's distance > 4/n) were removed before the final fit.
- Final model:
  `quality_hat = 4.0452 - 0.9933(volatile acidity) - 1.9328(chlorides) - 0.00253(total sulfur dioxide) - 0.4139(pH) + 1.1351(sulphates) + 0.2940(alcohol)`
- Training fit: RSE = 0.553, R² = 0.436 (adjusted 0.433), F = 134.3, p < 2e-16.
- Test-set performance: RMSE = 0.657, MAE = 0.516, R² = 0.321 — an improvement
  over the Project 1 simple-regression baseline (RMSE = 0.704, MAE = 0.553, R² = 0.220)
  re-evaluated on the same cleaned training/test split.
- Example: at the mean values of the retained predictors, predicted quality =
  5.663 (95% CI [5.629, 5.696], 95% PI [4.577, 6.748]).

Higher alcohol and sulphates are associated with higher predicted quality;
higher volatile acidity, chlorides, total sulfur dioxide, and pH are
associated with lower predicted quality. The multiple regression model
explains more variance than alcohol alone, but still leaves roughly two-thirds
of test-set variation unexplained — wine quality depends on more than what's
captured by these 11 chemical measurements. See the essay for full discussion,
diagnostics, and limitations.

## Files

- [`project_2_essay.pdf`](project_2_essay.pdf) — full write-up (introduction, data
  description, subset selection, model evaluation, conclusion, references).
- [`analysis.R`](analysis.R) — R code for the full analysis, from data loading
  through best subset selection, diagnostics, influential-point removal, test-set
  evaluation, and prediction.
- [`data/winequality-red.csv`](data/winequality-red.csv) — the dataset (semicolon-delimited).

## Reproducing the analysis

```r
install.packages(c("tidyverse", "ggpubr", "broom", "car", "leaps"))
```

Open this folder as your working directory (e.g. open `project_2/` in RStudio),
then run `analysis.R` top to bottom. It reads `data/winequality-red.csv` using
a relative path, so no `setwd()` edits should be needed if the folder structure
is kept intact.

## References

1. UCI Machine Learning Repository — Wine Quality dataset: https://archive.ics.uci.edu/dataset/186/wine+quality
2. STHDA — Multiple Linear Regression in R: https://www.sthda.com/english/articles/40-regression-analysis/168-multiple-linear-regression-in-r/
3. DataCamp — Multiple Linear Regression in R Tutorial: https://www.datacamp.com/tutorial/multiple-linear-regression-r-tutorial
