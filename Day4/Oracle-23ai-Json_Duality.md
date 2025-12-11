# Oracle Database 23ai: Complete Step-by-Step Implementation Guide

## Table of Contents
1. [Module 1: New Developer Features](#module-1-new-developer-features)
2. [Module 2: JSON Relational Duality](#module-2-json-relational-duality)
3. [Module 3: AI Vector Search & RAG](#module-3-ai-vector-search--rag)
4. [Hands-On Lab Exercises](#hands-on-lab-exercises)
5. [Best Practices & Implementation Strategy](#best-practices--implementation-strategy)

---

## Module 1: New Developer Features

### 1.1 Simpler DDL with IF [NOT] EXISTS

#### Problem Statement
**Before 23ai:** Creating deployment scripts required complex PL/SQL logic to handle object creation/deletion safely.

```sql
-- Old way (error-prone)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE projects';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/

CREATE TABLE projects (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100),
  status VARCHAR2(20)
);
```

**Issues:**
- Complex PL/SQL wrapper needed
- Difficult to maintain and debug
- Error handling scattered across multiple statements
- Not idiomatic for modern development

#### Solution: IF [NOT] EXISTS Syntax

```sql
-- 23ai way (clean and declarative)
CREATE TABLE IF NOT EXISTS projects (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100),
  status VARCHAR2(20)
);

DROP TABLE old_reports IF EXISTS;
```

#### Step-by-Step Implementation

**Step 1: Create a New Table Safely**

```sql
-- This will NOT error if the table already exists
CREATE TABLE IF NOT EXISTS customers (
  customer_id NUMBER PRIMARY KEY,
  customer_name VARCHAR2(150) NOT NULL,
  email VARCHAR2(100),
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP
);
```

**Step 2: Create Index with IF NOT EXISTS**

```sql
CREATE INDEX IF NOT EXISTS idx_customers_email 
ON customers(email);
```

**Step 3: Drop Objects Without Error Handling**

```sql
-- Clean up old objects without exception handling
DROP TABLE IF EXISTS temp_staging_data;
DROP INDEX IF EXISTS idx_old_metric;
DROP VIEW IF EXISTS v_customer_summary;
```

**Step 4: Implement in Deployment Scripts**

```sql
-- deployment_v1.0.sql
-- Run this script multiple times safely (idempotent)

CREATE TABLE IF NOT EXISTS audit_log (
  log_id NUMBER PRIMARY KEY,
  table_name VARCHAR2(30),
  operation VARCHAR2(10),
  change_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
  order_id NUMBER,
  item_id NUMBER,
  quantity NUMBER,
  unit_price NUMBER(10,2),
  PRIMARY KEY (order_id, item_id)
);

DROP SEQUENCE IF EXISTS seq_audit_log;
CREATE SEQUENCE seq_audit_log START WITH 1 INCREMENT BY 1;
```

#### Benefits Summary
| Feature | Benefit |
|---------|---------|
| **IF NOT EXISTS** | Safe table creation, prevents ORA-00955 errors |
| **IF EXISTS** | Safe deletion, prevents ORA-00942 errors |
| **Declarative** | No PL/SQL wrappers needed |
| **Idempotent** | Run scripts multiple times safely |

---

### 1.2 Modernizing I/O: Async and Reactive Drivers

#### Problem Statement
Traditional JDBC connections use **blocking I/O**, which means:
- Thread waits for database response
- Cannot handle other requests
- Resource-intensive for high-concurrency applications
- Doesn't scale with modern cloud architectures

#### Solution: R2DBC (Reactive Relational Database Connectivity)

**Architecture Comparison:**

```
TRADITIONAL JDBC (Blocking)
Request 1 → [Wait] → Response 1
Request 2 → [Wait] → Response 2
Request 3 → [Wait] → Response 3
= Thread pool exhaustion, low throughput

R2DBC (Non-Blocking)
Request 1 ─┐
Request 2 ─┼─ [Processing] ─ Response 1
Request 3 ─┘                 Response 2
                              Response 3
= Single thread handles multiple requests, high throughput
```

#### Step-by-Step Implementation

**Step 1: Add R2DBC Dependencies (Maven)**

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-r2dbc</artifactId>
    <version>3.2.0</version>
</dependency>

<dependency>
    <groupId>com.oracle.database.r2dbc</groupId>
    <artifactId>oracle-r2dbc</artifactId>
    <version>1.2.0</version>
</dependency>
```

**Step 2: Configure R2DBC Connection Pool**

```properties
# application.properties
spring.r2dbc.url=r2dbc:oracle:thin:@//host:1521/service_name
spring.r2dbc.username=appuser
spring.r2dbc.password=password
spring.r2dbc.pool.max-acquire-time=10000
spring.r2dbc.pool.max-life-time=1800000
spring.r2dbc.pool.max-idle-time=300000
spring.r2dbc.pool.initial-size=5
spring.r2dbc.pool.max-size=20
```

**Step 3: Create a Repository with Reactive Streams**

```java
// Employee.java
public class Employee {
    private Long employeeId;
    private String firstName;
    private String lastName;
    private String email;
    private LocalDateTime hireDate;
    
    // Getters and setters...
}

// EmployeeRepository.java
@Repository
public class EmployeeRepository {
    private final DatabaseClient databaseClient;
    
    public EmployeeRepository(DatabaseClient databaseClient) {
        this.databaseClient = databaseClient;
    }
    
    // Reactive query returning Flux<String> (multiple results)
    public Flux<String> getEmployeeNames() {
        return databaseClient.sql(
            "SELECT FIRST_NAME || ' ' || LAST_NAME as full_name FROM employees"
        )
        .map(row -> row.get("full_name", String.class))
        .all();
    }
    
    // Reactive query returning Mono<Employee> (single result)
    public Mono<Employee> findEmployeeById(Long employeeId) {
        return databaseClient.sql(
            "SELECT * FROM employees WHERE EMPLOYEE_ID = :id"
        )
        .bind("id", employeeId)
        .map(row -> new Employee(
            row.get("EMPLOYEE_ID", Long.class),
            row.get("FIRST_NAME", String.class),
            row.get("LAST_NAME", String.class),
            row.get("EMAIL", String.class),
            row.get("HIRE_DATE", LocalDateTime.class)
        ))
        .one();
    }
    
    // Batch insert (non-blocking)
    public Flux<Integer> batchInsertEmployees(List<Employee> employees) {
        return Flux.fromIterable(employees)
            .flatMap(emp -> databaseClient.sql(
                "INSERT INTO employees (FIRST_NAME, LAST_NAME, EMAIL) " +
                "VALUES (:firstName, :lastName, :email)"
            )
            .bind("firstName", emp.getFirstName())
            .bind("lastName", emp.getLastName())
            .bind("email", emp.getEmail())
            .fetch()
            .rowsUpdated());
    }
}
```

**Step 4: Create a REST Controller Using Reactive Endpoints**

```java
// EmployeeController.java
@RestController
@RequestMapping("/api/employees")
public class EmployeeController {
    private final EmployeeRepository employeeRepository;
    
    public EmployeeController(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }
    
    // Reactive endpoint - returns stream of names
    @GetMapping("/names")
    public Flux<String> getAllEmployeeNames() {
        return employeeRepository.getEmployeeNames();
    }
    
    // Reactive endpoint - returns single employee
    @GetMapping("/{id}")
    public Mono<ResponseEntity<Employee>> getEmployee(@PathVariable Long id) {
        return employeeRepository.findEmployeeById(id)
            .map(ResponseEntity::ok)
            .onErrorResume(e -> Mono.just(ResponseEntity.notFound().build()));
    }
}
```

**Step 5: Test Reactive Performance**

```java
// PerformanceTest.java
public class PerformanceTest {
    
    @Test
    public void testReactivePerformance() {
        // Simulate 1000 concurrent requests
        Flux.range(1, 1000)
            .flatMap(id -> employeeRepository.findEmployeeById((long) id))
            .doOnNext(emp -> System.out.println("Processed: " + emp.getFirstName()))
            .blockLast(); // For testing; in production, let Spring handle subscriptions
        
        // Result: Single thread pool handles 1000 requests efficiently
        // No thread pool exhaustion!
    }
}
```

#### Performance Benefits

| Metric | JDBC | R2DBC |
|--------|------|-------|
| **Threads for 1000 requests** | 1000+ | 10-20 |
| **Memory usage** | High | Low |
| **Max throughput** | Limited by thread pool | Much higher |
| **Latency under load** | Increases | Stable |

---

## Module 2: JSON Relational Duality

### 2.1 The Problem: Object-Relational Impedance Mismatch

#### Challenge
Modern applications have conflicting requirements:

```
┌─────────────────────────────────────────┐
│  What Developers Want                   │
│  - Flexible JSON documents              │
│  - Simple hierarchical structure        │
│  - No complex joins                     │
│  - NoSQL-like experience                │
└─────────────────────────────────────────┘

                    ↓ CONFLICT ↓

┌─────────────────────────────────────────┐
│  What Business Needs                    │
│  - ACID transactions                    │
│  - Data consistency                     │
│  - Normalized schema                    │
│  - Query flexibility                    │
└─────────────────────────────────────────┘
```

**Traditional Solutions (All Problematic):**
1. **Pure Relational** - Developers frustrated, many JOINs needed
2. **NoSQL** - No ACID guarantees, data duplication issues
3. **Hybrid** - Complex sync logic, data inconsistency risks

#### Solution: JSON Relational Duality Views

**Key Concept:** Store data once relationally, expose as JSON hierarchies.

```
STORAGE (Relational - Normalized)
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  customers   │────→│    orders    │────→│  order_items │
│              │     │              │     │              │
│ cust_id      │     │ order_id     │     │ item_id      │
│ name         │     │ cust_id      │     │ order_id     │
│ email        │     │ order_date   │     │ quantity     │
└──────────────┘     └──────────────┘     └──────────────┘

                        ↓ DUALITY VIEW ↓

ACCESS (JSON - Hierarchical)
{
  "_id": 101,
  "customerName": "John Doe",
  "email": "john@example.com",
  "orders": [
    {
      "_id": 1001,
      "orderDate": "2025-01-15",
      "items": [
        { "itemId": 5001, "quantity": 2 },
        { "itemId": 5002, "quantity": 1 }
      ]
    }
  ]
}
```

### 2.2 Creating JSON Relational Duality Views

#### Step 1: Design Relational Tables

```sql
-- Step 1a: Create customers table
CREATE TABLE IF NOT EXISTS customers (
  cust_id NUMBER PRIMARY KEY,
  cust_name VARCHAR2(150) NOT NULL,
  email VARCHAR2(100),
  phone VARCHAR2(20),
  country VARCHAR2(50),
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Step 1b: Create orders table
CREATE TABLE IF NOT EXISTS orders (
  order_id NUMBER PRIMARY KEY,
  cust_id NUMBER NOT NULL,
  order_date DATE DEFAULT TRUNC(SYSDATE),
  order_total NUMBER(10,2),
  status VARCHAR2(20),
  CONSTRAINT fk_orders_cust FOREIGN KEY (cust_id) 
    REFERENCES customers(cust_id)
);

-- Step 1c: Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  order_id NUMBER NOT NULL,
  item_seq NUMBER NOT NULL,
  product_id NUMBER,
  quantity NUMBER(5,2),
  unit_price NUMBER(10,2),
  PRIMARY KEY (order_id, item_seq),
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id) 
    REFERENCES orders(order_id)
);

-- Step 1d: Create indexes for performance
CREATE INDEX idx_orders_cust_id ON orders(cust_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
```

#### Step 2: Create the Duality View

```sql
-- Step 2: Create JSON Relational Duality View
CREATE JSON RELATIONAL DUALITY VIEW customer_dv AS
SELECT JSON {
  '_id': c.cust_id,
  'customerName': c.cust_name,
  'email': c.email,
  'phone': c.phone,
  'country': c.country,
  'orders': [
    SELECT JSON {
      '_id': o.order_id,
      'orderDate': o.order_date,
      'orderTotal': o.order_total,
      'status': o.status,
      'items': [
        SELECT JSON {
          'itemSequence': oi.item_seq,
          'productId': oi.product_id,
          'quantity': oi.quantity,
          'unitPrice': oi.unit_price,
          'subtotal': (oi.quantity * oi.unit_price)
        }
        FROM order_items oi
        WHERE oi.order_id = o.order_id
        ORDER BY oi.item_seq ASC
      ]
    }
    FROM orders o
    WHERE o.cust_id = c.cust_id
    ORDER BY o.order_date DESC
  ]
}
FROM customers c
WITH UPDATE INSERT DELETE;
```

#### Step 3: Insert Sample Data

```sql
-- Insert customers
INSERT INTO customers VALUES (101, 'John Doe', 'john@example.com', '555-1001', 'USA', SYSTIMESTAMP);
INSERT INTO customers VALUES (102, 'Jane Smith', 'jane@example.com', '555-1002', 'Canada', SYSTIMESTAMP);
INSERT INTO customers VALUES (103, 'Ahmed Ali', 'ahmed@example.com', '555-1003', 'UAE', SYSTIMESTAMP);
COMMIT;

-- Insert orders
INSERT INTO orders VALUES (1001, 101, '2025-01-10', 250.00, 'Completed');
INSERT INTO orders VALUES (1002, 101, '2025-01-15', 350.00, 'Pending');
INSERT INTO orders VALUES (1003, 102, '2025-01-12', 180.00, 'Completed');
COMMIT;

-- Insert order items
INSERT INTO order_items VALUES (1001, 1, 501, 2, 75.00);
INSERT INTO order_items VALUES (1001, 2, 502, 1, 100.00);
INSERT INTO order_items VALUES (1002, 1, 503, 3, 50.00);
INSERT INTO order_items VALUES (1002, 2, 501, 2, 75.00);
INSERT INTO order_items VALUES (1003, 1, 502, 1, 100.00);
INSERT INTO order_items VALUES (1003, 2, 504, 2, 40.00);
COMMIT;
```

#### Step 4: Query the Duality View

```sql
-- Read the entire customer hierarchy as JSON
SELECT JSON_SERIALIZE(data PRETTY) AS customer_json
FROM customer_dv
WHERE json_value(data, '$.customerName') = 'John Doe';

-- Output:
-- {
--   "_id": 101,
--   "customerName": "John Doe",
--   "email": "john@example.com",
--   "phone": "555-1001",
--   "country": "USA",
--   "orders": [
--     {
--       "_id": 1002,
--       "orderDate": "15-JAN-25",
--       "orderTotal": 350,
--       "status": "Pending",
--       "items": [...]
--     },
--     {
--       "_id": 1001,
--       "orderDate": "10-JAN-25",
--       "orderTotal": 250,
--       "status": "Completed",
--       "items": [...]
--     }
--   ]
-- }
```

#### Step 5: Update Data Through the Duality View

```sql
-- Update customer email through JSON document
UPDATE customer_dv
SET data = JSON_TRANSFORM(data, 
    SET '$.email' = 'newemail@example.com')
WHERE JSON_VALUE(data, '$._id') = 101;

-- Add new phone number
UPDATE customer_dv
SET data = JSON_TRANSFORM(data, 
    SET '$.phone' = '555-2001')
WHERE JSON_VALUE(data, '$.customerName') = 'John Doe';

-- Update nested order status
UPDATE customer_dv
SET data = JSON_TRANSFORM(data, 
    SET '$.orders[0].status' = 'Shipped')
WHERE JSON_VALUE(data, '$._id') = 101
AND JSON_VALUE(data, '$.orders[0]._id') = 1002;

COMMIT;
```

#### Step 6: Insert New Customer and Orders

```sql
-- Insert complete hierarchy through duality view
INSERT INTO customer_dv
VALUES (
  JSON {
    '_id': 104,
    'customerName': 'Maria Garcia',
    'email': 'maria@example.com',
    'phone': '555-1004',
    'country': 'Spain',
    'orders': [
      JSON {
        '_id': 1004,
        'orderDate': '2025-01-20',
        'orderTotal': 500.00,
        'status': 'Pending',
        'items': [
          JSON {'itemSequence': 1, 'productId': 505, 'quantity': 2, 'unitPrice': 250.00}
        ]
      }
    ]
  }
);
COMMIT;
```

#### Benefits Comparison

| Aspect | Traditional | Duality View |
|--------|-------------|--------------|
| **Data Storage** | Normalized (relational) | Normalized (relational) |
| **Data Access** | Relational queries | JSON documents |
| **Consistency** | ACID guaranteed | ACID guaranteed |
| **Development** | Complex JOINs | Simple JSON traversal |
| **Flexibility** | High schema coupling | Decoupled interfaces |

---

## Module 3: AI Vector Search & RAG

### 3.1 Understanding RAG (Retrieval Augmented Generation)

#### Problem: LLM Hallucinations

```
User Query: "What is Cloud Arc's current certifications?"

LLM Response (Without RAG):
"Cloud Arc Consultants is certified in SAP, Salesforce, 
and supply chain management solutions."
❌ WRONG - These are not your actual certifications!

LLM Response (With RAG):
"Cloud Arc specializes in Azure Solutions Architecture, 
Oracle Database Administration, and Banking Compliance."
✓ CORRECT - Grounded in actual company data!
```

#### RAG Workflow

```
1. DOCUMENT INGESTION
   PDF/Text → Split into chunks → Generate embeddings → Store in vector index
   
2. USER QUERY
   "Tell me about our Azure offerings"
   
3. RETRIEVAL
   Query embedding → Find similar document chunks → Get top 3 matches
   
4. AUGMENTATION
   Original query + Retrieved context → Build rich prompt
   
5. LLM GENERATION
   LLM processes augmented prompt → Generates grounded answer
   
6. RESPONSE
   "Based on your Azure training materials: [grounded answer]"
```

### 3.2 Setting Up Vector Search in Oracle 23ai

#### Step 1: Create Vector Tables

```sql
-- Step 1: Create documents table
CREATE TABLE IF NOT EXISTS documents (
  document_id NUMBER PRIMARY KEY,
  document_name VARCHAR2(255) NOT NULL,
  document_type VARCHAR2(50),
  file_path VARCHAR2(500),
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP,
  updated_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Step 2: Create document chunks table
CREATE TABLE IF NOT EXISTS document_chunks (
  chunk_id NUMBER PRIMARY KEY,
  document_id NUMBER NOT NULL,
  chunk_sequence NUMBER NOT NULL,
  chunk_text VARCHAR2(4000),
  chunk_length NUMBER,
  vector_embedding VECTOR(1024, FLOAT32),
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP,
  CONSTRAINT fk_chunk_doc FOREIGN KEY (document_id) 
    REFERENCES documents(document_id)
);

-- Step 3: Create vector index for fast similarity search
CREATE VECTOR INDEX IF NOT EXISTS idx_vector_embedding
ON document_chunks(vector_embedding)
WITH TARGET ACCURACY 95;

-- Step 4: Create regular index for chunk lookup
CREATE INDEX idx_doc_chunks_doc_id 
ON document_chunks(document_id);
```

#### Step 2: Insert Sample Documents and Embeddings

```sql
-- Insert a training document (Azure AZ-305)
INSERT INTO documents (document_id, document_name, document_type, file_path)
VALUES (1, 'Azure Solutions Architect Training', 'PDF', '/training/AZ-305-2025.pdf');

INSERT INTO documents (document_id, document_name, document_type, file_path)
VALUES (2, 'Oracle Database 23ai Administrator Guide', 'PDF', '/training/ORA-23ai-DBA.pdf');

COMMIT;

-- Insert document chunks with embeddings
-- Note: In production, generate embeddings using Python + OpenAI/Embedding model
-- For demo, using simulated embedding vectors

INSERT INTO document_chunks 
(chunk_id, document_id, chunk_sequence, chunk_text, chunk_length, vector_embedding)
VALUES (
  1, 1, 1,
  'Azure Solutions Architect role involves designing cloud solutions. ' ||
  'Must understand virtual networks, App Services, and Azure Synapse Analytics.',
  120,
  VECTOR('[0.125, 0.456, 0.789, 0.234, 0.567, 0.890, 0.123, 0.456, ...]', 1024, float32)
);

INSERT INTO document_chunks 
(chunk_id, document_id, chunk_sequence, chunk_text, chunk_length, vector_embedding)
VALUES (
  2, 1, 2,
  'Key Azure services: App Service, Azure SQL Database, Azure Storage, ' ||
  'Azure Synapse, Logic Apps, and Event Hubs. Understanding these is critical.',
  110,
  VECTOR('[0.234, 0.567, 0.890, 0.123, 0.456, 0.789, 0.234, 0.567, ...]', 1024, float32)
);

INSERT INTO document_chunks 
(chunk_id, document_id, chunk_sequence, chunk_text, chunk_length, vector_embedding)
VALUES (
  3, 2, 1,
  'Oracle Database 23ai introduces JSON Relational Duality Views and native Vector support. ' ||
  'These enable modern application architectures with full ACID compliance.',
  105,
  VECTOR('[0.345, 0.678, 0.901, 0.234, 0.567, 0.890, 0.123, 0.456, ...]', 1024, float32)
);

COMMIT;
```

#### Step 3: Implement Vector Similarity Search

```sql
-- Query 1: Find documents related to "cloud architecture"
SELECT 
  chunk_id,
  document_id,
  chunk_text,
  ROUND(VECTOR_DISTANCE(vector_embedding, 
        TO_VECTOR('[0.123, 0.456, 0.789, ...]', 1024, float32), 
        COSINE), 4) AS similarity_score
FROM document_chunks
ORDER BY VECTOR_DISTANCE(vector_embedding, 
         TO_VECTOR('[0.123, 0.456, 0.789, ...]', 1024, float32), 
         COSINE) ASC
FETCH FIRST 3 ROWS ONLY;

-- Output:
-- chunk_id  document_id  chunk_text                                    similarity_score
-- --------  -----------  ------------------------------------------    ----------------
--    2           1      Key Azure services: App Service, Azure SQL...    0.1234
--    1           1      Azure Solutions Architect role involves...      0.2156
--    3           2      Oracle Database 23ai introduces JSON...         0.3456
```

#### Step 4: Build RAG Query Pipeline

```sql
-- Step 4: Create a comprehensive RAG pipeline
-- This query retrieves context for LLM augmentation

CREATE OR REPLACE PROCEDURE rag_retrieve_context(
  p_query_vector IN VECTOR,
  p_top_k IN NUMBER DEFAULT 3
)
AS
  TYPE chunk_record IS RECORD (
    chunk_id NUMBER,
    document_id NUMBER,
    document_name VARCHAR2(255),
    chunk_text VARCHAR2(4000),
    similarity_score NUMBER
  );
  
  v_chunks SYS_REFCURSOR;
BEGIN
  OPEN v_chunks FOR
  SELECT 
    dc.chunk_id,
    dc.document_id,
    d.document_name,
    dc.chunk_text,
    ROUND(VECTOR_DISTANCE(dc.vector_embedding, p_query_vector, COSINE), 4) 
      AS similarity_score
  FROM document_chunks dc
  INNER JOIN documents d ON dc.document_id = d.document_id
  ORDER BY VECTOR_DISTANCE(dc.vector_embedding, p_query_vector, COSINE) ASC
  FETCH FIRST p_top_k ROWS ONLY;
  
  -- Return cursor with results
END rag_retrieve_context;
/
```

#### Step 5: Python Integration for Embeddings

```python
# python_rag_pipeline.py
import oracledb
from openai import OpenAI
import numpy as np

# Initialize OpenAI and Oracle connections
openai_client = OpenAI(api_key="your-api-key")
connection = oracledb.connect(
    user="rag_user",
    password="password",
    dsn="localhost:1521/orcl"
)

def generate_embedding(text: str) -> list:
    """Generate embeddings using OpenAI"""
    response = openai_client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding

def retrieve_context(query: str, top_k: int = 3) -> list:
    """Retrieve top K relevant chunks using vector search"""
    
    # Generate embedding for user query
    query_embedding = generate_embedding(query)
    
    cursor = connection.cursor()
    
    # Format embedding as Oracle VECTOR
    embedding_str = str(query_embedding).replace("'", "")
    
    sql = f"""
    SELECT 
      chunk_id,
      document_id,
      chunk_text,
      ROUND(VECTOR_DISTANCE(vector_embedding, 
            TO_VECTOR('{embedding_str}', 1024, float32), 
            COSINE), 4) AS similarity_score
    FROM document_chunks
    ORDER BY VECTOR_DISTANCE(vector_embedding, 
             TO_VECTOR('{embedding_str}', 1024, float32), 
             COSINE) ASC
    FETCH FIRST {top_k} ROWS ONLY
    """
    
    cursor.execute(sql)
    results = cursor.fetchall()
    cursor.close()
    
    return results

def generate_rag_response(user_query: str) -> str:
    """Complete RAG pipeline: Retrieve + Augment + Generate"""
    
    # Step 1: Retrieve context
    relevant_chunks = retrieve_context(user_query, top_k=3)
    
    # Step 2: Build context string
    context = "\n\n".join([chunk[2] for chunk in relevant_chunks])
    
    # Step 3: Create augmented prompt
    augmented_prompt = f"""
    You are an Oracle Database expert. Answer the following question based on the provided context.
    
    Context:
    {context}
    
    Question: {user_query}
    
    Provide a detailed, accurate answer based only on the context provided.
    """
    
    # Step 4: Call LLM
    response = openai_client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are an expert database consultant."},
            {"role": "user", "content": augmented_prompt}
        ],
        temperature=0.7,
        max_tokens=500
    )
    
    return response.choices[0].message.content

# Usage
if __name__ == "__main__":
    query = "What are the key features of Oracle 23ai?"
    answer = generate_rag_response(query)
    print(f"Question: {query}")
    print(f"\nAnswer:\n{answer}")
```

---

## Hands-On Lab Exercises

### Lab 1: DDL Simplification

**Objective:** Create an idempotent database schema

```sql
-- Create the schema with IF [NOT] EXISTS
CREATE TABLE IF NOT EXISTS app_users (
  user_id NUMBER PRIMARY KEY,
  username VARCHAR2(50) UNIQUE NOT NULL,
  email VARCHAR2(100),
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id NUMBER PRIMARY KEY,
  user_id NUMBER NOT NULL,
  preference_key VARCHAR2(50),
  preference_value VARCHAR2(500),
  CONSTRAINT fk_pref_user FOREIGN KEY (user_id) 
    REFERENCES app_users(user_id)
);

CREATE INDEX IF NOT EXISTS idx_prefs_user_id 
ON user_preferences(user_id);

-- Cleanup
DROP TABLE IF EXISTS user_sessions;
DROP INDEX IF EXISTS idx_old_index;
```

### Lab 2: JSON Duality Views

**Objective:** Create a duality view and perform CRUD operations

```sql
-- Create the duality view
CREATE JSON RELATIONAL DUALITY VIEW user_profile_dv AS
SELECT JSON {
  '_id': u.user_id,
  'username': u.username,
  'email': u.email,
  'preferences': [
    SELECT JSON {
      'key': up.preference_key,
      'value': up.preference_value
    }
    FROM user_preferences up
    WHERE up.user_id = u.user_id
  ]
}
FROM app_users u
WITH UPDATE INSERT DELETE;

-- INSERT through duality view
INSERT INTO user_profile_dv
VALUES (
  JSON {
    '_id': 1,
    'username': 'jdoe',
    'email': 'jdoe@example.com',
    'preferences': [
      JSON {'key': 'theme', 'value': 'dark'},
      JSON {'key': 'language', 'value': 'en'}
    ]
  }
);

-- READ through duality view
SELECT JSON_SERIALIZE(data PRETTY) FROM user_profile_dv
WHERE JSON_VALUE(data, '$.username') = 'jdoe';

-- UPDATE through duality view
UPDATE user_profile_dv
SET data = JSON_TRANSFORM(data, SET '$.email' = 'newemail@example.com')
WHERE JSON_VALUE(data, '$.username') = 'jdoe';
```

### Lab 3: Vector Search Implementation

**Objective:** Implement similarity search on document chunks

```sql
-- Insert documents with embeddings (simulated)
INSERT INTO documents (document_id, document_name, document_type)
VALUES (10, 'Cloud Architecture Guide', 'PDF');

INSERT INTO document_chunks 
(chunk_id, document_id, chunk_sequence, chunk_text, vector_embedding)
VALUES (
  100, 10, 1,
  'Cloud architecture requires understanding of scalability, availability, and cost optimization.',
  VECTOR('[0.1, 0.2, 0.3, 0.4, 0.5, ...]', 1024, float32)
);

-- Perform vector similarity search
SELECT 
  chunk_text,
  ROUND(VECTOR_DISTANCE(vector_embedding, 
        TO_VECTOR('[0.15, 0.25, 0.35, ...]', 1024, float32), 
        COSINE), 4) AS similarity
FROM document_chunks
ORDER BY similarity ASC
FETCH FIRST 5 ROWS ONLY;
```

---

## Best Practices & Implementation Strategy

### 1. DDL Best Practices

**DO:**
- ✅ Use IF [NOT] EXISTS for all production deployments
- ✅ Create idempotent scripts that can run multiple times
- ✅ Include timestamps for audit trails
- ✅ Use meaningful constraint names

**DON'T:**
- ❌ Rely on error handling for object creation
- ❌ Drop tables in deployment scripts
- ❌ Hard-code sequences without IF NOT EXISTS

### 2. Async Driver Best Practices

**DO:**
- ✅ Use R2DBC for high-concurrency applications
- ✅ Configure appropriate pool sizes (5-20 connections)
- ✅ Use reactive streams (Flux/Mono) correctly
- ✅ Handle backpressure properly

**DON'T:**
- ❌ Mix JDBC and R2DBC in same transaction
- ❌ Block reactive calls (no .block() in production)
- ❌ Create excessive thread pools

### 3. JSON Duality Best Practices

**DO:**
- ✅ Design duality views around business entities
- ✅ Use WITH UPDATE INSERT DELETE for full DML support
- ✅ Keep hierarchies 3-4 levels deep max
- ✅ Index nested collections appropriately

**DON'T:**
- ❌ Create duality views with extremely deep nesting
- ❌ Forget to index relationship keys
- ❌ Mix multiple entity types in single duality view

### 4. Vector Search Best Practices

**DO:**
- ✅ Use high-quality embedding models
- ✅ Implement proper chunking strategy (500-1000 tokens)
- ✅ Create vector indexes for production queries
- ✅ Monitor vector similarity scores

**DON'T:**
- ❌ Use untrained embedding models
- ❌ Store extremely large chunks (>4000 chars)
- ❌ Ignore vector index maintenance

---

## Certification & Training Path

### For AZ-305 Azure Solutions Architect
1. Master Module 1 concepts (DDL, Async I/O)
2. Understand how these translate to Azure patterns
3. Implement in sample architectures

### For Oracle DBA Bootcamp
1. Master all three modules comprehensively
2. Practice lab exercises multiple times
3. Implement RAG pipeline with real data

### For Banking Compliance Training
1. Focus on JSON Duality for customer data modeling
2. Understand ACID guarantees with JSON access
3. Implement audit trails with duality views

---

## Troubleshooting Guide

### Common Issues

**Issue: Vector index creation fails**
```sql
-- Solution: Ensure vector dimension matches
CREATE VECTOR INDEX idx_embedding 
ON document_chunks(vector_embedding)
WITH TARGET ACCURACY 95;
```

**Issue: Duality view UPDATE not reflecting in relational tables**
```sql
-- Solution: Verify WITH UPDATE INSERT DELETE clause exists
-- And check underlying table foreign key constraints
```

**Issue: R2DBC connection pool exhaustion**
```properties
# Solution: Increase pool size
spring.r2dbc.pool.max-size=30
spring.r2dbc.pool.max-acquire-time=15000
```

---

## Resources & References

- Oracle Database 23ai Documentation: https://docs.oracle.com/en/database/oracle/oracle-database/23/
- R2DBC Specification: https://r2dbc.io/
- OpenAI Embeddings API: https://platform.openai.com/docs/guides/embeddings
- JSON-LD Standard: https://json-ld.org/

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Prepared by:** Cloud Arc Consultants  
**Location:** Sharjah Media City, UAE
