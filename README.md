# teacher-turnover-ptr-analysis
SQL analysis exploring the relationship between pupil-to-qualified-teacher ratios and teacher turnover in schools in England.

This analysis investigates the relationship between pupil-to-qualified-teacher ratios and teacher turnover in schools in England over time, specifically examining the academic years 2010/11–2024/25. It uses publicly available datasets from the Department for Education (DfE) to investigate whether there is an association between the two measures. SQL was used to explore, clean, join and analyse the datasets.

## Data sources

Both datasets are publicly available from the Department for Education (DfE), as part of the *School workforce in England* publication:

- **Teacher turnover – school level** (https://explore-education-statistics.service.gov.uk/data-catalogue/data-set/a92cdbbb-5596-4b1c-a169-b350461c5294?)
- **Pupil to teacher ratios – school level** (https://explore-education-statistics.service.gov.uk/data-catalogue/data-set/d5f1867a-ca93-454d-9361-6c64df108872?)

## Methodology

Before beginning the analysis, an exploration of each dataset was conducted to determine its contents, breadth and scope. The data was cleaned by identifying any missing values or special codes used by the DfE to communicate the characteristics of the data, and checks were performed to ensure no duplication was present. Where values were identified that could not be used reliable, they were excluded from calculations but retained in the dataset.

Next, teacher turnover was defined and calculated as the full-time-equivalent (FTE) of teachers who left the state-funded system or remained in the system but moved to another school, divided by the total number of FTE teachers at school level and expressed as a percentage.

A join was performed with the second dataset to introduce pupil-to-qualified-teacher-ratios (PTR). Prior to this, the second dataset was reduced to the relevant columns and academic years, while retaining all records in the selected period. Three broad categories of establishment type were created rather than using more granular school-type categories, and relative PTR thresholds were calculated to reflect the distribution of the data within each category using the 33rd and 67th percentiles.

Finally, average turnover percentages across the establishment types were compared, which allowed differences between low, medium and high PTR to be examined over the 15 year period.
