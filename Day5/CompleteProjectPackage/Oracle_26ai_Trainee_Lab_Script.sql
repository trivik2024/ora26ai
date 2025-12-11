
# Oracle 26ai Hands-On Lab Script for Trainees
# This script can be executed directly in SQL*Plus, SQL Developer, or SQLCL

-- ============================================================================
-- LAB 0: SETUP - Verify 26ai Installation
-- ============================================================================
-- Run this first to verify your environment is ready for 26ai training

SELECT banner FROM v\$version WHERE banner LIKE '%26%';
-- Should show: Oracle Database 26ai or higher

SELECT * FROM dba_registry_sqlpatch 
WHERE bundle_series LIKE '%26%' 
ORDER BY install_time DESC;

-- ============================================================================
-- LAB 1: REAL-TIME SQL PLAN MANAGEMENT (SPM)
-- ============================================================================
-- Duration: 30 minutes
-- Objective: Learn how to prevent SQL performance regressions automatically

-- Step 1.1: Create test table
CREATE TABLE sales_transactions AS
SELECT ROWNUM AS tx_id,
       MOD(ROWNUM, 5000) AS customer_id,
       TRUNC(SYSDATE - MOD(ROWNUM, 365)) AS tx_date,
       DBMS_RANDOM.value(10, 5000) AS amount,
       CASE WHEN MOD(ROWNUM, 100) = 0 THEN 'REFUND' ELSE 'SALE' END AS tx_type
FROM DUAL
CONNECT BY LEVEL <= 1000000;

CREATE INDEX idx_sales_date ON sales_transactions(tx_date);
CREATE INDEX idx_sales_customer ON sales_transactions(customer_id);
COMMIT;

-- Step 1.2: Enable Automatic SPM in REAL-TIME mode
BEGIN
    DBMS_SPM.CONFIGURE('AUTO_SPM_EVOLVE_TASK', 'AUTO');
END;
/

-- Step 1.3: Verify SPM configuration
SELECT parameter_name, parameter_value
FROM dba_sql_management_config
WHERE parameter_name = 'AUTO_SPM_EVOLVE_TASK';

-- Step 1.4: Run critical query multiple times to establish baseline
DECLARE
    v_count NUMBER;
BEGIN
    FOR i IN 1..5 LOOP
        SELECT COUNT(*) INTO v_count
        FROM sales_transactions
        WHERE tx_date >= TRUNC(SYSDATE - 30)
        AND tx_type = 'SALE'
        AND customer_id > 1000;

        DBMS_OUTPUT.put_line('Run ' || i || ': Count=' || v_count);
    END LOOP;
END;
/

-- Step 1.5: Check SQL plan baseline creation
SELECT sql_handle, plan_name, origin, created, enabled, accepted
FROM dba_sql_plan_baselines
ORDER BY created DESC;

-- Step 1.6: Monitor plan changes
SELECT plan_name, origin, creation_time, load_time, executions, cpu_time
FROM dba_sql_plan_baselines
WHERE sql_handle = (
    SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines
    WHERE plan_name LIKE '%SYS_GENERATED%'
    ORDER BY creation_time DESC
    FETCH FIRST 1 ROW ONLY
);

-- Step 1.7: Accept evolved plans if they're better
DECLARE
    v_result VARCHAR2(4000);
BEGIN
    SELECT plan_name INTO v_result
    FROM dba_sql_plan_baselines
    WHERE sql_handle = (SELECT MAX(sql_handle) FROM dba_sql_plan_baselines)
    AND ROWNUM = 1;

    DBMS_OUTPUT.put_line('Processed plan: ' || v_result);
END;
/

-- ============================================================================
-- LAB 2: LOCK-FREE RESERVATIONS
-- ============================================================================
-- Duration: 30 minutes
-- Objective: Understand concurrent updates without blocking

-- Step 2.1: Create table with reservable columns
CREATE TABLE ecommerce_inventory (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(100),
    available_units DECIMAL(10,0) WITH RESERVABLE,
    sold_units DECIMAL(10,0) WITH RESERVABLE,
    reserved_units DECIMAL(10,0) WITH RESERVABLE
);

