---Diabetes Cohort Capstone
---Name= Hanaa Zbakh

---------------------Part A1 - First queries-------------------------

---Q1.1
select * from patients limit 10; 

---Q1.2
select patient_id, age, sex, glucose_mg_dl
from patients
where age > 80
order by age desc; 
--Answer: The first patient has an age of 278, which is impossible. 
--This indicates the presence of an error in the age column.

--Q1.3
select *
from care_centres
where region like 'Wallonie%'
order by centre_name;

 --Q1.4
select distinct blood_group
from patients;

--Q1.5
select patient_id, age, glucose_mg_dl
from patients
where glucose_mg_dl >= 126
order by glucose_mg_dl desc;
--Answer: 50 rows

--Q1.6
select * from treatments where patient_id = 'P335' order by start_date;

--Q1.7
select measure_date, glucose_mg_dl, weight_kg, hba1c_pct
from glucose_history
where patient_id ='P365'
order by measure_date;
---Answer: the patient's history starts on 05/04/2020

 --Q1.8
select * from patients where sex is null;

---------------------Part A2 - Counting and grouping-------------------------

--Q2.1
select count(*) from patients;
select count(*) from glucose_history;
select count(*) from consultations;

--Q2.2
select MIN(age), MAX(age), round(AVG(age):: numeric, 2), round(AVG(glucose_mg_dl):: numeric, 1)
from patients;

--Q2.3
select sex, count(*) from patients group by sex;
---Answer: there are 12 diffrent raw values for sex. Women 929, men 566, 5 unknown patients.

--Q2.4
select corticosteroids, count(*) from patients group by corticosteroids;
---Answer: there are 6 diffrent raw values. NA, Na, na, and NULL should be there.

--Q2.5
select activity_level, count(*) from lifestyle group by activity_level;
---Answer: there are 4 diffrent raw values. faible is inconsistent with Faible because of capitalization.
---They should represent the same activity level.

--Q2.6
select substr(measure_date::text, 1, 4) as year, count(*) as measurements, count(distinct patient_id) as patients 
from glucose_history
group by substr(measure_date::text, 1, 4)
order by "year";
---Answer: from 2020 to 2023, each year has exactly 92 measurments, from 46 patients.
--- this is unusual compared with the large numbers from 2024.

--Q2.7
select drug_class, count(*) as rows, count(distinct patient_id) as patients
from treatments
group by drug_class 
order by count(*) desc; 
---Answer: Antidiabetique is the most frequent drug class,
--- with 1375 rows and 1345 distinct patients.
----some patients have more the one antidiabetique treatment row.

--Q2.8
select patient_id, consult_date, consult_type, provider, reason, count(*)
from consultations
group by patient_id, consult_date, consult_type, provider, reason
having count(*) > 1;

select patient_id, relative, condition, count(*)
from family_history
group by patient_id, relative, condition
having count(*) > 1;
---Answer: there is 1 duplicated row in consultations
---and 10 duplicated row in family_history

--Q2.9
select patient_id, measure_date, count(*)
from glucose_history
group by patient_id, measure_date
having count(*) > 1;
---Answer: 2 patients have 2 measurments on the same date: P712, P799

--Q2.10
select glucose_mg_dl, count(*)
from glucose_history
group by glucose_mg_dl
order by count(*) desc
limit 5;
--Answer: 58 mg/dl is the most frequent value, appearring 114 times.
--the value itself is possible but its very high frequency is suspicions

-------------------------Part A3 — Cleaning the data -------------------------

--Q3.1
select * from patients WHERE LOWER(sex) IN ('f', 'femme');
update patients 
set sex = 'F' WHERE LOWER(sex) IN ('f', 'femme');

SELECT * FROM patients WHERE LOWER(sex) IN ('m', 'h', 'homme');

UPDATE patients SET sex = 'M' WHERE LOWER(sex) IN ('m', 'h', 'homme');

SELECT * FROM patients WHERE sex IS NULL OR sex NOT IN ('F', 'M');
UPDATE patients SET sex = 'Unknown' WHERE sex IS NULL OR sex NOT IN ('F', 'M');

