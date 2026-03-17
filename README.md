# AKI Risk Prediction — BigQuery SQL Analysis + Python ML Pipeline

> Two-part end-to-end project: **Part 1** — BigQuery SQL cohort analysis on MIMIC-III (40K+ ICU patients). **Part 2** — Python ML pipeline for AKI risk prediction. Random Forest Accuracy 83.4%, F1 0.69.

---

## Project Overview

This project has two distinct phases that work together as a full data engineering + data science pipeline:

| Phase | Tool | What It Does |
|-------|------|--------------|
| **Part 1: SQL Analysis** | BigQuery (GCP) | Cohort extraction, lab feature aggregation, demographics join, final feature table |
| **Part 2: ML Pipeline** | Python (scikit-learn) | EDA, imputation, SMOTE balancing, LASSO feature selection, classification models |

**Clinical goal**: Predict Acute Kidney Injury (AKI) in diabetic ICU patients using the KDIGO clinical criteria applied to creatinine measurements.

---

## Part 1 — BigQuery SQL Analysis (`/sql`)

### What the SQL pipeline does

The `/sql` folder contains a 4-stage BigQuery pipeline that extracts and engineers features directly from the MIMIC-III clinical database (physionet-data.mimiciii_clinical).

```
[BigQuery: MIMIC-III Clinical DB — physionet-data.mimiciii_clinical]
        |
        | 01_cohort_extraction.sql
        v
[Diabetic ICU Cohort — DKA patients, CKD Stage 5 excluded]
        |
        | 02_lab_features.sql
        v
[Lab Values — creatinine, BUN, WBC, bicarbonate, glucose, etc.]
        |
        | 03_demographics_vitals.sql
        v
[Demographics + Vitals — age, gender, ethnicity, BP, HR, temp, GCS]
        |
        | 04_final_feature_table.sql
        v
[Final Feature Table — one row per patient, AKI label as target]
```

### BigQuery Tables Used

| Table | Approx Rows | Description |
|-------|-------------|-------------|
| `patients` | 46,520 | Demographics (DOB, gender) |
| `admissions` | 58,976 | Hospital admissions, ethnicity |
| `icustays` | 61,532 | ICU stay records |
| `diagnoses_icd` | 651,047 | ICD-9 diagnosis codes |
| `labevents` | 27,854,055 | Lab results (creatinine, BUN, WBC, etc.) |
| `chartevents` | 330,712,483 | Vitals — HR, BP, temperature, GCS |

### SQL Design Decisions

- **Cohort inclusion**: Diabetic patients (ICD-9: 25010–25013) with ICU stays ≥ 24 hours
- **Cohort exclusion**: CKD Stage 5 patients (ICD-9: 5855, 5856) — pre-existing renal failure confounds AKI labeling
- **Lab aggregation**: Time-windowed AVG for vitals; first/last creatinine values for 48-hour and 7-day windows
- **Final output**: 822 patients, 37 engineered features, ready for ML pipeline

---

## Part 2 — Python ML Pipeline (`/src`, `/notebooks`)

### Dataset

- **Source**: Feature table extracted via Part 1 SQL pipeline
- **Size**: 822 patients × 37 features
- **Class distribution**: 614 No-AKI / 208 AKI (75/25 imbalance)

### Pipeline Steps

**1. EDA & Null Analysis**
- Seaborn null heatmap across all 37 columns
- Dropped 4 columns with >22% missing (height, total_urine_output, complications, comorbidities)

**2. Feature Engineering**
- Composite GCS score: `gcs_eyes × gcs_verbal × gcs_motor`
- Baseline creatinine: `min(creatinine_48hrs, creatinine_7days)` per patient

**3. AKI Label Engineering (KDIGO Criteria)**
```python
AKI = (creatinine_48hrs - baseline_creatinine >= 0.3)   # 48-hour rule
    | (creatinine_7days >= 1.5 * baseline_creatinine)   # 7-day rule
```

