# 03_logistic_model.R

library(dplyr)
library(pROC)

model_dataset <- readRDS("data/model_dataset.rds")

# Select features
final_data <- model_dataset %>%
  select(
    hist_revenue,
    hist_orders,
    hist_items,
    hist_avg_order,
    high_value_future
  ) %>%
  na.omit()

# Train-test split
set.seed(123)

train_index <- sample(1:nrow(final_data), 0.8 * nrow(final_data))

train_data <- final_data[train_index, ]
test_data  <- final_data[-train_index, ]

# Train logistic regression
log_model <- glm(
  high_value_future ~ .,
  data = train_data,
  family = "binomial"
)

# Predictions
test_data$log_prob <- predict(
  log_model,
  newdata = test_data,
  type = "response"
)

test_data$log_pred <- ifelse(test_data$log_prob > 0.5, 1, 0)

# Performance
log_roc <- roc(test_data$high_value_future, test_data$log_prob)
log_auc <- auc(log_roc)

log_accuracy <- mean(test_data$log_pred ==
                       test_data$high_value_future)

saveRDS(log_model, "results/logistic_model.rds")
saveRDS(test_data, "results/logistic_test_data.rds")

print(paste("Logistic Accuracy:", round(log_accuracy, 4)))
print(paste("Logistic AUC:", round(log_auc, 4)))