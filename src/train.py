"""
train.py
Trains Random Forest, Logistic Regression, and KNN classifiers.
Uses LASSO feature selection before all models.
Saves best model (Random Forest) to models/best_model_rf.pkl.

Results from original notebook:
  Random Forest      : Accuracy 83.4%, AUC 0.88, F1 0.69
  Logistic Regression: Accuracy 72.1%, AUC 0.74
"""
import os
import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression, LassoCV
from sklearn.neighbors import KNeighborsClassifier
from sklearn.feature_selection import SelectFromModel
from src.preprocess import preprocess


def select_features_lasso(X_train, y_train):
    lasso = LassoCV(cv=5, random_state=42, max_iter=5000)
    lasso.fit(X_train, y_train)
    selector = SelectFromModel(lasso, prefit=True)
    X_selected = selector.transform(X_train)
    selected_cols = X_train.columns[selector.get_support()].tolist()
    print(f"LASSO selected {len(selected_cols)} of {X_train.shape[1]} features")
    print(f"Selected: {selected_cols}")
    return X_selected, selected_cols, selector


def train_models(data_path: str = "data/processed/feature_matrix.csv"):
    df = pd.read_csv(data_path)
    X_train, X_test, y_train, y_test = preprocess(df)

    X_train_lasso, selected_cols, selector = select_features_lasso(X_train, y_train)
    X_test_lasso = selector.transform(X_test)

    models = {
        "Random Forest": RandomForestClassifier(
            n_estimators=100, random_state=42, class_weight="balanced"
        ),
        "Logistic Regression": LogisticRegression(
            max_iter=1000, random_state=42, class_weight="balanced"
        ),
        "KNN": KNeighborsClassifier(n_neighbors=5)
    }

    trained = {}
    for name, model in models.items():
        print(f"\nTraining: {name} ...")
        model.fit(X_train_lasso, y_train)
        trained[name] = model
        print(f"Done: {name}")

    os.makedirs("models", exist_ok=True)
    joblib.dump(trained["Random Forest"], "models/best_model_rf.pkl")
    print("\nBest model saved → models/best_model_rf.pkl")

    return trained, X_test_lasso, y_test, selected_cols


if __name__ == "__main__":
    train_models()
