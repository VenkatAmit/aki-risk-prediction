-- =============================================================
-- FILE: 04_final_feature_table.sql
-- PURPOSE: Join all features into final model-ready table
--          This is the table fed into the Python ML pipeline
-- DEPENDS ON: 02_lab_features.sql, 03_demographics_vitals.sql
-- OUTPUT: final_features — one row per patient, AKI label as target
-- =============================================================

-- Run in BigQuery to persist as a table:
-- CREATE OR REPLACE TABLE `your-project.aki_dataset.final_features` AS

SELECT

    -- Identifiers
    demo.subject_id,
    demo.hadm_id,
    demo.icustay_id,

    -- Demographics (features)
    demo.gender,
    demo.age,
    demo.ethnicity,
    demo.admission_type,
    demo.insurance,
    demo.weight_kg,
    demo.gcs_first,

    -- Lab features
    labs.creatinine_baseline,
    labs.creatinine_max_7d,
    labs.creatinine_rise,
    labs.creatinine_ratio,

    -- Outcome / mortality
    demo.in_hospital_death,

    -- TARGET VARIABLE
    labs.aki_flag

FROM (
    -- Demographics + vitals subquery (from 03_demographics_vitals.sql)
    SELECT *
    FROM `your-project.aki_dataset.demographics_vitals`
) demo

JOIN (
    -- Lab features subquery (from 02_lab_features.sql)
    SELECT *
    FROM `your-project.aki_dataset.lab_features`
) labs
    ON demo.subject_id  = labs.subject_id
    AND demo.hadm_id    = labs.hadm_id

WHERE
    labs.creatinine_baseline IS NOT NULL   -- Must have baseline creatinine
    AND demo.age BETWEEN 18 AND 90         -- Adult patients only

ORDER BY demo.subject_id;

-- =============================================================
-- SUMMARY STATS (run separately to validate output)
-- =============================================================
-- SELECT
--     COUNT(*)                            AS total_patients,
--     SUM(aki_flag)                       AS aki_positive,
--     ROUND(AVG(aki_flag) * 100, 1)       AS aki_rate_pct,
--     ROUND(AVG(age), 1)                  AS avg_age,
--     ROUND(AVG(creatinine_baseline), 2)  AS avg_baseline_creatinine
-- FROM `your-project.aki_dataset.final_features`;
