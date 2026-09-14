-- Teacher Turnover and Pupil-to-Qualified-Teacher Ratios in England
-- SQL analysis using Department for Education school-level datasets
-- Academic years: 2010/11 to 2024/25

-- 1. Data exploration and validation - Teacher turnover dataset

-- Explore dataset structure
SELECT *
FROM teacher_turnover.csv
LIMIT 10;

-- Count total records
SELECT COUNT(*) AS total_records
FROM teacher_turnover.csv;

-- Check time coverage
SELECT DISTINCT(time_period)
FROM teacher_turnover.csv
ORDER BY time_period DESC;

-- Check establishment types
SELECT DISTINCT(establishment_type_group)
FROM teacher_turnover.csv;

-- Check school coverage
SELECT COUNT(DISTINCT school_urn) AS total_schools
FROM teacher_turnover.csv;

-- Check for missing values
SELECT
SUM(
CASE WHEN time_period IS NULL THEN 1
ELSE 0
END) AS null_time_period,
SUM(
CASE WHEN establishment_type_group IS NULL THEN 1
ELSE 0
END) AS null_establishment_type_group,
SUM(
CASE WHEN school_urn IS NULL THEN 1
ELSE 0
END) AS null_school_urn,
SUM(
CASE WHEN left_the_state_funded_system IS NULL THEN 1
ELSE 0
END) AS null_left_the_state_funded_system,
SUM(
CASE WHEN teacher_fte_in_census_year IS NULL THEN 1
ELSE 0
END) AS null_teacher_fte_in_census_year,
SUM(
CASE WHEN remained_in_the_same_school IS NULL THEN 1
ELSE 0
END) AS null_teachers_remained,
SUM(
CASE WHEN left_to_another_state_funded_school IS NULL THEN 1
ELSE 0
END) AS null_left_to_other_school
FROM teacher_turnover.csv;

-- Check for special values
-- No special values were identified in the relevant teacher turnover fields.

-- Check for zero-FTE values
SELECT COUNT(teacher_fte_in_census_year) AS zero_fte_records
FROM teacher_turnover.csv
WHERE teacher_fte_in_census_year = 0;

-- Explore zero-FTE record
SELECT *
FROM teacher_turnover.csv
WHERE teacher_fte_in_census_year = 0;

-- Check for duplicates
-- No duplicate records identified in the dataset

-- 1. Data exploration and validation - Pupil to teacher ratios dataset

-- Explore dataset structure
SELECT *
FROM pupil_teacher_ratios_school_level_trimmed.csv
LIMIT 10;

-- Count total records
SELECT COUNT(*) AS total_records
FROM pupil_teacher_ratios_school_level_trimmed.csv;

-- Check time coverage
SELECT DISTINCT(time_period)
FROM pupil_teacher_ratios_school_level_trimmed.csv
ORDER BY time_period DESC;

-- Check establishment types
SELECT DISTINCT(establishment_type_group)
FROM pupil_teacher_ratios_school_level_trimmed.csv;

-- Check school coverage
SELECT COUNT(DISTINCT(school_urn)) AS total_unique_schools
FROM pupil_teacher_ratios_school_level_trimmed.csv;

-- Check for missing values
-- No null values identified in the dataset

-- Check for special values
SELECT pupil_to_qual_teacher_ratio, COUNT(*) AS records
FROM pupil_teacher_ratios_school_level_trimmed.csv
WHERE pupil_to_qual_teacher_ratio IN ('x', 'z', 'c', 'u')
GROUP BY pupil_to_qual_teacher_ratio;

-- Investigate records where the pupil-to-qualified-teacher ratio is unavailable ('x').
-- These records were checked against the two fields used to calculate PTR:
-- qualified_teachers_fte and pupils_fte.
SELECT
CASE WHEN qualified_teachers_fte = 'x' AND pupils_fte = 'x' THEN 'Both unavailable'
WHEN qualified_teachers_fte = 'x' THEN 'Qualified teacher fte unavailable'
WHEN pupils_fte = 'x' THEN 'Pupil fte unavailable'
END AS reason,
COUNT(*) AS records
FROM pupil_teacher_ratios_school_level_trimmed.csv
WHERE pupil_to_qual_teacher_ratio = 'x'
GROUP BY reason;

