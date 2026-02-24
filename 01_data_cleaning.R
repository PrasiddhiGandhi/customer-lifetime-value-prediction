# 01_data_cleaning.R

library(readxl)
library(dplyr)

# Load dataset
data <- read_excel("data/online_retail_II.xlsx")

# Remove missing Customer IDs
clean_data <- data %>%
  filter(!is.na(`Customer ID`))

# Remove returns and invalid prices
clean_data <- clean_data %>%
  filter(Quantity > 0, Price > 0)

# Create Invoice Value
clean_data <- clean_data %>%
  mutate(InvoiceValue = Quantity * Price)

# Save cleaned data (optional)
saveRDS(clean_data, "data/clean_data.rds")