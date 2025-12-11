# Step-by-Step Guide: Create JSON Relational Model in Oracle 23ai

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Prepare Your Relational Tables](#step-1-prepare-your-relational-tables)
4. [Step 2: Design Your JSON Document Structure](#step-2-design-your-json-document-structure)
5. [Step 3: Create the Duality View Using SQL](#step-3-create-the-duality-view-using-sql)
6. [Step 4: Specify Updatability Rules](#step-4-specify-updatability-rules)
7. [Step 5: Create Nested and Unnested Views](#step-5-create-nested-and-unnested-views)
8. [Step 6: Insert Documents into Duality Views](#step-6-insert-documents-into-duality-views)
9. [Step 7: Query Documents from Duality Views](#step-7-query-documents-from-duality-views)
10. [Step 8: Update Documents Using JSON](#step-8-update-documents-using-json)
11. [Step 9: Delete Documents from Duality Views](#step-9-delete-documents-from-duality-views)
12. [Step 10: Implement Optimistic Concurrency Control](#step-10-implement-optimistic-concurrency-control)
13. [Advanced Techniques](#advanced-techniques)

---

## Overview

**CREATE JSON RELATIONAL DUALITY VIEW** is a powerful feature in Oracle Database 23ai that enables developers to access relational data as JSON documents. This guide provides a complete step-by-step approach to implementing this technology in your Oracle database environment.

### Key Benefits:
- **Dual Access**: Access the same data as JSON documents OR relational tables
- **No Data Duplication**: Store data once in relational format, expose as JSON
- **Automatic Synchronization**: Changes in JSON automatically update relational tables
- **Lock-Free Concurrency**: Optimistic locking with ETAGs prevents conflicts
- **API-Ready**: Seamlessly integrate with REST APIs and MongoDB-compatible drivers

---

## Prerequisites

Before you begin, ensure you have:

1. **Oracle Database 23ai** or later installed
2. **Administrative privileges** to create tables and views
3. **SQL*Plus, SQL Developer, or equivalent** SQL client
4. **Understanding of**: JSON syntax, relational tables, and SQL
5. **Sample data** or real tables you want to expose as JSON

---

## Step 1: Prepare Your Relational Tables

### 1.1 Create Base Tables

Start by creating your relational tables with proper primary keys and foreign key relationships. The duality view will be built on top of these tables.

```sql
-- Create the SHOPS table
CREATE TABLE shops (
    shop_id NUMBER PRIMARY KEY,
    shop_name VARCHAR2(100) NOT NULL,
    location VARCHAR2(100)
);

-- Create the SHOP_ITEMS table (child table)
CREATE TABLE shop_items (
    item_no NUMBER PRIMARY KEY,
    item_name VARCHAR2(100) NOT NULL,
    quantity_available NUMBER,
    unit_price NUMBER(10, 2),
    shop_id NUMBER NOT NULL,
    CONSTRAINT fk_shop FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
);
```

### 1.2 Insert Sample Data

```sql
INSERT INTO shops VALUES (1, 'Tech Store', 'New York');
INSERT INTO shops VALUES (2, 'Fashion Hub', 'Los Angeles');

INSERT INTO shop_items VALUES (101, 'Laptop', 50, 899.99, 1);
INSERT INTO shop_items VALUES (102, 'Mouse', 200, 29.99, 1);
INSERT INTO shop_items VALUES (201, 'T-Shirt', 150, 19.99, 2);

COMMIT;
```

### 1.3 Verify Table Structure

```sql
DESC shops;
DESC shop_items;
```

**Key Points**:
- Tables must have a **primary key** (or unique key with identity)
- Use **proper normalization** to avoid data duplication
- Establish **foreign key relationships** between related tables
- Table structure should reflect your logical data model

---

## Step 2: Design Your JSON Document Structure

### 2.1 Define the Desired JSON Shape

Before writing SQL, sketch out what your JSON documents should look like:

```json
{
  "_id": 1,
  "shopName": "Tech Store",
  "location": "New York",
  "shopItems": [
    {
      "itemNo": 101,
      "itemName": "Laptop",
      "quantityAvailable": 50,
      "unitPrice": 899.99
    },
    {
      "itemNo": 102,
      "itemName": "Mouse",
      "quantityAvailable": 200,
      "unitPrice": 29.99
    }
  ]
}
```

### 2.2 Map Columns to JSON Fields

Create a mapping document:

| Table | Column | JSON Field | Nesting | Updatable |
|-------|--------|-----------|---------|-----------|
| shops | shop_id | _id | Top-level | No |
| shops | shop_name | shopName | Top-level | Yes |
| shops | location | location | Top-level | Yes |
| shop_items | item_no | itemNo | Nested in shopItems | Yes |
| shop_items | item_name | itemName | Nested in shopItems | Yes |
| shop_items | quantity_available | quantityAvailable | Nested in shopItems | Yes |
| shop_items | unit_price | unitPrice | Nested in shopItems | Yes |

**Key Design Considerations**:
- Choose a **document identifier (_id)** - typically the root table's primary key
- Decide which tables are **nested** (child) vs. **unnested** (flattened)
- Plan your **updatability rules** - which fields should be modifiable

---

## Step 3: Create the Duality View Using SQL

### 3.1 Basic Syntax

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW view_name AS
  SELECT JSON {
    '_id'      : table_alias.id_column,
    'field1'   : table_alias.col1,
    'nested'   : [
      SELECT JSON {
        'nestedField1' : child.colA,
        'nestedField2' : child.colB
      }
      FROM child_table child WITH INSERT UPDATE DELETE
      WHERE child.fk_col = parent.pk_col
    ]
  }
  FROM parent_table table_alias WITH UPDATE INSERT DELETE;
```

### 3.2 Create Your First Duality View

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_items_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'location': s.location,
    'shopItems': [
      SELECT JSON {
        'itemNo': si.item_no,
        'itemName': si.item_name,
        'quantityAvailable': si.quantity_available,
        'unitPrice': si.unit_price
      }
      FROM shop_items si WITH INSERT UPDATE DELETE
      WHERE si.shop_id = s.shop_id
    ]
  }
  FROM shops s WITH INSERT UPDATE DELETE;
```

### 3.3 Verify View Creation

```sql
-- Check if the view exists
SELECT view_name FROM user_views WHERE view_name = 'SHOP_ITEMS_DV';

-- Query the view to see documents
SELECT * FROM shop_items_dv;
```

**Syntax Components**:
- **JSON {...}**: Creates a JSON object with specified fields
- **JSON [SELECT ...]**: Creates a JSON array from a subquery
- **_id**: Mandatory document identifier (must map to root table's unique identifier)
- **FROM table_alias WITH**: Specifies updatability rules for the table
- **WHERE clause**: Joins child tables to parent rows

---

## Step 4: Specify Updatability Rules

### 4.1 Understand Updatability Annotations

Each table in your duality view can have one or more updatability annotations:

| Annotation | Meaning | Default |
|-----------|---------|---------|
| UPDATE | Field/column can be updated | No |
| NOUPDATE | Field/column cannot be updated | - |
| INSERT | Column participates in inserts | No |
| NOINSERT | Column does not participate in inserts | - |
| DELETE | Rows can be deleted via the view | No |
| NODELETE | Rows cannot be deleted via the view | - |
| CHECK | Include field in ETAG calculation | Yes |
| NOCHECK | Exclude field from ETAG calculation | - |

### 4.2 Fully Updatable View

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_items_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name WITH UPDATE,
    'location': s.location WITH UPDATE,
    'shopItems': [
      SELECT JSON {
        'itemNo': si.item_no WITH NOUPDATE,
        'itemName': si.item_name WITH UPDATE,
        'quantityAvailable': si.quantity_available WITH UPDATE,
        'unitPrice': si.unit_price WITH UPDATE
      }
      FROM shop_items si WITH INSERT UPDATE DELETE
      WHERE si.shop_id = s.shop_id
    ]
  }
  FROM shops s WITH INSERT UPDATE DELETE;
```

### 4.3 Read-Only View

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shops_read_only_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'location': s.location
  }
  FROM shops s;
  -- No WITH clause = read-only view
```

### 4.4 Partially Updatable View

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shops_limited_update_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name WITH UPDATE,
    'location': s.location
    -- location cannot be updated
  }
  FROM shops s WITH UPDATE DELETE NOINSERT;
  -- Can update and delete, but not insert
```

**Best Practices**:
- Set **NOUPDATE on _id fields** - document identifiers should not change
- Use **NOUPDATE on foreign keys** to prevent orphaned records
- Use **NOCHECK on calculated fields** to avoid ETAG conflicts
- Explicitly define updatability - don't rely on defaults

---

## Step 5: Create Nested and Unnested Views

### 5.1 Nested View (Default)

Data from related tables appears inside a child object or array:

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_detail_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'location': s.location,
    'inventory': [
      SELECT JSON {
        'itemNo': si.item_no,
        'itemName': si.item_name,
        'quantity': si.quantity_available
      }
      FROM shop_items si WITH INSERT UPDATE DELETE
      WHERE si.shop_id = s.shop_id
    ]
  }
  FROM shops s WITH INSERT UPDATE DELETE;
```

Document structure:
```json
{
  "_id": 1,
  "shopName": "Tech Store",
  "location": "New York",
  "inventory": [
    { "itemNo": 101, "itemName": "Laptop", "quantity": 50 }
  ]
}
```

### 5.2 Unnested View

Child table data is flattened into the parent object:

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_flat_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'location': s.location,
    UNNEST (
      SELECT JSON {
        'managerId': m.manager_id,
        'managerName': m.manager_name
      }
      FROM managers m WITH NOINSERT NOUPDATE NODELETE
      WHERE m.shop_id = s.shop_id
    )
  }
  FROM shops s WITH INSERT UPDATE DELETE;
```

Document structure (flattened):
```json
{
  "_id": 1,
  "shopName": "Tech Store",
  "location": "New York",
  "managerId": 501,
  "managerName": "John Smith"
}
```

**When to Use Each**:
- **Nested**: For 1-to-many relationships, when child records form logical collections
- **Unnested**: For 1-to-1 relationships, when you want a flatter JSON structure

---

## Step 6: Insert Documents into Duality Views

### 6.1 Insert a Complete Document

```sql
INSERT INTO shop_items_dv (data)
VALUES (JSON {
  '_id': 3,
  'shopName': 'Electronics Hub',
  'location': 'Chicago',
  'shopItems': [
    {
      'itemNo': 301,
      'itemName': 'Smartphone',
      'quantityAvailable': 75,
      'unitPrice': 699.99
    }
  ]
});

COMMIT;
```

### 6.2 Insert Without Specifying _id (Auto-generated)

```sql
-- Only possible if the underlying table has auto-increment primary key
INSERT INTO shop_items_dv (data)
VALUES (JSON {
  'shopName': 'Home Appliances',
  'location': 'Boston',
  'shopItems': []
});

COMMIT;
```

### 6.3 Using REST API (with Oracle ORDS)

```bash
curl -X POST https://apex.oracle.com/ords/api/shop_items_dv \
  -H "Content-Type: application/json" \
  -d '{
    "_id": 4,
    "shopName": "Sports Store",
    "location": "Seattle",
    "shopItems": [
      {
        "itemNo": 401,
        "itemName": "Running Shoes",
        "quantityAvailable": 100,
        "unitPrice": 129.99
      }
    ]
  }'
```

### 6.4 Verify Insertions

```sql
-- Check documents in duality view
SELECT * FROM shop_items_dv WHERE json_value(data, '$.shopName') = 'Tech Store';

-- Check underlying table data
SELECT * FROM shops;
SELECT * FROM shop_items;
```

**Key Points**:
- The **data column** contains the complete JSON document
- Document insertion **automatically updates underlying tables**
- Use **transaction control (COMMIT/ROLLBACK)** for consistency
- Foreign key constraints are **automatically enforced**

---

## Step 7: Query Documents from Duality Views

### 7.1 Select All Documents

```sql
SELECT * FROM shop_items_dv;
```

### 7.2 Query Specific Fields Using JSON Path

```sql
-- Get shop names and locations
SELECT 
  json_value(data, '$.shopName') as shop_name,
  json_value(data, '$.location') as location
FROM shop_items_dv;
```

### 7.3 Filter Documents

```sql
-- Find shops in specific location
SELECT * FROM shop_items_dv 
WHERE json_value(data, '$.location') = 'New York';

-- Find shops with items over certain price
SELECT * FROM shop_items_dv 
WHERE json_exists(data, '$.shopItems[*].unitPrice ? (@ > 500)');
```

### 7.4 Extract Nested Array Data

```sql
-- Get all items with their shop information
SELECT 
  json_value(data, '$.shopName') as shop,
  json_value(item, '$.itemName') as item_name,
  json_value(item, '$.unitPrice') as price
FROM shop_items_dv,
JSON_TABLE(data, '$.shopItems[*]' COLUMNS (item JSON PATH '$'));
```

### 7.5 Return Pretty-Printed JSON

```sql
-- Display formatted JSON documents
SELECT json_serialize(data PRETTY) as formatted_document
FROM shop_items_dv
WHERE json_value(data, '$._id') = 1;
```

**Query Performance Tips**:
- Use **json_value()** for extracting scalar values (optimized)
- Use **json_exists()** with path expressions for filtering
- **Create JSON indexes** on frequently queried paths
- Use **JSON_TABLE()** to convert JSON to relational rows for complex queries

---

## Step 8: Update Documents Using JSON

### 8.1 Update Entire Document

```sql
UPDATE shop_items_dv s
SET s.data = JSON {
  '_id': 1,
  'shopName': 'Tech Superstore',
  'location': 'New York',
  'shopItems': [
    {
      'itemNo': 101,
      'itemName': 'Gaming Laptop',
      'quantityAvailable': 45,
      'unitPrice': 1299.99
    }
  ]
}
WHERE json_value(s.data, '$._id') = 1;

COMMIT;
```

### 8.2 Update Specific Fields

```sql
-- Update only the shop name
UPDATE shop_items_dv s
SET s.data = json_transform(
  s.data,
  SET '$.shopName' = 'Updated Tech Store'
)
WHERE json_value(s.data, '$._id') = 1;

COMMIT;
```

### 8.3 Update Nested Array Values

```sql
-- Update quantity of a specific item
UPDATE shop_items_dv s
SET s.data = json_transform(
  s.data,
  SET '$.shopItems[0].quantityAvailable' = 60
)
WHERE json_value(s.data, '$._id') = 1;

COMMIT;
```

### 8.4 Update Via REST API

```bash
curl -X PUT https://apex.oracle.com/ords/api/shop_items_dv/1 \
  -H "Content-Type: application/json" \
  -d '{
    "_id": 1,
    "shopName": "Tech Superstore Updated",
    "location": "New York",
    "shopItems": [...]
  }'
```

### 8.5 Using json_transform() for Complex Updates

```sql
-- Add a new item to shopItems array
UPDATE shop_items_dv s
SET s.data = json_transform(
  s.data,
  APPEND '$.shopItems' = JSON {
    'itemNo': 103,
    'itemName': 'Keyboard',
    'quantityAvailable': 80,
    'unitPrice': 99.99
  }
)
WHERE json_value(s.data, '$._id') = 1;

COMMIT;
```

**Update Considerations**:
- Updates are **atomic at document level**
- Changes **automatically sync to underlying tables**
- Use **ETAG for optimistic locking** in concurrent scenarios
- **Partial updates** are more efficient than full replacements

---

## Step 9: Delete Documents from Duality Views

### 9.1 Delete by Document ID

```sql
-- Using JSON path comparison
DELETE FROM shop_items_dv
WHERE json_value(data, '$._id') = 3;

COMMIT;
```

### 9.2 Delete Multiple Documents

```sql
-- Delete all shops in a specific location
DELETE FROM shop_items_dv
WHERE json_value(data, '$.location') = 'Chicago';

COMMIT;
```

### 9.3 Delete Via REST API

```bash
curl -X DELETE https://apex.oracle.com/ords/api/shop_items_dv/3
```

### 9.4 Delete from Underlying Table (Cascading Delete)

```sql
-- Delete from base table - automatically removes documents
DELETE FROM shops WHERE shop_id = 3;

COMMIT;

-- Verify deletion from duality view
SELECT COUNT(*) FROM shop_items_dv 
WHERE json_value(data, '$._id') = 3;
-- Result: 0
```

### 9.5 Verify Deletions

```sql
-- Check if document still exists
SELECT COUNT(*) as document_count
FROM shop_items_dv;

-- Check underlying tables
SELECT COUNT(*) FROM shops;
SELECT COUNT(*) FROM shop_items;
```

**Delete Behavior**:
- **Document deletion** removes all related rows from underlying tables
- **Foreign key constraints** prevent orphaned records
- Deletion is **transactional** - either all succeeds or all rolls back
- Use **soft deletes** with status flags if you need audit trails

---

## Step 10: Implement Optimistic Concurrency Control

### 10.1 Understand ETAG (Entity Tag)

ETAG is a **hash value** representing the document state. It changes whenever the document is updated. Use it to detect conflicts in concurrent operations.

### 10.2 Retrieve Document with ETAG

```sql
-- Get current ETAG from the view
SELECT 
  data,
  json_value(data, '$.etag') as current_etag,
  json_value(data, '$.shopName') as shop_name
FROM shop_items_dv
WHERE json_value(data, '$._id') = 1;
```

### 10.3 Update with ETAG Check

```sql
-- Optimistic update: only succeeds if ETAG hasn't changed
UPDATE shop_items_dv s
SET s.data = JSON {
  '_id': 1,
  'shopName': 'Tech Store Updated Again',
  'location': 'New York',
  'shopItems': [...]
}
WHERE json_value(s.data, '$._id') = 1
  AND json_value(s.data, '$.etag') = 'abc123xyz789';

-- Check rows affected
-- If 0 rows = conflict detected, another process updated the document
-- If 1 row = success, document updated

COMMIT;
```

### 10.4 ETAG-Based Conflict Detection Pattern

```sql
-- Application flow:
-- 1. Fetch document with ETAG
DECLARE
  v_etag VARCHAR2(255);
  v_doc  JSON;
BEGIN
  SELECT data INTO v_doc FROM shop_items_dv WHERE json_value(data, '$._id') = 1;
  v_etag := json_value(v_doc, '$.etag');
  
  -- 2. Modify document locally
  -- 3. Attempt update with ETAG check
  UPDATE shop_items_dv SET data = v_doc
  WHERE json_value(data, '$._id') = 1 
    AND json_value(data, '$.etag') = v_etag;
  
  -- 4. Handle result
  IF SQL%ROWCOUNT = 0 THEN
    -- Conflict detected
    DBMS_OUTPUT.PUT_LINE('Update failed: Document was modified by another process');
    ROLLBACK;
  ELSE
    -- Success
    DBMS_OUTPUT.PUT_LINE('Document updated successfully');
    COMMIT;
  END IF;
END;
/
```

### 10.5 Using SYS_ROW_ETAG Function

```sql
-- For table-based updates using ETAG
SELECT sys_row_etag(t.ROWID) as row_etag
FROM shops t
WHERE shop_id = 1;

-- Lock-free update with SYS_ROW_ETAG
UPDATE shops t
SET shop_name = 'New Name'
WHERE shop_id = 1
  AND sys_row_etag(t.ROWID) = 'previous_etag_value';
```

### 10.6 REST API with ETAG Headers

```bash
# Get document with ETag header
curl -i https://apex.oracle.com/ords/api/shop_items_dv/1

# Response includes ETag header:
# ETag: "abc123xyz789"

# Conditional update using If-Match
curl -X PUT https://apex.oracle.com/ords/api/shop_items_dv/1 \
  -H "Content-Type: application/json" \
  -H "If-Match: abc123xyz789" \
  -d '{"shopName": "Updated Name", ...}'

# If ETag doesn't match, server returns 412 Precondition Failed
```

**ETAG Best Practices**:
- **Always retrieve ETAG** before updating
- **Include ETAG in update request** for conflict detection
- **Handle 409/412 errors** in your application (conflict response)
- **Retry logic**: Fetch fresh ETAG and retry on conflicts
- **Stateless applications**: ETAG enables concurrent REST operations without locks

---

## Advanced Techniques

### A1. Using GraphQL Syntax

Create duality views using GraphQL notation (alternative to SQL):

```sql
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_items_gql_dv AS
  shops @insert @update @delete {
    _id: shop_id
    shopName: shop_name
    location: location
    shopItems: shop_items @insert @update @delete [
      {
        itemNo: item_no
        itemName: item_name
        quantityAvailable: quantity_available
        unitPrice: unit_price
      }
    ]
  };
```

### A2. Filtering Rows in Duality Views

```sql
-- Only expose high-value items
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW premium_items_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'location': s.location,
    'premiumItems': [
      SELECT JSON {
        'itemNo': si.item_no,
        'itemName': si.item_name,
        'unitPrice': si.unit_price
      }
      FROM shop_items si WITH INSERT UPDATE DELETE
      WHERE si.shop_id = s.shop_id
        AND si.unit_price > 500  -- Only items over $500
    ]
  }
  FROM shops s WITH INSERT UPDATE DELETE;
```

### A3. Multiple Duality Views on Same Tables

```sql
-- View 1: Full item details for inventory management
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW inventory_dv AS
  SELECT JSON { ... } FROM shops s ...;

-- View 2: Limited view for customer browsing
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW customer_catalog_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'availableItems': [...]
  } FROM shops s ...;

-- View 3: Price management view
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW price_mgmt_dv AS
  SELECT JSON {
    '_id': si.item_no,
    'itemName': si.item_name,
    'currentPrice': si.unit_price WITH UPDATE
  } FROM shop_items si WITH UPDATE NOUPDATE DELETE;
```

### A4. Adding Computed Fields

```sql
-- View with computed total value
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_value_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'location': s.location,
    'totalInventoryValue': (
      SELECT SUM(si.quantity_available * si.unit_price)
      FROM shop_items si
      WHERE si.shop_id = s.shop_id
    ),
    'shopItems': [...]
  }
  FROM shops s WITH UPDATE INSERT DELETE;
```

### A5. JSON Columns in Underlying Tables

```sql
-- Table with JSON column for schema-flexible data
CREATE TABLE shop_metadata (
  shop_id NUMBER PRIMARY KEY,
  shop_name VARCHAR2(100),
  extra_info JSON,
  FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
);

-- View exposing JSON column data
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW shop_full_dv AS
  SELECT JSON {
    '_id': s.shop_id,
    'shopName': s.shop_name,
    'metadata': sm.extra_info,
    'items': [...]
  }
  FROM shops s
  LEFT JOIN shop_metadata sm ON s.shop_id = sm.shop_id
  WITH INSERT UPDATE DELETE;
```

### A6. Handling Large Datasets

```sql
-- Use indexes for performance
CREATE INDEX idx_shop_name ON shops(shop_name);
CREATE INDEX idx_shop_location ON shops(location);
CREATE INDEX idx_items_shop ON shop_items(shop_id);

-- Use pagination in REST API
-- GET /api/shop_items_dv?offset=0&limit=20

-- Query with LIMIT clause
SELECT * FROM shop_items_dv
WHERE json_value(data, '$.location') = 'New York'
FETCH FIRST 50 ROWS ONLY;
```

### A7. Error Handling

```sql
-- PL/SQL block with error handling
BEGIN
  INSERT INTO shop_items_dv (data)
  VALUES (JSON {
    '_id': 5,
    'shopName': 'New Shop',
    'location': 'Denver',
    'shopItems': []
  });
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Insert successful');
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Error: Shop ID already exists');
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END;
/
```

---

## Troubleshooting Guide

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| ORA-42647: Invalid JSON | Malformed JSON syntax | Validate JSON structure, use json_valid() |
| ORA-42649: Document ID not found | _id field missing/invalid | Ensure _id maps to primary key, use correct value |
| View not updatable | Missing WITH annotations | Add WITH UPDATE INSERT DELETE to tables |
| ETAG validation fails | Document was modified elsewhere | Refetch document with new ETAG, retry |
| Cascade delete fails | Foreign key constraint violation | Check if child rows exist, allow cascading deletes |
| Poor query performance | Missing indexes on JSON paths | Create JSON indexes: CREATE INDEX idx_name ON table(col) |

---

## Best Practices

1. **Always define _id explicitly** - Map to unique identifier in root table
2. **Use explicit updatability annotations** - Don't rely on defaults
3. **Implement ETAG checking** - Essential for concurrent applications
4. **Test all CRUD operations** - Verify behavior before production
5. **Monitor performance** - Use EXPLAIN PLAN, create indexes as needed
6. **Document view purpose** - Clearly mark views as read-only or updatable
7. **Use transactions** - Group related operations for consistency
8. **Version your views** - Use CREATE OR REPLACE for updates
9. **Separate views by use case** - Different views for different applications
10. **Backup before major changes** - Test view modifications on non-prod first

---

## Summary

JSON Relational Duality Views in Oracle 23ai provide a powerful bridge between relational and document-centric data models. By following this step-by-step guide, you can:

- Create flexible, multi-modal views of your relational data
- Enable JSON document access to normalized tables
- Implement lock-free concurrent updates with ETAG
- Support both traditional SQL and modern document APIs
- Reduce data duplication while maintaining relational integrity

Start with simple views and gradually introduce advanced features like computed fields, filtering, and optimistic concurrency control as your requirements evolve.