-- 'u' values indicate potentially unreliable PTR data.
-- These records were retained in the source data but excluded from the analysis.

-- Identifying minimum and maximum PTR values
SELECT 
	MIN(CAST(pupil_to_qual_teacher_ratio AS DOUBLE)) AS min_ptr,
    MAX(CAST(pupil_to_qual_teacher_ratio AS DOUBLE)) AS max_ptr
FROM pupil_teacher_ratios_school_level_trimmed.csv
WHERE pupil_to_qual_teacher_ratio <> 'x'
AND pupil_to_qual_teacher_ratio <> 'u';

-- Exploring minimum PTR value
SELECT 
	MIN(CAST(pupil_to_qual_teacher_ratio AS DOUBLE)) AS min_ptr,
    MAX(CAST(pupil_to_qual_teacher_ratio AS DOUBLE)) AS max_ptr
FROM pupil_teacher_ratios_school_level_trimmed.csv
WHERE pupil_to_qual_teacher_ratio <> 'x'
AND pupil_to_qual_teacher_ratio <> 'u';

-- Exploring maximum PTR value
SELECT *
FROM pupil_teacher_ratios_school_level_trimmed.csv
WHERE pupil_to_qual_teacher_ratio = '50';

-- Check for duplicate records
-- No duplicate records identified in the dataset

-- 3. Teacher turnover measure

-- Calculate teacher turnover as the percentage of total teacher FTE
-- that either left the state-funded system or moved to another
-- state-funded school. Records with teacher FTE = 0 are excluded
-- from the calculation, and results are rounded to two decimal places.
SELECT *, ROUND (
	((left_to_another_state_funded_school + left_the_state_funded_system) / teacher_fte_in_census_year) * 100, 2) AS total_turnover_percentage
FROM teacher_turnover.csv
WHERE teacher_fte_in_census_year > 0;

-- Calculate the average school-level turnover rate for each academic year
SELECT time_period, 
ROUND(
AVG (
	((left_to_another_state_funded_school + left_the_state_funded_system)
 / teacher_fte_in_census_year) * 100
), 
2
) AS avg_turnover_percentage
FROM teacher_turnover.csv
WHERE teacher_fte_in_census_year > 0
GROUP BY time_period
ORDER BY time_period;

-- Compare average school-level teacher turnover by establishment type
SELECT establishment_type_group, 
ROUND(
AVG(
((left_to_another_state_funded_school + left_the_state_funded_system)
/ teacher_fte_in_census_year) * 100
),
2
) AS avg_turnover_percentage
FROM teacher_turnover.csv
WHERE teacher_fte_in_census_year > 0
GROUP BY establishment_type_group;

-- Compare average turnover rates by establishment type for each academic year:
SELECT time_period, establishment_type_group, 
ROUND(
AVG(
((left_to_another_state_funded_school + left_the_state_funded_system)
/ teacher_fte_in_census_year) * 100
),
2
) AS avg_turnover_percentage
FROM teacher_turnover.csv
WHERE teacher_fte_in_census_year > 0
GROUP BY time_period, 
	establishment_type_group
ORDER BY time_period,
	establishment_type_group;

-- 4. Join and validation

-- Count matching records
SELECT COUNT(*) AS matching_records
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period;

-- Count unmatched records
SELECT COUNT(*) AS unmatched_records
FROM pupil_teacher_ratios_school_level_trimmed.csv AS ptr
LEFT JOIN teacher_turnover.csv AS tt
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.school_urn IS NULL;

