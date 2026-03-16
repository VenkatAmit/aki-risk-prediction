"""
preprocess.py
Handles missing values, encoding, SMOTE, and train/test split.
Mirrors preprocessing from AKI.ipynb:
  - KNN imputation (k=5)
  - One-hot encoding for categoricals
  - SMOTE for class imbalance (training set only)
  - Stratified 80/20 split
"""
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.impute import KNNImputer
from imblearn.over_sampling import SMOTE


def preprocess(df: pd.DataFrame, target_col: str = "aki_flag"):
    drop_cols = ["subject_id", "hadm_id", "icustay_id", "in_hospital_death"]
    df = df.drop(columns=[c for c in drop_cols if c in df.columns])

    cat_cols = ["gender", "ethnicity", "admission_type", "insurance"]
    df = pd.get_dummies(
        df,
        columns=[c for c in cat_cols if c in df.columns],
        drop_first=True
    )

    X = df.drop(columns=[target_col])
    y = df[target_col]

    imputer = KNNImputer(n_neighbors=5)
    X_imputed = pd.DataFrame(imputer.fit_transform(X), columns=X.columns)

    scaler = StandardScaler()
    X_scaled = pd.DataFrame(scaler.fit_transform(X_imputed), columns=X.columns)

    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42, stratify=y
    )

    sm = SMOTE(random_state=42)
    X_train_res, y_train_res = sm.fit_resample(X_train, y_train)

    print(f"Train size after SMOTE : {X_train_res.shape}")
    print(f"Test size              : {X_test.shape}")
    print(f"Class balance          : {pd.Series(y_train_res).value_counts().to_dict()}")
    return X_train_res, X_test, y_train_res, y_test
