library(readxl)
getwd()
setwd("E:/Job Material/Sql Projects/Retail_Sales Analysis Project")
data <- read_excel("online_retail_II.xlsx")

str(data)
summary(data)

clean_data <- data[!is.na(data$`Customer ID`), ]
clean_data <- clean_data[clean_data$Quantity > 0, ]
clean_data <- clean_data[clean_data$Price > 0, ]
clean_data$InvoiceValue <- clean_data$Quantity * clean_data$Price

dim(clean_data)
summary(clean_data$InvoiceValue)

library(dplyr)

customer_data <- clean_data %>%
  group_by(`Customer ID`) %>%
  summarise(
    total_revenue = sum(InvoiceValue),
    total_orders = n_distinct(Invoice),
    total_items = sum(Quantity),
    avg_order_value = total_revenue / total_orders,
    first_purchase = min(InvoiceDate),
    last_purchase = max(InvoiceDate)
  )


dim(customer_data)
summary(customer_data$total_revenue)

summary(customer_data$total_revenue)


max_date <- max(clean_data$InvoiceDate)

customer_data$recency_days <- as.numeric(difftime(
  max_date,
  customer_data$last_purchase,
  units = "days"
))

summary(customer_data$recency_days)

customer_data$frequency <- customer_data$total_orders

summary(customer_data$frequency)

customer_data$R_score <- ntile(-customer_data$recency_days, 5)
customer_data$F_score <- ntile(customer_data$frequency, 5)
customer_data$M_score <- ntile(customer_data$total_revenue, 5)

head(customer_data[, c("R_score", "F_score", "M_score")])


customer_data$RFM_score <- paste0(
  customer_data$R_score,
  customer_data$F_score,
  customer_data$M_score
)

customer_data$segment <- "Other"

customer_data$segment[
  customer_data$R_score >= 4 &
    customer_data$F_score >= 4 &
    customer_data$M_score >= 4
] <- "Champions"

customer_data$segment[
  customer_data$R_score >= 3 &
    customer_data$F_score >= 3 &
    customer_data$M_score >= 3 &
    customer_data$segment == "Other"
] <- "High Value"

customer_data$segment[
  customer_data$R_score >= 3 &
    customer_data$F_score >= 2 &
    customer_data$segment == "Other"
] <- "Loyal"

customer_data$segment[
  customer_data$R_score <= 2 &
    customer_data$F_score >= 3
] <- "At Risk"

customer_data$segment[
  customer_data$R_score == 1
] <- "Churned"

table(customer_data$segment)

aggregate(total_revenue ~ segment, data = customer_data, sum)


customer_data$high_value_flag <- ifelse(
  customer_data$segment %in% c("Champions", "High Value"),
  1,
  0
)

# ===============================
# 1️⃣ Create Target Variable
# ===============================

customer_data$high_value_flag <- ifelse(
  customer_data$segment %in% c("Champions", "High Value"),
  1,
  0
)


# ===============================
# 2️⃣ Select Features for Model
# ===============================

model_data <- customer_data[, c(
  "recency_days",
  "frequency",
  "avg_order_value",
  "total_items",
  "high_value_flag"
)]


# ===============================
# 3️⃣ Train-Test Split (80/20)
# ===============================

set.seed(123)

train_index <- sample(
  1:nrow(model_data),
  0.8 * nrow(model_data)
)

train_data <- model_data[train_index, ]
test_data  <- model_data[-train_index, ]


# ===============================
# 4️⃣ Train Logistic Regression
# ===============================

log_model <- glm(
  high_value_flag ~ recency_days + frequency + avg_order_value + total_items,
  data = train_data,
  family = "binomial"
)

summary(log_model)


# ===============================
# 5️⃣ Generate Predictions
# ===============================

test_data$probability <- predict(
  log_model,
  newdata = test_data,
  type = "response"
)

test_data$predicted_class <- ifelse(
  test_data$probability > 0.5,
  1,
  0
)


# ===============================
# 6️⃣ Confusion Matrix
# ===============================

table(
  Actual = test_data$high_value_flag,
  Predicted = test_data$predicted_class
)


# ===============================
# 7️⃣ Accuracy
# ===============================

accuracy <- mean(
  test_data$predicted_class == test_data$high_value_flag
)

print(paste("Accuracy:", round(accuracy, 4)))


# ===============================
# 8️⃣ ROC Curve & AUC
# ===============================

library(pROC)

roc_obj <- roc(
  test_data$high_value_flag,
  test_data$probability
)