-- Explore the distribution of unmatched PTR records across academic years
SELECT ptr.time_period, COUNT(*) AS unmatched_records
FROM pupil_teacher_ratios_school_level_trimmed.csv AS ptr
LEFT JOIN teacher_turnover.csv AS tt
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.school_urn IS NULL
GROUP BY ptr.time_period
ORDER BY ptr.time_period ASC;

-- Count the number of useable records in the analysis-ready dataset
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT COUNT(*) AS total_records
FROM joined_data;

-- 5. Analysis

-- Calculate the global 33rd and 67th percentiles of PTR to establish
-- initial relative thresholds for low, medium and high PTR groups
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT 
QUANTILE_CONT(ptr_value, 0.33) AS lower_threshold,
QUANTILE_CONT(ptr_value, 0.67) AS upper_threshold
FROM joined_data;

-- Assign records to low, medium and high PTR groups using the global
-- percentile thresholds, then calculate average turnover for each group
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT 
CASE 
WHEN ptr_value <= 17.9 THEN 'Low PTR'
WHEN ptr_value > 17.9 AND ptr_value <= 21.6 THEN 'Medium PTR'
ELSE 'High PTR'
END AS ptr_group,
ROUND(AVG(turnover_rate), 2) AS avg_turnover_rate
FROM joined_data
GROUP BY ptr_group;

-- Compare average turnover across the global PTR groups over time
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT 
CASE 
WHEN ptr_value <= 17.9 THEN 'Low PTR'
WHEN ptr_value > 17.9 AND ptr_value <= 21.6 THEN 'Medium PTR'
ELSE 'High PTR'
END AS ptr_group,
ROUND(AVG(turnover_rate), 2) AS avg_turnover_rate,
time_period
FROM joined_data
GROUP BY ptr_group, time_period
ORDER BY time_period, ptr_group;

-- Compare average turnover across global PTR groups within each
-- establishment type to assess whether the overall pattern is consistent
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT establishment_type,
CASE 
WHEN ptr_value <= 17.9 THEN 'Low PTR'
WHEN ptr_value > 17.9 AND ptr_value <= 21.6 THEN 'Medium PTR'
ELSE 'High PTR'
END AS ptr_group,
ROUND(AVG(turnover_rate), 2) AS avg_turnover_rate
FROM joined_data
GROUP BY establishment_type, ptr_group
ORDER BY establishment_type, ptr_group;

-- Examine the distribution of records across establishment groups
-- to assess whether one group disproportionately influences the overall results
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT
CASE
WHEN establishment_type = 'LA maintained nursery and primary' THEN 'Primary and nursery'
WHEN establishment_type = 'Primary academies' THEN 'Primary and nursery'
WHEN establishment_type = 'LA maintained secondary' THEN 'Secondary'
WHEN establishment_type = 'Secondary academies' THEN 'Secondary'
WHEN establishment_type = 'LA maintained special or PRU' THEN 'Special and PRU'
WHEN establishment_type = 'Special and PRU academies' THEN 'Special and PRU'
ELSE 'Other'
END AS broad_establishment_group,
COUNT(*) AS total_records
FROM joined_data
GROUP BY broad_establishment_group;

-- Count records by establishment group to identify differences
-- in their representation within the dataset.
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT
CASE
WHEN establishment_type = 'LA maintained nursery and primary' THEN 'Primary and nursery'
WHEN establishment_type = 'Primary academies' THEN 'Primary and nursery'
WHEN establishment_type = 'LA maintained secondary' THEN 'Secondary'
WHEN establishment_type = 'Secondary academies' THEN 'Secondary'
WHEN establishment_type = 'LA maintained special or PRU' THEN 'Special and PRU'
WHEN establishment_type = 'Special and PRU academies' THEN 'Special and PRU'
ELSE 'Other'
END AS broad_establishment_group,
CASE 
WHEN ptr_value <= 17.9 THEN 'Low PTR'
WHEN ptr_value > 17.9 AND ptr_value <= 21.6 THEN 'Medium PTR'
ELSE 'High PTR'
END AS ptr_group,
ROUND(AVG(turnover_rate), 2) AS avg_turnover_rate,
COUNT(*) AS total_records
FROM joined_data
GROUP BY broad_establishment_group, ptr_group
ORDER BY broad_establishment_group, ptr_group;