SELECT sex, COUNT(*) FROM patients GROUP BY sex;
--Answer: After cleaning, there are 929 F, 566 M, and 5 Unknown patients.

--Q3.2
SELECT patient_id, corticosteroids FROM patients
WHERE LOWER(corticosteroids) = 'na' OR corticosteroids IS NULL;

SELECT * FROM treatments WHERE drug_class = 'Corticoïdes' AND patient_id IN ( SELECT patient_id 
FROM patients WHERE LOWER(corticosteroids) = 'na' OR corticosteroids IS null );

UPDATE patients
SET corticosteroids = 'Non'
WHERE LOWER(corticosteroids) = 'na' OR corticosteroids IS NULL;

SELECT corticosteroids, COUNT(*) FROM patients GROUP BY corticosteroids;
-- Answer: The check returned 0 corticosteroid treatment rows. 
--After cleaning, there are 128 Oui and 1,372 Non.

--Q3.3
SELECT * FROM patients WHERE age > 110;
UPDATE patients SET age = null WHERE age > 110;
SELECT MIN(age), MAX(age), ROUND(AVG(age)::numeric, 2) FROM patients;
-- Answer: After cleaning, the min age is 18, the max is 85, and the avg is 50.75 years.
-- The average decreased by 0.15 years, from 50.90 to 50.75.

--Q3.4
SELECT * FROM lifestyle WHERE activity_level = 'faible';
UPDATE lifestyle SET activity_level = 'Faible' WHERE activity_level = 'faible';
SELECT activity_level, COUNT(*) FROM lifestyle GROUP BY activity_level;
--Answer: After cleaning, there are 313 Faible, 456 Modérée and 731 Élevée. 
-- faible was corrected by Faible

--Q3.5
CREATE TABLE consultations_clean as SELECT DISTINCT * FROM consultations;
CREATE TABLE family_history_clean as SELECT DISTINCT * FROM family_history;

SELECT COUNT(*) FROM consultations_clean;
SELECT COUNT(*) FROM family_history_clean;
-- Answer:
--One duplicate was removed from consultations and 10 duplicates were removed from family_history.
--So, consultations_clean contains 3,608 rows and family_history_clean contains 1,652 rows.


-------------------------Part A4 — Analysis on clean data -------------------------
--Q4.1
SELECT sex,
       COUNT(*),
       ROUND(100.0 * COUNT(*) / 1500, 1),
       AVG (age)
FROM patients
GROUP BY sex;

--Q4.2
select CASE
        WHEN glucose_mg_dl < 100 THEN 'Normal'
        WHEN glucose_mg_dl < 126 THEN 'Impaired'
        ELSE 'Diabetes range'
    END AS glucose_category,
    COUNT(*) AS n_patients
FROM patients
GROUP BY glucose_category;
--Answer: Most patients are in the Normal glucose category (1,104),
--followed by Impaired (346), while 50 patients are in the Diabetes range.

--Q4.3

SELECT SUBSTR(consult_date::text, 1, 4) AS year,
       COUNT(*) as consultations,
       COUNT(DISTINCT patient_id) as patients
FROM consultations_clean
GROUP BY SUBSTR(consult_date::text, 1, 4)
order by "year";
--Answer: Consultations increased by about 16.6% from 2024 to 2025.

--Q4.4
SELECT consult_type,
       COUNT(*) AS consultations
FROM consultations_clean
GROUP BY consult_type
ORDER BY COUNT(*) DESC;

--Q4.5

SELECT COUNT(*) AS measurements,
       COUNT(DISTINCT patient_id) AS patients
FROM glucose_history
WHERE glucose_mg_dl >= 126;
--Answer: 450 measurements show a glucose of 126 mg/dL or more,mconcerning 82 different patients.

--Q4.6
SELECT SUBSTR(measure_date::text, 1, 4) AS year,
       COUNT(*) AS measurements,
       ROUND(AVG(hba1c_pct)::numeric, 2) AS avg_hba1c
