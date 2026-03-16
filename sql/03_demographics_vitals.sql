-- =============================================================
-- FILE: 03_demographics_vitals.sql
-- PURPOSE: Extract patient demographics and first-recorded vitals
-- SOURCE: physionet-data.mimiciii_clinical
-- TABLES: patients, admissions, icustays, chartevents
-- DEPENDS ON: 01_cohort_extraction.sql (final_population)
-- =============================================================

WITH cohort AS (

    SELECT subject_id, hadm_id, icustay_id, intime
    FROM `physionet-data.mimiciii_clinical.icustays`
    -- In production: FROM `your-project.aki_dataset.final_population`

),

demographics AS (

    -- Patient demographics joined with admission info
    SELECT
        p.subject_id,
        a.hadm_id,
        p.gender,
        DATE_DIFF(
            CAST(a.admittime AS DATE),
            CAST(p.dob AS DATE),
            YEAR
        )                                   AS age,
        a.ethnicity,
        a.admission_type,
        a.insurance,
        a.hospital_expire_flag              AS in_hospital_death
    FROM `physionet-data.mimiciii_clinical.patients` p
    JOIN `physionet-data.mimiciii_clinical.admissions` a
        ON p.subject_id = a.subject_id
    JOIN cohort c
        ON a.subject_id = c.subject_id
        AND a.hadm_id   = c.hadm_id

),

first_weight AS (

    -- First recorded weight from chartevents for each ICU stay
    -- itemids 762, 763, 3723, 3580 = weight in MIMIC-III
    SELECT DISTINCT
        icustay_id,
        FIRST_VALUE(valuenum) OVER (
            PARTITION BY icustay_id
            ORDER BY charttime ASC
        )                                   AS weight_kg
    FROM `physionet-data.mimiciii_clinical.chartevents`
    WHERE itemid    IN (762, 763, 3723, 3580)
      AND valuenum  IS NOT NULL
      AND valuenum  BETWEEN 20 AND 400      -- Physiologically plausible range
      AND error     IS DISTINCT FROM 1

),

first_gcs AS (

    -- First GCS total score (Glasgow Coma Scale)
    -- itemid 198 = GCS Total in MIMIC-III chartevents
    SELECT DISTINCT
        icustay_id,
        FIRST_VALUE(valuenum) OVER (
            PARTITION BY icustay_id
            ORDER BY charttime ASC
        )                                   AS gcs_first
    FROM `physionet-data.mimiciii_clinical.chartevents`
    WHERE itemid    = 198
      AND valuenum  IS NOT NULL
      AND error     IS DISTINCT FROM 1

)

SELECT
    d.subject_id,
    d.hadm_id,
    c.icustay_id,
    d.gender,
    d.age,
    d.ethnicity,
    d.admission_type,
    d.insurance,
    d.in_hospital_death,
    w.weight_kg,
    g.gcs_first
FROM demographics d
JOIN cohort c
    ON d.subject_id = c.subject_id
    AND d.hadm_id   = c.hadm_id
LEFT JOIN first_weight w
    ON c.icustay_id = w.icustay_id
LEFT JOIN first_gcs g
    ON c.icustay_id = g.icustay_id
WHERE d.age BETWEEN 18 AND 90    -- Exclude pediatric and extreme outliers
ORDER BY d.subject_id;