-- Calculate the 33rd and 67th percentiles of PTR within each broad
-- establishment group to establish relative low, medium and high PTR threshold
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u')
SELECT
CASE
WHEN establishment_type = 'LA maintained nursery and primary' THEN 'Primary and nursery'
WHEN establishment_type = 'Primary academies' THEN 'Primary and nursery'
WHEN establishment_type = 'LA maintained secondary' THEN 'Secondary'
WHEN establishment_type = 'Secondary academies' THEN 'Secondary'
WHEN establishment_type = 'LA maintained special or PRU' THEN 'Special and PRU'
WHEN establishment_type = 'Special and PRU academies' THEN 'Special and PRU'
ELSE 'Other'
END AS broad_establishment_group,
QUANTILE_CONT(ptr_value, 0.33) AS lower_threshold,
QUANTILE_CONT(ptr_value, 0.67) AS upper_threshold
FROM joined_data
GROUP BY broad_establishment_group;

-- Apply the establishment-group-specific PTR thresholds to classify records
-- and compare average turnover across relative low, medium and high PTR groups
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u'
),
broad_groups AS (
SELECT
CASE
WHEN establishment_type = 'LA maintained nursery and primary' THEN 'Primary and nursery'
WHEN establishment_type = 'Primary academies' THEN 'Primary and nursery'
WHEN establishment_type = 'LA maintained secondary' THEN 'Secondary'
WHEN establishment_type = 'Secondary academies' THEN 'Secondary'
WHEN establishment_type = 'LA maintained special or PRU' THEN 'Special and PRU'
WHEN establishment_type = 'Special and PRU academies' THEN 'Special and PRU'
ELSE 'Other'
END AS broad_establishment_group,
ptr_value,
turnover_rate
FROM joined_data
)
SELECT
broad_establishment_group,
CASE
WHEN broad_establishment_group = 'Primary and nursery'
     AND ptr_value <= 19.4 THEN 'Low PTR'
WHEN broad_establishment_group = 'Primary and nursery'
     AND ptr_value > 19.4
     AND ptr_value <= 22.3 THEN 'Medium PTR'
WHEN broad_establishment_group = 'Primary and nursery'
     AND ptr_value > 22.3 THEN 'High PTR'
WHEN broad_establishment_group = 'Secondary'
     AND ptr_value <= 15.6 THEN 'Low PTR'
WHEN broad_establishment_group = 'Secondary'
     AND ptr_value > 15.6
     AND ptr_value <= 17.4 THEN 'Medium PTR'
WHEN broad_establishment_group = 'Secondary'
     AND ptr_value > 17.4 THEN 'High PTR'
WHEN broad_establishment_group = 'Special and PRU'
     AND ptr_value <= 5.8 THEN 'Low PTR'
WHEN broad_establishment_group = 'Special and PRU'
     AND ptr_value > 5.8
     AND ptr_value <= 7.4 THEN 'Medium PTR'
WHEN broad_establishment_group = 'Special and PRU'
     AND ptr_value > 7.4 THEN 'High PTR'
END AS ptr_group,
ROUND(AVG(turnover_rate), 2) AS avg_turnover,
COUNT(*) AS total_records
FROM broad_groups
GROUP BY broad_establishment_group, ptr_group
ORDER BY broad_establishment_group, ptr_group;