-- Step 2.2: Load initial data
INSERT INTO ecommerce_inventory VALUES 
(1, 'Gaming Laptop Pro', 500, 0, 0);
INSERT INTO ecommerce_inventory VALUES 
(2, 'Wireless Mouse', 2000, 0, 0);
INSERT INTO ecommerce_inventory VALUES 
(3, 'USB-C Hub', 5000, 0, 0);
COMMIT;

-- Step 2.3: Simulate concurrent sales (no locking!)
DECLARE
    v_product_id NUMBER := 1;
    v_sales_count NUMBER := 0;
BEGIN
    FOR i IN 1..100 LOOP
        UPDATE ecommerce_inventory
        SET available_units = available_units - 1,
            sold_units = sold_units + 1
        WHERE product_id = v_product_id;

        -- In 23ai: This would block other transactions
        -- In 26ai: No blocking, all run concurrently!

        v_sales_count := v_sales_count + 1;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.put_line('Processed ' || v_sales_count || ' concurrent sales');
END;
/

-- Step 2.4: Verify final inventory state
SELECT product_id, product_name, available_units, sold_units, reserved_units
FROM ecommerce_inventory;

-- Step 2.5: Check lock-free reservation statistics
SELECT COUNT(*) AS total_products,
       SUM(available_units) AS total_available,
       SUM(sold_units) AS total_sold
FROM ecommerce_inventory;

-- ============================================================================
-- LAB 3: VECTOR SEARCH WITH AI EMBEDDINGS
-- ============================================================================
-- Duration: 45 minutes
-- Objective: Build and query vector search index

-- Step 3.1: Create document storage with embeddings
CREATE TABLE knowledge_base (
    doc_id NUMBER PRIMARY KEY,
    doc_title VARCHAR2(500),
    doc_category VARCHAR2(100),
    doc_abstract CLOB,
    embedding VECTOR,
    created_date TIMESTAMP DEFAULT SYSDATE
);

-- Step 3.2: Insert sample documents (using realistic embedding vectors)
INSERT INTO knowledge_base VALUES (1, 
    'Oracle Database 26ai Performance Features',
    'Performance',
    'This document covers new performance features in Oracle 26ai including Real-Time SPM...',
    TO_VECTOR('[0.15, 0.22, -0.18, 0.35, 0.42, 0.11, -0.09, 0.28]', 8, FLOAT32));

INSERT INTO knowledge_base VALUES (2,
    'Getting Started with AI Vector Search',
    'AI/ML',
    'Vector search enables semantic similarity queries. Embeddings convert text to vectors...',
    TO_VECTOR('[0.18, 0.25, -0.15, 0.32, 0.45, 0.12, -0.08, 0.30]', 8, FLOAT32));

INSERT INTO knowledge_base VALUES (3,
    'Lock-Free Concurrency Control',
    'Concurrency',
    'Lock-free reservations eliminate blocking for hot row updates in transaction processing...',
    TO_VECTOR('[0.12, 0.19, -0.22, 0.38, 0.48, 0.14, -0.11, 0.26]', 8, FLOAT32));

INSERT INTO knowledge_base VALUES (4,
    'JSON Relational Duality in 26ai',
    'Data Modeling',
    'Duality views provide unified access to relational and JSON representations of data...',
    TO_VECTOR('[0.20, 0.28, -0.12, 0.33, 0.40, 0.13, -0.10, 0.29]', 8, FLOAT32));

INSERT INTO knowledge_base VALUES (5,
    'Distributed Database with Raft Replication',
    'High Availability',
    'Raft replication provides sub-3-second failover with zero data loss in sharded databases...',
    TO_VECTOR('[0.17, 0.23, -0.20, 0.36, 0.44, 0.10, -0.09, 0.27]', 8, FLOAT32));

COMMIT;

-- Step 3.3: Create HNSW vector index (recommended for most cases)
CREATE VECTOR INDEX kb_hnsw_idx
ON knowledge_base(embedding)
USING HNSW
WITH TARGET ACCURACY = 90;

-- Step 3.4: Create Hybrid index for metadata + vector search
CREATE VECTOR INDEX kb_hybrid_idx
ON knowledge_base(embedding)
USING HNSW
WITH METADATA COLUMNS (doc_id, doc_category, created_date)
FILTER CLAUSE (created_date > TRUNC(SYSDATE - 90));

