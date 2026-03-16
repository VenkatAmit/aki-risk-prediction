"""
bq_extract.py
Connects to BigQuery and extracts the AKI feature matrix.
Usage: python src/bq_extract.py
Requires: GCP_PROJECT_ID env var + google-cloud-bigquery installed
"""
import os
import pandas as pd
from google.cloud import bigquery


def extract_feature_matrix(project_id: str, output_path: str) -> pd.DataFrame:
    client = bigquery.Client(project=project_id)
    query = """
        SELECT *
        FROM `your-project.aki_dataset.final_features`
        ORDER BY subject_id
    """
    print(f"Connecting to BigQuery project: {project_id}")
    df = client.query(query).to_dataframe()
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    df.to_csv(output_path, index=False)
    print(f"Extracted {len(df):,} records to: {output_path}")
    print(f"AKI positive rate: {df['aki_flag'].mean():.1%}")
    return df


if __name__ == "__main__":
    extract_feature_matrix(
        project_id=os.getenv("GCP_PROJECT_ID", "your-project-id"),
        output_path="data/processed/feature_matrix.csv"
    )
