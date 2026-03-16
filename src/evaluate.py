"""
evaluate.py
Evaluates all 3 models: accuracy, precision, recall, F1, AUC-ROC.
Saves confusion matrix and ROC curve plots to docs/.
"""
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    classification_report, roc_auc_score,
    confusion_matrix, roc_curve
)
from src.train import train_models


def evaluate_all(data_path: str = "data/processed/feature_matrix.csv"):
    trained, X_test, y_test, _ = train_models(data_path)
    os.makedirs("docs", exist_ok=True)
    results = {}

    fig, axes = plt.subplots(1, len(trained), figsize=(15, 4))
    fig.suptitle("Confusion Matrices — AKI Risk Prediction", fontsize=14)

    for i, (name, model) in enumerate(trained.items()):
        y_pred = model.predict(X_test)
        y_prob = model.predict_proba(X_test)[:, 1]
        auc    = roc_auc_score(y_test, y_prob)
        cm     = confusion_matrix(y_test, y_pred)
        results[name] = {"auc": round(auc, 4)}

        print(f"\n{'='*55}")
        print(f"  {name}  |  AUC-ROC: {auc:.4f}")
        print(classification_report(y_test, y_pred,
                                    target_names=["No AKI", "AKI"]))

        sns.heatmap(cm, annot=True, fmt="d", ax=axes[i], cmap="Blues",
                    xticklabels=["No AKI", "AKI"],
                    yticklabels=["No AKI", "AKI"])
        axes[i].set_title(f"{name}\nAUC: {auc:.3f}")
        axes[i].set_ylabel("Actual")
        axes[i].set_xlabel("Predicted")

    plt.tight_layout()
    plt.savefig("docs/confusion_matrices.png", dpi=150, bbox_inches="tight")
    print("\nSaved → docs/confusion_matrices.png")

    plt.figure(figsize=(8, 6))
    for name, model in trained.items():
        y_prob = model.predict_proba(X_test)[:, 1]
        fpr, tpr, _ = roc_curve(y_test, y_prob)
        auc = roc_auc_score(y_test, y_prob)
        plt.plot(fpr, tpr, label=f"{name} (AUC = {auc:.3f})")

    plt.plot([0, 1], [0, 1], "k--", label="Random Baseline")
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC Curve Comparison — AKI Risk Prediction")
    plt.legend(loc="lower right")
    plt.tight_layout()
    plt.savefig("docs/roc_curves.png", dpi=150, bbox_inches="tight")
    print("Saved → docs/roc_curves.png")

    print(f"\n{'='*55}")
    print("  MODEL SUMMARY")
    print(pd.DataFrame(results).T.to_string())
    return results


if __name__ == "__main__":
    evaluate_all()