plot(roc_obj, col = "blue")
auc_value <- auc(roc_obj)

print(paste("AUC:", round(auc_value, 4)))

# Define cutoff date
cutoff_date <- as.POSIXct("2010-09-30 23:59:59")

# Split dataset
historical_data <- clean_data[clean_data$InvoiceDate <= cutoff_date, ]
future_data     <- clean_data[clean_data$InvoiceDate > cutoff_date, ]


library(dplyr)

historical_customers <- historical_data %>%
  group_by(`Customer ID`) %>%
  summarise(
    hist_revenue = sum(InvoiceValue),
    hist_orders = n_distinct(Invoice),
    hist_items = sum(Quantity),
    hist_avg_order = hist_revenue / hist_orders,
    last_purchase_hist = max(InvoiceDate)
  )

future_revenue <- future_data %>%
  group_by(`Customer ID`) %>%
  summarise(
    future_revenue = sum(InvoiceValue)
  )

model_dataset <- merge(
  historical_customers,
  future_revenue,
  by = "Customer ID",
  all.x = TRUE
)

# Replace NA future revenue with 0
model_dataset$future_revenue[is.na(model_dataset$future_revenue)] <- 0

threshold <- quantile(model_dataset$future_revenue, 0.7)

model_dataset$high_value_future <- ifelse(
  model_dataset$future_revenue >= threshold,
  1,
  0
)

summary(model_dataset$future_revenue)
table(model_dataset$high_value_future)

library(dplyr)

final_data <- model_dataset %>%
  select(
    hist_revenue,
    hist_orders,
    hist_items,
    hist_avg_order,
    high_value_future
  )

# Remove any NA
final_data <- na.omit(final_data)
set.seed(123)

train_index <- sample(
  1:nrow(final_data),
  0.8 * nrow(final_data)
)

train_data <- final_data[train_index, ]
test_data  <- final_data[-train_index, ]
log_model <- glm(
  high_value_future ~ .,
  data = train_data,
  family = "binomial"
)

# Predict
test_data$log_prob <- predict(
  log_model,
  newdata = test_data,
  type = "response"
)

test_data$log_pred <- ifelse(test_data$log_prob > 0.5, 1, 0)

library(pROC)

# Logistic AUC
log_roc <- roc(as.numeric(as.character(test_data$high_value_future)),
               test_data$log_prob)

log_auc <- auc(log_roc)

ls()
library(randomForest)

# Ensure target is factor
train_data$high_value_future <- as.factor(train_data$high_value_future)
test_data$high_value_future  <- as.factor(test_data$high_value_future)

# Train model
rf_model <- randomForest(
  high_value_future ~ hist_revenue + hist_orders + hist_items + hist_avg_order,
  data = train_data,
  ntree = 300,
  importance = TRUE
)

# Predict probabilities
rf_pred_prob <- predict(rf_model, test_data, type = "prob")[,2]

# Predict class
rf_pred_class <- ifelse(rf_pred_prob > 0.5, 1, 0)
rf_pred_class <- as.factor(rf_pred_class)

library(pROC)
# RF AUC
rf_roc <- roc(as.numeric(as.character(test_data$high_value_future)),
              rf_pred_prob)

rf_auc <- auc(rf_roc)

# Accuracy
log_accuracy <- mean(test_data$log_pred ==
                       as.numeric(as.character(test_data$high_value_future)))

rf_accuracy <- mean(rf_pred_class ==
                      test_data$high_value_future)

print(paste("Logistic Accuracy:", round(log_accuracy, 4)))
print(paste("Logistic AUC:", round(log_auc, 4)))

print(paste("RF Accuracy:", round(rf_accuracy, 4)))
print(paste("RF AUC:", round(rf_auc, 4)))

plot(log_roc, col="blue", main="ROC Curve Comparison")
plot(rf_roc, col="red", add=TRUE)
legend("bottomright",
       legend=c("Logistic", "Random Forest"),
       col=c("blue","red"),
       lwd=2)


png("visuals/roc_comparison.png")
plot(log_roc, col="blue")
plot(rf_roc, col="red", add=TRUE)
dev.off()

png("visuals/feature_importance.png")
varImpPlot(rf_model)
dev.off()

png("visuals/roc_comparison.png")
plot(log_roc, col="blue")
plot(rf_roc, col="red", add=TRUE)
dev.off()

png("visuals/feature_importance.png")
varImpPlot(rf_model)
dev.off()