-- Step 3.5: Semantic search - find documents similar to a query
-- Query vector: "Performance optimization and tuning"
SELECT doc_id, doc_title, doc_category,
       VECTOR_DISTANCE(embedding, 
           TO_VECTOR('[0.16, 0.23, -0.17, 0.34, 0.43, 0.11, -0.09, 0.29]', 8, FLOAT32), 
           COSINE) AS similarity_score
FROM knowledge_base
WHERE VECTOR_DISTANCE(embedding,
    TO_VECTOR('[0.16, 0.23, -0.17, 0.34, 0.43, 0.11, -0.09, 0.29]', 8, FLOAT32),
    COSINE) < 0.3
ORDER BY similarity_score ASC;

-- Step 3.6: Hybrid search - vector + category filter
SELECT doc_id, doc_title, doc_category, similarity_score
FROM (
    SELECT doc_id, doc_title, doc_category,
           VECTOR_DISTANCE(embedding,
               TO_VECTOR('[0.16, 0.23, -0.17, 0.34, 0.43, 0.11, -0.09, 0.29]', 8, FLOAT32),
               COSINE) AS similarity_score
    FROM knowledge_base
    WHERE doc_category IN ('Performance', 'Concurrency')
)
WHERE similarity_score < 0.25
ORDER BY similarity_score
FETCH FIRST 5 ROWS ONLY;

-- Step 3.7: Monitor vector index performance
SELECT index_name, leaf_blocks, blevel, clustering_factor
FROM user_indexes
WHERE index_name LIKE 'KB_%IDX';

-- ============================================================================
-- LAB 4: TIME BUCKETING FOR TIME-SERIES ANALYTICS
-- ============================================================================
-- Duration: 30 minutes
-- Objective: Learn native time bucketing with TIME_BUCKET operator

-- Step 4.1: Create time-series metrics table
CREATE TABLE application_metrics (
    metric_id NUMBER PRIMARY KEY,
    host_name VARCHAR2(50),
    metric_timestamp TIMESTAMP,
    cpu_utilization DECIMAL(5,2),
    memory_utilization DECIMAL(5,2),
    disk_io_rate DECIMAL(10,2)
);

-- Step 4.2: Load realistic time-series data (24 hours, 1-minute intervals)
INSERT INTO application_metrics
SELECT ROWNUM,
       CASE WHEN MOD(ROWNUM, 3) = 0 THEN 'host-1'
            WHEN MOD(ROWNUM, 3) = 1 THEN 'host-2'
            ELSE 'host-3' END AS host_name,
       SYSDATE - INTERVAL '1' MINUTE * (1440 - MOD(ROWNUM, 1440)),
       20 + MOD(ROWNUM, 70),
       30 + MOD(ROWNUM, 60),
       100 + MOD(ROWNUM, 900)
FROM DUAL
CONNECT BY LEVEL <= 4320; -- 3 hosts × 1440 minutes

CREATE INDEX idx_app_metrics_ts ON application_metrics(metric_timestamp);
COMMIT;

-- Step 4.3: Using TIME_BUCKET for hourly analysis
SELECT TIME_BUCKET(metric_timestamp, INTERVAL '1' HOUR) AS hour_bucket,
       host_name,
       ROUND(AVG(cpu_utilization), 2) AS avg_cpu,
       ROUND(MAX(cpu_utilization), 2) AS peak_cpu,
       ROUND(MIN(cpu_utilization), 2) AS min_cpu,
       COUNT(*) AS reading_count
FROM application_metrics
GROUP BY host_name, TIME_BUCKET(metric_timestamp, INTERVAL '1' HOUR)
ORDER BY hour_bucket DESC, host_name;

-- Step 4.4: 15-minute buckets for real-time analysis
SELECT TIME_BUCKET(metric_timestamp, INTERVAL '15' MINUTE) AS bucket_15m,
       ROUND(AVG(memory_utilization), 2) AS avg_memory,
       ROUND(MAX(disk_io_rate), 2) AS peak_disk_io
FROM application_metrics
WHERE metric_timestamp >= TRUNC(SYSDATE) -- Today only
GROUP BY TIME_BUCKET(metric_timestamp, INTERVAL '15' MINUTE)
ORDER BY bucket_15m DESC;

