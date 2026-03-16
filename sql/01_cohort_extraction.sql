-- =============================================================
-- FILE: 01_cohort_extraction.sql
-- PURPOSE: Build study cohort — DKA patients in ICU, exclude CKD Stage 5
-- SOURCE: physionet-data.mimiciii_clinical (BigQuery Public Dataset)
-- TABLES: diagnoses_icd, icustays
-- =============================================================

WITH dka_patients AS (

    -- Step 1: Identify patients with DKA using ICD-9 codes
    SELECT DISTINCT
        di.subject_id,
        di.hadm_id,
        di.icd9_code
    FROM `physionet-data.mimiciii_clinical.diagnoses_icd` di
    WHERE di.icd9_code IN ('25010', '25011', '25012', '25013')

),

ckd_stage_5_patients AS (

    -- Step 2: Identify patients with CKD Stage 5 (exclusion criteria)
    SELECT DISTINCT
        di.subject_id,
        di.hadm_id
    FROM `physionet-data.mimiciii_clinical.diagnoses_icd` di
    WHERE di.icd9_code IN ('5855', '5856')

),

first_icu_stay AS (

    -- Step 3: Find the first ICU stay per hospital admission
    -- ROW_NUMBER partitioned by hadm_id, ordered by ICU admit time
    SELECT
        icu.subject_id,
        icu.hadm_id,
        icu.icustay_id,
        icu.intime,
        icu.outtime,
        ROW_NUMBER() OVER (
            PARTITION BY icu.hadm_id
            ORDER BY icu.intime ASC
        ) AS rn
    FROM `physionet-data.mimiciii_clinical.icustays` icu

),

final_population AS (

    -- Step 4: Combine DKA patients with first ICU stay
    -- Exclude CKD Stage 5 patients via LEFT JOIN + IS NULL filter
    SELECT
        dka.subject_id,
        dka.hadm_id,
        icu.icustay_id,
        icu.intime,
        icu.outtime
    FROM dka_patients dka
    JOIN first_icu_stay icu
        ON dka.subject_id = icu.subject_id
        AND dka.hadm_id   = icu.hadm_id
    LEFT JOIN ckd_stage_5_patients ckd
        ON dka.subject_id = ckd.subject_id
        AND dka.hadm_id   = ckd.hadm_id
    WHERE icu.rn          = 1        -- First ICU stay only
      AND ckd.hadm_id     IS NULL    -- Exclude CKD Stage 5

)

SELECT *
FROM final_population
ORDER BY subject_id, intime;
