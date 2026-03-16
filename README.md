# AKI Risk Prediction — BigQuery + ML Pipeline

> End-to-end pipeline: BigQuery SQL feature extraction from MIMIC-III (40K+ ICU patients) -> Python ML for AKI risk prediction. AUC 0.88.

---

## Architecture

    [BigQuery: MIMIC-III Clinical DB]
             |
             | SQL 4-stage pipeline (/sql)
             v
    [Cohort] -> [Lab Features] -> [Demographics]
             |
             v
    [Final Feature Table — BigQuery]
             |
             | src/bq_extract.py
             v
    [feature_matrix.csv]
             |
             | src/preprocess.py
             v
    [Train/Test Split]
             |
             | src/train.py
             v
    [Models] -> src/evaluate.py -> [Metrics + Plots]

---

## Why This Project

- **Source**: BigQuery public dataset (physionet-data.mimiciii_clinical)
- **Scale**: 40,000+ ICU admissions, 27M+ lab events, 330M+ chart events
- **Feature engineering**: Multi-table SQL joins, time-window aggregations
- **ML**: Classification with SMOTE balancing and LASSO feature selection
- **Stack**: Same GCP + SQL architecture as production data pipelines

---

## BigQuery Schema Used

| Table | Approx Rows | Description |
|-------|-------------|-------------|
| patients | 46,520 | Demographics (DOB, gender) |
| admissions | 58,976 | Hospital admissions |
| icustays | 61,532 | ICU stay records |
| diagnoses_icd | 651,047 | ICD-9 diagnosis codes |
| labevents | 27.8M | Lab measurements (creatinine) |
| chartevents | 330M | Bedside vitals (weight, GCS) |

---

## SQL Pipeline (/sql)

| File | Purpose | Key Techniques |
|------|---------|----------------|
| 01_cohort_extraction.sql | Build DKA study population | CTEs, ROW_NUMBER() OVER (PARTITION BY), LEFT JOIN IS NULL |
| 02_lab_features.sql | Creatinine + AKI label | Time-window filtering, KDIGO criteria |
| 03_demographics_vitals.sql | Demographics + weight + GCS | FIRST_VALUE() OVER, range validation |
| 04_final_feature_table.sql | Final model-ready table | Join, validation query |

---

## AKI Definition (KDIGO Criteria)

AKI labeled positive (aki_flag = 1) if either condition met within 7 days:
- Absolute creatinine rise >= 0.3 mg/dL, OR
- Relative creatinine rise >= 1.5x baseline

---

## ML Results

| Model | Accuracy | AUC-ROC | F1 (AKI class) |
|-------|----------|---------|----------------|
| Random Forest | 83.4% | 0.88 | 0.69 |
| Logistic Regression | 72.1% | 0.74 | — |
| KNN | — | — | — |

See /docs for confusion matrices and ROC curves.

---

## Python Pipeline (/src)

| File | Purpose |
|------|---------|
| bq_extract.py | Connect to BigQuery, run SQL, save feature matrix |
| preprocess.py | KNN imputation, encoding, SMOTE, train/test split |
| train.py | LASSO feature selection, train RF/LR/KNN, save model |
| evaluate.py | Full metrics, confusion matrix, ROC curve plots |

---

## Project Structure

    aki-risk-prediction/
    +-- sql/
    |   +-- 01_cohort_extraction.sql
    |   +-- 02_lab_features.sql
    |   +-- 03_demographics_vitals.sql
    |   +-- 04_final_feature_table.sql
    +-- src/
    |   +-- bq_extract.py
    |   +-- preprocess.py
    |   +-- train.py
    |   +-- evaluate.py
    +-- notebooks/
    |   +-- AKI_Pipeline_Walkthrough.ipynb
    +-- data/processed/
    |   +-- feature_matrix_sample.csv
    +-- docs/
    |   +-- confusion_matrices.png
    |   +-- roc_curves.png
    +-- requirements.txt
    +-- README.md

---

## How to Run

1. Install dependencies
   pip install -r requirements.txt

2. Set GCP credentials
   export GCP_PROJECT_ID=your-project-id
   export GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json

3. Run SQL files in BigQuery (01 to 04 in order)

4. Extract feature matrix
   python src/bq_extract.py

5. Train and evaluate
   python src/train.py
   python src/evaluate.py

---

## Data Note

Raw MIMIC-III requires credentialed access via PhysioNet (https://physionet.org/content/mimiciii/1.4/).
A 500-row anonymized sample is in data/processed/ for reproducibility.

---

## Transferable Applications

- Fintech: transaction fraud, loan default prediction
- E-commerce: return fraud, churn prediction
- Banking: credit risk scoring, portfolio screening

---

## Tech Stack

GCP (BigQuery) · Python · SQL · Pandas · Scikit-learn · imbalanced-learn · Matplotlib · Seaborn · Jupyter

---

## Team

Venkat Amit Kommineni — SQL querying, model development
Namrata Patil — SQL querying, model evaluation
Krishnendu Nair — Model development, model evaluation
