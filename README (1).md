# Customer Segmentation and Purchase Prediction (Python, SQL)

Segmenting e-commerce customers by purchasing behaviour with RFM analysis and K-Means clustering, then predicting which customers will buy again and how much they will spend. Each segment comes with a recommended marketing action.

**Tools:** Python (Pandas, NumPy, Scikit-learn, Matplotlib, Seaborn), MySQL, Jupyter Notebook

---

## 1. Business Problem

Marketing teams often send the same offer to every customer, which wastes budget on low-value customers and under-rewards the best ones. This project answers three questions:

1. Which groups of customers exist, based on how they buy?
2. Which customers are likely to purchase again in the next 30 days?
3. What should the business do differently for each group?

## 2. Dataset

- **File:** `online_retail.csv`, transactional data from a UK-based online retailer (public UCI Online Retail dataset)
- **Columns:** InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
- **Size:** 99,999 rows covering about 12 weeks (Dec 2010 to Feb 2011)

**Scope note:** the dataset has no demographic fields such as age or gender (only `Country`), so segmentation is based on purchase behaviour. Only about 12 weeks of data were available, so "future" purchases are defined as the last 30 days.

## 3. Approach

### 3.1 Data cleaning

- **924 duplicate rows:** removed
- **About 35% of rows with no CustomerID:** removed, because customers cannot be tracked without an ID
- **Cancelled invoices (InvoiceNo starts with "C") and negative or zero Quantity/UnitPrice:** removed
- **Missing product descriptions:** filled with "UNKNOWN"
- **Two mixed date formats in InvoiceDate:** standardised to `YYYY-MM-DD HH:MM:SS`
- **No revenue column:** created `TotalPrice = Quantity x UnitPrice`

**Result:** 62,408 clean rows with no missing values (`online_retail_clean.csv`).

### 3.2 Feature engineering

To avoid data leakage, features use only data before a cutoff date (30 days before the last transaction). The target comes from the 30 days after it.

- **Recency:** days since last purchase
- **Frequency:** number of distinct orders
- **Monetary:** total spend (historical customer lifetime value)
- **Average Order Value:** Monetary divided by Frequency
- **Unique Products:** distinct products purchased
- **Avg Items per Order:** items divided by orders
- **Tenure:** days since first purchase

### 3.3 Segmentation

- Applied a log transform and standard scaling to Recency, Frequency and Monetary, because all three are heavily right-skewed
- Chose the number of clusters using the elbow method and silhouette score
- Fitted **K-Means with k = 4** on 1,178 customers and profiled each cluster

### 3.4 Predictive modelling

- **Classification:** Decision Tree (depth 4, class-balanced) predicts whether a customer will purchase in the next 30 days
- **Regression:** Random Forest predicts future spend, modelled on the log scale because spend is highly skewed

## 4. Results

### Customer segments

**Champions** (109 customers, 9% of customers, 49% of revenue)
- Average recency 10 days, 5.6 orders, average spend 4,572
- Repeat-purchase rate: 72%

**Loyal / frequent** (255 customers, 22% of customers, 26% of revenue)
- Average recency 30 days, 2.2 orders, average spend 1,028
- Repeat-purchase rate: 50%

**Potential / new** (266 customers, 23% of customers, 12% of revenue)
- Average recency 8 days, 1.3 orders, average spend 456
- Repeat-purchase rate: 30%

**At-risk / low value** (548 customers, 47% of customers, 14% of revenue)
- Average recency 43 days, 1.0 orders, average spend 262
- Repeat-purchase rate: 21%

**Key finding:** 9% of customers generate almost half of the revenue, and nearly half of all customers bought only once and have not returned recently.

### Model performance

**Decision Tree (classification)**
- Accuracy: 0.72
- Precision: 0.58
- Recall: 0.68

**Random Forest (regression)**
- RMSE (log scale): 2.67 vs. 2.91 for a baseline that always predicts the mean

The classifier identifies about two-thirds of returning customers, and purchase frequency is the strongest predictor. The regression improvement over the baseline is modest, which is expected with a short time window and a few very large buyers, so treat the spend model as a proof of concept, not a production forecast.

## 5. Business Recommendations

- **Champions:** VIP programme, early access to new products and referral rewards. Protect the relationship rather than discounting heavily.
- **Loyal / frequent:** loyalty points, product bundles and cross-selling to raise average order value.
- **Potential / new:** welcome email series and a second-purchase incentive to turn one-time buyers into repeat customers.
- **At-risk / low value:** time-limited win-back campaign through low-cost channels such as email. Limit spend on this group.

## 6. Limitations and Next Steps

- Only about 12 weeks of data and no demographic fields. Next step: rerun on a full year of data to capture seasonality and make the prediction window more reliable.
- Segment sizes and model metrics are specific to this sample.
- Possible extensions: add product-category preferences, compare K-Means with hierarchical clustering or Gaussian mixture models, and tune the models with cross-validation.

## 7. Repository Structure

- `Customer_Segmentation.ipynb`: full analysis with charts
- `customer_segmentation.sql`: SQL version (MySQL 8) covering cleaning, features and RFM segments
- `online_retail_clean.csv`: cleaned transaction data
- `online_retail.csv`: raw data
- `images/`: chart screenshots
- `README.md`: this file

## 8. How to Run

1. Install the libraries: `pip install pandas numpy scikit-learn matplotlib seaborn jupyter`
2. Place `online_retail.csv` in the same folder as the notebook
3. Open the notebook: `jupyter notebook Customer_Segmentation.ipynb`

For the SQL version, update the file path in the `LOAD DATA` statement and run the script in MySQL 8 or later.

## 9. Author

**Somya Verma**, Data Analyst
Skills: Python, SQL, Advanced Excel, Power BI, MySQL