-- Compare average turnover across relative PTR groups by establishment
-- group and academic year to examine how the relationship changes over time
WITH joined_data AS (
SELECT
tt.school_urn,
tt.time_period,
tt.establishment_type_group AS establishment_type,
ROUND(
(tt.left_the_state_funded_system + tt.left_to_another_state_funded_school)
/ tt.teacher_fte_in_census_year * 100, 
2
) AS turnover_rate,
CAST(ptr.pupil_to_qual_teacher_ratio AS DOUBLE) AS ptr_value
FROM teacher_turnover.csv AS tt
INNER JOIN pupil_teacher_ratios_school_level_trimmed.csv AS ptr
ON tt.school_urn = ptr.school_urn
AND tt.time_period = ptr.time_period
WHERE tt.teacher_fte_in_census_year > 0
AND ptr.pupil_to_qual_teacher_ratio <> 'x'
AND ptr.pupil_to_qual_teacher_ratio <> 'u'
),
broad_groups AS (
SELECT
CASE
WHEN establishment_type = 'LA maintained nursery and primary' THEN 'Primary and nursery'
WHEN establishment_type = 'Primary academies' THEN 'Primary and nursery'
WHEN establishment_type = 'LA maintained secondary' THEN 'Secondary'
WHEN establishment_type = 'Secondary academies' THEN 'Secondary'
WHEN establishment_type = 'LA maintained special or PRU' THEN 'Special and PRU'
WHEN establishment_type = 'Special and PRU academies' THEN 'Special and PRU'
ELSE 'Other'
END AS broad_establishment_group,
ptr_value,
turnover_rate,
time_period
FROM joined_data
)
SELECT
time_period,
broad_establishment_group,
CASE
WHEN broad_establishment_group = 'Primary and nursery'
     AND ptr_value <= 19.4 THEN 'Low PTR'
WHEN broad_establishment_group = 'Primary and nursery'
     AND ptr_value > 19.4
     AND ptr_value <= 22.3 THEN 'Medium PTR'
WHEN broad_establishment_group = 'Primary and nursery'
     AND ptr_value > 22.3 THEN 'High PTR'
WHEN broad_establishment_group = 'Secondary'
     AND ptr_value <= 15.6 THEN 'Low PTR'
WHEN broad_establishment_group = 'Secondary'
     AND ptr_value > 15.6
     AND ptr_value <= 17.4 THEN 'Medium PTR'
WHEN broad_establishment_group = 'Secondary'
     AND ptr_value > 17.4 THEN 'High PTR'
WHEN broad_establishment_group = 'Special and PRU'
     AND ptr_value <= 5.8 THEN 'Low PTR'
WHEN broad_establishment_group = 'Special and PRU'
     AND ptr_value > 5.8
     AND ptr_value <= 7.4 THEN 'Medium PTR'
WHEN broad_establishment_group = 'Special and PRU'
     AND ptr_value > 7.4 THEN 'High PTR'
END AS ptr_group,
ROUND(AVG(turnover_rate), 2) AS avg_turnover,
COUNT(*) AS total_records
FROM broad_groups
GROUP BY broad_establishment_group, time_period, ptr_group
ORDER BY broad_establishment_group, time_period, ptr_group;

-- 6. Preparation for visualisation

-- Create separate datasets for each broad establishment group and
-- reformat time_period as academic year for clearer visualisation labels

-- Primary and nursery
SELECT *, 
CONCAT(
LEFT(
CAST(time_period AS VARCHAR), 4),
'/',
RIGHT(
CAST (time_period AS VARCHAR), 2)
) AS academic_year 
FROM df37
WHERE broad_establishment_group = 'Primary and nursery'
ORDER BY time_period, ptr_group;

-- Secondary
SELECT *, 
CONCAT(
LEFT(
CAST(time_period AS VARCHAR), 4),
'/',
RIGHT(
CAST (time_period AS VARCHAR), 2)
) AS academic_year 
FROM df37
WHERE broad_establishment_group = 'Secondary'
ORDER BY time_period, ptr_group;

-- Special and PRU
SELECT *, 
CONCAT(
LEFT(
CAST(time_period AS VARCHAR), 4),
'/',
RIGHT(
CAST (time_period AS VARCHAR), 2)
) AS academic_year 
FROM df37
WHERE broad_establishment_group = 'Special and PRU'
ORDER BY time_period, ptr_group;
