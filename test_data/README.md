## Sample Anonymised Patient Data - Column Definitions

| Column Name        | Description |
|-------------------|-------------|
| Patient Name      | Made-up patient names used for anonymisation. Names are consistent within the dataset but do not represent real individuals. |
| Patient ID        | Short numeric code used as a unique identifier for a patient. Does not resemble original IDs. |
| Phone Number      | Patient’s contact number. Optional field. |
| Date of Birth     | Patient’s date of birth. |
| Gender            | Gender of the patient. |
| Registration Date | Date when the patient was enrolled into the system. If not available, the system uses Visit Time as the registration date. |
| Visit Time        | Date when the patient visited the facility. Mandatory field. Records are skipped if this is missing. |
| Systolic          | Systolic blood pressure reading. If missing along with diastolic, BP record is skipped. |
| Diastolic         | Diastolic blood pressure reading. If missing along with systolic, BP record is skipped. |
| Blood Sugar Type  | Type of blood sugar reading (random / fasting / hba1c). Defaults to "random" if not provided. |
| Blood Sugar Value | Actual blood sugar measurement value. |
| Region            | Top-level hierarchy. Defaults to "Demo Region" if not provided. |
| District          | Second-level hierarchy under Region. |
| Facility          | Third-level hierarchy under District. Defaults to "UNKNOWN" if not provided. |
| Sub Facility      | Lowest-level hierarchy under Facility. |