# Sample anonymised patient data

This folder contains sample anonymised patient data for testing purposes only. No real patient information is present.

Numbers like Patient IDs and names that look realistic are not real:

- **Patient names** are replaced with made-up names that are consistent within the same dataset
- **Patient ID** are replaced with short numeric codes that don't resemble the originals. These are the unique identifier for a patient.
- **Phone number** reperesent phone number of the patient, not a mandatory field.
- **Date of Birth** date of birth of the patient.
- **Gender** gender of the patient
- **Registration Date** represents the date when the patient was enrolled into the system. For cases where this date is not present, the system will use Last Visit Time as the registration date.
- **Last Visit Time** represents the date when patient last visited the facility. This is a mandatory field and system skips inserting the data for patients where we don't have this field.
- **Systolic** systolic blood pressure reading for a patient.
- **Diastolic** diastolic blood pressure reading for a patient. If either systolic or diastolic reading is not found, the bp record will be skipped.
- **Blood Sugar Type** type of the blood sugar reading - random/fasting/hba1c. If no value is found for this, system assumes a random reading.
- **Blood Sugar Value** represents the actual blood sugar reading
- **Region** Top most hierarchy level system supports. If not provided system defaults it to "Demo Region"
- **District** Second level in the hierarchy after Region, the district to which a patient belongs to.
- **Facility** Third level in the hierarchy after District. If not provided system defaults it to "UNKNOWN"
- **Sub Facility** Last level in the hierarchy system supports.
