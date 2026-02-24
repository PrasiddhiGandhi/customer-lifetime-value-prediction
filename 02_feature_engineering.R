# 02_feature_engineering.R

library(dplyr)

clean_data <- readRDS("data/clean_data.rds")

# Define cutoff date
cutoff_date <- as.POSIXct("2010-09-30 23:59:59")

# Split historical and future data
historical_data <- clean_data %>%
  filter(InvoiceDate <= cutoff_date)

future_data <- clean_data %>%
  filter(InvoiceDate > cutoff_date)

# Aggregate historical features
historical_customers <- historical_data %>%
  group_by(`Customer ID`) %>%
  summarise(
    hist_revenue = sum(InvoiceValue),
    hist_orders = n_distinct(Invoice),
    hist_items = sum(Quantity),
    hist_avg_order = hist_revenue / hist_orders,
    .groups = "drop"
  )

# Future revenue
future_revenue <- future_data %>%
  group_by(`Customer ID`) %>%
  summarise(
    future_revenue = sum(InvoiceValue),
    .groups = "drop"
  )

# Merge datasets
model_dataset <- historical_customers %>%
  left_join(future_revenue, by = "Customer ID")

# Replace NA future revenue with 0
model_dataset$future_revenue[is.na(model_dataset$future_revenue)] <- 0

# Create target variable (Top 30%)
threshold <- quantile(model_dataset$future_revenue, 0.7)

model_dataset$high_value_future <- ifelse(
  model_dataset$future_revenue >= threshold,
  1,
  0
)

saveRDS(model_dataset, "data/model_dataset.rds")