# 04_random_forest_and_visuals.R

library(randomForest)
library(pROC)

test_data <- readRDS("results/logistic_test_data.rds")
model_dataset <- readRDS("data/model_dataset.rds")

# Prepare data
final_data <- model_dataset %>%
  select(
    hist_revenue,
    hist_orders,
    hist_items,
    hist_avg_order,
    high_value_future
  ) %>%
  na.omit()

set.seed(123)

train_index <- sample(1:nrow(final_data), 0.8 * nrow(final_data))

train_data <- final_data[train_index, ]
test_data  <- final_data[-train_index, ]

train_data$high_value_future <- as.factor(train_data$high_value_future)
test_data$high_value_future  <- as.factor(test_data$high_value_future)

# Train Random Forest
rf_model <- randomForest(
  high_value_future ~ hist_revenue + hist_orders + hist_items + hist_avg_order,
  data = train_data,
  ntree = 300,
  importance = TRUE
)

rf_pred_prob <- predict(rf_model, test_data, type = "prob")[,2]
rf_pred_class <- ifelse(rf_pred_prob > 0.5, 1, 0)

# ROC
rf_roc <- roc(as.numeric(as.character(test_data$high_value_future)),
              rf_pred_prob)

rf_auc <- auc(rf_roc)
rf_accuracy <- mean(rf_pred_class ==
                      as.numeric(as.character(test_data$high_value_future)))

print(paste("RF Accuracy:", round(rf_accuracy, 4)))
print(paste("RF AUC:", round(rf_auc, 4)))

# Save visuals
png("visuals/roc_comparison.png", width=800, height=600)
plot(rf_roc, col="red", main="ROC Curve - Random Forest")
dev.off()

png("visuals/feature_importance.png", width=800, height=600)
varImpPlot(rf_model)
dev.off()

# Save performance summary
results <- data.frame(
  Model = "Random Forest",
  Accuracy = rf_accuracy,
  AUC = as.numeric(rf_auc)
)

write.csv(results, "results/model_performance.csv", row.names = FALSE)