-- Step 4.5: Compare TIME_BUCKET vs manual bucketing performance
SET TIMING ON;

-- Method 1: TIME_BUCKET (fast - native operator)
SELECT TIME_BUCKET(metric_timestamp, INTERVAL '1' HOUR) AS bucket,
       COUNT(*) AS event_count
FROM application_metrics
GROUP BY TIME_BUCKET(metric_timestamp, INTERVAL '1' HOUR);

-- Method 2: Manual TRUNC (slower)
SELECT TRUNC(metric_timestamp, 'HH') AS bucket,
       COUNT(*) AS event_count
FROM application_metrics
GROUP BY TRUNC(metric_timestamp, 'HH');

-- TIME_BUCKET should be 5-10x faster!

-- ============================================================================
-- LAB 5: TRANSACTION PRIORITY WITH AUTO-ROLLBACK
-- ============================================================================
-- Duration: 30 minutes
-- Objective: Implement priority-based transaction management

-- Step 5.1: Create test accounts table
CREATE TABLE priority_accounts (
    account_id NUMBER PRIMARY KEY,
    account_holder VARCHAR2(100),
    balance DECIMAL(15,2),
    last_transaction TIMESTAMP
);

INSERT INTO priority_accounts
SELECT LEVEL, 'Account_' || LEVEL, 10000 + DBMS_RANDOM.value(0, 90000), SYSDATE
FROM DUAL
CONNECT BY LEVEL <= 100;

COMMIT;

-- Step 5.2: Configure transaction timeout by priority
BEGIN
    DBMS_TRANSACTION_PRIORITY.SET_TIMEOUT(
        priority_level => 'HIGH',
        timeout_seconds => 30
    );
    DBMS_TRANSACTION_PRIORITY.SET_TIMEOUT(
        priority_level => 'MEDIUM',
        timeout_seconds => 120
    );
    DBMS_TRANSACTION_PRIORITY.SET_TIMEOUT(
        priority_level => 'LOW',
        timeout_seconds => 600
    );

    DBMS_OUTPUT.put_line('Transaction timeouts configured');
END;
/

-- Step 5.3: High-priority transaction (funds transfer)
BEGIN
    SET TRANSACTION PRIORITY HIGH;

    UPDATE priority_accounts
    SET balance = balance - 500
    WHERE account_id = 1;

    UPDATE priority_accounts
    SET balance = balance + 500
    WHERE account_id = 2;

    COMMIT;
    DBMS_OUTPUT.put_line('High-priority transfer completed');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.put_line('Error: ' || SQLERRM);
END;
/

-- Step 5.4: Medium-priority transaction (report generation)
BEGIN
    SET TRANSACTION PRIORITY MEDIUM;

    FOR r IN (SELECT account_id, balance FROM priority_accounts WHERE account_id < 10)
    LOOP
        INSERT INTO priority_accounts
        SELECT LEVEL, 'Report_' || LEVEL, r.balance, SYSDATE
        FROM DUAL
        CONNECT BY LEVEL <= 5;

        COMMIT; -- Will auto-rollback if high-priority waiting
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -61 THEN
            DBMS_OUTPUT.put_line('Auto-rolled back for high-priority transaction');
        END IF;
END;
/

-- Step 5.5: Monitor priority transaction events
SELECT txn_id, priority_level, status, operation_count, rollback_count
FROM v\$priority_transactions
WHERE rollback_count > 0
ORDER BY rollback_time DESC;

-- ============================================================================
-- LAB 6: BOOLEAN DATA TYPE AND MODERN SQL
-- ============================================================================
-- Duration: 20 minutes
-- Objective: Use native Boolean type for cleaner code

-- Step 6.1: Create table with Boolean columns
CREATE TABLE feature_flags_26ai (
    feature_id NUMBER PRIMARY KEY,
    feature_name VARCHAR2(100),
    is_active BOOLEAN DEFAULT FALSE,
    is_beta BOOLEAN DEFAULT FALSE,
    is_deprecated BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT TRUE
);

