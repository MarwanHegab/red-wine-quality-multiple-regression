# Chemicals and Red Wine Quality: A Multiple Linear Regression Model
#
# How to run:
#   1. Install packages once:  install.packages(c("tidyverse","ggpubr","broom","car","leaps"))
#   2. Open this project folder in RStudio (or set it as your working directory
#      with setwd()) so the relative path "data/winequality-red.csv" resolves.
#   3. Run the script top to bottom (source it, or run section by section).
#
# Data: UCI Machine Learning Repository, Wine Quality (red wine subset)
#   https://archive.ics.uci.edu/dataset/186/wine+quality
#   Included at data/winequality-red.csv (semicolon-delimited).

# SECTION 0: setup ------------------------------------------------------
library(tidyverse)
library(ggpubr)
library(broom)
library(car)
library(leaps)
theme_set(theme_pubr())

# SECTION 1: load and rename columns --------------------------------------
wine <- readr::read_delim("data/winequality-red.csv", delim = ";", show_col_types = FALSE)
wine <- wine %>%
  rename(
    fixed_acidity = `fixed acidity`,
    volatile_acidity = `volatile acidity`,
    citric_acid = `citric acid`,
    residual_sugar = `residual sugar`,
    chlorides = chlorides,
    free_sulfur_dioxide = `free sulfur dioxide`,
    total_sulfur_dioxide = `total sulfur dioxide`,
    density = density,
    pH = pH,
    sulphates = sulphates,
    alcohol = alcohol,
    quality = quality
  )
dim(wine)
names(wine)
summary(wine)

# SECTION 2: clean data -----------------------------------------------------
df <- wine %>%
  select(
    quality,
    fixed_acidity,
    volatile_acidity,
    citric_acid,
    residual_sugar,
    chlorides,
    free_sulfur_dioxide,
    total_sulfur_dioxide,
    density,
    pH,
    sulphates,
    alcohol
  )
colSums(is.na(df))
df <- df %>% drop_na()

# SECTION 3: train/test split -----------------------------------------------
set.seed(456)
n <- nrow(df)
train_idx <- sample(seq_len(n), size = floor(0.7 * n))
train <- df[train_idx, ]
test  <- df[-train_idx, ]
n_train <- nrow(train)
n_test  <- nrow(test)
n_train; n_test

# SECTION 4: exploratory correlations ----------------------------------------
summary(train)
cor_mat <- cor(train)
round(cor_mat, 3)

quality_corr <- sort(cor_mat[, "quality"], decreasing = TRUE)
quality_corr

quality_corr_df <- data.frame(
  variable = names(quality_corr),
  correlation_with_quality = as.numeric(quality_corr)
)
quality_corr_df

# SECTION 5: full model (all 11 predictors) ----------------------------------
model_full <- lm(
  quality ~ fixed_acidity + volatile_acidity + citric_acid +
    residual_sugar + chlorides + free_sulfur_dioxide +
    total_sulfur_dioxide + density + pH + sulphates + alcohol,
  data = train
)
summary(model_full)

# SECTION 6: best subset selection -------------------------------------------
subset_fit <- regsubsets(
  quality ~ .,
  data = train,
  nvmax = 11,
  method = "exhaustive"
)
subset_summary <- summary(subset_fit)

subset_table <- data.frame(
  n_predictors = 1:11,
  adjr2 = subset_summary$adjr2,
  cp = subset_summary$cp,
  bic = subset_summary$bic
)
subset_table

best_adjr2_size <- which.max(subset_summary$adjr2)
best_cp_size    <- which.min(subset_summary$cp)
best_bic_size   <- which.min(subset_summary$bic)
best_adjr2_size
best_cp_size
best_bic_size

coef(subset_fit, best_adjr2_size)
coef(subset_fit, best_cp_size)
coef(subset_fit, best_bic_size)

# SECTION 7: build candidate model formulas ----------------------------------
make_formula <- function(subset_object, id) {
  vars <- names(coef(subset_object, id))[-1]
  rhs <- paste(vars, collapse = " + ")
  as.formula(paste("quality ~", rhs))
}
formula_adjr2 <- make_formula(subset_fit, best_adjr2_size)
formula_cp    <- make_formula(subset_fit, best_cp_size)
formula_bic   <- make_formula(subset_fit, best_bic_size)

formula_adjr2
formula_cp
formula_bic

