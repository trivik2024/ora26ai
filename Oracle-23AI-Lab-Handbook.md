# Oracle Database 23AI – Comprehensive Participant Lab Handbook

**Version:** 1.0  
**Date:** November 2025  
**Duration:** 5-Day Training Program  
**Target Audience:** Database Administrators, Developers, Database Architects  

---

## Table of Contents

1. [Environment Setup & Prerequisites](#environment-setup--prerequisites)
2. [Day 1 – Installation, Architecture & CDB/PDB Lab](#day-1--installation-architecture--cdbpdb-lab)
3. [Day 2 – Users, Roles, RMAN Backup & Recovery Lab](#day-2--users-roles-rman-backup--recovery-lab)
4. [Day 3 – Vector Table, Embeddings & Similarity Queries Lab](#day-3--vector-table-embeddings--similarity-queries-lab)
5. [Day 4 – JSON Duality & Semantic Search API Lab](#day-4--json-duality--semantic-search-api-lab)
6. [Day 5 – End-to-End AI Project Lab](#day-5--end-to-end-ai-project-lab)
7. [Troubleshooting & Common Issues](#troubleshooting--common-issues)
8. [Reference & Quick Commands](#reference--quick-commands)

---

## Environment Setup & Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Oracle Linux 8 or RHEL 8 | Oracle Linux 9 / RHEL 9 |
| **CPU Cores** | 2 | 4 or more |
| **RAM** | 8 GB | 16 GB or more |
| **Disk Space** | 50 GB | 100 GB or more |
| **Network** | 1 Gbps | 1 Gbps or higher |

### Pre-Lab Checklist

- [ ] Verify Linux OS version: `cat /etc/os-release`
- [ ] Confirm free disk space: `df -h /u01`
- [ ] Check free memory: `free -h`
- [ ] Ensure hostname is set: `hostname -f`
- [ ] Network connectivity confirmed: `ping 8.8.8.8`
- [ ] Oracle 23AI installation media obtained
- [ ] SSH/Terminal access available
- [ ] SQL*Plus or SQLcl tool available locally (optional)

### Environment Variables Setup

After installation, add to your `~/.bashrc` or `~/.bash_profile`:

```bash
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/23c
export ORACLE_SID=orcl
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
```

Apply the changes:
```bash
source ~/.bashrc
```

---

# Day 1 – Installation, Architecture & CDB/PDB Lab

**Learning Objectives:**
- Understand Oracle 23AI architecture and multitenant design
- Successfully install Oracle 23AI on Linux
- Create a Container Database (CDB) and Pluggable Database (PDB)
- Configure listener and verify network connectivity

## Pre-Installation Phase

### Step 1: Verify System Readiness

**Objective:** Confirm the Linux server meets all requirements for Oracle 23AI installation.

**Linux Commands:**

```bash
# Check OS version and kernel
cat /etc/os-release
uname -r

# Verify CPU cores
nproc

# Check free memory
free -h

# Check disk space on target mount points
df -h /u01
df -h /

# Verify hostname
hostname -f

# Test network connectivity
ping -c 3 8.8.8.8
```

**Expected Output:**
- OS: Oracle Linux 8.x, RHEL 8.x, or 9.x
- Kernel: Version 4.18 or higher
- CPU: At least 2 cores (4+ recommended)
- RAM: At least 8 GB free
- Disk: At least 50 GB available on /u01
- Hostname: FQDN (fully qualified domain name)
- Network: Connectivity confirmed

**Screenshot Reference:** Oracle Database 23c installation prerequisites verification screen showing system information.

### Step 2: Create Operating System Users and Groups

**Objective:** Set up dedicated OS user and groups for Oracle database.

**Linux Commands:**

```bash
# Create oinstall group (for installation)
sudo groupadd oinstall

# Create dba group (for database administration)
sudo groupadd dba

# Create oracle user with oinstall as primary group
sudo useradd -g oinstall -G dba -s /bin/bash -m oracle

# Set password for oracle user
sudo passwd oracle

# Verify user creation
id oracle
```

**Expected Output:**
```
uid=500(oracle) gid=501(oinstall) groups=501(oinstall),502(dba)
```

### Step 3: Create Directory Structure

**Objective:** Set up required directory hierarchy with correct permissions.

**Linux Commands:**

```bash
# Create main directories
sudo mkdir -p /u01/app/oracle/product/23c
sudo mkdir -p /u01/app/oraInventory
sudo mkdir -p /u01/app/oracle/oradata
sudo mkdir -p /u01/app/oracle/backup
sudo mkdir -p /u01/app/oracle/archive

# Set ownership and permissions
sudo chown -R oracle:oinstall /u01/app
sudo chmod -R 775 /u01/app

# Verify directory structure
tree /u01/app -L 2
ls -la /u01/app/oracle/
```

**Directory Purpose:**

| Directory | Purpose |
|-----------|---------|
| `/u01/app/oracle/product/23c` | Oracle Home (installation files) |
| `/u01/app/oraInventory` | Inventory of Oracle installations |
| `/u01/app/oracle/oradata` | Database datafiles location |
| `/u01/app/oracle/backup` | RMAN backup location |
| `/u01/app/oracle/archive` | Archived redo logs |

### Step 4: Install Required Packages and Dependencies

**Objective:** Install all prerequisite packages needed for Oracle 23AI.

**Linux Commands:**

```bash
# Update system packages
sudo dnf update -y

# Install Oracle preinstall package (recommended approach)
sudo dnf install -y oracle-database-preinstall-23c

# Or install individual packages if preinstall not available
sudo dnf install -y \
  binutils \
  glibc \
  glibc-devel \
  libxcb \
  libX11 \
  libXau \
  libXext \
  libXi \
  libXrender \
  libXrandr \
  x11-libs \
  bc \
  net-tools

# Verify installations
rpm -qa | grep oracle-database-preinstall
```

---

## Installation Phase

### Step 5: Download and Prepare Oracle 23AI Installation Media

**Objective:** Obtain and verify Oracle 23AI installation files.

**Actions:**

1. Download from Oracle Technology Network (OTN):
   - Go to https://www.oracle.com/database/technologies/oracle-database-software-downloads.html
   - Download Oracle Database 23c (23ai) for Linux x86-64

2. Verify file integrity:
   ```bash
   cd /path/to/downloaded/files
   ls -lh *.zip
   
   # Verify checksum if provided
   sha256sum -c CHECKSUM_FILE.txt
   ```

3. Extract installation media:
   ```bash
   cd /tmp
   unzip -q /path/to/LINUX.X64_233000_db_home.zip
   ```

### Step 6: Run Oracle Installer (GUI Mode)

**Objective:** Execute the Oracle Universal Installer to install Oracle 23AI software.

**Linux Commands:**

```bash
# Switch to oracle user
su - oracle

# Set display for GUI (if using X11 forwarding)
export DISPLAY=your_local_machine_ip:0

# Navigate to installer directory
cd /tmp/database

# Start the installer
./runInstaller
```

**Installer Steps:**

1. **Configuration Option Screen:**
   - Select: "Set Up Software Only"
   - Click Next

2. **Installation Type:**
   - Select: "Single instance database installation"
   - Click Next

3. **Product Languages:**
   - Keep default (English)
   - Click Next

4. **Installation Location:**
   - Oracle Base: `/u01/app/oracle`
   - Software Location: `/u01/app/oracle/product/23c`
   - Click Next

5. **Privileged Operating System Groups:**
   - OSDBA Group: `dba`
   - OSOPER Group: `dba` (or leave empty)
   - Click Next

6. **Summary:**
   - Review all settings
   - Click Install

7. **Root Scripts:**
   - When prompted, run scripts as root in a separate terminal:
   ```bash
   sudo /u01/app/oraInventory/orainstRoot.sh
   sudo /u01/app/oracle/product/23c/root.sh
   ```

8. **Finish:**
   - Click Close once installation completes

**Screenshot Reference:** Oracle Database 23c installation wizard showing progress and configuration screens.

### Step 7: Verify Software Installation

**Objective:** Confirm Oracle 23AI software was installed correctly.

**Linux Commands:**

```bash
# Switch to oracle user
su - oracle

# Check Oracle Home
echo $ORACLE_HOME
ls -la $ORACLE_HOME/bin/ | head -20

# Verify sqlplus is available
sqlplus -v

# Check inventory
cat /u01/app/oraInventory/ContentsXML/inventory.xml | grep -i "23c"
```

**Expected Output:**
```
SQL*Plus: Release 23.0.0.0.0 - Production
```

---

## Database Creation Phase

### Step 8: Create Container Database (CDB) Using DBCA

**Objective:** Use Database Configuration Assistant to create a multitenant container database.

**Option A: Interactive GUI Mode**

```bash
su - oracle
dbca
```

**DBCA Step-by-Step:**

1. **Operation:** Select "Create a Database" → Next

2. **Database Mode:** Select "High Availability Database" or "Multitenant database"

3. **Database Configuration:**
   - Database Type: Container Database (CDB)
   - Global Database Name: `orclpdb.localdomain`
   - SID: `orcl`
   - Check: "Create as Container Database"
   - Number of PDBs: 1

4. **Storage Options:**
   - Storage Type: File System
   - Database Files Location: `/u01/app/oracle/oradata`

5. **Database Features:**
   - Sample Schemas: Check if desired
   - Memory Settings: Automatic or manual (SGA: 4GB, PGA: 1GB typical)

6. **Management Options:**
   - Enterprise Manager: Skip for lab (Optional)
   - Database Express: Skip for lab

7. **Credentials:**
   - Set admin password
   - Confirm password

8. **Summary:**
   - Review all settings
   - Click Finish

**Option B: Silent Installation (Automated)**

```bash
su - oracle

dbca -silent \
  -createDatabase \
  -templateName General_Purpose.dbc \
  -gdbName orclpdb \
  -sid orcl \
  -createAsContainerDatabase true \
  -numberOfPDBs 1 \
  -pdbName pdb1 \
  -sysPassword SysPass123 \
  -systemPassword SystemPass123 \
  -storageType FS \
  -datafileDest /u01/app/oracle/oradata \
  -emConfiguration NONE \
  -totalMemory 4096
```

**Monitoring DBCA Progress:**

```bash
# In another terminal, monitor database creation
tail -f /u01/app/oracle/oradiag/diag/rdbms/orcl/orcl/trace/alert_orcl.log

# Check if database is starting up
ps -ef | grep pmon
```

**Screenshot Reference:** DBCA wizard showing database configuration and creation progress.

### Step 9: Create Additional PDB (Optional)

**Objective:** Create a second pluggable database manually via SQL.

**SQL Commands:**

```sql
-- Connect as SYSDBA to CDB root
sqlplus sys@orcl as sysdba

-- Create PDB manually
CREATE PLUGGABLE DATABASE pdb2 
  ADMIN USER pdbadmin 
  IDENTIFIED BY PdbPass123 
  FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/orcl/', '/u01/app/oracle/oradata/pdb2/');

-- Open the newly created PDB
ALTER PLUGGABLE DATABASE pdb2 OPEN;

-- Verify PDB creation
SELECT pdb_name, open_mode FROM dba_pdbs;
```

**Expected Output:**
```
PDB_NAME   OPEN_MODE
---------- ----------
pdb1       READ WRITE
pdb2       READ WRITE
```

---

## Network Configuration Phase

### Step 10: Configure Listener

**Objective:** Set up Oracle Listener for database connectivity on port 1521.

**Option A: Using NetCA (Interactive)**

```bash
su - oracle
netca
```

**NETCA Steps:**

1. **Listener Configuration:** Select "Listener configuration"
2. **Listener Name:** Accept default "LISTENER" or provide custom name
3. **Listener Port:** Accept default 1521
4. **Listener Protocols:**
   - Select TCP (enabled by default)
   - Click OK

5. **Start Listener:** Yes

**Option B: Manual Configuration**

```bash
su - oracle

# Edit listener.ora file
vi $ORACLE_HOME/network/admin/listener.ora
```

**Add the following content:**

```
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = yourhostname)(PORT = 1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = orcl)
      (SID_NAME = orcl)
      (ORACLE_HOME = /u01/app/oracle/product/23c)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = pdb1)
      (SID_NAME = orcl)
      (ORACLE_HOME = /u01/app/oracle/product/23c)
    )
  )
```

**Start Listener:**

```bash
lsnrctl start

# Verify listener status
lsnrctl status

# Expected output shows listener running on port 1521
```

**Sample Output:**
```
LISTENER for Linux: Version 23.0.0.0.0 - Production on 25-NOV-2025 10:00:00

Copyright (c) 1991, 2024, Oracle.  All rights reserved.

Starting /u01/app/oracle/product/23c/bin/lsnrctl: please wait...

LISTENER for Linux: Version 23.0.0.0.0 - Production on 25-NOV-2025 10:00:05
Copyright (c) 1991, 2024, Oracle.  All rights reserved.
Starting up TNSLSNR for Linux: Version 23.0.0.0.0 - Production
...
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=yourhostname)(PORT=1521)))

Connecting to (ADDRESS=(PROTOCOL=tcp)(HOST=)(PORT=1521))
STATUS of the LISTENER
--------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 23.0.0.0.0 - Production
Start Date                25-NOV-2025 10:00:05
Uptime                    0 days 0 hr. 0 min. 0 sec
Trace Level               off
Security                  OFF
SNMP                      OFF
Listener Log File         /u01/app/oracle/product/23c/network/log/listener.log
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=yourhostname)(PORT=1521)))
Services Summary...
  Service "orcl" has 1 instance(s).
    Instance "orcl", status READY, has 1 handler(s) for this service...
  Service "pdb1" has 1 instance(s).
    Instance "orcl", status READY, has 1 handler(s) for this service...
The command completed successfully.
```

### Step 11: Configure TNS Names Entry

**Objective:** Set up local TNS names for easy database connectivity.

**Linux Commands:**

```bash
su - oracle

# Edit tnsnames.ora
vi $ORACLE_HOME/network/admin/tnsnames.ora
```

**Add entries for CDB and PDB:**

```
# CDB Entry
orclcdb =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = yourhostname)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )

# PDB1 Entry
orclpdb =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = yourhostname)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = pdb1)
    )
  )

# PDB2 Entry (if created)
pdb2 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = yourhostname)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = pdb2)
    )
  )
```

**Test TNS Names Resolution:**

```bash
tnsping orclpdb

# Expected output
Used TNSNAMES adapter to resolve the name
Attempting to contact (DESCRIPTION = (...))
OK (0 msec)
```

---

## Verification Phase

### Step 12: Verify CDB and PDB Connectivity

**Objective:** Confirm successful installation and connectivity to both CDB and PDB.

**SQL Commands:**

```bash
su - oracle

# Connect to CDB
sqlplus sys@orclcdb as sysdba
```

**In SQL*Plus:**

```sql
-- Show current container name
SHOW CON_NAME;

-- List all PDBs in the CDB
SELECT pdb_name, open_mode FROM dba_pdbs;

-- Check database version
SELECT banner FROM v$version WHERE rownum = 1;

-- Check instance name
SELECT instance_name FROM v$instance;

-- Exit SQL*Plus
EXIT;
```

**Expected Output:**
```
CON_NAME
------------------------------
CDB$ROOT

PDB_NAME   OPEN_MODE
---------- ----------
pdb1       READ WRITE
pdb2       READ WRITE

BANNER
--------
Oracle Database 23c Enterprise Edition Release 23.0.0.0.0 - Production

INSTANCE_NAME
--------------
orcl
```

**Connect to PDB:**

```bash
sqlplus sys@orclpdb as sysdba
```

**In SQL*Plus:**

```sql
-- Show current PDB
SHOW CON_NAME;

-- Check open mode
SELECT open_mode FROM v$database;

-- List tablespaces
SELECT tablespace_name FROM dba_tablespaces;

-- Exit
EXIT;
```

**Expected Output:**
```
CON_NAME
------------------------------
pdb1

OPEN_MODE
----------
READ WRITE

TABLESPACE_NAME
------------------------------
SYSTEM
SYSAUX
UNDO
TEMP
USERS
```

### Step 13: Test Remote Connectivity (Optional)

**Objective:** Verify database can be accessed from a remote client machine.

**From Remote Client:**

```bash
# Using SQL*Plus
sqlplus sys@yourhostname:1521/pdb1 as sysdba

# Or using tnsnames entry (if configured on client)
sqlplus sys@orclpdb as sysdba
```

**In SQL*Plus:**

```sql
-- Verify connection
SELECT name FROM v$database;
SELECT sys_context('USERENV','INSTANCE_NAME') AS instance_name FROM dual;

-- Check connected user
SHOW USER;

-- Test query execution
SELECT count(*) FROM dba_tables;

-- Exit
EXIT;
```

---

## Lab Completion Checklist – Day 1

- [ ] Oracle 23AI software successfully installed in `/u01/app/oracle/product/23c`
- [ ] CDB (orcl) created and in OPEN mode
- [ ] PDB (pdb1) created and in OPEN mode
- [ ] Additional PDB (pdb2) created (optional but recommended)
- [ ] Listener running on port 1521
- [ ] TNS names configured and tested
- [ ] Local and remote connectivity verified
- [ ] Alert log reviewed for any errors
- [ ] Database auto-start configured (optional)
- [ ] Documentation: Record SID, CDB name, PDB names, and admin credentials

---

# Day 2 – Users, Roles, RMAN Backup & Recovery Lab

**Learning Objectives:**
- Create and manage database users and roles
- Configure RMAN for database backups
- Understand backup and recovery concepts
- Perform recovery from backup scenarios

---

## User and Role Management Phase

### Step 1: Connect as DBA to PDB

**Objective:** Establish connection to PDB with administrative privileges.

**Linux Commands:**

```bash
su - oracle
sqlplus sys@orclpdb as sysdba
```

**Expected Output:**
```
SQL*Plus: Release 23.0.0.0.0 - Production on Tue Nov 25 10:15:30 2025
Copyright (c) 1982, 2024, Oracle.  All rights reserved.

Connected to:
Oracle Database 23c Enterprise Edition Release 23.0.0.0.0 - Production

SQL>
```

### Step 2: Create Application Roles

**Objective:** Define roles with specific privileges for application users.

**SQL Commands:**

```sql
-- Create a read-only role
CREATE ROLE app_readonly_role;

GRANT CREATE SESSION TO app_readonly_role;
GRANT SELECT ANY TABLE TO app_readonly_role;

-- Create a developer role with more privileges
CREATE ROLE app_developer_role;

GRANT CREATE SESSION TO app_developer_role;
GRANT CREATE TABLE TO app_developer_role;
GRANT CREATE VIEW TO app_developer_role;
GRANT CREATE PROCEDURE TO app_developer_role;
GRANT UNLIMITED TABLESPACE TO app_developer_role;

-- Create an administrator role
CREATE ROLE app_admin_role;

GRANT CREATE SESSION TO app_admin_role;
GRANT CREATE TABLE TO app_admin_role;
GRANT CREATE ROLE TO app_admin_role;
GRANT GRANT ANY ROLE TO app_admin_role;
GRANT UNLIMITED TABLESPACE TO app_admin_role;

-- Verify roles created
SELECT role FROM dba_roles WHERE role LIKE 'APP%' ORDER BY role;
```

**Expected Output:**
```
ROLE
------------------
APP_ADMIN_ROLE
APP_DEVELOPER_ROLE
APP_READONLY_ROLE
```

### Step 3: Create Database Users

**Objective:** Create user accounts with appropriate profiles and default tablespaces.

**SQL Commands:**

```sql
-- Create a readonly user
CREATE USER readonly_user 
  IDENTIFIED BY ReadOnlyPass123 
  DEFAULT TABLESPACE users 
  TEMPORARY TABLESPACE temp
  ACCOUNT UNLOCK;

-- Create a developer user
CREATE USER developer_user 
  IDENTIFIED BY DevPass123 
  DEFAULT TABLESPACE users 
  TEMPORARY TABLESPACE temp
  ACCOUNT UNLOCK;

-- Create an admin user
CREATE USER app_admin 
  IDENTIFIED BY AdminPass123 
  DEFAULT TABLESPACE users 
  TEMPORARY TABLESPACE temp
  ACCOUNT UNLOCK;

-- Verify users created
SELECT username FROM dba_users WHERE username LIKE '%USER%' OR username = 'APP_ADMIN' ORDER BY username;
```

**Expected Output:**
```
USERNAME
---------
APP_ADMIN
DEVELOPER_USER
READONLY_USER
```

### Step 4: Assign Roles to Users

**Objective:** Grant appropriate roles to each user based on their responsibilities.

**SQL Commands:**

```sql
-- Assign roles to users
GRANT app_readonly_role TO readonly_user;
GRANT app_developer_role TO developer_user;
GRANT app_admin_role TO app_admin;

-- Verify role assignments
SELECT grantee, granted_role FROM dba_role_privs 
WHERE grantee IN ('READONLY_USER', 'DEVELOPER_USER', 'APP_ADMIN')
ORDER BY grantee;

-- Show privileges granted to roles
SELECT role, privilege FROM dba_sys_privs 
WHERE role LIKE 'APP%'
ORDER BY role, privilege;
```

**Expected Output:**
```
GRANTEE         GRANTED_ROLE
-----------     ------------------
APP_ADMIN       APP_ADMIN_ROLE
DEVELOPER_USER  APP_DEVELOPER_ROLE
READONLY_USER   APP_READONLY_ROLE

ROLE                    PRIVILEGE
---------------------  -----------
APP_ADMIN_ROLE          CREATE SESSION
APP_ADMIN_ROLE          CREATE TABLE
APP_DEVELOPER_ROLE      CREATE SESSION
APP_DEVELOPER_ROLE      CREATE TABLE
APP_DEVELOPER_ROLE      CREATE VIEW
APP_READONLY_ROLE       CREATE SESSION
APP_READONLY_ROLE       SELECT ANY TABLE
```

### Step 5: Test User Connectivity

**Objective:** Verify each user can successfully connect and perform appropriate operations.

**Test Read-Only User:**

```bash
sqlplus readonly_user@orclpdb
```

**In SQL*Plus:**

```sql
-- User password: ReadOnlyPass123

-- Check user identity
SHOW USER;

-- Try to query existing table (should work)
SELECT * FROM all_tables WHERE rownum <= 1;

-- Try to create table (should fail)
CREATE TABLE test_table (id NUMBER);
-- Expected error: ORA-01031: insufficient privileges

-- Exit
EXIT;
```

**Test Developer User:**

```bash
sqlplus developer_user@orclpdb
```

**In SQL*Plus:**

```sql
-- User password: DevPass123

SHOW USER;

-- Create a test table (should work)
CREATE TABLE developer_test_table (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100),
  created_date DATE DEFAULT SYSDATE
);

-- Insert sample data
INSERT INTO developer_test_table (id, name) VALUES (1, 'Test Record');
COMMIT;

-- Verify table created
SELECT * FROM developer_test_table;

-- Exit
EXIT;
```

---

## RMAN Configuration and Backup Phase

### Step 6: Enable ARCHIVELOG Mode

**Objective:** Configure database to archive redo logs for point-in-time recovery.

**Linux Commands:**

```bash
su - oracle
sqlplus / as sysdba
```

**SQL Commands:**

```sql
-- Check if database is in ARCHIVELOG mode
SELECT log_mode FROM v$database;

-- If not in ARCHIVELOG, enable it
-- First, shutdown database
SHUTDOWN IMMEDIATE;

-- Startup in mount mode
STARTUP MOUNT;

-- Enable archivelog
ALTER DATABASE ARCHIVELOG;

-- Open database
ALTER DATABASE OPEN;

-- Verify ARCHIVELOG is enabled
SELECT log_mode FROM v$database;

-- Exit
EXIT;
```

**Expected Output:**
```
LOG_MODE
-----------
ARCHIVELOG
```

**Check Archive Destination:**

```sql
sqlplus / as sysdba

-- Query archive destination
SHOW PARAMETER db_recovery_file_dest;

-- If not set, configure it
ALTER SYSTEM SET db_recovery_file_dest='/u01/app/oracle/backup/recovery_area' SCOPE=BOTH;
ALTER SYSTEM SET db_recovery_file_dest_size=50G SCOPE=BOTH;

-- Verify
SHOW PARAMETER db_recovery_file_dest;

-- Exit
EXIT;
```

**Expected Output:**
```
NAME                          TYPE        VALUE
---------------------------   ---------   -----------
db_recovery_file_dest         string      /u01/app/oracle/backup/recovery_area
db_recovery_file_dest_size    big integer 53687091200
```

### Step 7: Configure RMAN Environment

**Objective:** Set up RMAN retention policies and backup format strings.

**Linux Commands:**

```bash
su - oracle

# Connect to RMAN
rman target /

# Or with explicit database connection
rman target sys/SysPass123@orclpdb
```

**RMAN Commands:**

```rman
-- Display current RMAN configuration
SHOW ALL;

-- Configure retention policy (keep 7 days of backups)
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

-- Enable control file auto backup
CONFIGURE CONTROLFILE AUTOBACKUP ON;

-- Set control file backup location
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/u01/app/oracle/backup/%F';

-- Set default backup format
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/u01/app/oracle/backup/%d_%U_%T.bkp';

-- Show updated configuration
SHOW ALL;

-- Exit RMAN
EXIT;
```

**Expected Output:**
```
RMAN configuration parameters for database with db_unique_name orcl are:
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
CONFIGURE BACKUP COMPRESSION ALGORITHM 'BASIC';
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/u01/app/oracle/backup/%F';
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/u01/app/oracle/backup/%d_%U_%T.bkp';
```

### Step 8: Create Full Database Backup

**Objective:** Take a full backup of the database for recovery scenarios.

**RMAN Commands:**

```bash
su - oracle

# Connect to RMAN
rman target /
```

**RMAN Backup Script:**

```rman
-- Backup database
BACKUP AS BACKUPSET DATABASE PLUS ARCHIVELOG DELETE INPUT;

-- Or more detailed backup with compression
RUN {
  BACKUP COMPRESSION ALGORITHM 'BASIC' AS BACKUPSET DATABASE 
    FORMAT '/u01/app/oracle/backup/full_db_%d_%T_%s.bkp' 
    TAG 'FULL_DB_BACKUP';
  BACKUP ARCHIVELOG ALL 
    FORMAT '/u01/app/oracle/backup/arch_%d_%T_%s.bkp' 
    TAG 'ARCHIVE_BACKUP' 
    DELETE INPUT;
  BACKUP CURRENT CONTROLFILE 
    FORMAT '/u01/app/oracle/backup/cf_%d_%T_%s.bkp' 
    TAG 'CONTROL_FILE_BACKUP';
}

-- List backup pieces
LIST BACKUP SUMMARY;

-- Exit RMAN
EXIT;
```

**Verify Backup Files:**

```bash
ls -lh /u01/app/oracle/backup/
```

**Screenshot Reference:** RMAN backup status screen showing completed backup sets and file sizes.

### Step 9: Create Recovery Test Scenario

**Objective:** Simulate a data loss scenario by dropping a table.

**SQL Commands:**

```bash
sqlplus developer_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Verify table exists before deletion
SELECT table_name FROM all_tables WHERE table_name = 'DEVELOPER_TEST_TABLE';

-- Record current data
SELECT * FROM developer_test_table;

-- Drop the table to simulate data loss
DROP TABLE developer_test_table PURGE;

-- Verify table is gone
SELECT table_name FROM all_tables WHERE table_name = 'DEVELOPER_TEST_TABLE';
-- Should return no rows

-- Exit
EXIT;
```

---

## Recovery Phase

### Step 10: Restore from Backup (Recover Dropped Table)

**Objective:** Perform recovery to restore the dropped table from backup.

**Option A: Tablespace Recovery**

```bash
su - oracle
sqlplus / as sysdba
```

**SQL Commands:**

```sql
-- Determine which tablespace contains user data
SELECT tablespace_name FROM dba_tables WHERE table_name = 'DEVELOPER_TEST_TABLE';
-- If you don't remember, check DBA_TABLESPACES
SELECT tablespace_name FROM dba_tablespaces WHERE contents = 'PERMANENT';
```

**RMAN Recovery:**

```bash
rman target /
```

**RMAN Commands:**

```rman
-- Restore tablespace from backup
RUN {
  SET UNTIL TIME "sysdate - 1 minute";
  RESTORE TABLESPACE users;
  RECOVER TABLESPACE users;
}

-- Or full database point-in-time recovery
RUN {
  SET UNTIL TIME "trunc(sysdate)||' 12:00:00'";
  RESTORE DATABASE;
  RECOVER DATABASE;
}

-- Exit RMAN
EXIT;
```

**Option B: Full Database Recovery**

```bash
su - oracle
sqlplus / as sysdba
```

**SQL Commands:**

```sql
-- Shutdown database
SHUTDOWN IMMEDIATE;

-- Startup in mount mode for recovery
STARTUP MOUNT;

-- Exit SQL*Plus
EXIT;
```

**RMAN Full Recovery:**

```bash
rman target /
```

**RMAN Commands:**

```rman
-- Restore entire database
RESTORE DATABASE;

-- Recover database to point-in-time
RECOVER DATABASE UNTIL TIME "to_date('25-NOV-2025 10:30:00','DD-MON-YYYY HH:MI:SS')";

-- Open with resetlogs (required after PITR)
ALTER DATABASE OPEN RESETLOGS;

-- Exit RMAN
EXIT;
```

**Verify Database After Recovery:**

```bash
sqlplus / as sysdba
```

**SQL Commands:**

```sql
-- Check database is open
SELECT open_mode FROM v$database;

-- Verify recovered data
SELECT * FROM developer_user.developer_test_table;

-- Check database status
SELECT status FROM v$instance;

-- Exit
EXIT;
```

**Expected Output:**
```
OPEN_MODE
----------
READ WRITE

ID NAME         CREATED_DATE
-- ------------ -----------
1  Test Record  25-NOV-2025
```

### Step 11: Verify Recovery and Data Integrity

**Objective:** Confirm that recovered data matches backed-up state.

**SQL Commands:**

```bash
sqlplus / as sysdba
```

```sql
-- Check alert log for recovery completion
-- If recovery was successful, you'll see messages like:
-- "Completed: alter database open resetlogs"

-- Verify all tablespaces are accessible
SELECT tablespace_name, status FROM dba_tablespaces ORDER BY tablespace_name;

-- Check for any invalid objects
SELECT owner, object_name, object_type, status 
FROM dba_objects 
WHERE status = 'INVALID'
ORDER BY owner;

-- Run a test query from recovered table
SELECT COUNT(*) FROM developer_user.developer_test_table;

-- Check datafile status
SELECT file#, status, name FROM v$datafile ORDER BY file#;

-- Exit
EXIT;
```

**Expected Output:**
```
TABLESPACE_NAME  STATUS
---------------  ---------
SYSTEM           ONLINE
SYSAUX           ONLINE
UNDOTBS1         ONLINE
TEMP             ONLINE
USERS            ONLINE

(No rows = No invalid objects)

COUNT(*)
--------
1

FILE#  STATUS    NAME
-----  --------  -----------
1      ONLINE    /u01/app/oracle/oradata/orcl/system01.dbf
...
```

---

## Advanced RMAN Operations

### Step 12: Create RMAN Backup Catalog (Optional Advanced Topic)

**Objective:** Set up external catalog for enhanced backup management.

**Note:** This is optional for advanced backup management. Lab can skip this if time-constrained.

```bash
su - oracle

# Create catalog tablespace
sqlplus / as sysdba
```

**SQL Commands:**

```sql
-- Create separate tablespace for RMAN catalog
CREATE TABLESPACE catalog_ts
  DATAFILE '/u01/app/oracle/oradata/orcl/catalog01.dbf' SIZE 500M
  AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED;

-- Exit
EXIT;
```

---

## Lab Completion Checklist – Day 2

- [ ] Roles created: `app_readonly_role`, `app_developer_role`, `app_admin_role`
- [ ] Users created: `readonly_user`, `developer_user`, `app_admin`
- [ ] Users successfully assigned to appropriate roles
- [ ] User connectivity tested for all three users
- [ ] Database set to ARCHIVELOG mode
- [ ] Recovery area configured (`db_recovery_file_dest`)
- [ ] RMAN configured with retention policy
- [ ] Full database backup completed successfully
- [ ] Backup files verified on disk
- [ ] Recovery scenario tested (drop table)
- [ ] Recovery from backup successful
- [ ] Data integrity verified after recovery
- [ ] Alert log reviewed for errors
- [ ] Document: Backup strategy, retention policy, recovery procedures

---

# Day 3 – Vector Table, Embeddings & Similarity Queries Lab

**Learning Objectives:**
- Understand Oracle 23AI vector data type
- Create vector-enabled tables for embedding storage
- Build vector indexes for fast similarity search
- Execute semantic similarity queries
- Understand distance metrics and ranking

---

## Vector Table Creation Phase

### Step 1: Prepare Vector-Enabled Schema

**Objective:** Create a schema and user dedicated to vector database operations.

**SQL Commands:**

```bash
su - oracle
sqlplus sys@orclpdb as sysdba
```

**In SQL*Plus:**

```sql
-- Create dedicated tablespace for vector data
CREATE TABLESPACE vector_ts
  DATAFILE '/u01/app/oracle/oradata/orcl/vector_ts01.dbf' SIZE 2G
  AUTOEXTEND ON NEXT 500M MAXSIZE UNLIMITED;

-- Create dedicated user for vector operations
CREATE USER vector_user 
  IDENTIFIED BY VectorPass123 
  DEFAULT TABLESPACE vector_ts 
  TEMPORARY TABLESPACE temp;

-- Grant necessary privileges
GRANT CREATE SESSION TO vector_user;
GRANT CREATE TABLE TO vector_user;
GRANT CREATE INDEX TO vector_user;
GRANT UNLIMITED TABLESPACE TO vector_user;

-- Exit
EXIT;
```

### Step 2: Create Vector-Enabled Table

**Objective:** Design and create a table with vector column for storing embeddings.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Create vector documents table
-- Vector dimension: 384 (matches common embedding models like all-MiniLM-L6-v2)
CREATE TABLE documents (
  doc_id          NUMBER PRIMARY KEY,
  doc_title       VARCHAR2(500),
  doc_text        CLOB,
  doc_category    VARCHAR2(100),
  created_date    DATE DEFAULT SYSDATE,
  last_updated    DATE DEFAULT SYSDATE,
  embedding       VECTOR(384)  -- Store 384-dimensional embedding
);

-- Create additional indexes for faster queries
CREATE INDEX idx_doc_category ON documents(doc_category);
CREATE INDEX idx_created_date ON documents(created_date);

-- Verify table structure
DESC documents;

-- Exit
EXIT;
```

**Expected Output:**
```
Name                Null?    Type
------------------- -------- -------------------
DOC_ID              NOT NULL NUMBER
DOC_TITLE                    VARCHAR2(500)
DOC_TEXT                     CLOB
DOC_CATEGORY                 VARCHAR2(100)
CREATED_DATE                 DATE
LAST_UPDATED                 DATE
EMBEDDING                    VECTOR(384)
```

### Step 3: Prepare Sample Embeddings Data

**Objective:** Generate or obtain sample embeddings for testing vector operations.

**Sample Data Script:**

```bash
# Create Python script to generate sample embeddings
cat > /tmp/generate_embeddings.py << 'EOF'
import numpy as np
import json

# Simulate sample documents with embeddings
documents = [
    {
        "doc_id": 1,
        "title": "Introduction to Machine Learning",
        "text": "Machine learning is a subset of artificial intelligence that enables systems to learn from data.",
        "category": "AI"
    },
    {
        "doc_id": 2,
        "title": "Deep Learning Fundamentals",
        "text": "Deep learning uses neural networks with multiple layers to process complex patterns.",
        "category": "AI"
    },
    {
        "doc_id": 3,
        "title": "Natural Language Processing",
        "text": "NLP enables computers to understand and process human language data.",
        "category": "AI"
    },
    {
        "doc_id": 4,
        "title": "Oracle Database Administration",
        "text": "DBA tasks include backup, recovery, user management, and performance tuning.",
        "category": "Database"
    },
    {
        "doc_id": 5,
        "title": "SQL Query Optimization",
        "text": "Optimize queries using indexes, execution plans, and join strategies.",
        "category": "Database"
    }
]

# Generate random embeddings (in production, use embedding model)
embeddings_data = []
for doc in documents:
    embedding = np.random.randn(384).tolist()  # 384 dimensions
    embeddings_data.append({
        "doc_id": doc["doc_id"],
        "title": doc["title"],
        "text": doc["text"],
        "category": doc["category"],
        "embedding": embedding
    })

# Save to JSON file
with open('/tmp/embeddings.json', 'w') as f:
    json.dump(embeddings_data, f, indent=2)

print("✓ Generated 5 sample documents with 384-dimensional embeddings")
print("✓ Saved to /tmp/embeddings.json")
EOF

# Run the Python script
python3 /tmp/generate_embeddings.py
```

**View Generated Data:**

```bash
head -50 /tmp/embeddings.json
```

### Step 4: Insert Embeddings into Oracle Table

**Objective:** Load sample embeddings into the vector table.

**SQL Script:**

```bash
sqlplus vector_user@orclpdb << 'EOF'
VectorPass123

-- Password: VectorPass123

-- Insert sample documents with embeddings
-- Note: Using simplified format for lab (values as comma-separated numbers)
INSERT INTO documents (doc_id, doc_title, doc_text, doc_category, embedding) VALUES (
  1, 
  'Introduction to Machine Learning',
  'Machine learning is a subset of artificial intelligence that enables systems to learn from data.',
  'AI',
  VECTOR('[0.12, 0.34, -0.23, 0.45, 0.67, ..., 0.89]',384)  -- First 384 dimensions
);

INSERT INTO documents (doc_id, doc_title, doc_text, doc_category, embedding) VALUES (
  2,
  'Deep Learning Fundamentals',
  'Deep learning uses neural networks with multiple layers to process complex patterns.',
  'AI',
  VECTOR('[0.23, -0.12, 0.56, 0.34, 0.78, ..., 0.45]',384)
);

INSERT INTO documents (doc_id, doc_title, doc_text, doc_category, embedding) VALUES (
  3,
  'Natural Language Processing',
  'NLP enables computers to understand and process human language data.',
  'AI',
  VECTOR('[0.34, 0.56, 0.12, -0.23, 0.45, ..., 0.67]',384)
);

INSERT INTO documents (doc_id, doc_title, doc_text, doc_category, embedding) VALUES (
  4,
  'Oracle Database Administration',
  'DBA tasks include backup, recovery, user management, and performance tuning.',
  'Database',
  VECTOR('[0.45, 0.12, -0.34, 0.67, 0.23, ..., 0.56]',384)
);

INSERT INTO documents (doc_id, doc_title, doc_text, doc_category, embedding) VALUES (
  5,
  'SQL Query Optimization',
  'Optimize queries using indexes, execution plans, and join strategies.',
  'Database',
  VECTOR('[0.56, 0.23, 0.45, -0.12, 0.78, ..., 0.34]',384)
);

COMMIT;

-- Verify data inserted
SELECT doc_id, doc_title, doc_category FROM documents ORDER BY doc_id;

-- Count rows
SELECT COUNT(*) as total_documents FROM documents;

-- Exit
EXIT;
EOF
```

**Expected Output:**
```
DOC_ID DOC_TITLE                        DOC_CATEGORY
------ -------------------------------- ---------
1      Introduction to Machine Learning AI
2      Deep Learning Fundamentals       AI
3      Natural Language Processing       AI
4      Oracle Database Administration    Database
5      SQL Query Optimization            Database

TOTAL_DOCUMENTS
---------------
5
```

---

## Vector Index Creation Phase

### Step 5: Create Vector Index (ANN – HNSW)

**Objective:** Build an Approximate Nearest Neighbor (HNSW) index for efficient similarity search.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Create HNSW vector index for fast similarity search
-- Parameters:
--   M=16: Maximum number of neighbors per node
--   ef_construction=200: Size of dynamic list during insertion
CREATE INDEX idx_doc_embedding 
  ON documents(embedding) 
  INDEXTYPE IS VECTOR_AI_HNSW 
  PARAMETERS ('M=16', 'ef_construction=200');

-- Wait for index creation (monitor with background process)
-- Index creation progress can be checked via:

-- Verify index was created
SELECT index_name, index_type FROM user_indexes WHERE table_name = 'DOCUMENTS';

-- Check index status
SELECT index_name, status FROM user_indexes WHERE table_name = 'DOCUMENTS';

-- Exit
EXIT;
```

**Expected Output:**
```
INDEX_NAME           INDEX_TYPE
-------------------- -----
IDX_DOC_EMBEDDING    VECTOR_AI_HNSW
IDX_DOC_CATEGORY     NORMAL
IDX_CREATED_DATE     NORMAL

INDEX_NAME           STATUS
-------------------- ------
IDX_DOC_EMBEDDING    VALID
IDX_DOC_CATEGORY     VALID
IDX_CREATED_DATE     VALID
```

**Screenshot Reference:** Vector index creation and monitoring dashboard showing index status and parameters.

---

## Vector Similarity Query Phase

### Step 6: Execute Basic Similarity Queries

**Objective:** Run vector similarity searches to find most relevant documents.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Define a query vector (representing a search query like "ML algorithms")
-- In production, this would be generated from the user's text query
DEFINE query_vector = "VECTOR('[0.15, 0.32, -0.18, 0.42, 0.65, ..., 0.88]',384)"

-- Find top 3 most similar documents using cosine distance
-- Distance operator: <=> (vector similarity)
SELECT 
  doc_id,
  doc_title,
  doc_category,
  ROUND(1 - VECTOR_DISTANCE(embedding, &query_vector, COSINE), 4) AS similarity_score
FROM documents
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, COSINE)
FETCH FIRST 3 ROWS ONLY;

-- Exit
EXIT;
```

**Expected Output (Example):**
```
DOC_ID DOC_TITLE                      DOC_CATEGORY SIMILARITY_SCORE
------ ------------------------------ ------------ ----------------
1      Introduction to Machine Learning AI           0.8750
2      Deep Learning Fundamentals      AI           0.8420
3      Natural Language Processing     AI           0.7890
```

### Step 7: Execute Filtered Similarity Searches

**Objective:** Combine vector similarity with regular SQL predicates for refined searches.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Find top 3 AI documents similar to query vector
DEFINE query_vector = "VECTOR('[0.15, 0.32, -0.18, 0.42, 0.65, ..., 0.88]',384)"

SELECT 
  doc_id,
  doc_title,
  doc_category,
  created_date,
  ROUND(1 - VECTOR_DISTANCE(embedding, &query_vector, COSINE), 4) AS similarity
FROM documents
WHERE doc_category = 'AI'  -- Filter by category
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, COSINE)
FETCH FIRST 3 ROWS ONLY;

-- Find Database category documents similar to query
DEFINE query_vector2 = "VECTOR('[0.42, 0.15, -0.32, 0.65, 0.18, ..., 0.55]',384)"

SELECT 
  doc_id,
  doc_title,
  ROUND(1 - VECTOR_DISTANCE(embedding, &query_vector2, COSINE), 4) AS similarity
FROM documents
WHERE doc_category = 'Database'
ORDER BY VECTOR_DISTANCE(embedding, &query_vector2, COSINE)
FETCH FIRST 3 ROWS ONLY;

-- Exit
EXIT;
```

**Expected Output (Example):**
```
DOC_ID DOC_TITLE                       DOC_CATEGORY CREATED_DATE SIMILARITY
------ ------------------------------- ------------ ------------ ----------
4      Oracle Database Administration  Database     25-NOV-2025  0.9120
5      SQL Query Optimization          Database     25-NOV-2025  0.8750
```

### Step 8: Compare Distance Metrics

**Objective:** Understand different distance metrics and their impact on results.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

DEFINE query_vector = "VECTOR('[0.15, 0.32, -0.18, 0.42, 0.65, ..., 0.88]',384)"

-- Compare different distance metrics
SELECT 
  doc_id,
  doc_title,
  ROUND(VECTOR_DISTANCE(embedding, &query_vector, COSINE), 4) AS cosine_dist,
  ROUND(VECTOR_DISTANCE(embedding, &query_vector, L2), 4) AS l2_dist,
  ROUND(VECTOR_DISTANCE(embedding, &query_vector, EUCLIDEAN), 4) AS euclidean_dist
FROM documents
ORDER BY doc_id;

-- Find top 3 by each metric

-- Top 3 by Cosine Distance
SELECT doc_id, doc_title, 
       ROUND(VECTOR_DISTANCE(embedding, &query_vector, COSINE), 4) AS cosine_dist
FROM documents
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, COSINE)
FETCH FIRST 3 ROWS ONLY;

-- Top 3 by L2 Distance
SELECT doc_id, doc_title,
       ROUND(VECTOR_DISTANCE(embedding, &query_vector, L2), 4) AS l2_dist
FROM documents
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, L2)
FETCH FIRST 3 ROWS ONLY;

-- Exit
EXIT;
```

**Distance Metrics Explained:**

| Metric | Range | Use Case |
|--------|-------|----------|
| **Cosine** | 0-1 | Angular distance, most common for embeddings |
| **L2 (Euclidean)** | 0-∞ | Straight-line distance |
| **L1 (Manhattan)** | 0-∞ | City-block distance |
| **DOT PRODUCT** | -∞ to ∞ | Inner product, normalized for similarity |

### Step 9: Vector Query Performance Analysis

**Objective:** Understand query performance with and without vector index.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Enable query execution plan
SET AUTOTRACE ON EXPLAIN;

DEFINE query_vector = "VECTOR('[0.15, 0.32, -0.18, 0.42, 0.65, ..., 0.88]',384)"

-- Execute query with index
SELECT doc_id, doc_title
FROM documents
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, COSINE)
FETCH FIRST 5 ROWS ONLY;

-- Check execution plan
-- Should show: INDEX RANGE SCAN on IDX_DOC_EMBEDDING

SET AUTOTRACE OFF;

-- Exit
EXIT;
```

**Expected Execution Plan (with index):**
```
Plan hash value: xxxxx

-------------------------------------
| Id  | Operation                   | Name                |
-------------------------------------
| 0   | SELECT STATEMENT            |                     |
| 1   | VIEW                        | VW_SFW_1            |
| 2   | INDEX RANGE SCAN            | IDX_DOC_EMBEDDING   |
-------------------------------------
```

---

## Lab Completion Checklist – Day 3

- [ ] Vector-enabled tablespace created (`vector_ts`)
- [ ] Vector user created with appropriate privileges
- [ ] Documents table created with 384-dimensional embedding column
- [ ] 5 sample documents inserted with embeddings
- [ ] HNSW vector index successfully created on embedding column
- [ ] Index status verified as VALID
- [ ] Basic similarity queries executed successfully
- [ ] Query results show correct ranking by similarity
- [ ] Filtered searches (category filter) work correctly
- [ ] Different distance metrics tested (Cosine, L2, etc.)
- [ ] Query performance analyzed and index being used
- [ ] Top-N similarity results retrieved accurately
- [ ] Document: Vector dimension choice, distance metric rationale, query patterns

---

# Day 4 – JSON Duality & Semantic Search API Lab

**Learning Objectives:**
- Understand JSON relational duality in Oracle 23AI
- Create and manage JSON columns efficiently
- Build semantic search queries combining vector and JSON data
- Develop a simple semantic search API with Python/Java
- Integrate database queries with API endpoints

---

## JSON Data Model Phase

### Step 1: Create JSON-Enabled Table

**Objective:** Design table supporting both relational and JSON access patterns.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Create JSON documents table with duality support
-- This table stores both structured (relational) and semi-structured (JSON) data
CREATE TABLE json_documents (
  doc_id          NUMBER PRIMARY KEY,
  doc_metadata    JSON,                -- JSON column for flexible metadata
  doc_title       VARCHAR2(500),       -- Relational denormalization
  doc_text        CLOB,               -- Full text content
  embedding       VECTOR(384),        -- Vector for similarity search
  created_date    DATE DEFAULT SYSDATE,
  updated_date    DATE DEFAULT SYSDATE
);

-- Create JSON search index for faster JSON queries
CREATE SEARCH INDEX idx_json_metadata ON json_documents(doc_metadata) FOR JSON;

-- Create composite index for common queries
CREATE INDEX idx_json_docs_title ON json_documents(doc_title);

-- Verify table structure
DESC json_documents;

-- Exit
EXIT;
```

**Expected Output:**
```
Name                Null?    Type
------------------ -------- -----------
DOC_ID             NOT NULL NUMBER
DOC_METADATA              JSON
DOC_TITLE                 VARCHAR2(500)
DOC_TEXT                  CLOB
EMBEDDING                 VECTOR(384)
CREATED_DATE              DATE
UPDATED_DATE              DATE
```

### Step 2: Insert JSON Data with Relational Fields

**Objective:** Populate table with JSON documents and corresponding relational data.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Insert JSON documents
INSERT INTO json_documents (doc_id, doc_metadata, doc_title, doc_text, embedding)
VALUES (
  1,
  JSON_OBJECT(
    'title' VALUE 'Machine Learning Guide',
    'author' VALUE 'John Doe',
    'tags' VALUE JSON_ARRAY('AI', 'ML', 'algorithms'),
    'keywords' VALUE 'supervised learning, classification, regression',
    'source' VALUE 'internal_wiki',
    'version' VALUE 2,
    'language' VALUE 'en'
  ),
  'Machine Learning Guide',
  'A comprehensive guide to machine learning concepts, algorithms, and best practices...',
  VECTOR('[0.12, 0.34, -0.23, ... 0.89]',384)
);

INSERT INTO json_documents (doc_id, doc_metadata, doc_title, doc_text, embedding)
VALUES (
  2,
  JSON_OBJECT(
    'title' VALUE 'Deep Learning Primer',
    'author' VALUE 'Jane Smith',
    'tags' VALUE JSON_ARRAY('AI', 'DeepLearning', 'neural_networks'),
    'keywords' VALUE 'neural networks, backpropagation, optimization',
    'source' VALUE 'external_research',
    'version' VALUE 1,
    'language' VALUE 'en'
  ),
  'Deep Learning Primer',
  'Introduction to deep learning concepts using neural networks...',
  VECTOR('[0.23, -0.12, 0.56, ... 0.45]',384)
);

INSERT INTO json_documents (doc_id, doc_metadata, doc_title, doc_text, embedding)
VALUES (
  3,
  JSON_OBJECT(
    'title' VALUE 'Oracle 23AI Features',
    'author' VALUE 'Admin Team',
    'tags' VALUE JSON_ARRAY('Database', 'Oracle', 'AI', 'Vectors'),
    'keywords' VALUE 'vector database, AI integration, JSON storage',
    'source' VALUE 'official_docs',
    'version' VALUE 3,
    'language' VALUE 'en'
  ),
  'Oracle 23AI Features',
  'Comprehensive overview of new features in Oracle Database 23AI...',
  VECTOR('[0.34, 0.56, 0.12, ... 0.67]',384)
);

COMMIT;

-- Verify data inserted
SELECT doc_id, doc_title FROM json_documents;

-- Exit
EXIT;
```

### Step 3: Query JSON Fields Using Relational Syntax

**Objective:** Demonstrate JSON relational duality – accessing JSON as if it were columns.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Query JSON values using JSON_VALUE function
SELECT 
  doc_id,
  doc_title,
  JSON_VALUE(doc_metadata, '$.author') AS author,
  JSON_VALUE(doc_metadata, '$.source') AS source,
  JSON_VALUE(doc_metadata, '$.language') AS language
FROM json_documents
ORDER BY doc_id;

-- Query with filter on JSON field
SELECT 
  doc_id,
  doc_title,
  JSON_VALUE(doc_metadata, '$.author') AS author
FROM json_documents
WHERE JSON_VALUE(doc_metadata, '$.source') = 'internal_wiki'
ORDER BY doc_id;

-- Extract and search within JSON arrays
SELECT 
  doc_id,
  doc_title,
  JSON_QUERY(doc_metadata, '$.tags[*]') AS tags
FROM json_documents
ORDER BY doc_id;

-- Exit
EXIT;
```

**Expected Output:**
```
DOC_ID DOC_TITLE              AUTHOR       SOURCE          LANGUAGE
------ ---------------------- ------------ --------------- --------
1      Machine Learning Guide John Doe     internal_wiki   en
2      Deep Learning Primer   Jane Smith   external_research en
3      Oracle 23AI Features   Admin Team   official_docs   en

DOC_ID DOC_TITLE              AUTHOR
------ ---------------------- ----------
1      Machine Learning Guide John Doe

DOC_ID DOC_TITLE              TAGS
------ ---------------------- --------------------------------
1      Machine Learning Guide ["AI","ML","algorithms"]
2      Deep Learning Primer   ["AI","DeepLearning","neural_networks"]
3      Oracle 23AI Features   ["Database","Oracle","AI","Vectors"]
```

### Step 4: Create Indexes for Efficient JSON Queries

**Objective:** Optimize JSON field access with indexes.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Create functional indexes on commonly queried JSON fields
CREATE INDEX idx_json_author ON json_documents(JSON_VALUE(doc_metadata, '$.author'));
CREATE INDEX idx_json_source ON json_documents(JSON_VALUE(doc_metadata, '$.source'));
CREATE INDEX idx_json_tags ON json_documents(JSON_QUERY(doc_metadata, '$.tags[*]'));

-- Verify indexes created
SELECT index_name, index_type FROM user_indexes 
WHERE table_name = 'JSON_DOCUMENTS'
ORDER BY index_name;

-- Exit
EXIT;
```

**Expected Output:**
```
INDEX_NAME           INDEX_TYPE
-------------------- ----------
IDX_JSON_AUTHOR      NORMAL
IDX_JSON_METADATA    JSONB (or JSON)
IDX_JSON_SOURCE      NORMAL
IDX_JSON_TAGS        NORMAL
IDX_JSON_DOCS_TITLE  NORMAL
```

---

## Semantic Search Implementation Phase

### Step 5: Build Combined Vector-JSON Search Queries

**Objective:** Create sophisticated searches combining vector similarity with JSON metadata filtering.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Semantic search with JSON metadata filters
-- Find documents about AI by specific authors
DEFINE query_vector = "VECTOR('[0.15, 0.32, -0.18, ... 0.88]',384)"

SELECT 
  doc_id,
  doc_title,
  JSON_VALUE(doc_metadata, '$.author') AS author,
  JSON_VALUE(doc_metadata, '$.source') AS source,
  ROUND(1 - VECTOR_DISTANCE(embedding, &query_vector, COSINE), 4) AS relevance_score
FROM json_documents
WHERE JSON_VALUE(doc_metadata, '$.source') IN ('internal_wiki', 'official_docs')
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, COSINE)
FETCH FIRST 5 ROWS ONLY;

-- More complex filter: Find AI documents from specific authors
SELECT 
  doc_id,
  doc_title,
  JSON_VALUE(doc_metadata, '$.author') AS author,
  JSON_VALUE(doc_metadata, '$.version') AS version,
  ROUND(1 - VECTOR_DISTANCE(embedding, &query_vector, COSINE), 4) AS score
FROM json_documents
WHERE JSON_VALUE(doc_metadata, '$.author') IN ('John Doe', 'Admin Team')
  AND JSON_VALUE(doc_metadata, '$.version') >= '1'
ORDER BY VECTOR_DISTANCE(embedding, &query_vector, COSINE);

-- Exit
EXIT;
```

### Step 6: Create Database Views for API Integration

**Objective:** Create reusable views that API layer can query directly.

**SQL Commands:**

```bash
sqlplus vector_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: VectorPass123

-- Create view for semantic search results
CREATE OR REPLACE VIEW v_semantic_search AS
SELECT 
  doc_id,
  doc_title,
  doc_text,
  JSON_VALUE(doc_metadata, '$.author') AS author,
  JSON_VALUE(doc_metadata, '$.source') AS source,
  JSON_QUERY(doc_metadata, '$.tags[*]') AS tags,
  JSON_VALUE(doc_metadata, '$.keywords') AS keywords,
  created_date,
  updated_date
FROM json_documents;

-- Create view for document metadata
CREATE OR REPLACE VIEW v_document_metadata AS
SELECT 
  doc_id,
  doc_title,
  JSON_VALUE(doc_metadata, '$.author') AS author,
  JSON_VALUE(doc_metadata, '$.source') AS source,
  JSON_VALUE(doc_metadata, '$.version') AS version,
  JSON_VALUE(doc_metadata, '$.language') AS language,
  CAST(JSON_VALUE(doc_metadata, '$.version') AS NUMBER) AS version_num
FROM json_documents;

-- Test views
SELECT * FROM v_document_metadata;

-- Exit
EXIT;
```

---

## Semantic Search API Development Phase

### Step 7: Build Python Semantic Search API

**Objective:** Develop a Flask-based API that performs semantic searches against Oracle database.

**Python API Code:**

```bash
# Create Python API script
cat > /tmp/semantic_search_api.py << 'EOF'
#!/usr/bin/env python3

"""
Oracle 23AI Semantic Search API
================================
Simple API for semantic search combining vector similarity and JSON filtering.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import cx_Oracle
import json
from datetime import datetime
import logging

# Configuration
DB_CONFIG = {
    'user': 'vector_user',
    'password': 'VectorPass123',
    'dsn': 'localhost:1521/pdb1',  # Adjust to your environment
    'events': False
}

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database connection pool
def get_db_connection():
    """Create database connection"""
    try:
        conn = cx_Oracle.connect(**DB_CONFIG)
        return conn
    except cx_Oracle.Error as e:
        logger.error(f"Database connection error: {e}")
        raise

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM dual")
        cursor.close()
        conn.close()
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat()
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

@app.route('/api/search', methods=['POST'])
def semantic_search():
    """
    Semantic search endpoint
    
    Request JSON:
    {
        "query": "machine learning algorithms",
        "embedding": [0.12, 0.34, ..., 0.89],  # 384-dim vector
        "limit": 5,
        "filters": {
            "source": "internal_wiki",
            "author": "John Doe"
        }
    }
    """
    try:
        data = request.json
        
        # Validate required fields
        if 'embedding' not in data:
            return jsonify({'error': 'Missing embedding vector'}), 400
        
        embedding = data['embedding']
        limit = data.get('limit', 5)
        filters = data.get('filters', {})
        
        # Validate embedding dimensions
        if len(embedding) != 384:
            return jsonify({'error': f'Invalid embedding dimensions. Expected 384, got {len(embedding)}'}), 400
        
        # Build query
        query = """
        SELECT 
          doc_id,
          doc_title,
          JSON_VALUE(doc_metadata, '$.author') AS author,
          JSON_VALUE(doc_metadata, '$.source') AS source,
          ROUND(1 - VECTOR_DISTANCE(embedding, :embedding, COSINE), 4) AS relevance_score
        FROM json_documents
        WHERE 1=1
        """
        
        params = {'embedding': embedding}
        
        # Add dynamic filters
        filter_idx = 1
        if filters.get('source'):
            query += f" AND JSON_VALUE(doc_metadata, '$.source') = :source"
            params['source'] = filters['source']
        
        if filters.get('author'):
            query += f" AND JSON_VALUE(doc_metadata, '$.author') = :author"
            params['author'] = filters['author']
        
        # Add ordering and limit
        query += f"""
        ORDER BY VECTOR_DISTANCE(embedding, :embedding, COSINE)
        FETCH FIRST {limit} ROWS ONLY
        """
        
        # Execute query
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(query, params)
        
        # Format results
        columns = [desc[0].lower() for desc in cursor.description]
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'status': 'success',
            'count': len(results),
            'results': results,
            'timestamp': datetime.now().isoformat()
        }), 200
    
    except Exception as e:
        logger.error(f"Search error: {e}")
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500

@app.route('/api/documents', methods=['GET'])
def list_documents():
    """List all documents"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
        SELECT 
          doc_id,
          doc_title,
          JSON_VALUE(doc_metadata, '$.author') AS author,
          JSON_VALUE(doc_metadata, '$.source') AS source,
          created_date
        FROM json_documents
        ORDER BY doc_id
        """)
        
        columns = [desc[0].lower() for desc in cursor.description]
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'status': 'success',
            'count': len(results),
            'documents': results
        }), 200
    
    except Exception as e:
        logger.error(f"List documents error: {e}")
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500

@app.route('/api/documents/<int:doc_id>', methods=['GET'])
def get_document(doc_id):
    """Get single document details"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
        SELECT 
          doc_id,
          doc_title,
          doc_text,
          doc_metadata,
          created_date,
          updated_date
        FROM json_documents
        WHERE doc_id = :doc_id
        """, {'doc_id': doc_id})
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            return jsonify({'status': 'error', 'message': 'Document not found'}), 404
        
        result = {
            'doc_id': row[0],
            'title': row[1],
            'text': row[2],
            'metadata': json.loads(row[3]),
            'created_date': str(row[4]),
            'updated_date': str(row[5])
        }
        
        return jsonify({
            'status': 'success',
            'document': result
        }), 200
    
    except Exception as e:
        logger.error(f"Get document error: {e}")
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500

if __name__ == '__main__':
    logger.info("Starting Semantic Search API...")
    logger.info("Available endpoints:")
    logger.info("  GET  /api/health - Health check")
    logger.info("  GET  /api/documents - List all documents")
    logger.info("  GET  /api/documents/<id> - Get document details")
    logger.info("  POST /api/search - Perform semantic search")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

chmod +x /tmp/semantic_search_api.py
```

**Install Required Python Packages:**

```bash
pip install flask flask-cors cx-Oracle numpy
```

### Step 8: Test API Endpoints

**Objective:** Verify API functionality with sample requests.

**Start API Server:**

```bash
cd /tmp
python3 semantic_search_api.py

# Output should show:
# Starting Semantic Search API...
# Running on http://0.0.0.0:5000
```

**Test Health Check (New Terminal):**

```bash
curl http://localhost:5000/api/health

# Expected output:
# {"status": "healthy", "timestamp": "2025-11-25T10:30:00.123456"}
```

**List Documents:**

```bash
curl http://localhost:5000/api/documents

# Expected output:
# {
#   "status": "success",
#   "count": 3,
#   "documents": [
#     {"doc_id": 1, "doc_title": "Machine Learning Guide", ...},
#     ...
#   ]
# }
```

**Get Single Document:**

```bash
curl http://localhost:5000/api/documents/1

# Expected output:
# {
#   "status": "success",
#   "document": {
#     "doc_id": 1,
#     "title": "Machine Learning Guide",
#     "text": "...",
#     "metadata": {...},
#     ...
#   }
# }
```

**Semantic Search with Filters:**

```bash
curl -X POST http://localhost:5000/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "machine learning",
    "embedding": [0.12, 0.34, -0.23, 0.45, ...], # 384 dimensions
    "limit": 5,
    "filters": {
      "source": "internal_wiki"
    }
  }'

# Expected output:
# {
#   "status": "success",
#   "count": 2,
#   "results": [
#     {
#       "doc_id": 1,
#       "doc_title": "Machine Learning Guide",
#       "author": "John Doe",
#       "source": "internal_wiki",
#       "relevance_score": 0.875
#     },
#     ...
#   ]
# }
```

---

## Lab Completion Checklist – Day 4

- [ ] JSON-enabled table created with vector column
- [ ] JSON search index created for metadata queries
- [ ] Sample JSON documents inserted (min 3 documents)
- [ ] JSON relational duality queries tested
- [ ] JSON field extraction working (JSON_VALUE, JSON_QUERY)
- [ ] Functional indexes on JSON fields created
- [ ] Combined vector-JSON search queries working
- [ ] Database views created for API integration (`v_semantic_search`, `v_document_metadata`)
- [ ] Python Flask API developed and tested
- [ ] All API endpoints responding correctly
- [ ] Semantic search with filters working
- [ ] Health check endpoint operational
- [ ] Error handling implemented in API
- [ ] Document: API architecture, endpoint specifications, integration patterns

---

# Day 5 – End-to-End AI Project Lab

**Learning Objectives:**
- Design complete AI-enabled data architecture
- Ingest documents and generate embeddings
- Build production-grade semantic search pipeline
- Integrate with Large Language Models (LLM)
- Demonstrate end-to-end question-answering system

---

## Project Planning and Setup Phase

### Step 1: Define Project Scope and Architecture

**Objective:** Design the complete system architecture for enterprise knowledge search and Q&A.

**System Architecture Diagram:**

```
┌─────────────────────┐
│   User Interface    │
│   (Web/Mobile)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Question Query     │
│  Processing Layer   │
└──────────┬──────────┘
           │
    ┌──────┴───────┐
    ▼              ▼
┌───────────┐  ┌──────────────┐
│Embeddings │  │ Search Query │
│Generator  │  │ Processor    │
└─────┬─────┘  └──────┬───────┘
      │               │
      └───────┬───────┘
              ▼
    ┌──────────────────┐
    │ Oracle 23AI DB   │
    │ - Vector Index   │
    │ - JSON Metadata  │
    │ - Full Text      │
    └────────┬─────────┘
             │
         ┌───┴───┐
         ▼       ▼
    ┌────────┐  ┌──────────┐
    │ Search │  │ Retrieved│
    │ Results│  │ Chunks   │
    └────┬───┘  └────┬─────┘
         │           │
         └─────┬─────┘
               ▼
    ┌──────────────────┐
    │  LLM Service     │
    │  (OpenAI/Local)  │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  Final Answer    │
    │  + References    │
    └──────────────────┘
```

**Project Components:**

1. **Data Ingestion:** Document collection, parsing, chunking
2. **Embedding Generation:** Convert chunks to vectors
3. **Storage:** Oracle 23AI with vector indexes and JSON metadata
4. **Search Engine:** Semantic search with similarity ranking
5. **LLM Integration:** Context injection for answer generation
6. **API Layer:** REST API for application integration
7. **Monitoring:** Performance metrics and logging

### Step 2: Prepare Documents for Ingestion

**Objective:** Collect, clean, and chunk documents for embedding generation.

**Document Preparation Script:**

```bash
cat > /tmp/prepare_documents.py << 'EOF'
#!/usr/bin/env python3

"""
Document Preparation Pipeline
==============================
Prepare documents for embedding generation
"""

import os
import json
from pathlib import Path
from typing import List, Dict
import re

class DocumentProcessor:
    def __init__(self, chunk_size=500, overlap=50):
        self.chunk_size = chunk_size  # Characters per chunk
        self.overlap = overlap        # Overlap between chunks
    
    def chunk_document(self, text: str, doc_id: str, doc_title: str) -> List[Dict]:
        """Split document into overlapping chunks"""
        chunks = []
        chunk_num = 0
        
        # Clean text
        text = self.clean_text(text)
        
        # Create overlapping chunks
        start = 0
        while start < len(text):
            end = start + self.chunk_size
            chunk_text = text[start:end].strip()
            
            if chunk_text:
                chunk_id = f"{doc_id}_chunk_{chunk_num}"
                chunks.append({
                    'chunk_id': chunk_id,
                    'doc_id': doc_id,
                    'doc_title': doc_title,
                    'chunk_number': chunk_num,
                    'text': chunk_text,
                    'start_offset': start,
                    'end_offset': end
                })
                chunk_num += 1
            
            # Move start position with overlap
            start = end - self.overlap
        
        return chunks
    
    def clean_text(self, text: str) -> str:
        """Clean and normalize text"""
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove special characters (keep basic punctuation)
        text = re.sub(r'[^\w\s.!?,;:\'"()-]', '', text)
        
        return text.strip()
    
    def process_documents(self, docs: List[Dict]) -> List[Dict]:
        """Process list of documents into chunks"""
        all_chunks = []
        
        for doc in docs:
            print(f"Processing: {doc['title']}")
            chunks = self.chunk_document(doc['text'], doc['id'], doc['title'])
            all_chunks.extend(chunks)
            print(f"  -> Created {len(chunks)} chunks")
        
        return all_chunks

# Sample documents
SAMPLE_DOCUMENTS = [
    {
        'id': 'doc_001',
        'title': 'Oracle Database 23AI Overview',
        'text': '''
        Oracle Database 23AI is the latest generation of Oracle Database, incorporating AI capabilities 
        for enhanced functionality. It includes support for vector data types, JSON storage, and advanced 
        similarity search. Key features include: 1) Vector Data Support: Native vector type with ANN indexes 
        for similarity search, 2) JSON Duality: Relational and JSON access patterns for same data, 
        3) AI Integration: Built-in LLM integration, 4) Performance: Advanced optimization for AI workloads...
        '''
    },
    {
        'id': 'doc_002',
        'title': 'Machine Learning Best Practices',
        'text': '''
        Machine learning success depends on several best practices: Data Quality - Ensure high-quality, 
        representative training data, Feature Engineering - Create meaningful features for models, 
        Model Selection - Choose appropriate algorithms for your problem, Validation - Use proper 
        train/test splits and cross-validation, Monitoring - Track model performance in production...
        '''
    },
    {
        'id': 'doc_003',
        'title': 'Vector Database Design',
        'text': '''
        Vector databases excel at similarity search for embeddings. Design considerations: 
        Dimension Selection - Choose appropriate embedding dimensions (typically 256-1024), 
        Index Type - HNSW provides good balance of speed and accuracy, Distance Metrics - 
        Cosine for normalized embeddings, L2 for others, Scaling - Plan for growth and query volume...
        '''
    }
]

# Main execution
if __name__ == '__main__':
    processor = DocumentProcessor(chunk_size=500, overlap=50)
    
    # Process documents
    chunks = processor.process_documents(SAMPLE_DOCUMENTS)
    
    # Save chunks to JSON
    output_file = '/tmp/document_chunks.json'
    with open(output_file, 'w') as f:
        json.dump(chunks, f, indent=2)
    
    print(f"\n✓ Processed {len(SAMPLE_DOCUMENTS)} documents into {len(chunks)} chunks")
    print(f"✓ Saved to {output_file}")
    
    # Show sample chunk
    print(f"\nSample chunk:\n{json.dumps(chunks[0], indent=2)}")
EOF

python3 /tmp/prepare_documents.py
```

**Expected Output:**

```
Processing: Oracle Database 23AI Overview
  -> Created 3 chunks
Processing: Machine Learning Best Practices
  -> Created 2 chunks
Processing: Vector Database Design
  -> Created 2 chunks

✓ Processed 3 documents into 7 chunks
✓ Saved to /tmp/document_chunks.json
```

### Step 3: Generate Embeddings for Document Chunks

**Objective:** Convert document chunks into vector embeddings using an embedding model.

**Embedding Generation Script:**

```bash
cat > /tmp/generate_embeddings.py << 'EOF'
#!/usr/bin/env python3

"""
Embedding Generation Pipeline
=============================
Generate vector embeddings for document chunks
"""

import json
import numpy as np
from typing import List, Dict
from datetime import datetime
import random

class EmbeddingGenerator:
    def __init__(self, model_name="all-MiniLM-L6-v2", dimension=384):
        self.model_name = model_name
        self.dimension = dimension
        print(f"Initialized with model: {model_name}, dimension: {dimension}")
    
    def generate_embedding(self, text: str) -> List[float]:
        """
        Generate embedding for text
        
        In production, use:
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer('all-MiniLM-L6-v2')
        embedding = model.encode(text)
        
        For lab, generate random embeddings (normalized)
        """
        # Simulate embedding generation
        # In production, replace with actual embedding model
        embedding = np.random.randn(self.dimension)
        # Normalize to unit vector (for cosine similarity)
        embedding = embedding / np.linalg.norm(embedding)
        return embedding.tolist()
    
    def generate_embeddings(self, chunks: List[Dict]) -> List[Dict]:
        """Generate embeddings for all chunks"""
        enriched_chunks = []
        
        for i, chunk in enumerate(chunks, 1):
            print(f"Generating embedding {i}/{len(chunks)}: {chunk['chunk_id']}")
            
            embedding = self.generate_embedding(chunk['text'])
            
            enriched_chunks.append({
                **chunk,
                'embedding': embedding,
                'embedding_model': self.model_name,
                'generated_at': datetime.now().isoformat()
            })
        
        return enriched_chunks

# Main execution
if __name__ == '__main__':
    # Load chunks
    with open('/tmp/document_chunks.json', 'r') as f:
        chunks = json.load(f)
    
    # Generate embeddings
    generator = EmbeddingGenerator(model_name="all-MiniLM-L6-v2", dimension=384)
    enriched_chunks = generator.generate_embeddings(chunks)
    
    # Save with embeddings
    output_file = '/tmp/chunks_with_embeddings.json'
    with open(output_file, 'w') as f:
        json.dump(enriched_chunks, f, indent=2)
    
    print(f"\n✓ Generated {len(enriched_chunks)} embeddings")
    print(f"✓ Saved to {output_file}")
    
    # Show statistics
    print(f"\nEmbedding Statistics:")
    print(f"  Chunks: {len(enriched_chunks)}")
    print(f"  Dimensions: 384")
    print(f"  Model: all-MiniLM-L6-v2")
EOF

python3 /tmp/generate_embeddings.py
```

---

### Step 4: Create Oracle Schema for Project

**Objective:** Set up complete database schema for storing project data.

**SQL Commands:**

```bash
sqlplus sys@orclpdb as sysdba
```

**In SQL*Plus:**

```sql
-- Create project-specific tablespace
CREATE TABLESPACE project_ts
  DATAFILE '/u01/app/oracle/oradata/orcl/project_ts01.dbf' SIZE 5G
  AUTOEXTEND ON NEXT 1G MAXSIZE UNLIMITED;

-- Create project user
CREATE USER project_user 
  IDENTIFIED BY ProjectPass123 
  DEFAULT TABLESPACE project_ts 
  TEMPORARY TABLESPACE temp;

-- Grant privileges
GRANT CREATE SESSION TO project_user;
GRANT CREATE TABLE TO project_user;
GRANT CREATE INDEX TO project_user;
GRANT UNLIMITED TABLESPACE TO project_user;

-- Exit to switch user
EXIT;
```

**As Project User:**

```bash
sqlplus project_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: ProjectPass123

-- Create document chunks table with embeddings
CREATE TABLE project_chunks (
  chunk_id          VARCHAR2(100) PRIMARY KEY,
  doc_id            VARCHAR2(50),
  doc_title         VARCHAR2(500),
  chunk_number      NUMBER,
  text_content      CLOB,
  embedding         VECTOR(384),
  start_offset      NUMBER,
  end_offset        NUMBER,
  embedding_model   VARCHAR2(100),
  generated_at      TIMESTAMP,
  ingested_at       TIMESTAMP DEFAULT SYSDATE,
  processed_status  VARCHAR2(20) DEFAULT 'PENDING'
);

-- Create metadata table
CREATE TABLE project_metadata (
  doc_id            VARCHAR2(50) PRIMARY KEY,
  doc_title         VARCHAR2(500),
  doc_source        VARCHAR2(200),
  doc_category      VARCHAR2(100),
  doc_language      VARCHAR2(20),
  chunk_count       NUMBER,
  total_chars       NUMBER,
  created_at        TIMESTAMP DEFAULT SYSDATE,
  updated_at        TIMESTAMP DEFAULT SYSDATE,
  metadata_json     JSON
);

-- Create search results cache
CREATE TABLE search_results_cache (
  query_hash        VARCHAR2(64) PRIMARY KEY,
  query_text        VARCHAR2(2000),
  embedding         VECTOR(384),
  results_json      CLOB,
  result_count      NUMBER,
  execution_time_ms NUMBER,
  created_at        TIMESTAMP DEFAULT SYSDATE,
  ttl_expiry        TIMESTAMP
);

-- Create answer cache for LLM results
CREATE TABLE llm_answers_cache (
  answer_id         VARCHAR2(100) PRIMARY KEY,
  query_text        VARCHAR2(2000),
  retrieved_chunks  NUMBER,
  answer_text       CLOB,
  confidence_score  NUMBER,
  processing_time_ms NUMBER,
  model_version     VARCHAR2(50),
  created_at        TIMESTAMP DEFAULT SYSDATE
);

-- Create indexes
CREATE INDEX idx_project_doc_id ON project_chunks(doc_id);
CREATE INDEX idx_project_title ON project_chunks(doc_title);
CREATE INDEX idx_project_status ON project_chunks(processed_status);
CREATE INDEX idx_metadata_category ON project_metadata(doc_category);
CREATE INDEX idx_cache_expiry ON search_results_cache(ttl_expiry);

-- Create vector index for similarity search
CREATE INDEX idx_project_embedding 
  ON project_chunks(embedding) 
  INDEXTYPE IS VECTOR_AI_HNSW 
  PARAMETERS ('M=16', 'ef_construction=200');

-- Verify tables
SELECT table_name FROM user_tables WHERE table_name LIKE 'PROJECT%' OR table_name LIKE '%CACHE';

-- Exit
EXIT;
```

**Expected Output:**

```
TABLE_NAME
-------------------
PROJECT_CHUNKS
PROJECT_METADATA
SEARCH_RESULTS_CACHE
LLM_ANSWERS_CACHE
```

---

### Step 5: Ingest Data into Oracle

**Objective:** Load processed embeddings and metadata into Oracle database.

**Data Ingestion Script:**

```bash
cat > /tmp/ingest_data.py << 'EOF'
#!/usr/bin/env python3

"""
Data Ingestion Pipeline
=======================
Load document chunks with embeddings into Oracle 23AI
"""

import json
import cx_Oracle
from datetime import datetime, timedelta
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class OracleDataIngestor:
    def __init__(self, user, password, dsn):
        self.user = user
        self.password = password
        self.dsn = dsn
        self.conn = None
    
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = cx_Oracle.connect(
                user=self.user,
                password=self.password,
                dsn=self.dsn
            )
            logger.info(f"Connected to Oracle database: {self.dsn}")
        except cx_Oracle.Error as e:
            logger.error(f"Connection error: {e}")
            raise
    
    def disconnect(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
            logger.info("Disconnected from database")
    
    def ingest_chunks(self, chunks: list):
        """Ingest document chunks into database"""
        cursor = self.conn.cursor()
        batch_size = 100
        inserted = 0
        
        try:
            for i, chunk in enumerate(chunks):
                # Format embedding as string representation
                embedding_str = ','.join([str(x) for x in chunk['embedding']])
                
                # Insert chunk
                cursor.execute("""
                    INSERT INTO project_chunks 
                    (chunk_id, doc_id, doc_title, chunk_number, text_content, 
                     embedding, start_offset, end_offset, embedding_model, 
                     generated_at, processed_status)
                    VALUES (:1, :2, :3, :4, :5, VECTOR(:6, 384), :7, :8, :9, :10, 'READY')
                """, (
                    chunk['chunk_id'],
                    chunk['doc_id'],
                    chunk['doc_title'],
                    chunk['chunk_number'],
                    chunk['text'],
                    embedding_str,
                    chunk['start_offset'],
                    chunk['end_offset'],
                    chunk['embedding_model'],
                    datetime.fromisoformat(chunk['generated_at'])
                ))
                
                inserted += 1
                
                # Commit in batches
                if (i + 1) % batch_size == 0:
                    self.conn.commit()
                    logger.info(f"Ingested {inserted}/{len(chunks)} chunks")
            
            # Final commit
            self.conn.commit()
            logger.info(f"✓ Successfully ingested all {inserted} chunks")
            
        except cx_Oracle.Error as e:
            self.conn.rollback()
            logger.error(f"Ingestion error: {e}")
            raise
        finally:
            cursor.close()
    
    def ingest_metadata(self, chunks: list):
        """Ingest document metadata"""
        cursor = self.conn.cursor()
        
        try:
            # Group chunks by document
            docs = {}
            for chunk in chunks:
                doc_id = chunk['doc_id']
                if doc_id not in docs:
                    docs[doc_id] = {
                        'title': chunk['doc_title'],
                        'chunks': 0,
                        'total_chars': 0
                    }
                docs[doc_id]['chunks'] += 1
                docs[doc_id]['total_chars'] += len(chunk['text'])
            
            # Insert metadata
            for doc_id, info in docs.items():
                metadata = {
                    'source': 'lab_project',
                    'category': 'training',
                    'indexed': True
                }
                
                cursor.execute("""
                    INSERT INTO project_metadata
                    (doc_id, doc_title, doc_source, doc_category, doc_language, 
                     chunk_count, total_chars, metadata_json)
                    VALUES (:1, :2, :3, :4, :5, :6, :7, :8)
                """, (
                    doc_id,
                    info['title'],
                    'lab_project',
                    'training',
                    'en',
                    info['chunks'],
                    info['total_chars'],
                    json.dumps(metadata)
                ))
            
            self.conn.commit()
            logger.info(f"✓ Ingested metadata for {len(docs)} documents")
            
        except cx_Oracle.Error as e:
            self.conn.rollback()
            logger.error(f"Metadata ingestion error: {e}")
            raise
        finally:
            cursor.close()

# Main execution
if __name__ == '__main__':
    # Load embeddings
    with open('/tmp/chunks_with_embeddings.json', 'r') as f:
        chunks = json.load(f)
    
    # Create ingestor
    ingestor = OracleDataIngestor(
        user='project_user',
        password='ProjectPass123',
        dsn='localhost:1521/pdb1'  # Adjust to your environment
    )
    
    try:
        # Connect
        ingestor.connect()
        
        # Ingest chunks
        ingestor.ingest_chunks(chunks)
        
        # Ingest metadata
        ingestor.ingest_metadata(chunks)
        
        logger.info("✓ Data ingestion completed successfully")
        
    finally:
        ingestor.disconnect()
EOF

python3 /tmp/ingest_data.py
```

**Verify Ingestion:**

```bash
sqlplus project_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: ProjectPass123

-- Check ingested chunks
SELECT chunk_id, doc_title, COUNT(*) as chunk_count
FROM project_chunks
GROUP BY chunk_id, doc_title
ORDER BY doc_title;

-- Check metadata
SELECT doc_id, doc_title, chunk_count, total_chars FROM project_metadata;

-- Verify index was used
SELECT COUNT(*) as total_embeddings FROM project_chunks WHERE embedding IS NOT NULL;

-- Exit
EXIT;
```

---

### Step 6: Build and Optimize Vector Index

**Objective:** Create efficient HNSW index for semantic search.

**SQL Commands:**

```bash
sqlplus project_user@orclpdb
```

**In SQL*Plus:**

```sql
-- Password: ProjectPass123

-- Check if index exists
SELECT index_name, status FROM user_indexes 
WHERE table_name = 'PROJECT_CHUNKS' AND index_name LIKE 'IDX%EMBEDDING%';

-- Get index statistics
SELECT index_name, distinct_keys, leaf_blocks FROM user_ind_statistics 
WHERE table_name = 'PROJECT_CHUNKS' AND index_name LIKE 'IDX%EMBEDDING%';

-- Test index usage with EXPLAIN PLAN
EXPLAIN PLAN FOR
SELECT chunk_id, doc_title FROM project_chunks 
ORDER BY VECTOR_DISTANCE(embedding, VECTOR('[0.1, 0.2, ..., 0.384]', 384), COSINE)
FETCH FIRST 10 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

-- Exit
EXIT;
```

---

### Step 7: Implement Semantic Search Pipeline

**Objective:** Create production semantic search query engine.

**Semantic Search Script:**

```bash
cat > /tmp/semantic_search_engine.py << 'EOF'
#!/usr/bin/env python3

"""
Semantic Search Engine
======================
Query engine for Oracle 23AI semantic search
"""

import cx_Oracle
import json
import hashlib
from datetime import datetime, timedelta
from typing import List, Dict, Tuple

class SemanticSearchEngine:
    def __init__(self, user, password, dsn):
        self.user = user
        self.password = password
        self.dsn = dsn
        self.conn = None
    
    def connect(self):
        """Connect to database"""
        self.conn = cx_Oracle.connect(
            user=self.user,
            password=self.password,
            dsn=self.dsn
        )
    
    def disconnect(self):
        """Disconnect from database"""
        if self.conn:
            self.conn.close()
    
    def search_chunks(self, query_embedding: List[float], limit: int = 5,
                     filters: Dict = None) -> Tuple[List[Dict], float]:
        """
        Search for similar chunks
        
        Returns:
            (results list, execution time in ms)
        """
        cursor = self.conn.cursor()
        
        try:
            # Convert embedding to string format
            embedding_str = ','.join([str(x) for x in query_embedding])
            
            # Build query
            query = """
            SELECT chunk_id, doc_id, doc_title, text_content,
                   ROUND(1 - VECTOR_DISTANCE(embedding, VECTOR(:embedding, 384), COSINE), 4) AS similarity_score,
                   chunk_number, doc_title
            FROM project_chunks
            WHERE processed_status = 'READY'
            """
            
            params = [embedding_str]
            
            # Add filters if provided
            if filters and 'doc_id' in filters:
                query += " AND doc_id = :doc_id"
                params.append(filters['doc_id'])
            
            if filters and 'category' in filters:
                query += " AND doc_title LIKE :category"
                params.append(f"%{filters['category']}%")
            
            # Add ordering and limit
            query += f"""
            ORDER BY VECTOR_DISTANCE(embedding, VECTOR(:embedding, 384), COSINE)
            FETCH FIRST {limit} ROWS ONLY
            """
            
            # Execute with timing
            import time
            start_time = time.time()
            cursor.execute(query, params)
            results = cursor.fetchall()
            exec_time_ms = (time.time() - start_time) * 1000
            
            # Format results
            formatted_results = []
            for row in results:
                formatted_results.append({
                    'chunk_id': row[0],
                    'doc_id': row[1],
                    'doc_title': row[2],
                    'text': row[3][:500],  # First 500 chars
                    'similarity_score': float(row[4]),
                    'chunk_number': row[5]
                })
            
            return formatted_results, exec_time_ms
        
        finally:
            cursor.close()
    
    def cache_search_results(self, query_text: str, query_embedding: List[float],
                           results: List[Dict], exec_time_ms: float):
        """Cache search results"""
        cursor = self.conn.cursor()
        
        try:
            query_hash = hashlib.sha256(query_text.encode()).hexdigest()
            
            cursor.execute("""
                INSERT INTO search_results_cache
                (query_hash, query_text, embedding, results_json, result_count, execution_time_ms, ttl_expiry)
                VALUES (:1, :2, VECTOR(:3, 384), :4, :5, :6, :7)
            """, (
                query_hash,
                query_text,
                ','.join([str(x) for x in query_embedding]),
                json.dumps(results),
                len(results),
                exec_time_ms,
                datetime.now() + timedelta(hours=24)
            ))
            
            self.conn.commit()
        
        finally:
            cursor.close()

# Main test
if __name__ == '__main__':
    engine = SemanticSearchEngine(
        user='project_user',
        password='ProjectPass123',
        dsn='localhost:1521/pdb1'
    )
    
    try:
        engine.connect()
        
        # Test query
        test_embedding = [0.1] * 384  # Dummy embedding for testing
        
        results, exec_time = engine.search_chunks(
            query_embedding=test_embedding,
            limit=5,
            filters={'category': 'Oracle'}
        )
        
        print(f"Search completed in {exec_time:.2f}ms")
        print(f"Found {len(results)} results:\n")
        
        for result in results:
            print(f"  - {result['chunk_id']}: {result['doc_title']}")
            print(f"    Similarity: {result['similarity_score']}")
            print()
        
    finally:
        engine.disconnect()
EOF

python3 /tmp/semantic_search_engine.py
```

---

### Step 8: Integrate with LLM for Question Answering

**Objective:** Build end-to-end Q&A system with LLM integration.

**LLM Integration Script:**

```bash
cat > /tmp/qa_system.py << 'EOF'
#!/usr/bin/env python3

"""
Question Answering System
=========================
Complete Q&A pipeline with LLM integration
"""

import json
import cx_Oracle
import hashlib
from datetime import datetime
from typing import List, Dict, Tuple

class QASystem:
    def __init__(self, user, password, dsn, llm_model='mock'):
        self.user = user
        self.password = password
        self.dsn = dsn
        self.llm_model = llm_model
        self.conn = None
    
    def connect(self):
        """Connect to database"""
        self.conn = cx_Oracle.connect(
            user=self.user,
            password=self.password,
            dsn=self.dsn
        )
    
    def disconnect(self):
        """Disconnect from database"""
        if self.conn:
            self.conn.close()
    
    def generate_query_embedding(self, query_text: str) -> List[float]:
        """
        Generate embedding for user query
        
        In production, use embedding model
        For lab, return mock embedding
        """
        import hashlib
        import random
        
        # Seed random with query for reproducibility
        random.seed(int(hashlib.md5(query_text.encode()).hexdigest(), 16))
        
        # Generate 384-dim embedding
        return [random.gauss(0, 1) for _ in range(384)]
    
    def search_relevant_chunks(self, query_embedding: List[float], limit: int = 5) -> List[Dict]:
        """Search for relevant document chunks"""
        cursor = self.conn.cursor()
        
        try:
            embedding_str = ','.join([str(x) for x in query_embedding])
            
            cursor.execute(f"""
                SELECT chunk_id, doc_id, doc_title, text_content,
                       ROUND(1 - VECTOR_DISTANCE(embedding, VECTOR('{embedding_str}', 384), COSINE), 4)
                FROM project_chunks
                WHERE processed_status = 'READY'
                ORDER BY VECTOR_DISTANCE(embedding, VECTOR('{embedding_str}', 384), COSINE)
                FETCH FIRST {limit} ROWS ONLY
            """)
            
            results = []
            for row in cursor.fetchall():
                results.append({
                    'chunk_id': row[0],
                    'doc_id': row[1],
                    'doc_title': row[2],
                    'text': row[3],
                    'score': float(row[4])
                })
            
            return results
        
        finally:
            cursor.close()
    
    def generate_answer_with_llm(self, query: str, context_chunks: List[Dict]) -> str:
        """
        Generate answer using LLM with context
        
        In production, call actual LLM API (OpenAI, Claude, etc.)
        For lab, generate mock answer
        """
        
        # Mock LLM response (in production, integrate with actual API)
        mock_answers = {
            'oracle': "Oracle 23AI is the latest generation of Oracle Database with AI capabilities...",
            'vector': "Vector databases store and search high-dimensional embeddings efficiently...",
            'embedding': "Embeddings are numerical representations of text used for similarity search...",
            'default': f"Based on the retrieved documents: {', '.join([c['doc_title'] for c in context_chunks[:3]])}"
        }
        
        query_lower = query.lower()
        for key, answer in mock_answers.items():
            if key in query_lower:
                return answer
        
        return mock_answers['default']
    
    def answer_question(self, question: str) -> Dict:
        """
        Complete Q&A pipeline
        
        Steps:
        1. Generate question embedding
        2. Search for relevant chunks
        3. Generate answer with LLM
        4. Cache result
        """
        
        print(f"\n{'='*60}")
        print(f"Question: {question}")
        print(f"{'='*60}")
        
        # Step 1: Generate embedding
        query_embedding = self.generate_query_embedding(question)
        print(f"✓ Generated query embedding (384 dimensions)")
        
        # Step 2: Search relevant chunks
        relevant_chunks = self.search_relevant_chunks(query_embedding, limit=5)
        print(f"✓ Found {len(relevant_chunks)} relevant chunks")
        
        for i, chunk in enumerate(relevant_chunks, 1):
            print(f"  {i}. {chunk['doc_title']} (Score: {chunk['score']})")
        
        # Step 3: Generate answer
        answer = self.generate_answer_with_llm(question, relevant_chunks)
        print(f"\n✓ Generated answer with LLM")
        
        # Step 4: Cache result
        result = {
            'question': question,
            'answer': answer,
            'source_count': len(relevant_chunks),
            'sources': [
                {
                    'doc_title': c['doc_title'],
                    'chunk_id': c['chunk_id'],
                    'relevance': c['score']
                }
                for c in relevant_chunks
            ],
            'timestamp': datetime.now().isoformat()
        }
        
        # Cache in database
        self._cache_answer(question, result)
        
        return result
    
    def _cache_answer(self, question: str, result: Dict):
        """Cache LLM answer in database"""
        cursor = self.conn.cursor()
        
        try:
            answer_id = hashlib.md5(f"{question}{datetime.now()}".encode()).hexdigest()[:20]
            
            cursor.execute("""
                INSERT INTO llm_answers_cache
                (answer_id, query_text, retrieved_chunks, answer_text, confidence_score, model_version)
                VALUES (:1, :2, :3, :4, :5, :6)
            """, (
                answer_id,
                question,
                result['source_count'],
                result['answer'],
                0.85,  # Mock confidence
                self.llm_model
            ))
            
            self.conn.commit()
        
        finally:
            cursor.close()

# Main test
if __name__ == '__main__':
    qa = QASystem(
        user='project_user',
        password='ProjectPass123',
        dsn='localhost:1521/pdb1',
        llm_model='mock-gpt-4'
    )
    
    try:
        qa.connect()
        
        # Test questions
        test_questions = [
            "What is Oracle 23AI?",
            "How does vector database work?",
            "What are embeddings used for?"
        ]
        
        for question in test_questions:
            result = qa.answer_question(question)
            print(f"\nAnswer: {result['answer']}\n")
        
    finally:
        qa.disconnect()
EOF

python3 /tmp/qa_system.py
```

**Expected Output:**

```
============================================================
Question: What is Oracle 23AI?
============================================================
✓ Generated query embedding (384 dimensions)
✓ Found 3 relevant chunks
  1. Oracle Database 23AI Overview (Score: 0.875)
  2. Vector Database Design (Score: 0.742)
  3. Machine Learning Best Practices (Score: 0.698)

✓ Generated answer with LLM

Answer: Oracle 23AI is the latest generation of Oracle Database with AI capabilities...
```

---

### Step 9: Test End-to-End Pipeline

**Objective:** Validate complete system with comprehensive testing.

**Test Script:**

```bash
cat > /tmp/test_pipeline.py << 'EOF'
#!/usr/bin/env python3

"""
End-to-End Pipeline Testing
==========================
Comprehensive system validation
"""

import cx_Oracle
import json
from datetime import datetime

class PipelineTester:
    def __init__(self, user, password, dsn):
        self.user = user
        self.password = password
        self.dsn = dsn
        self.conn = None
    
    def connect(self):
        self.conn = cx_Oracle.connect(
            user=self.user,
            password=self.password,
            dsn=self.dsn
        )
    
    def disconnect(self):
        if self.conn:
            self.conn.close()
    
    def test_data_ingestion(self):
        """Test 1: Verify data was ingested correctly"""
        print("\n[TEST 1] Data Ingestion Verification")
        print("-" * 50)
        
        cursor = self.conn.cursor()
        
        # Check chunks count
        cursor.execute("SELECT COUNT(*) FROM project_chunks")
        chunk_count = cursor.fetchone()[0]
        print(f"✓ Total chunks ingested: {chunk_count}")
        
        # Check embeddings
        cursor.execute("SELECT COUNT(*) FROM project_chunks WHERE embedding IS NOT NULL")
        embedding_count = cursor.fetchone()[0]
        print(f"✓ Chunks with embeddings: {embedding_count}")
        
        # Check metadata
        cursor.execute("SELECT COUNT(*) FROM project_metadata")
        metadata_count = cursor.fetchone()[0]
        print(f"✓ Documents in metadata: {metadata_count}")
        
        cursor.close()
    
    def test_vector_index(self):
        """Test 2: Verify vector index functionality"""
        print("\n[TEST 2] Vector Index Verification")
        print("-" * 50)
        
        cursor = self.conn.cursor()
        
        # Check index exists
        cursor.execute("""
            SELECT index_name, status FROM user_indexes 
            WHERE table_name = 'PROJECT_CHUNKS' AND index_name LIKE 'IDX%EMBEDDING%'
        """)
        
        result = cursor.fetchone()
        if result:
            print(f"✓ Vector index exists: {result[0]}")
            print(f"✓ Index status: {result[1]}")
        else:
            print("✗ Vector index not found")
        
        cursor.close()
    
    def test_semantic_search(self):
        """Test 3: Verify semantic search works"""
        print("\n[TEST 3] Semantic Search Verification")
        print("-" * 50)
        
        cursor = self.conn.cursor()
        
        # Execute similarity search
        test_embedding = "[" + ",".join(["0.1"] * 384) + "]"
        
        cursor.execute(f"""
            SELECT COUNT(*), AVG(sim_score) FROM (
                SELECT ROUND(1 - VECTOR_DISTANCE(embedding, VECTOR('{test_embedding}', 384), COSINE), 4) AS sim_score
                FROM project_chunks
                WHERE ROWNUM <= 10
            )
        """)
        
        result = cursor.fetchone()
        print(f"✓ Similarity search executed")
        print(f"✓ Results returned: {result[0]}")
        print(f"✓ Average similarity: {result[1]:.4f}")
        
        cursor.close()
    
    def test_caching(self):
        """Test 4: Verify caching mechanism"""
        print("\n[TEST 4] Caching Verification")
        print("-" * 50)
        
        cursor = self.conn.cursor()
        
        # Check cache tables
        cursor.execute("SELECT COUNT(*) FROM search_results_cache")
        cache_count = cursor.fetchone()[0]
        print(f"✓ Search results cached: {cache_count}")
        
        cursor.execute("SELECT COUNT(*) FROM llm_answers_cache")
        llm_cache_count = cursor.fetchone()[0]
        print(f"✓ LLM answers cached: {llm_cache_count}")
        
        cursor.close()
    
    def run_all_tests(self):
        """Run all tests"""
        print("\n" + "=" * 50)
        print("END-TO-END PIPELINE TEST SUITE")
        print("=" * 50)
        
        try:
            self.test_data_ingestion()
            self.test_vector_index()
            self.test_semantic_search()
            self.test_caching()
            
            print("\n" + "=" * 50)
            print("✓ ALL TESTS COMPLETED")
            print("=" * 50)
            
        except Exception as e:
            print(f"\n✗ Test failed: {e}")

# Main execution
if __name__ == '__main__':
    tester = PipelineTester(
        user='project_user',
        password='ProjectPass123',
        dsn='localhost:1521/pdb1'
    )
    
    try:
        tester.connect()
        tester.run_all_tests()
    finally:
        tester.disconnect()
EOF

python3 /tmp/test_pipeline.py
```

---

### Step 10: Performance Analysis and Optimization

**Objective:** Analyze system performance and identify optimization opportunities.

**Performance Analysis Script:**

```bash
cat > /tmp/performance_analysis.py << 'EOF'
#!/usr/bin/env python3

"""
Performance Analysis
====================
System performance metrics and optimization recommendations
"""

import cx_Oracle
import time
from datetime import datetime

class PerformanceAnalyzer:
    def __init__(self, user, password, dsn):
        self.user = user
        self.password = password
        self.dsn = dsn
        self.conn = None
    
    def connect(self):
        self.conn = cx_Oracle.connect(
            user=self.user,
            password=self.password,
            dsn=self.dsn
        )
    
    def analyze_query_performance(self):
        """Analyze semantic search query performance"""
        print("\n[ANALYSIS] Query Performance")
        print("-" * 50)
        
        cursor = self.conn.cursor()
        
        # Test query with timing
        test_embedding = "[" + ",".join(["0.1"] * 384) + "]"
        
        queries = [
            ("Top-10 similarity search", f"""
                SELECT chunk_id, ROUND(1 - VECTOR_DISTANCE(embedding, VECTOR('{test_embedding}', 384), COSINE), 4)
                FROM project_chunks
                ORDER BY VECTOR_DISTANCE(embedding, VECTOR('{test_embedding}', 384), COSINE)
                FETCH FIRST 10 ROWS ONLY
            """),
            ("Filtered search with category", f"""
                SELECT chunk_id, ROUND(1 - VECTOR_DISTANCE(embedding, VECTOR('{test_embedding}', 384), COSINE), 4)
                FROM project_chunks
                WHERE doc_title LIKE '%Oracle%'
                ORDER BY VECTOR_DISTANCE(embedding, VECTOR('{test_embedding}', 384), COSINE)
                FETCH FIRST 10 ROWS ONLY
            """)
        ]
        
        for test_name, query in queries:
            times = []
            for i in range(3):  # Run 3 times
                start = time.time()
                cursor.execute(query)
                cursor.fetchall()
                elapsed = (time.time() - start) * 1000
                times.append(elapsed)
            
            avg_time = sum(times) / len(times)
            print(f"✓ {test_name}: {avg_time:.2f}ms (runs: {len(times)})")
        
        cursor.close()
    
    def analyze_index_usage(self):
        """Analyze index statistics"""
        print("\n[ANALYSIS] Index Usage")
        print("-" * 50)
        
        cursor = self.conn.cursor()
        
        # Get index statistics
        cursor.execute("""
            SELECT index_name, distinct_keys, leaf_blocks, blevel
            FROM user_ind_statistics
            WHERE table_name = 'PROJECT_CHUNKS'
        """)
        
        print(f"{'Index Name':<30} {'Distinct Keys':<15} {'Leaf Blocks':<15} {'Levels':<10}")
        print("-" * 70)
        
        for row in cursor.fetchall():
            print(f"{row[0]:<30} {row[1]:<15} {row[2]:<15} {row[3]:<10}")
        
        cursor.close()
    
    def provide_recommendations(self):
        """Provide optimization recommendations"""
        print("\n[RECOMMENDATIONS] Performance Optimization")
        print("-" * 50)
        
        recommendations = [
            "1. Use batch queries for multiple searches",
            "2. Implement result caching with TTL",
            "3. Consider partitioning for large datasets (>1M chunks)",
            "4. Use compression for vector index if supported",
            "5. Monitor query execution plans regularly",
            "6. Implement query result pagination",
            "7. Use connection pooling for API layer",
            "8. Schedule index maintenance during off-peak hours"
        ]
        
        for rec in recommendations:
            print(f"✓ {rec}")

# Main execution
if __name__ == '__main__':
    analyzer = PerformanceAnalyzer(
        user='project_user',
        password='ProjectPass123',
        dsn='localhost:1521/pdb1'
    )
    
    try:
        analyzer.connect()
        analyzer.analyze_query_performance()
        analyzer.analyze_index_usage()
        analyzer.provide_recommendations()
    finally:
        analyzer.conn.close()
EOF

python3 /tmp/performance_analysis.py
```

---

## Lab Completion Checklist – Day 5

- [ ] Project scope and architecture designed
- [ ] Documents prepared and chunked (min 3 documents)
- [ ] Embeddings generated for all chunks (384 dimensions)
- [ ] Oracle schema created for project
- [ ] 7+ document chunks successfully ingested
- [ ] HNSW vector index built and optimized
- [ ] Semantic search engine tested with various queries
- [ ] LLM integration pipeline developed and tested
- [ ] Q&A system end-to-end pipeline functional
- [ ] All 5 core test cases passed
- [ ] Performance analysis completed
- [ ] Response times documented (milliseconds)
- [ ] Query results validated for accuracy
- [ ] System bottlenecks identified
- [ ] Optimization recommendations documented
- [ ] Full architecture diagram created
- [ ] Production deployment checklist created
- [ ] Document: Complete system design, code snippets, performance metrics, lessons learned

---

# Troubleshooting & Common Issues

## Common Problems and Solutions

### Issue 1: "ORA-01031: Insufficient Privileges"

**Symptoms:** Getting permission denied errors when executing SQL commands.

**Solution:**
```sql
-- Check current user privileges
SHOW USER;

-- Grant missing privileges (as SYSDBA)
GRANT CREATE SESSION TO your_user;
GRANT CREATE TABLE TO your_user;
GRANT UNLIMITED TABLESPACE TO your_user;
```

### Issue 2: "ORA-00904: Invalid Column Name"

**Symptoms:** Column name not recognized in SQL statements.

**Solution:**
```sql
-- Verify column names exist
DESC table_name;

-- Use correct case (Oracle columns are uppercase by default)
SELECT COL_NAME FROM TABLE_NAME;
```

### Issue 3: "Vector dimension mismatch"

**Symptoms:** Getting dimension mismatch errors when inserting vectors.

**Solution:**
```sql
-- Verify vector dimensions match
SELECT VECTOR_DIMENSION(embedding) FROM project_chunks FETCH FIRST 1 ROWS ONLY;

-- Ensure all vectors are 384-dimensional
INSERT INTO project_chunks (..., embedding) 
VALUES (..., VECTOR('[value1, value2, ..., value384]', 384));
```

### Issue 4: Connection timeout from Python

**Symptoms:** Python scripts fail to connect to Oracle database.

**Solution:**
```python
# Verify connection string
dsn = cx_Oracle.makedsn("localhost", 1521, service_name="pdb1")
conn = cx_Oracle.connect("username", "password", dsn)

# Check if database is running
# From Linux: lsnrctl status
```

### Issue 5: "TNS:listener does not currently know of service"

**Symptoms:** Cannot connect using service name from tnsnames.ora.

**Solution:**
```bash
# Verify tnsnames.ora entry exists
cat $ORACLE_HOME/network/admin/tnsnames.ora

# Restart listener
lsnrctl stop
lsnrctl start

# Test connection
sqlplus username@service_name
```

---

# Reference & Quick Commands

## Essential Oracle Commands

### Database Startup/Shutdown

```bash
# Startup database
sqlplus / as sysdba
STARTUP;

# Shutdown immediately
SHUTDOWN IMMEDIATE;

# Shutdown with normal wait
SHUTDOWN NORMAL;
```

### User and Role Management

```sql
-- Create user
CREATE USER username IDENTIFIED BY password;

-- Grant privileges
GRANT CREATE SESSION, CREATE TABLE TO username;

-- Drop user
DROP USER username CASCADE;

-- List users
SELECT username FROM dba_users;
```

### Tablespace Management

```sql
-- Create tablespace
CREATE TABLESPACE ts_name DATAFILE '/path/file.dbf' SIZE 100M;

-- Check tablespace usage
SELECT tablespace_name, sum(bytes)/1024/1024 AS size_mb FROM dba_data_files GROUP BY tablespace_name;

-- Drop tablespace
DROP TABLESPACE ts_name INCLUDING CONTENTS;
```

### RMAN Backup Commands

```bash
# Connect to RMAN
rman target /

# Backup database
BACKUP DATABASE PLUS ARCHIVELOG;

# List backups
LIST BACKUP;

# Restore database
RESTORE DATABASE;

# Recover database
RECOVER DATABASE;
```

### Vector Operations

```sql
-- Create vector table
CREATE TABLE vectors (id NUMBER, embedding VECTOR(384));

-- Insert vector
INSERT INTO vectors VALUES (1, VECTOR('[val1, val2, ..., val384]', 384));

-- Vector similarity query
SELECT id FROM vectors 
ORDER BY VECTOR_DISTANCE(embedding, VECTOR('[...384...]', 384), COSINE)
FETCH FIRST 10 ROWS ONLY;

-- Create vector index
CREATE INDEX idx_vec ON vectors(embedding) INDEXTYPE IS VECTOR_AI_HNSW;
```

### JSON Operations

```sql
-- Create JSON column
CREATE TABLE docs (id NUMBER, json_data JSON);

-- Insert JSON
INSERT INTO docs VALUES (1, JSON_OBJECT('key' VALUE 'value'));

-- Query JSON
SELECT JSON_VALUE(json_data, '$.key') FROM docs;

-- Extract JSON array
SELECT JSON_QUERY(json_data, '$.array[*]') FROM docs;
```

---

## Quick Reference Tables

### Vector Distance Metrics

| Metric | Range | Best For |
|--------|-------|----------|
| COSINE | 0-1 | Normalized embeddings, text |
| L2 | 0-∞ | General distance |
| EUCLIDEAN | 0-∞ | Geometric distance |
| DOT_PRODUCT | -∞ to ∞ | Dot product similarity |

### Oracle 23AI Vector Index Types

| Index Type | Speed | Accuracy | Memory | Use Case |
|-----------|-------|----------|--------|----------|
| HNSW | Fast | Good | Medium | General purpose |
| IVF | Medium | Medium | Low | Large-scale |
| FLAT | Slow | Perfect | High | Small datasets |

### Directory Structure

```
/u01/app/oracle/
├── product/23c/           # Oracle Home (software)
├── oradata/               # Database datafiles
├── backup/                # RMAN backups
├── archive/               # Archived redo logs
└── oraInventory/          # Installation inventory
```

---

## Useful SQL*Plus Commands

```sql
-- Set line size for output
SET LINESIZE 200;

-- Set page size
SET PAGESIZE 50;

-- Enable/disable headers
SET HEADING ON|OFF;

-- Show query execution time
SET TIMING ON|OFF;

-- Enable explain plan
SET AUTOTRACE ON|OFF;

-- Format column output
COLUMN column_name FORMAT A20;

-- Exit SQL*Plus
EXIT;

-- Run script file
@/path/to/script.sql;

-- Run system command
!command;
```

---

**End of Oracle Database 23AI – Comprehensive Participant Lab Handbook**

---

## Document Information

- **Version:** 1.0
- **Created:** November 25, 2025
- **Duration:** 5-Day Training Program
- **Total Labs:** 13 comprehensive labs
- **Code Samples:** 50+ SQL and Python scripts
- **Commands:** 200+ practical examples
- **Expected Completion:** 40 hours hands-on training

**Next Steps for Participants:**
1. Review environment prerequisites before Day 1
2. Follow each step sequentially
3. Refer to troubleshooting section for issues
4. Keep detailed notes on commands and outputs
5. Complete lab checklist for each day
6. Prepare questions for live training sessions

