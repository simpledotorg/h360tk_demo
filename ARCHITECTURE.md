# H360TK Demo – Architecture Document

## 1. Overview

The H360TK Demo is a containerized system designed to ingest, process, and visualize patient health data. It enables users to upload structured datasets (Excel/CSV files), transform them into a normalized database schema, and explore insights through dashboards.

This repository is intended for:
- Local deployments
- Demonstrations of data pipelines
- Independent usage of the HEARTS360 Toolkit

---

## 2. High-Level Architecture

The system is composed of multiple loosely coupled services running via Docker.

### Components

1. **Upload Interface (Web UI)**
   - Allows users to upload Excel/CSV files
   - Accessible via browser

2. **FTP Server**
   - Enables manual or automated file uploads
   - Used for bulk ingestion workflows

3. **Ingestion Service**
   - Processes uploaded files
   - Validates and transforms data
   - Inserts into PostgreSQL

4. **PostgreSQL Database**
   - Stores patient, visit, and clinical data
   - Acts as the system of record

5. **Grafana Dashboard**
   - Visualizes processed data
   - Provides analytics and reporting

---

## 3. System Architecture Diagram
               +----------------------+
               |     User / Client    |
               +----------+-----------+
                          |
           +--------------+--------------+
           |                             |
   +-------v-------+             +-------v-------+
   |   Web Upload  |             |   FTP Server  |
   |   (HTTP UI)   |             | (File Drop)   |
   +-------+-------+             +-------+-------+
           |                             |
           +-------------+---------------+
                         |
                 +-------v-------+
                 |  Ingestion    |
                 |  Service      |
                 +-------+-------+
                         |
                 +-------v-------+
                 | PostgreSQL DB |
                 +-------+-------+
                         |
                 +-------v-------+
                 |   Grafana     |
                 |  Dashboard    |
                 +---------------+
                
---

## 4. Data Flow

### 4.1 Upload via Web UI

1. User uploads Excel/CSV file via browser  
2. File is stored in a shared volume  
3. Ingestion service detects new file  
4. File is parsed and validated  
5. Data is inserted into PostgreSQL  
6. Grafana dashboards update automatically  

---

### 4.2 Upload via FTP

1. User uploads file to FTP server  
2. File is written to ingestion directory  
3. Ingestion service polls for new files  
4. Same processing pipeline as Web UI  
5. File is optionally archived or marked processed  

---

## 5. Sequence Diagram

### End-to-End Flow (UI + FTP)

User            Web UI         FTP Server     Ingestion Service     PostgreSQL     Grafana
 |                 |                |                |                   |             |
 |---Upload File-->|                |                |                   |             |
 |                 |---Save File--->|                |                   |             |
 |                 |                |                |                   |             |
 |                 |                |                |---Detect File---->|             |
 |                 |                |                |                   |             |
 |                 |                |                |---Parse & Validate             |
 |                 |                |                |                   |             |
 |                 |                |                |---Insert Data---->|             |
 |                 |                |                |                   |             |
 |                 |                |                |                   |---Query---->|
 |                 |                |                |                   |             |
 |                 |                |                |                   |<--Dashboard |

---

## 6. Container Breakdown

The system is deployed using Docker Compose.

### 6.1 PostgreSQL Container
- Stores all processed data  
- Exposes database port internally  
- Used by ingestion service and Grafana  

---

### 6.2 Ingestion Service Container
- Core processing logic  
- Responsibilities:
  - File parsing
  - Data validation
  - Transformation
  - Database insertion    

---

### 6.3 Web Upload Container
- Provides HTTP interface for file upload  
- Saves files to shared volume  

---

### 6.4 FTP Server Container
- Provides file transfer access  
- Supports:
  - Manual uploads
  - Automated pipelines (external systems)  
- Writes files into ingestion directory  

---

### 6.5 Grafana Container
- Connects to PostgreSQL  
- Displays dashboards  

Default access:
- URL: http://localhost:3000  
- Username: admin  

---

## 7. File Lifecycle

[Upload]
   ↓
[Landing Directory]
   ↓
[Processing by Ingestion Service]
   ↓
[Database Insert]
   ↓
[Optional Archive / Delete]

---

## 8. Ingestion Logic (Conceptual)

Each file undergoes:

1. **Schema Mapping**
   - Map Excel columns → DB schema  

2. **Validation**
   - Required fields  
   - Data type checks  
   - Allowed values 

3. **Transformation**
   - Normalize values  
   - Derive metrics  

4. **Insertion**
   - Insert into relational tables  

---

## 9. Deployment

Start all services:

```bash
docker compose up -d