FROM glucose_history
GROUP BY year
ORDER BY year;
-- Answer: The average HbA1c remains quite stable over time,
-- ranging from 7.05% to 7.10%.

--Q1.7
SELECT COUNT(*) AS ongoing_treatments
FROM treatments
WHERE end_date IS NULL
  AND drug_class <> 'Aucun traitement';

-- Answer: There are 1,194 ongoing treatments, excluding the rows 'Aucun traitement'.

-------------------------Part A5 — Combining tables -------------------------

--Q5.1
SELECT l.stress_level,
       COUNT(*) AS n_patients,
       ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
JOIN lifestyle l
  ON l.patient_id = p.patient_id
GROUP BY l.stress_level;
--Answer: Average glucose increases with stress level

--Q5.2
--Q5.2
SELECT l.activity_level,
       COUNT(*) AS n_patients,
       ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
JOIN lifestyle l
  ON l.patient_id = p.patient_id
GROUP BY l.activity_level;

SELECT l.smoker,
       COUNT(*) AS n_patients,
       ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
JOIN lifestyle l
  ON l.patient_id = p.patient_id
GROUP BY l.smoker;
--Answer: Activity level seems linked to glucose: average glucose decreases as activity level increases.
-- Smoking does not show a clear link, since the average glucose

--Q5.3
SELECT c.region,
       COUNT(*) AS n_patients
FROM patient_centre pc
JOIN care_centres c
  ON pc.centre_id = c.centre_id
GROUP BY c.region;

--Q5.4
SELECT c.centre_type, COUNT(*) AS n_patients, ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
JOIN patient_centre pc
    ON p.patient_id = pc.patient_id
JOIN care_centres c
    ON pc.centre_id = c.centre_id GROUP BY c.centre_type;

--Q5.5
SELECT
    COUNT(*) AS n_patients,
    ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
WHERE p.patient_id IN (
    SELECT patient_id
    FROM family_history_clean
    WHERE condition = 'Diabète de type 2' );
SELECT
    COUNT(*) AS n_patients,
    ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
WHERE p.patient_id NOT IN (
    SELECT patient_id
    FROM family_history_clean
    WHERE condition = 'Diabète de type 2' );

--Q5.6
SELECT
    t.drug_name,
    COUNT(DISTINCT p.patient_id) AS n_patients,
    ROUND(AVG(p.glucose_mg_dl)::numeric, 1) AS avg_glucose
FROM patients p
JOIN treatments t
    ON p.patient_id = t.patient_id
WHERE t.drug_class = 'Antidiabétiques'
GROUP BY t.drug_name
ORDER BY n_patients DESC;

--Answer: The three rare drugs have a high average glucose because they are used by very few patients. 

--Q.5.7
SELECT COUNT(DISTINCT patient_id)
FROM treatments
WHERE drug_class = 'Antidépresseurs';

SELECT
    l.stress_level,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM treatments t
            WHERE t.patient_id = l.patient_id
              AND t.drug_class = 'Antidépresseurs'
        )
        THEN 'Avec antidépresseur'
        ELSE 'Sans antidépresseur'
    END AS groupe,
    COUNT(DISTINCT l.patient_id) AS n_patients
FROM lifestyle l
GROUP BY l.stress_level, groupe
ORDER BY groupe, l.stress_level;

--Answer: Surprisingly, the proportion of patients with high stress was slightly lower among antidepressant 
--users (23.3%) than among non-users (27.0%). This suggests that antidepressant treatment
--is not strongly associated with higher recorded stress levels in this dataset.
--However, antidepressants may be prescribed for  conditions other than stress, 
--and the dataset does not provide enough information to  establish a causal relationship.

--Q5.8
SELECT MAX(measure_date) AS last_measurement_date
FROM glucose_history;

SELECT
    patient_id,
    drug_name,
    start_date
FROM treatments
WHERE start_date > (
    SELECT MAX(measure_date)
    FROM glucose_history
)
ORDER BY start_date;

--Answer: The last glucose measurement was on 2026-06-28. 
--Six treatments started after this date. This is possible, 
--but it indicates a difference in time coverage between the
--tables and should be reported as a data-quality issue.