-- =============================================================
-- FILE: 02_lab_features.sql
-- PURPOSE: Extract creatinine lab values and compute AKI label
--          using KDIGO criteria (0.3 mg/dL rise OR 1.5x baseline)
-- SOURCE: physionet-data.mimiciii_clinical
-- TABLES: labevents, admissions
-- DEPENDS ON: 01_cohort_extraction.sql (final_population)
-- =============================================================

WITH cohort AS (

    -- Reference cohort built in 01_cohort_extraction.sql
    -- Replace with your project dataset if saving as BQ table
    SELECT subject_id, hadm_id, icustay_id, intime
    FROM `physionet-data.mimiciii_clinical.icustays`  -- placeholder
    -- In production: FROM `your-project.aki_dataset.final_population`

),

creatinine_raw AS (

    -- Pull all creatinine measurements for cohort patients
    -- itemid 50912 = Creatinine (Blood) in MIMIC-III labevents
    SELECT
        l.subject_id,
        l.hadm_id,
        l.charttime,
        l.valuenum                                              AS creatinine_value,
        TIMESTAMP_DIFF(l.charttime, c.intime, HOUR)            AS hours_from_icu_admit
    FROM `physionet-data.mimiciii_clinical.labevents` l
    JOIN cohort c
        ON l.subject_id = c.subject_id
        AND l.hadm_id   = c.hadm_id
    WHERE l.itemid      = 50912          -- Creatinine, Blood
      AND l.valuenum    IS NOT NULL
      AND l.valuenum    > 0
      AND l.valuenum    < 30             -- Remove physiologically impossible values

),

baseline_creatinine AS (

    -- Baseline = minimum creatinine in the window -6h to +48h of ICU admit
    -- Using minimum per KDIGO guideline definition
    SELECT
        subject_id,
        hadm_id,
        MIN(creatinine_value)   AS creatinine_baseline
    FROM creatinine_raw
    WHERE hours_from_icu_admit BETWEEN -6 AND 48
    GROUP BY subject_id, hadm_id

),

creatinine_7day AS (

    -- Max creatinine within 7 days (168 hours) of ICU admit
    SELECT
        subject_id,
        hadm_id,
        MAX(creatinine_value)   AS creatinine_max_7d
    FROM creatinine_raw
    WHERE hours_from_icu_admit BETWEEN 0 AND 168
    GROUP BY subject_id, hadm_id

),

aki_labeled AS (

    -- Apply KDIGO AKI criteria:
    --   Stage 1+: absolute rise >= 0.3 mg/dL within 48h OR
    --             relative rise >= 1.5x baseline within 7 days
    SELECT
        b.subject_id,
        b.hadm_id,
        b.creatinine_baseline,
        m.creatinine_max_7d,
        ROUND(m.creatinine_max_7d - b.creatinine_baseline, 4)  AS creatinine_rise,
        ROUND(m.creatinine_max_7d / NULLIF(b.creatinine_baseline, 0), 4)
                                                                AS creatinine_ratio,
        CASE
            WHEN (m.creatinine_max_7d - b.creatinine_baseline) >= 0.3  THEN 1
            WHEN (m.creatinine_max_7d / NULLIF(b.creatinine_baseline, 0)) >= 1.5 THEN 1
            ELSE 0
        END                                                     AS aki_flag
    FROM baseline_creatinine b
    JOIN creatinine_7day m
        ON b.subject_id = m.subject_id
        AND b.hadm_id   = m.hadm_id

)

SELECT *
FROM aki_labeled
ORDER BY subject_id;