model_adjr2 <- lm(formula_adjr2, data = train)
model_cp    <- lm(formula_cp, data = train)
model_bic   <- lm(formula_bic, data = train)

# SECTION 8: compare candidate models -----------------------------------------
compare_models <- function(model, label) {
  g <- glance(model)
  data.frame(
    model = label,
    predictors = paste(names(coef(model))[-1], collapse = ", "),
    adj_r_squared = g$adj.r.squared,
    r_squared = g$r.squared,
    sigma = g$sigma,
    AIC = AIC(model),
    BIC = BIC(model)
  )
}
comparison_table <- bind_rows(
  compare_models(model_adjr2, "Best Adjusted R2 Model"),
  compare_models(model_cp,    "Best Cp Model"),
  compare_models(model_bic,   "Best BIC Model")
)
comparison_table

model_selected <- model_bic
summary(model_selected)

# SECTION 9: multicollinearity check -------------------------------------------
vif(model_selected)

# SECTION 10: diagnostic plots ----------------------------------------------
par(mfrow = c(2, 2))
plot(model_selected)
par(mfrow = c(1, 1))
qqnorm(residuals(model_selected), main = "Normal Q-Q Plot (Diagonal Plot Check)")
qqline(residuals(model_selected))

# SECTION 11: identify influential points -------------------------------------
cooks <- cooks.distance(model_selected)
cook_threshold <- 4 / n_train
which_influential <- which(cooks > cook_threshold)
length(which_influential)
cook_threshold

train_clean <- train
if (length(which_influential) > 0) {
  train_clean <- train[-which_influential, ]
}

# SECTION 12: refit final model on cleaned training data ------------------------
final_formula <- formula(model_selected)
model_final <- lm(final_formula, data = train_clean)
summary(model_final)

# SECTION 13: final model assessment -------------------------------------------
summary(model_final)
confint(model_final)
tidy(model_final)
glance(model_final)

AIC(model_final)
BIC(model_final)
vif(model_final)

# SECTION 14: baseline simple regression for comparison (Project 1) -------------
model_simple <- lm(quality ~ alcohol, data = train_clean)
summary(model_simple)
glance(model_simple)
AIC(model_simple)
BIC(model_simple)

# SECTION 15: test-set evaluation ----------------------------------------------
test$pred_simple <- predict(model_simple, newdata = test)
test$pred_final  <- predict(model_final, newdata = test)

get_test_metrics <- function(actual, predicted) {
  rmse <- sqrt(mean((actual - predicted)^2))
  mae  <- mean(abs(actual - predicted))
  sst  <- sum((actual - mean(actual))^2)
  sse  <- sum((actual - predicted)^2)
  r2   <- 1 - (sse / sst)
  data.frame(
    RMSE = rmse,
    MAE = mae,
    R2_test = r2
  )
}

metrics_simple <- get_test_metrics(test$quality, test$pred_simple)
metrics_final  <- get_test_metrics(test$quality, test$pred_final)

metrics_simple$model <- "Simple Regression: quality ~ alcohol"
metrics_final$model  <- "Final Multiple Regression"

test_comparison <- bind_rows(metrics_simple, metrics_final) %>%
  select(model, RMSE, MAE, R2_test)
test_comparison

# SECTION 16: actual vs predicted plot -----------------------------------------
p_avp_final <- ggplot(test, aes(x = quality, y = pred_final)) +
  geom_point(alpha = 0.6) +
  geom_abline(slope = 1, intercept = 0) +
  labs(
    title = "Test Set: Actual vs Predicted Quality (Final Multiple Model)",
    x = "Actual quality",
    y = "Predicted quality"
  )
p_avp_final

# SECTION 17: final model summary -----------------------------------------------
summary(model_final)
glance(model_final)
tidy(model_final)
AIC(model_final)
BIC(model_final)
vif(model_final)

# SECTION 18: example prediction at mean predictor profile (CI + PI) ------------
final_predictors <- names(coef(model_final))[-1]
new_x <- as.data.frame(
  t(colMeans(train_clean[, final_predictors, drop = FALSE]))
)
new_x

predict(model_final, newdata = new_x, interval = "confidence", level = 0.95)
predict(model_final, newdata = new_x, interval = "prediction", level = 0.95)

# SECTION 19: coefficient table --------------------------------------------------
coef_table <- tidy(model_final)
coef_table