**4. Imputation**
- KNN Imputer (k=5) on all numerical columns — preserves clinical relationships better than mean/median fill

**5. Class Imbalance**
- Applied SMOTE to training set: 145 → 430 AKI samples
- Final training set: 430 / 430 (balanced)

**6. Encoding**
- One-hot encoding for gender, ethnicity, dm_type → 54 total features

**7. Feature Selection**
- LASSO (L1 Logistic Regression) reduced 54 → 39 features
- Statsmodels Logit identified statistically significant features (p < 0.1):
  - `creatinine_48hrs`, `creatinine_7days`, `baseline_creatinine` (p < 0.001)
  - `age`, `heart_rate`, `temperature`, `wbc`

**8. Models Trained**

| Model | Accuracy | Precision (AKI) | Recall (AKI) | F1 (AKI) |
|-------|----------|-----------------|--------------|----------|
| Logistic Regression | 72.1% | 0.46 | 0.52 | 0.49 |
| **Random Forest** | **83.4%** | **0.66** | **0.73** | **0.69** |

Validation set: 247 patients (30% holdout, stratified)

Both models include ROC curves and calibration plots — see `/notebooks/AKI_Pipeline_Walkthrough.ipynb`.

---

## Repository Structure

```
aki-risk-prediction/
├── sql/
│   ├── 01_cohort_extraction.sql      # Diabetic ICU cohort, CKD exclusion
│   ├── 02_lab_features.sql           # Lab value time-window aggregation
│   ├── 03_demographics_vitals.sql    # Demographics + vitals join
│   └── 04_final_feature_table.sql    # Final feature table (BigQuery output)
├── src/
│   ├── bq_extract.py                 # Pull feature table from BigQuery
│   ├── preprocess.py                 # KNN impute, SMOTE, encode, scale
│   ├── train.py                      # Train RF + LR + KNN, LASSO selection
│   └── evaluate.py                   # AUC, F1, confusion matrix, calibration
├── notebooks/
│   └── AKI_Pipeline_Walkthrough.ipynb  # Full Part 2 walkthrough with outputs
├── data/processed/
│   └── feature_matrix_sample.csv    # 200-row anonymized sample (MIMIC-III)
├── requirements.txt
└── README.md
```

---

## Stack

- **Cloud**: Google BigQuery (GCP) — `physionet-data.mimiciii_clinical`
- **SQL**: Standard SQL with CTEs, window functions, multi-table JOINs
- **Python**: pandas, scikit-learn, imbalanced-learn, statsmodels, seaborn, matplotlib
- **ML**: Random Forest, Logistic Regression, KNN; SMOTE, LASSO, KNN Imputer

---

## How to Run

### Part 1 — BigQuery SQL
1. Enable `physionet-data.mimiciii_clinical` dataset in your GCP project
2. Run SQL files in order: `01 → 02 → 03 → 04`
3. Export `04_final_feature_table` as CSV → save to `data/processed/`

### Part 2 — Python ML
```bash
git clone https://github.com/VenkatAmit/aki-risk-prediction.git
cd aki-risk-prediction
pip install -r requirements.txt
python src/bq_extract.py      # or use your exported CSV directly
python src/preprocess.py
python src/train.py
python src/evaluate.py
```

---

## Key Findings

- **Creatinine delta is the dominant predictor** — 48-hour rise and 7-day ratio both significant at p < 0.001, which aligns with KDIGO clinical guidelines
- **Random Forest outperforms Logistic Regression** significantly on the AKI-positive class (F1: 0.69 vs 0.49), suggesting non-linear feature interactions
- **SMOTE was critical** — without balancing, models defaulted to predicting No-AKI (75% baseline accuracy with zero predictive value)
- **WBC and temperature** as significant predictors suggest systemic inflammation as a co-factor in AKI onset

---

## Data Source

MIMIC-III Clinical Database via Google BigQuery public datasets.  
PhysioNet: https://physionet.org/content/mimiciii/1.4/  
Access requires credentialed PhysioNet account + BigQuery project setup.
