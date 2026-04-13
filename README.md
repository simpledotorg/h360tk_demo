In order to launch this system:

```
docker compose up -d
```

Once the system is running, access the dashboard at:

- **URL:** http://localhost:3000/d/heart360demo/heart-360-global-dashboard
- **Username:** `admin`
- **Password:** `your_secure_password`

### Upload Files

To upload files, navigate to:

- **URL:** http://localhost:8080/
- **Username:** `admin`
- **Password:** `admin`

### Important Security Note

⚠️ **The credentials provided above are default credentials.** They should be changed in the `docker-compose.yml` file after cloning the repository for security purposes.

### Data Ingestion Script

There is an ingestion script `ingest_file_h360tk.py` which gets triggered when a file is uploaded and inserts data into the database.

There are several customizations that you can apply to this script to better suit your data format.

#### Header Row Configuration

Your Excel file might contain metadata at the beginning, and the actual data may start later in the file.

The script uses the `HEADER_ROW` variable to determine where the header is located.

- Default value: `1` → header is on row 1, data starts from row 2  
- If set to `4` → header is on row 4, data starts from row 5  

#### Column Header Mapping

The script defines column names to extract data from specific fields.

For example:
COL_PATIENT_NAME = 'Patient Name'

If your file uses a different column name (e.g., `Full Name`), you can update it as:
COL_PATIENT_NAME = 'Full Name'


You can similarly update other column mappings as needed.

#### Date Formats

The script supports multiple date formats defined in the `CSV_DATE_FORMATS` variable.

If your data contains date formats not included in this list, you can add them accordingly.

#### Default Region

A default region value is defined using:

SP_REGION_VALUE = "Demo Region"


If your dataset does not include a region field, this value will be used. You can modify it based on your requirements.

#### Hierarchy Levels

The dashboard supports hierarchical data with the following default structure:

Region → District → Facility → Sub-Facility

This is configured in the script as:

HIERARCHY_LEVELS = [
{'level': 1, 'column': [COL_REGION], 'display_name': 'Region', 'var_name': 'region', 'default': SP_REGION_VALUE},
{'level': 2, 'column': [COL_DISTRICT], 'display_name': 'District', 'var_name': 'district', 'default': None},
{'level': 3, 'column': [COL_PHC], 'display_name': 'Facility', 'var_name': 'facility', 'default': 'UNKNOWN'},
{'level': 4, 'column': [COL_SHC], 'display_name': 'Sub-Facility', 'var_name': 'sub_facility', 'default': None},
]

If your data has fewer hierarchy levels (e.g., only 3 levels), you can modify it like this:

HIERARCHY_LEVELS = [
{'level': 1, 'column': [COL_REGION], 'display_name': 'Region', 'var_name': 'region', 'default': SP_REGION_VALUE},
{'level': 2, 'column': [COL_DISTRICT], 'display_name': 'District', 'var_name': 'district', 'default': None},
{'level': 3, 'column': [COL_PHC], 'display_name': 'Facility', 'var_name': 'facility', 'default': 'UNKNOWN'}
]

#### Default Blood Sugar Type

When ingesting blood sugar records, a type value is required.

- Column source: `COL_BS_TYPE`  
- Default value (if missing):  
  DEFAULT_SUGAR_TYPE = "RBS"

If your system uses a different default value, you can update this accordingly.