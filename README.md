# aki-risk-prediction
Predictive modeling of AKI in ICU patients using MIMIC-III
This project was developed as part of the Healthcare Analytics course at California State University, Northridge. It aims to predict the onset of Acute Kidney Injury (AKI) in ICU patients using data from the MIMIC-III clinical database. The workflow included SQL-based cohort extraction, exploratory data analysis (EDA), feature engineering, and predictive modeling.

Objective
To develop a predictive model that can identify ICU patients at high risk of developing AKI using structured EHR data, enabling early clinical intervention.

Team Members
Venkat Amit Kommineni – SQL querying, model development
Namrata Patil - SQL querying, model development, model evaluation
Krishnendu Nair - Model development, model evaluation
Project Components

1. Data Source:
MIMIC-III Clinical Database – De-identified EHRs of 40,000+ ICU patients
Tables used: admissions, icustays, chartevents, labevents, inputevents_mv, diagnoses_icd

2. Cohort Definition:
Included patients with ≥1 ICU stay and time-aligned creatinine measurements
Excluded chronic kidney disease cases
Cohort extraction performed using SQL joins and filters

3. Data Cleaning & EDA:
Visualized missing data via heatmaps
Aggregated and analyzed gender, dm_type, and ethnicity
Computed GCS composite score and removed raw GCS columns
Used pie charts and bar plots to show distributions

4. Feature Engineering:
Missing values imputed using KNN Imputer
Baseline creatinine calculated as min(creatinine_48hrs, creatinine_7days)
AKI diagnosis labeled using KDIGO criteria (0.3 mg/dL or 1.5x baseline)
Applied one-hot encoding and feature scaling

5. Modeling Techniques:
Models used: Logistic Regression, Random Forest (with LASSO feature selection)
Validation: Stratified train-test split and SMOTE for class balancing
Evaluation Metrics: Accuracy, Precision, Recall, F1-score, AUC-ROC
Advanced statsmodel Logit analysis on LASSO-selected features

6. Key Results
Random Forest:
Accuracy: 83.4%
AUC: 0.88
F1-score (AKI class): 0.69
Confusion Matrix:
[[160, 24],
[17, 46]]

Logistic Regression:
Accuracy: 72.1%
AUC: 0.74
LASSO-enhanced Logistic model (statsmodels):
Pseudo R²: 0.88
Log-likelihood: -71.3 over 860 observations


7. Tools & Technologies:
SQL (PostgreSQL)
Python: pandas, numpy, seaborn, matplotlib, scikit-learn, imblearn, statsmodels
Jupyter Notebooks
