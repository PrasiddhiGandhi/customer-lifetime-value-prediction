**📊 Customer Lifetime Value Prediction (R)**

**🎯 Business Problem**
An e-commerce retailer wants to identify customers likely to become high-value in the upcoming quarter in order to:
- Improve retention strategy
- Optimize marketing spend
- Increase customer lifetime value (CLV)
- Prioritize high-impact customer segments

This project develops a forward-looking predictive model using historical transaction data to identify high-value customers before they generate future revenue.

**📁 Dataset**
- 500,000+ transactional records
- UK-based online retail data
- Time period: 2009–2010
- 4,000+ unique customers

The dataset includes:
- Invoice-level transactions
- Quantity purchased
- Unit price
- Customer ID
- Timestamp

**🧹 Data Preparation**
Data cleaning steps included:
- Removed transactions with missing Customer IDs
- Removed returns (negative quantities)
- Removed negative pricing entries
- Created transaction-level revenue (Quantity × Price)
- Aggregated customer-level historical features
Final modelling dataset contained clean, customer-level behavioural features.

**🧠 Feature Engineering**
To prevent data leakage, a **time-based validation framework** was implemented.

**Historical Period (Jan–Sep 2010)**
- Used to build features:
- Historical Revenue
- Order Frequency
- Average Order Value
- Total Items Purchased

**Future Period (Oct–Dec 2010)**
Used to define target variable:
- High-Value Future Customer (Top 30% of revenue contributors)
This ensures true forward-looking predictive modelling.

**🤖 Model Comparison**
Two models were trained and evaluated using an 80/20 train-test split:
- Model	Accuracy	AUC
- Logistic Regression	77%	0.79
- Random Forest	76%	0.77
- Key Observations

- Logistic regression slightly outperformed Random Forest.
- Purchase frequency and historical revenue were strongest predictors.
- The model demonstrates meaningful predictive power for future customer value.

**📈 Key Insights**

- Revenue distribution is highly right-skewed, indicating strong customer concentration.
- A relatively small segment of customers drives the majority of revenue.
- Recency and purchase frequency significantly impact future high-value probability.
- Time-aware modelling produces more realistic performance than static segmentation.

**💡 Business Impact**
This modelling framework enables:
- Early identification of high-value customers
- Targeted retention and loyalty campaigns
- Improved marketing ROI
- Data-driven customer prioritization
By identifying customers likely to generate significant future revenue, the business can allocate resources more efficiently.

**📊 Visual Outputs**
The /visuals folder includes:
- Revenue distribution (log scale)
- Revenue contribution by segment
- ROC curve comparison
- Random Forest feature importance

**🛠 Tools & Libraries**
- R
- dplyr
- randomForest
- pROC
- Logistic Regression
- Time-based validation
