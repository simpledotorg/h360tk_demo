## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/simpledotorg/h360tk_demo.git
cd h360tk_demo
```

### 2. Start the System

```bash
docker compose up -d
```

Once the system is running, access the dashboard at:

- **URL:** http://localhost:3000/d/heart360demo/heart-360-global-dashboard
- **Username:** `admin`
- **Password:** `your_secure_password`

### FTP Server

To upload manually through UI, navigate to:

- **Web Admin URL:** http://localhost:8090/
- **Username:** `webuser`
- **Password:** `userpass456`

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
COL_FIRST_NAME = 'First Name'

If your file uses a different column name (e.g., `Full Name`), you can update it as:
COL_FIRST_NAME = 'Full Name'


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

```
HIERARCHY_LEVELS = [
{'level': 1, 'column': [COL_REGION], 'display_name': 'Region', 'var_name': 'region', 'default': SP_REGION_VALUE},
{'level': 2, 'column': [COL_DISTRICT], 'display_name': 'District', 'var_name': 'district', 'default': None},
{'level': 3, 'column': [COL_PHC], 'display_name': 'Facility', 'var_name': 'facility', 'default': 'UNKNOWN'},
{'level': 4, 'column': [COL_SHC], 'display_name': 'Sub-Facility', 'var_name': 'sub_facility', 'default': None},
]
```

If your data has fewer hierarchy levels (e.g., only 3 levels), you can modify it like this:

```
HIERARCHY_LEVELS = [
{'level': 1, 'column': [COL_REGION], 'display_name': 'Region', 'var_name': 'region', 'default': SP_REGION_VALUE},
{'level': 2, 'column': [COL_DISTRICT], 'display_name': 'District', 'var_name': 'district', 'default': None},
{'level': 3, 'column': [COL_PHC], 'display_name': 'Facility', 'var_name': 'facility', 'default': 'UNKNOWN'}
]
```

#### Default Blood Sugar Type

When ingesting blood sugar records, a type value is required.

- Column source: `COL_BS_TYPE`  
- Default value (if missing):  
  DEFAULT_SUGAR_TYPE = "RBS"

If your system uses a different default value, you can update this accordingly.

---

### FTP Server Configuration (Automated Uploads)

#### Note:
This configuration is needed when the system is hosted somewhere other than localhost.
If you are using it your local system, and running the service on localhost, you might choose to skip this.

The system includes an FTP server powered by SFTPGo, which allows you to automate file uploads for ingestion.

The FTP service is exposed on:

* **Host:** `127.0.0.1`
* **Port:** `2121`
* **Protocol:** FTP
* **Username:** `webuser`
* **Password:** `userpass456`

This is configured in the Docker setup under the `sftpgo` service, which exposes the FTP port and passive data ports for file transfer.

---

#### Uploading Files via Command Line

You can upload files using tools like `curl`:

```
curl -T ./test_data/01_Sample_Data.xlsx "ftp://webuser:userpass456@127.0.0.1:2121/01_Sample_Data.xlsx"
```

---

#### Automating Periodic Uploads

You can automate uploads using cron jobs.

Example (runs every hour):

```bash
crontab -e
```

Add:

```
0 * * * * curl -T /path/to/file.xlsx "ftp://webuser:userpass456@127.0.0.1:2121/file.xlsx"
```

---

#### How It Works

* Files uploaded via FTP are stored in the shared `.upload` directory
* The system automatically triggers the ingestion script:

  * `ingest_file_h360tk.py`
* This is handled via an upload hook configured in the FTP service

So **no manual trigger is required** — uploading the file is enough.

---

#### HOST_UID and HOST_GID Configuration

The `sftpgo` container runs using a specific user and group ID defined by:

```bash
user: "${HOST_UID:-1000}:${HOST_GID:-1000}"
```

These values should match user and group IDs which has created .upload directory to avoid permission issues when reading/writing uploaded files.

##### Why this is important

* The `.upload` directory is mounted from your host into the container
* If the container runs with a different UID/GID than your host user:

  * Files may be created with incorrect ownership
  * You may not be able to read/edit/delete uploaded files from your host
  * The ingestion script may fail due to permission errors

##### How to set it correctly
Check from which user the .upload directory, inside the prohect directory, is created with. Most likely in a hosted system (other than localhost), it will be root

Run the following commands on your host:

```bash
id -u root  # returns user ID of root user
id -g root  # returns group ID of root user
```

Then add these values to your `.env` file:

```bash
HOST_UID=1000
HOST_GID=1000
```

(Replace `1000` with your actual values)
Example, if the .upload directry is created with root user, then you should change the values to
```
HOST_UID=0
HOST_GID=0
```

##### When you need to modify this

* If you see permission errors in `.upload` directory
* If uploaded files are owned by an unexpected user
* When running on shared servers or non-standard Linux setups

---

#### ⚠️ Important Notes

* Ensure `FTP_PASSIVE_IP` is correctly set in your `.env`:

  * `127.0.0.1` → for local usage
  * Your Host IP → for network access
* Passive ports `50000–50100` must be open if accessing from outside
* Change default credentials in production
