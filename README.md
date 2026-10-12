# Customer-Segmentation-and-Purchase-Prediction
Segmenting e-commerce customers by purchasing behaviour with RFM analysis and K-Means clustering, then predicting which customers will buy again and how much they will spend. Each segment comes with a recommended marketing action.


**Tools:** Python (Pandas, NumPy, Scikit-learn, Matplotlib, Seaborn) · MySQL 


**1. Business Problem**


Marketing teams often send the same offer to every customer, which wastes budget on low-value customers and under-rewards the best ones. This project answers three questions:

Which groups of customers exist, based on how they buy?

Which customers are likely to purchase again in the next 30 days?

What should the business do differently for each group?



**2. Dataset**


File: online_retail.csv, transactional data from a UK-based online retailer (public UCI Online Retail dataset).

Columns: InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country

Size: 99,999 rows covering about 12 weeks (Dec 2010 – Feb 2011).


**Scope note:** the dataset contains no demographic fields such as age or gender (only Country), so segmentation is based on purchase behaviour. Only about 12 weeks of data were available, so "future" purchases are defined as the last 30 days.



**3. Approach**


**3.1 Data cleaning**


|Issue	                                      |                        Action                                              |

|----------------------------------------------|---------------------------------------------------------------------------|

|924 duplicate rows	                           |                   Removed                                                  |

|~35% of rows with no CustomerID	           |                  Removed (customers cannot be tracked without an ID)       |

|Cancelled invoices (InvoiceNo starts with "C"),
negative or zero Quantity/UnitPrice            |               Removed                                                   |

|Missing product descriptions	               |                 Filled with "UNKNOWN"                                   |


|Two mixed date formats in InvoiceDate	        |                Standardised to YYYY-MM-DD HH:MM:SS                     |


|No revenue column	                            |                 Created TotalPrice = Quantity × UnitPrice               |



Result: 62,408 clean rows with no missing values (online_retail_clean.csv).



**3.2 Feature engineering**

To avoid data leakage, features use only data before a cutoff date (30 days before the last transaction). The target comes from the 30 days after it.

|Feature	                                 |                       Definition                                           |

|-------------------------------------------|-----------------------------------------------------------------------------|

|Recency	                                 |                       Days since last purchase                             |

|Frequency	                                 |                     Number of distinct orders                               |

|Monetary	                                 |                     Total spend (historical customer lifetime value)        |

|Average Order Value                         |                  	Monetary ÷ Frequency                                   |

|Unique Products	                         |                       Distinct products purchased                           |

|Avg Items per Order	                     |                       Items ÷ orders                                       |

|Tenure	                                     |                   Days since first purchase                                 |



**3.3 Segmentation**


Applied a log transform and standard scaling to Recency, Frequency and Monetary, because all three are heavily right-skewed.
Chose the number of clusters using the elbow method and silhouette score.

Fitted K-Means with k = 4 on 1,178 customers and profiled each cluster.


**3.4 Predictive modelling**


|Task                |                     Model                                  |                    	Target              |

|--------------------|------------------------------------------------------------|-----------------------------------------|

|Classification	     |            Decision Tree (depth 4, class-balanced)	       |     Will the customer purchase in the |                                                                                            next 30 days?

|Regression          |                	Random Forest                             |    Future spend, modelled on the log                                                                                            scale because spend is highly skewed |


**4. Results**

Customer segments

|Segment	    |  Customers	| % of customer | % of revenue	| Avg recency 	| Avg orders  | Avgspend |  Repeatpurchase |                                                                                       (days)                  rate
|---------------|---------------|---------------|---------------|---------------|-------------|-----------|-----------------|

Champion        |    109        |        9%      |       49%    |       10      |    5.6     |  4,572	  |     72%         |

Loyal / frequent|	255	        |        22%	 |      26%	     |      30	     |    2.2	  |   1,028	   |    50%         |

Potential / new	|  266	        |        23%	 |      12%	     |      8	     |    1.3      |   456	   |   30%          |

At-risk /       | 	548	        |        47%	 |          14%	   |        43	 |    1.0	    |   262	    |    21%       |   low value  

 
**Key finding:** 9% of customers generate almost half of the revenue, and nearly half of all customers bought only once and have not returned recently.

**Model performance**

|Model	                |                    Metric	               |             Result                             |

|-----------------------|------------------------------------------|-------------------------------------------------|

|Decision Tree 	        |                     Accuracy 	            |             0.72                               |
 (classification)	

|	                     |                   Precision	             |            0.58                               |
											
  
 |                       |                 	Recall	                |              0.68                               |
											
  
|Random Forest 	          |              RMSE (log scale)	         |        2.67 vs. 2.91 baseline                   |
(regression)



**Classification:** the model identifies about two-thirds of returning customers. Purchase frequency is the strongest predictor.


**Regression:** the improvement over the baseline is modest, which is expected with a short time window and a few very large buyers. Treat the spend model as a proof of concept, not a production forecast.


**5. Business Recommendations**


|Segment                   |                  	   Recommended action                                                       |

|--------------------------|------------------------------------------------------------------------------------------------|

|Champions	                |          VIP programme, early access to new products and referral rewards. Protect the       |                                        relationship rather than discounting heavily. 


|Loyal / frequent	        |        Loyalty points, product bundles and cross-selling to raise average order value.        |


|Potential / new	        |         Welcome email series and a second-purchase incentive to turn one-time buyers         |                                               into repeat customers.


|At-risk / low value	    |          Time-limited win-back campaign through low-cost channels (email). Limit spend       |                                           on this group.



**6. Repository Structure**


├── Customer_Segmentation.ipynb     # Full analysis with charts

├── customer_segmentation.sql       # SQL version (MySQL 8): cleaning, features, RFM segments

├── online_retail_clean.csv         # Cleaned transaction data

└── README.md



**7. How to Run**

bash

pip install pandas numpy scikit-learn matplotlib seaborn jupyter

Customer_Segmentation.ipynb  (https://github.com/somyav801-ship-it/Customer-Segmentation-and-Purchase-Prediction/blob/main/Customer_Segmentation%20.ipynb)


SQL QUERIES -(https://github.com/somyav801-ship-it/Customer-Segmentation-and-Purchase-Prediction/blob/main/customer_segmentation.sql)


**8. Author**

Somya Verma · Data Analyst