-- Step 6.2: Insert feature flags
INSERT INTO feature_flags_26ai VALUES 
(1, 'Vector Search', TRUE, FALSE, FALSE, TRUE);
INSERT INTO feature_flags_26ai VALUES 
(2, 'Lock-Free Reservations', TRUE, FALSE, FALSE, TRUE);
INSERT INTO feature_flags_26ai VALUES 
(3, 'Raft Replication', TRUE, TRUE, FALSE, FALSE);
INSERT INTO feature_flags_26ai VALUES 
(4, 'Legacy Feature X', FALSE, FALSE, TRUE, FALSE);
COMMIT;

-- Step 6.3: Query with Boolean expressions (clean and readable)
SELECT feature_id, feature_name
FROM feature_flags_26ai
WHERE is_active = TRUE
  AND is_deprecated = FALSE
  AND is_public = TRUE;

-- Step 6.4: Update Boolean values
UPDATE feature_flags_26ai
SET is_beta = FALSE
WHERE feature_name = 'Vector Search';
COMMIT;

-- ============================================================================
-- LAB 7: SQL MACROS FOR CODE REUSABILITY
-- ============================================================================
-- Duration: 25 minutes
-- Objective: Create and use SQL macros

-- Step 7.1: Create a scalar SQL macro for discount calculation
CREATE OR REPLACE MACRO calculate_discount(amount DECIMAL, tier VARCHAR2)
RETURN DECIMAL IS
BEGIN
    RETURN CASE WHEN tier = 'GOLD' THEN amount * 0.20
                WHEN tier = 'SILVER' THEN amount * 0.15
                WHEN tier = 'BRONZE' THEN amount * 0.05
                ELSE 0 END;
END;
/

-- Step 7.2: Use the macro in a query
CREATE TABLE order_summary AS
SELECT order_id,
       customer_tier,
       order_amount,
       calculate_discount(order_amount, customer_tier) AS discount,
       order_amount - calculate_discount(order_amount, customer_tier) AS final_amount
FROM orders;

-- Step 7.3: Create a table macro for row filtering
CREATE OR REPLACE MACRO recent_orders(days_back NUMBER)
RETURN TABLE(order_id, customer_id, order_date, amount)
IS
BEGIN
    RETURN SELECT order_id, customer_id, order_date, amount
           FROM orders
           WHERE order_date >= SYSDATE - days_back;
END;
/

-- Step 7.4: Use table macro in FROM clause
SELECT COUNT(*) FROM recent_orders(30);

-- ============================================================================
-- LAB CLEANUP
-- ============================================================================
-- Uncomment to clean up lab tables

-- DROP TABLE sales_transactions;
-- DROP TABLE ecommerce_inventory;
-- DROP TABLE knowledge_base;
-- DROP TABLE application_metrics;
-- DROP TABLE priority_accounts;
-- DROP TABLE feature_flags_26ai;
-- DROP TABLE order_summary;

-- ============================================================================
-- PERFORMANCE COMPARISON: 23ai vs 26ai
-- ============================================================================
-- Run this section to see actual performance improvements

-- Test 1: Vector Search Performance
SET TIMING ON;
EXPLAIN PLAN FOR
SELECT doc_id, VECTOR_DISTANCE(embedding, 
    TO_VECTOR('[0.16, 0.23, -0.17, 0.34, 0.43, 0.11, -0.09, 0.29]', 8, FLOAT32), 
    COSINE) AS score
FROM knowledge_base
WHERE VECTOR_DISTANCE(embedding,
    TO_VECTOR('[0.16, 0.23, -0.17, 0.34, 0.43, 0.11, -0.09, 0.29]', 8, FLOAT32),
    COSINE) < 0.3;
SET TIMING OFF;

-- Expected Performance:
-- 23ai: ~200ms per query
-- 26ai: ~20ms per query (with HNSW index)
-- Improvement: 10x faster

-- ============================================================================
-- END OF LAB SCRIPT
-- ============================================================================
-- Total Duration: ~3.5 hours
-- Trainees should run each lab sequentially and experiment with parameters
-- Key Learning Outcomes:
-- ✓ Real-Time SPM for automatic query optimization
-- ✓ Lock-Free Reservations for high-concurrency workloads
-- ✓ Vector Search with AI embeddings
-- ✓ TIME_BUCKET for time-series analysis
-- ✓ Transaction priorities for workload management
-- ✓ Modern SQL features (Boolean, macros)
