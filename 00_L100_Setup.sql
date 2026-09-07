-- ============================================================
-- SoFi Finance AI HOL — Level 100 Bootstrap (All-in-One)
-- ============================================================
--
-- Single script that sets up everything from scratch.
-- Attendees paste this into a Snowsight SQL Worksheet and Run All.
--
-- Creates: role, warehouse, database, 6 tables with data,
--          tags, semantic view, Cortex Agent for CoWork.
--
-- Total data: ~2,100 rows across 6 tables.
-- Estimated run time: ~30 seconds.
-- ============================================================

-- ============================================================
-- 1. Role & Warehouse
-- ============================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE ROLE finance_hol_admin
  COMMENT = 'Admin role for SoFi Finance AI HOL';

GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE finance_hol_admin;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE finance_hol_admin;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE finance_hol_admin;

SET current_user = (SELECT CURRENT_USER());
GRANT ROLE finance_hol_admin TO USER IDENTIFIER($current_user);

USE ROLE finance_hol_admin;

CREATE OR REPLACE WAREHOUSE finance_hol_wh
  WAREHOUSE_SIZE = 'small'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- ============================================================
-- 2. Database, Schemas, Tags
-- ============================================================

CREATE OR REPLACE DATABASE sofi_finance_hol;
CREATE OR REPLACE SCHEMA sofi_finance_hol.financial;

USE DATABASE sofi_finance_hol;
USE SCHEMA financial;

CREATE OR REPLACE TAG domain COMMENT = 'Business domain this table belongs to';
CREATE OR REPLACE TAG source_system COMMENT = 'Upstream system of record';
CREATE OR REPLACE TAG data_sensitivity COMMENT = 'Data classification level';
CREATE OR REPLACE TAG refresh_frequency COMMENT = 'How often this data is refreshed';

-- ============================================================
-- 3. Tables
-- ============================================================

CREATE OR REPLACE TABLE products (
  product_id NUMBER(38,0),
  product_name VARCHAR,
  category VARCHAR,
  risk_tier VARCHAR,
  launch_date DATE
)
COMMENT = 'Financial product catalog with risk tier classifications (Personal Loan, Home Loan, Credit Card, etc.)';

CREATE OR REPLACE TABLE earnings_transcripts (
  transcript_id NUMBER(38,0),
  company VARCHAR,
  ticker VARCHAR,
  quarter VARCHAR,
  fiscal_year NUMBER(4,0),
  call_date DATE,
  revenue_millions NUMBER(12,2),
  eps NUMBER(8,4),
  yoy_revenue_growth_pct NUMBER(5,2),
  active_users_millions NUMBER(8,2),
  key_themes VARCHAR,
  forward_guidance VARCHAR,
  sentiment_score NUMBER(3,2)
)
COMMENT = 'Quarterly earnings call summaries for peer fintech companies — revenue, EPS, growth metrics, key themes, and sentiment';

CREATE OR REPLACE TABLE invoices (
  invoice_id NUMBER(38,0),
  vendor_id NUMBER(38,0),
  invoice_number VARCHAR,
  invoice_date DATE,
  due_date DATE,
  amount NUMBER(12,2),
  currency VARCHAR,
  department VARCHAR,
  cost_center VARCHAR,
  status VARCHAR,
  payment_date DATE,
  description VARCHAR
)
COMMENT = 'Vendor invoices with amounts, dates, departments, and payment status (Paid, Pending, Overdue, Disputed)';

CREATE OR REPLACE TABLE vendor_catalog (
  vendor_id NUMBER(38,0),
  vendor_name VARCHAR,
  category VARCHAR,
  contract_status VARCHAR,
  contract_start_date DATE,
  contract_end_date DATE,
  annual_spend_budget NUMBER(12,2),
  payment_terms VARCHAR,
  risk_rating VARCHAR
)
COMMENT = 'Vendor master list with contract details, annual spend budgets, payment terms, and risk ratings';

CREATE OR REPLACE TABLE loan_originations (
  date DATE,
  region VARCHAR,
  product_id NUMBER(38,0),
  applications NUMBER(38,0),
  approvals NUMBER(38,0),
  denials NUMBER(38,0),
  funded_amount NUMBER(38,2)
)
COMMENT = 'Monthly loan application and funding data by region and product — applications, approvals, denials, funded amounts';

CREATE OR REPLACE TABLE loan_performance (
  snapshot_date DATE,
  product_id NUMBER(38,0),
  vintage VARCHAR,
  outstanding_balance NUMBER(38,0),
  current_count NUMBER(38,0),
  dpd_30 NUMBER(38,0),
  dpd_60 NUMBER(38,0),
  dpd_90_plus NUMBER(38,0),
  chargeoff_amount NUMBER(38,2)
)
COMMENT = 'Monthly portfolio performance snapshots — delinquency buckets (30/60/90+ DPD), outstanding balances, and charge-offs by product and vintage';

-- ============================================================
-- 4. Tags
-- ============================================================

ALTER TABLE products SET TAG
  domain = 'Product Management',
  source_system = 'Product Catalog',
  data_sensitivity = 'Internal',
  refresh_frequency = 'Monthly';

ALTER TABLE earnings_transcripts SET TAG
  domain = 'Market Intelligence',
  source_system = 'Investor Relations / Public Filings',
  data_sensitivity = 'Public',
  refresh_frequency = 'Quarterly';

ALTER TABLE invoices SET TAG
  domain = 'Accounts Payable',
  source_system = 'AP System',
  data_sensitivity = 'Confidential',
  refresh_frequency = 'Daily';

ALTER TABLE vendor_catalog SET TAG
  domain = 'Vendor Management',
  source_system = 'Procurement',
  data_sensitivity = 'Internal',
  refresh_frequency = 'Monthly';

ALTER TABLE loan_originations SET TAG
  domain = 'Lending',
  source_system = 'Loan Origination System',
  data_sensitivity = 'Confidential',
  refresh_frequency = 'Monthly';

ALTER TABLE loan_performance SET TAG
  domain = 'Credit Risk',
  source_system = 'Loan Servicing',
  data_sensitivity = 'Confidential',
  refresh_frequency = 'Monthly';

-- Contacts (visible in Data Catalog Table Details — governance)
CREATE CONTACT finance_data_team
  EMAIL_DISTRIBUTION_LIST = 'finance-data-team@sofi-hol.com';
CREATE CONTACT finance_data_support
  EMAIL_DISTRIBUTION_LIST = 'finance-data-support@sofi-hol.com';
CREATE CONTACT finance_security_compliance
  EMAIL_DISTRIBUTION_LIST = 'finance-security-compliance@sofi-hol.com';

-- Set at schema level so all 6 tables inherit them
ALTER SCHEMA financial SET CONTACT
  STEWARD = finance_data_team,
  SUPPORT = finance_data_support,
  SECURITY_COMPLIANCE = finance_security_compliance;

-- ============================================================
-- 5. Load Data (~2,100 rows)
-- ============================================================

-- Products (12 rows)
INSERT INTO products (product_id, product_name, category, risk_tier, launch_date) VALUES
(1, 'Personal Loan - Prime', 'Personal Loans', 'Prime', '2018-03-15'),
(2, 'Personal Loan - Near Prime', 'Personal Loans', 'Near Prime', '2018-03-15'),
(3, 'Personal Loan - Subprime', 'Personal Loans', 'Subprime', '2019-06-01'),
(4, 'Student Loan Refi - Variable', 'Student Loan Refinancing', 'Prime', '2017-01-10'),
(5, 'Student Loan Refi - Fixed', 'Student Loan Refinancing', 'Prime', '2017-01-10'),
(6, 'Student Loan Refi - Hybrid', 'Student Loan Refinancing', 'Near Prime', '2020-09-01'),
(7, 'Home Loan - 30yr Fixed', 'Home Loans', 'Prime', '2019-11-01'),
(8, 'Home Loan - 15yr Fixed', 'Home Loans', 'Prime', '2019-11-01'),
(9, 'Home Loan - ARM 5/1', 'Home Loans', 'Near Prime', '2020-03-15'),
(10, 'Credit Card - Essential', 'Credit Cards', 'Near Prime', '2021-04-01'),
(11, 'Credit Card - Premium', 'Credit Cards', 'Prime', '2021-04-01'),
(12, 'Credit Card - Secured', 'Credit Cards', 'Subprime', '2022-01-15');

-- Earnings Transcripts (16 rows)
INSERT INTO earnings_transcripts (transcript_id, company, ticker, quarter, fiscal_year, call_date, revenue_millions, eps, yoy_revenue_growth_pct, active_users_millions, key_themes, forward_guidance, sentiment_score) VALUES
(1, 'Coinbase', 'COIN', 'Q1', 2026, '2026-04-15', 1400.00, 1.72, 22.50, 110.00, 'Crypto adoption; institutional growth; international expansion; regulatory clarity', 'Revenue expected $1.5-1.7B in Q2; continued institutional focus', 0.78),
(2, 'Coinbase', 'COIN', 'Q2', 2026, '2026-07-20', 1550.00, 1.89, 18.30, 115.00, 'DeFi integration; staking revenue growth; Base L2 adoption; compliance investment', 'Full year revenue guidance raised to $6.2-6.5B', 0.82),
(3, 'Coinbase', 'COIN', 'Q3', 2025, '2025-10-18', 1250.00, 1.45, 15.20, 102.00, 'Cost optimization; international licensing; derivatives launch; custody growth', 'Q4 revenue guidance $1.3-1.5B; headcount stable', 0.71),
(4, 'Coinbase', 'COIN', 'Q4', 2025, '2026-01-22', 1320.00, 1.58, 19.80, 106.00, 'Bitcoin ETF tailwinds; retail re-engagement; subscription revenue mix shift', '2026 revenue guidance $5.8-6.2B; margin expansion target 35%', 0.75),
(5, 'Robinhood', 'HOOD', 'Q1', 2026, '2026-04-22', 890.00, 0.42, 35.00, 24.50, 'Options trading growth; retirement accounts; Gold subscription; crypto expansion', 'Q2 revenue $920-960M; targeting 30M funded accounts by year-end', 0.80),
(6, 'Robinhood', 'HOOD', 'Q2', 2026, '2026-07-25', 950.00, 0.48, 28.00, 25.80, 'International expansion UK/EU; advisory product launch; margin lending growth', 'Full year revenue raised to $3.8B; ARPU growth 15% target', 0.84),
(7, 'Robinhood', 'HOOD', 'Q3', 2025, '2025-10-22', 720.00, 0.28, 20.00, 22.10, 'Credit card launch; 24-hour trading; futures product; retirement AUM growth', 'Q4 revenue $780-820M; continued product investment', 0.68),
(8, 'Robinhood', 'HOOD', 'Q4', 2025, '2026-01-28', 810.00, 0.35, 25.00, 23.40, 'Record net deposits; crypto trading surge; index options; wealth management', '2026 revenue guidance $3.5-3.8B; path to 25% operating margin', 0.74),
(9, 'LendingClub', 'LC', 'Q1', 2026, '2026-04-18', 320.00, 0.44, 12.50, 5.20, 'Marketplace recovery; auto refinance growth; structured certificates; bank channel', 'Q2 originations $2.0-2.2B; net interest margin stable', 0.72),
(10, 'LendingClub', 'LC', 'Q2', 2026, '2026-07-22', 345.00, 0.52, 15.80, 5.50, 'Prime borrower mix improvement; bank partnership expansion; AI underwriting', 'Full year originations guidance raised to $8.5-9.0B', 0.76),
(11, 'LendingClub', 'LC', 'Q3', 2025, '2025-10-20', 275.00, 0.32, 8.00, 4.80, 'Rate environment headwinds; credit tightening; deposit growth; efficiency gains', 'Q4 originations $1.6-1.8B; provision expense elevated', 0.58),
(12, 'LendingClub', 'LC', 'Q4', 2025, '2026-01-25', 295.00, 0.38, 10.50, 5.00, 'Seasonal strength; buy-now-pay-later pilot; small business lending; investor demand', '2026 originations guidance $7.5-8.5B; targeting positive operating leverage', 0.65),
(13, 'Marqeta', 'MQ', 'Q1', 2026, '2026-04-20', 145.00, 0.02, 18.00, NULL, 'Block/Cash App renewal; embedded finance growth; credit card issuing; Europe launch', 'Q2 revenue $150-155M; gross profit margin 44-46%', 0.70),
(14, 'Marqeta', 'MQ', 'Q2', 2026, '2026-07-23', 155.00, 0.05, 20.50, NULL, 'Banking-as-a-service; expense management vertical; tokenization; Visa Direct integration', 'Full year revenue guidance $600-620M; adjusted EBITDA positive', 0.74),
(15, 'Marqeta', 'MQ', 'Q3', 2025, '2025-10-19', 118.00, -0.03, 10.00, NULL, 'Customer concentration risk; platform migration; new verticals; cost restructuring', 'Q4 revenue $125-130M; breakeven target Q1 2026', 0.55),
(16, 'Marqeta', 'MQ', 'Q4', 2025, '2026-01-24', 128.00, 0.00, 14.00, NULL, 'Diversification progress; fintech partnerships; cross-border payments; AI fraud detection', '2026 revenue guidance $570-600M; first full year of profitability expected', 0.62);

-- Invoices (500 rows)
INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(1, 9, 'INV-2025001', '2025-04-25', '2025-05-25', 35314.71, 'USD', 'Investor Relations', 'CC-4002', 'Paid', '2025-05-24', 'Annual license renewal'),
(2, 1, 'INV-2025002', '2026-03-09', '2026-04-08', 58548.89, 'USD', 'Tax', 'CC-1001', 'Paid', '2026-03-30', 'Compliance monitoring'),
(3, 18, 'INV-2025003', '2025-07-23', '2025-09-21', 175185.82, 'USD', 'Treasury', 'CC-1003', 'Paid', '2025-09-21', 'Document processing services'),
(4, 5, 'INV-2025004', '2025-12-15', '2026-01-29', 26001.46, 'USD', 'Investor Relations', 'CC-3002', 'Pending', NULL, 'Data feed - monthly'),
(5, 20, 'INV-2025005', '2026-01-03', '2026-02-17', 291302.64, 'USD', 'Corporate Finance', 'CC-1002', 'Paid', '2026-02-11', 'Compliance monitoring'),
(6, 20, 'INV-2025006', '2025-10-28', '2025-12-27', 70620.97, 'USD', 'Strategic Finance', 'CC-2002', 'Paid', '2025-12-24', 'Annual license renewal'),
(7, 13, 'INV-2025007', '2025-08-27', '2025-09-26', 214174.48, 'USD', 'Corporate Finance', 'CC-3001', 'Disputed', NULL, 'Regulatory filing support'),
(8, 9, 'INV-2025008', '2025-08-03', '2025-10-02', 160164.92, 'USD', 'Tax', 'CC-3002', 'Paid', '2025-09-25', 'API usage charges'),
(9, 11, 'INV-2025009', '2025-08-13', '2025-10-12', 412270.61, 'USD', 'Accounting', 'CC-2002', 'Paid', '2025-10-06', 'Annual license renewal'),
(10, 11, 'INV-2025010', '2025-08-05', '2025-10-04', 99210.16, 'USD', 'Investor Relations', 'CC-4001', 'Disputed', NULL, 'Consulting engagement - Phase 1'),
(11, 8, 'INV-2025011', '2025-09-29', '2025-10-29', 242795.22, 'USD', 'Legal', 'CC-5001', 'Pending', NULL, 'Cloud compute charges'),
(12, 5, 'INV-2025012', '2026-01-06', '2026-02-05', 23181.9, 'USD', 'Legal', 'CC-1001', 'Disputed', NULL, 'Data feed - monthly'),
(13, 6, 'INV-2025013', '2025-06-06', '2025-08-05', 96499.44, 'USD', 'Treasury', 'CC-4001', 'Paid', '2025-07-27', 'Financial modeling support'),
(14, 1, 'INV-2025014', '2025-09-15', '2025-11-14', 203078.96, 'USD', 'Tax', 'CC-2002', 'Pending', NULL, 'Document processing services'),
(15, 1, 'INV-2025015', '2025-06-11', '2025-07-26', 97884.87, 'USD', 'Corporate Finance', 'CC-2002', 'Paid', '2025-07-16', 'Financial modeling support'),
(16, 12, 'INV-2025016', '2025-07-23', '2025-08-22', 269872.57, 'USD', 'Capital Markets', 'CC-3001', 'Paid', '2025-08-21', 'Platform access fee'),
(17, 8, 'INV-2025017', '2025-09-03', '2025-10-03', 21870.54, 'USD', 'Technology', 'CC-1002', 'Paid', '2025-09-26', 'Compliance monitoring'),
(18, 16, 'INV-2025018', '2025-05-09', '2025-06-08', 66631.63, 'USD', 'Legal', 'CC-3002', 'Paid', '2025-05-30', 'Storage and archival services'),
(19, 10, 'INV-2025019', '2025-07-25', '2025-09-23', 282909.13, 'USD', 'Treasury', 'CC-1002', 'Pending', NULL, 'Training and certification'),
(20, 11, 'INV-2025020', '2025-08-19', '2025-09-18', 53235.88, 'USD', 'Accounting', 'CC-1001', 'Paid', '2025-09-08', 'Training and certification'),
(21, 11, 'INV-2025021', '2025-03-11', '2025-04-10', 69980.08, 'USD', 'Tax', 'CC-2001', 'Paid', '2025-04-03', 'Compliance monitoring'),
(22, 19, 'INV-2025022', '2025-05-16', '2025-07-15', 61127.81, 'USD', 'Technology', 'CC-4001', 'Disputed', NULL, 'Document processing services'),
(23, 4, 'INV-2025023', '2025-07-14', '2025-08-13', 260161.1, 'USD', 'Treasury', 'CC-1001', 'Pending', NULL, 'Data feed - monthly'),
(24, 11, 'INV-2025024', '2025-03-04', '2025-04-18', 48301.72, 'USD', 'Tax', 'CC-4001', 'Paid', '2025-04-10', 'Consulting engagement - Phase 1'),
(25, 9, 'INV-2025025', '2026-03-09', '2026-04-08', 83923.2, 'USD', 'Procurement', 'CC-1002', 'Paid', '2026-03-31', 'Quarterly advisory retainer'),
(26, 8, 'INV-2025026', '2025-01-16', '2025-02-15', 146186.28, 'USD', 'Capital Markets', 'CC-3002', 'Overdue', NULL, 'Quarterly advisory retainer'),
(27, 1, 'INV-2025027', '2025-06-18', '2025-08-02', 403308.21, 'USD', 'Treasury', 'CC-2002', 'Pending', NULL, 'Document processing services'),
(28, 7, 'INV-2025028', '2026-05-14', '2026-06-13', 310631.13, 'USD', 'Corporate Finance', 'CC-1001', 'Paid', '2026-06-05', 'Audit support services'),
(29, 19, 'INV-2025029', '2025-02-28', '2025-03-30', 14691.46, 'USD', 'Procurement', 'CC-1002', 'Paid', '2025-03-22', 'Implementation services'),
(30, 3, 'INV-2025030', '2025-03-12', '2025-05-11', 30411.71, 'USD', 'Investor Relations', 'CC-5001', 'Overdue', NULL, 'Training and certification'),
(31, 3, 'INV-2025031', '2025-02-10', '2025-04-11', 141916.64, 'USD', 'Treasury', 'CC-3001', 'Pending', NULL, 'Training and certification'),
(32, 5, 'INV-2025032', '2025-09-29', '2025-11-13', 79386.21, 'USD', 'Corporate Finance', 'CC-1002', 'Disputed', NULL, 'Monthly subscription fee'),
(33, 19, 'INV-2025033', '2026-04-15', '2026-06-14', 277648.11, 'USD', 'Tax', 'CC-3001', 'Paid', '2026-06-12', 'Annual license renewal'),
(34, 10, 'INV-2025034', '2025-09-08', '2025-10-23', 366592.97, 'USD', 'Capital Markets', 'CC-5001', 'Disputed', NULL, 'Financial modeling support'),
(35, 18, 'INV-2025035', '2025-01-09', '2025-03-10', 110431.0, 'USD', 'Corporate Finance', 'CC-1002', 'Paid', '2025-03-09', 'Compliance monitoring'),
(36, 10, 'INV-2025036', '2025-06-09', '2025-07-24', 141618.79, 'USD', 'Technology', 'CC-2002', 'Paid', '2025-07-14', 'Financial modeling support'),
(37, 2, 'INV-2025037', '2026-05-16', '2026-06-30', 69839.04, 'USD', 'Tax', 'CC-3001', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(38, 15, 'INV-2025038', '2025-09-26', '2025-10-26', 100343.25, 'USD', 'Legal', 'CC-1003', 'Overdue', NULL, 'Compliance monitoring'),
(39, 19, 'INV-2025039', '2025-02-06', '2025-03-23', 68822.99, 'USD', 'Legal', 'CC-1001', 'Paid', '2025-03-18', 'Regulatory filing support'),
(40, 8, 'INV-2025040', '2025-08-04', '2025-10-03', 447860.62, 'USD', 'Tax', 'CC-3002', 'Pending', NULL, 'Professional development'),
(41, 6, 'INV-2025041', '2025-06-08', '2025-07-08', 6684.2, 'USD', 'Capital Markets', 'CC-3001', 'Overdue', NULL, 'Document processing services'),
(42, 6, 'INV-2025042', '2025-09-12', '2025-10-27', 436366.96, 'USD', 'Tax', 'CC-2001', 'Overdue', NULL, 'Storage and archival services'),
(43, 10, 'INV-2025043', '2026-04-17', '2026-06-01', 6404.28, 'USD', 'Investor Relations', 'CC-3002', 'Paid', '2026-05-29', 'Audit support services'),
(44, 9, 'INV-2025044', '2025-10-13', '2025-11-12', 429647.52, 'USD', 'Strategic Finance', 'CC-3001', 'Overdue', NULL, 'Monthly subscription fee'),
(45, 6, 'INV-2025045', '2025-04-29', '2025-06-13', 10045.17, 'USD', 'Technology', 'CC-5001', 'Pending', NULL, 'Document processing services'),
(46, 11, 'INV-2025046', '2025-12-20', '2026-02-18', 96606.26, 'USD', 'Treasury', 'CC-2001', 'Paid', '2026-02-09', 'API usage charges'),
(47, 14, 'INV-2025047', '2025-02-15', '2025-04-16', 91373.26, 'USD', 'Accounting', 'CC-3001', 'Paid', '2025-04-15', 'Professional development'),
(48, 4, 'INV-2025048', '2025-11-18', '2026-01-17', 196782.31, 'USD', 'Corporate Finance', 'CC-2002', 'Pending', NULL, 'Compliance monitoring'),
(49, 14, 'INV-2025049', '2025-05-11', '2025-06-10', 185427.44, 'USD', 'Treasury', 'CC-1001', 'Paid', '2025-06-02', 'Platform access fee'),
(50, 14, 'INV-2025050', '2025-10-21', '2025-11-20', 248971.91, 'USD', 'Technology', 'CC-2001', 'Pending', NULL, 'Financial modeling support');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(51, 6, 'INV-2025051', '2026-04-30', '2026-06-29', 334823.39, 'USD', 'Tax', 'CC-3001', 'Pending', NULL, 'Annual license renewal'),
(52, 10, 'INV-2025052', '2025-08-29', '2025-10-28', 37264.81, 'USD', 'Investor Relations', 'CC-2001', 'Paid', '2025-10-28', 'Tax preparation services'),
(53, 14, 'INV-2025053', '2025-03-16', '2025-04-30', 222790.31, 'USD', 'Technology', 'CC-2001', 'Paid', '2025-04-24', 'Consulting engagement - Phase 1'),
(54, 14, 'INV-2025054', '2025-01-06', '2025-02-05', 363160.3, 'USD', 'Investor Relations', 'CC-1001', 'Paid', '2025-01-29', 'Compliance monitoring'),
(55, 15, 'INV-2025055', '2025-09-13', '2025-10-13', 494551.6, 'USD', 'Capital Markets', 'CC-5001', 'Disputed', NULL, 'Audit support services'),
(56, 17, 'INV-2025056', '2026-03-30', '2026-05-29', 384644.95, 'USD', 'Treasury', 'CC-4001', 'Disputed', NULL, 'Risk assessment report'),
(57, 9, 'INV-2025057', '2025-09-23', '2025-10-23', 173568.85, 'USD', 'Legal', 'CC-1002', 'Disputed', NULL, 'Platform access fee'),
(58, 11, 'INV-2025058', '2025-08-29', '2025-10-13', 35024.33, 'USD', 'Strategic Finance', 'CC-3002', 'Paid', '2025-10-10', 'Consulting engagement - Phase 1'),
(59, 14, 'INV-2025059', '2025-08-08', '2025-09-07', 237098.41, 'USD', 'Treasury', 'CC-2001', 'Pending', NULL, 'Document processing services'),
(60, 1, 'INV-2025060', '2026-02-03', '2026-04-04', 474233.75, 'USD', 'Technology', 'CC-2002', 'Overdue', NULL, 'Cloud compute charges'),
(61, 18, 'INV-2025061', '2026-03-06', '2026-05-05', 172820.89, 'USD', 'Technology', 'CC-1001', 'Paid', '2026-04-28', 'Cloud compute charges'),
(62, 13, 'INV-2025062', '2025-12-11', '2026-02-09', 491324.89, 'USD', 'Capital Markets', 'CC-4002', 'Disputed', NULL, 'Monthly subscription fee'),
(63, 19, 'INV-2025063', '2026-02-08', '2026-04-09', 111064.77, 'USD', 'Accounting', 'CC-1003', 'Paid', '2026-04-02', 'Quarterly advisory retainer'),
(64, 11, 'INV-2025064', '2025-09-24', '2025-11-08', 82048.03, 'USD', 'Investor Relations', 'CC-3002', 'Disputed', NULL, 'API usage charges'),
(65, 3, 'INV-2025065', '2026-03-08', '2026-04-22', 73438.52, 'USD', 'Procurement', 'CC-2001', 'Paid', '2026-04-17', 'Annual license renewal'),
(66, 8, 'INV-2025066', '2025-02-11', '2025-03-13', 157345.22, 'USD', 'Investor Relations', 'CC-1002', 'Paid', '2025-03-06', 'Software maintenance'),
(67, 9, 'INV-2025067', '2025-08-12', '2025-09-26', 483680.63, 'USD', 'Strategic Finance', 'CC-1003', 'Paid', '2025-09-25', 'Platform access fee'),
(68, 1, 'INV-2025068', '2025-04-21', '2025-06-20', 99465.28, 'USD', 'Corporate Finance', 'CC-2001', 'Overdue', NULL, 'Annual license renewal'),
(69, 10, 'INV-2025069', '2025-09-06', '2025-10-06', 304669.65, 'USD', 'Technology', 'CC-3001', 'Paid', '2025-10-06', 'Compliance monitoring'),
(70, 12, 'INV-2025070', '2026-03-15', '2026-05-14', 3656.71, 'USD', 'Tax', 'CC-3002', 'Pending', NULL, 'Tax preparation services'),
(71, 12, 'INV-2025071', '2025-04-19', '2025-06-03', 380207.89, 'USD', 'Procurement', 'CC-2002', 'Paid', '2025-05-24', 'Professional development'),
(72, 14, 'INV-2025072', '2026-05-11', '2026-06-25', 80914.99, 'USD', 'Technology', 'CC-2001', 'Pending', NULL, 'Annual license renewal'),
(73, 8, 'INV-2025073', '2025-10-13', '2025-11-27', 84430.96, 'USD', 'Procurement', 'CC-4001', 'Overdue', NULL, 'Audit support services'),
(74, 7, 'INV-2025074', '2025-07-06', '2025-08-20', 85414.54, 'USD', 'Strategic Finance', 'CC-5001', 'Pending', NULL, 'API usage charges'),
(75, 7, 'INV-2025075', '2025-01-11', '2025-03-12', 269860.03, 'USD', 'Tax', 'CC-4001', 'Paid', '2025-03-09', 'Tax preparation services'),
(76, 3, 'INV-2025076', '2026-04-04', '2026-05-04', 159487.32, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2026-04-24', 'Regulatory filing support'),
(77, 17, 'INV-2025077', '2026-04-30', '2026-06-29', 297674.81, 'USD', 'Strategic Finance', 'CC-3001', 'Overdue', NULL, 'Risk assessment report'),
(78, 9, 'INV-2025078', '2025-10-05', '2025-11-19', 191996.57, 'USD', 'Investor Relations', 'CC-1003', 'Paid', '2025-11-11', 'Storage and archival services'),
(79, 16, 'INV-2025079', '2025-08-10', '2025-10-09', 424682.76, 'USD', 'Corporate Finance', 'CC-2002', 'Pending', NULL, 'Training and certification'),
(80, 10, 'INV-2025080', '2026-01-05', '2026-02-04', 68940.68, 'USD', 'Accounting', 'CC-4002', 'Paid', '2026-02-04', 'Platform access fee'),
(81, 16, 'INV-2025081', '2025-05-10', '2025-07-09', 261228.63, 'USD', 'Tax', 'CC-3001', 'Paid', '2025-07-02', 'Implementation services'),
(82, 16, 'INV-2025082', '2025-02-22', '2025-04-08', 83336.98, 'USD', 'Tax', 'CC-1001', 'Paid', '2025-03-29', 'Consulting engagement - Phase 1'),
(83, 10, 'INV-2025083', '2025-06-02', '2025-08-01', 30053.66, 'USD', 'Tax', 'CC-5001', 'Paid', '2025-07-26', 'Professional development'),
(84, 13, 'INV-2025084', '2025-08-20', '2025-10-19', 74689.61, 'USD', 'Procurement', 'CC-5001', 'Disputed', NULL, 'Document processing services'),
(85, 20, 'INV-2025085', '2025-11-09', '2026-01-08', 143504.56, 'USD', 'Accounting', 'CC-2002', 'Paid', '2026-01-05', 'Annual license renewal'),
(86, 6, 'INV-2025086', '2025-06-10', '2025-07-10', 39554.89, 'USD', 'Legal', 'CC-4001', 'Paid', '2025-07-04', 'Professional development'),
(87, 2, 'INV-2025087', '2026-04-27', '2026-06-11', 366344.4, 'USD', 'Investor Relations', 'CC-4001', 'Pending', NULL, 'Annual license renewal'),
(88, 19, 'INV-2025088', '2025-08-28', '2025-10-12', 29136.69, 'USD', 'Investor Relations', 'CC-2001', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(89, 3, 'INV-2025089', '2025-09-30', '2025-10-30', 317769.82, 'USD', 'Accounting', 'CC-2002', 'Paid', '2025-10-21', 'Risk assessment report'),
(90, 10, 'INV-2025090', '2025-05-08', '2025-06-22', 272207.85, 'USD', 'Treasury', 'CC-1002', 'Pending', NULL, 'Professional development'),
(91, 11, 'INV-2025091', '2025-02-10', '2025-03-27', 6953.29, 'USD', 'Technology', 'CC-2001', 'Pending', NULL, 'Software maintenance'),
(92, 9, 'INV-2025092', '2025-01-22', '2025-03-23', 128835.83, 'USD', 'Technology', 'CC-4001', 'Paid', '2025-03-15', 'API usage charges'),
(93, 14, 'INV-2025093', '2025-07-05', '2025-09-03', 233756.64, 'USD', 'Procurement', 'CC-1002', 'Paid', '2025-08-29', 'Implementation services'),
(94, 16, 'INV-2025094', '2025-12-04', '2026-01-18', 297543.47, 'USD', 'Corporate Finance', 'CC-4001', 'Overdue', NULL, 'Annual license renewal'),
(95, 11, 'INV-2025095', '2025-11-19', '2026-01-03', 421217.24, 'USD', 'Tax', 'CC-1001', 'Overdue', NULL, 'Compliance monitoring'),
(96, 2, 'INV-2025096', '2026-04-19', '2026-06-03', 274321.9, 'USD', 'Investor Relations', 'CC-4001', 'Pending', NULL, 'Quarterly advisory retainer'),
(97, 18, 'INV-2025097', '2025-07-28', '2025-09-11', 364212.51, 'USD', 'Capital Markets', 'CC-1002', 'Pending', NULL, 'Monthly subscription fee'),
(98, 6, 'INV-2025098', '2025-09-03', '2025-11-02', 91944.14, 'USD', 'Corporate Finance', 'CC-4001', 'Paid', '2025-11-01', 'Data feed - monthly'),
(99, 10, 'INV-2025099', '2025-06-07', '2025-07-22', 267124.81, 'USD', 'Legal', 'CC-4001', 'Pending', NULL, 'Training and certification'),
(100, 5, 'INV-2025100', '2026-04-13', '2026-06-12', 278708.4, 'USD', 'Treasury', 'CC-1002', 'Paid', '2026-06-10', 'API usage charges');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(101, 17, 'INV-2025101', '2026-03-01', '2026-04-15', 71068.33, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2026-04-11', 'Software maintenance'),
(102, 15, 'INV-2025102', '2026-05-17', '2026-06-16', 86608.42, 'USD', 'Legal', 'CC-4002', 'Disputed', NULL, 'Compliance monitoring'),
(103, 11, 'INV-2025103', '2026-01-22', '2026-03-08', 155103.1, 'USD', 'Investor Relations', 'CC-1001', 'Paid', '2026-03-02', 'Audit support services'),
(104, 13, 'INV-2025104', '2026-04-30', '2026-06-29', 66658.83, 'USD', 'Treasury', 'CC-5001', 'Paid', '2026-06-21', 'Audit support services'),
(105, 4, 'INV-2025105', '2025-04-13', '2025-05-28', 4329.23, 'USD', 'Legal', 'CC-1003', 'Disputed', NULL, 'Document processing services'),
(106, 16, 'INV-2025106', '2025-06-08', '2025-07-08', 228867.5, 'USD', 'Corporate Finance', 'CC-1002', 'Pending', NULL, 'Audit support services'),
(107, 16, 'INV-2025107', '2026-01-25', '2026-03-11', 155646.61, 'USD', 'Legal', 'CC-2002', 'Paid', '2026-03-01', 'Training and certification'),
(108, 4, 'INV-2025108', '2025-04-03', '2025-05-18', 42008.01, 'USD', 'Tax', 'CC-2002', 'Disputed', NULL, 'Monthly subscription fee'),
(109, 2, 'INV-2025109', '2025-02-17', '2025-04-03', 94022.85, 'USD', 'Corporate Finance', 'CC-1003', 'Pending', NULL, 'Training and certification'),
(110, 19, 'INV-2025110', '2026-06-28', '2026-08-12', 44179.8, 'USD', 'Capital Markets', 'CC-3002', 'Paid', '2026-08-03', 'Professional development'),
(111, 19, 'INV-2025111', '2025-09-04', '2025-10-19', 164289.8, 'USD', 'Capital Markets', 'CC-1001', 'Paid', '2025-10-15', 'Risk assessment report'),
(112, 18, 'INV-2025112', '2025-10-22', '2025-12-21', 205504.53, 'USD', 'Capital Markets', 'CC-2002', 'Paid', '2025-12-12', 'Document processing services'),
(113, 10, 'INV-2025113', '2025-09-14', '2025-10-29', 97993.97, 'USD', 'Investor Relations', 'CC-3002', 'Overdue', NULL, 'Software maintenance'),
(114, 10, 'INV-2025114', '2026-01-03', '2026-03-04', 346203.42, 'USD', 'Corporate Finance', 'CC-1001', 'Paid', '2026-02-28', 'Software maintenance'),
(115, 16, 'INV-2025115', '2025-02-20', '2025-04-21', 208544.43, 'USD', 'Corporate Finance', 'CC-2001', 'Paid', '2025-04-11', 'Professional development'),
(116, 5, 'INV-2025116', '2025-09-14', '2025-11-13', 77578.75, 'USD', 'Tax', 'CC-1001', 'Paid', '2025-11-06', 'Software maintenance'),
(117, 5, 'INV-2025117', '2026-01-09', '2026-03-10', 82016.42, 'USD', 'Tax', 'CC-3002', 'Pending', NULL, 'Implementation services'),
(118, 18, 'INV-2025118', '2025-07-25', '2025-08-24', 165636.54, 'USD', 'Strategic Finance', 'CC-4001', 'Pending', NULL, 'Platform access fee'),
(119, 15, 'INV-2025119', '2025-12-13', '2026-01-12', 151526.61, 'USD', 'Tax', 'CC-3002', 'Paid', '2026-01-02', 'Compliance monitoring'),
(120, 13, 'INV-2025120', '2026-01-10', '2026-02-09', 254653.71, 'USD', 'Accounting', 'CC-2002', 'Pending', NULL, 'Software maintenance'),
(121, 12, 'INV-2025121', '2026-01-26', '2026-03-27', 328796.09, 'USD', 'Tax', 'CC-3001', 'Paid', '2026-03-19', 'Professional development'),
(122, 3, 'INV-2025122', '2025-08-15', '2025-10-14', 102504.17, 'USD', 'Procurement', 'CC-1001', 'Pending', NULL, 'Quarterly advisory retainer'),
(123, 4, 'INV-2025123', '2025-11-08', '2025-12-23', 111048.82, 'USD', 'Tax', 'CC-3001', 'Paid', '2025-12-16', 'Compliance monitoring'),
(124, 5, 'INV-2025124', '2026-03-06', '2026-05-05', 327043.5, 'USD', 'Treasury', 'CC-1001', 'Paid', '2026-05-01', 'Regulatory filing support'),
(125, 15, 'INV-2025125', '2025-08-11', '2025-09-25', 25288.98, 'USD', 'Investor Relations', 'CC-3001', 'Pending', NULL, 'Compliance monitoring'),
(126, 13, 'INV-2025126', '2026-01-03', '2026-02-02', 477054.85, 'USD', 'Corporate Finance', 'CC-1002', 'Paid', '2026-01-26', 'Storage and archival services'),
(127, 11, 'INV-2025127', '2025-01-22', '2025-02-21', 142342.51, 'USD', 'Investor Relations', 'CC-2001', 'Paid', '2025-02-13', 'Software maintenance'),
(128, 11, 'INV-2025128', '2025-08-10', '2025-09-09', 69680.07, 'USD', 'Capital Markets', 'CC-1003', 'Paid', '2025-09-07', 'Compliance monitoring'),
(129, 4, 'INV-2025129', '2025-09-14', '2025-10-14', 4207.65, 'USD', 'Accounting', 'CC-5001', 'Paid', '2025-10-11', 'Audit support services'),
(130, 9, 'INV-2025130', '2025-01-17', '2025-02-16', 286738.49, 'USD', 'Accounting', 'CC-4001', 'Paid', '2025-02-15', 'Risk assessment report'),
(131, 19, 'INV-2025131', '2026-01-06', '2026-03-07', 475437.04, 'USD', 'Tax', 'CC-1001', 'Disputed', NULL, 'Financial modeling support'),
(132, 1, 'INV-2025132', '2025-11-05', '2025-12-20', 241823.13, 'USD', 'Accounting', 'CC-1002', 'Disputed', NULL, 'Tax preparation services'),
(133, 3, 'INV-2025133', '2026-03-31', '2026-04-30', 16887.72, 'USD', 'Strategic Finance', 'CC-5001', 'Paid', '2026-04-26', 'Software maintenance'),
(134, 20, 'INV-2025134', '2025-11-29', '2026-01-13', 322442.06, 'USD', 'Legal', 'CC-1002', 'Pending', NULL, 'Data feed - monthly'),
(135, 15, 'INV-2025135', '2025-08-09', '2025-09-23', 85063.44, 'USD', 'Investor Relations', 'CC-4001', 'Overdue', NULL, 'Cloud compute charges'),
(136, 4, 'INV-2025136', '2026-03-02', '2026-05-01', 78474.63, 'USD', 'Strategic Finance', 'CC-2002', 'Overdue', NULL, 'Regulatory filing support'),
(137, 16, 'INV-2025137', '2025-06-06', '2025-08-05', 91953.55, 'USD', 'Tax', 'CC-3001', 'Paid', '2025-08-04', 'Consulting engagement - Phase 1'),
(138, 18, 'INV-2025138', '2025-03-03', '2025-05-02', 234863.88, 'USD', 'Legal', 'CC-3002', 'Pending', NULL, 'Quarterly advisory retainer'),
(139, 10, 'INV-2025139', '2025-10-22', '2025-12-21', 145732.46, 'USD', 'Strategic Finance', 'CC-4001', 'Paid', '2025-12-11', 'Training and certification'),
(140, 18, 'INV-2025140', '2025-04-21', '2025-06-05', 308345.0, 'USD', 'Strategic Finance', 'CC-4002', 'Paid', '2025-05-30', 'Professional development'),
(141, 9, 'INV-2025141', '2025-01-27', '2025-03-28', 68680.96, 'USD', 'Accounting', 'CC-3001', 'Paid', '2025-03-24', 'Regulatory filing support'),
(142, 5, 'INV-2025142', '2025-01-07', '2025-02-06', 17861.56, 'USD', 'Technology', 'CC-1001', 'Overdue', NULL, 'Annual license renewal'),
(143, 13, 'INV-2025143', '2026-06-28', '2026-07-28', 85553.55, 'USD', 'Treasury', 'CC-3001', 'Disputed', NULL, 'Platform access fee'),
(144, 20, 'INV-2025144', '2025-11-29', '2026-01-28', 39317.19, 'USD', 'Tax', 'CC-1001', 'Paid', '2026-01-19', 'Annual license renewal'),
(145, 14, 'INV-2025145', '2025-10-06', '2025-11-20', 147006.03, 'USD', 'Procurement', 'CC-4002', 'Disputed', NULL, 'Data feed - monthly'),
(146, 4, 'INV-2025146', '2025-12-20', '2026-02-03', 188788.73, 'USD', 'Corporate Finance', 'CC-2001', 'Disputed', NULL, 'Cloud compute charges'),
(147, 7, 'INV-2025147', '2025-02-26', '2025-03-28', 393872.4, 'USD', 'Corporate Finance', 'CC-3001', 'Paid', '2025-03-24', 'Data feed - monthly'),
(148, 14, 'INV-2025148', '2025-01-08', '2025-02-22', 95361.76, 'USD', 'Capital Markets', 'CC-4002', 'Paid', '2025-02-19', 'Compliance monitoring'),
(149, 13, 'INV-2025149', '2025-12-29', '2026-01-28', 5176.01, 'USD', 'Accounting', 'CC-1002', 'Overdue', NULL, 'Audit support services'),
(150, 13, 'INV-2025150', '2026-03-16', '2026-05-15', 29235.76, 'USD', 'Treasury', 'CC-1001', 'Pending', NULL, 'Audit support services');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(151, 15, 'INV-2025151', '2025-06-25', '2025-08-24', 97638.41, 'USD', 'Strategic Finance', 'CC-5001', 'Paid', '2025-08-18', 'Cloud compute charges'),
(152, 13, 'INV-2025152', '2026-06-21', '2026-07-21', 55782.23, 'USD', 'Corporate Finance', 'CC-1003', 'Pending', NULL, 'Annual license renewal'),
(153, 4, 'INV-2025153', '2026-06-07', '2026-08-06', 207218.87, 'USD', 'Legal', 'CC-1003', 'Paid', '2026-07-27', 'Training and certification'),
(154, 9, 'INV-2025154', '2025-04-16', '2025-05-16', 392096.88, 'USD', 'Investor Relations', 'CC-1002', 'Paid', '2025-05-06', 'Implementation services'),
(155, 19, 'INV-2025155', '2026-05-21', '2026-07-05', 446921.67, 'USD', 'Technology', 'CC-5001', 'Disputed', NULL, 'Audit support services'),
(156, 15, 'INV-2025156', '2025-11-20', '2025-12-20', 186269.2, 'USD', 'Tax', 'CC-2002', 'Disputed', NULL, 'Software maintenance'),
(157, 17, 'INV-2025157', '2025-02-27', '2025-04-13', 66923.26, 'USD', 'Tax', 'CC-3001', 'Pending', NULL, 'Platform access fee'),
(158, 3, 'INV-2025158', '2025-03-20', '2025-05-19', 299442.37, 'USD', 'Technology', 'CC-1001', 'Overdue', NULL, 'Risk assessment report'),
(159, 20, 'INV-2025159', '2025-07-12', '2025-08-26', 252735.4, 'USD', 'Procurement', 'CC-1002', 'Paid', '2025-08-21', 'Financial modeling support'),
(160, 8, 'INV-2025160', '2025-06-26', '2025-07-26', 324412.43, 'USD', 'Procurement', 'CC-3001', 'Disputed', NULL, 'Regulatory filing support'),
(161, 14, 'INV-2025161', '2025-10-17', '2025-12-01', 341287.41, 'USD', 'Strategic Finance', 'CC-3001', 'Paid', '2025-11-30', 'Data feed - monthly'),
(162, 9, 'INV-2025162', '2026-01-31', '2026-03-17', 83673.83, 'USD', 'Technology', 'CC-1003', 'Paid', '2026-03-08', 'Regulatory filing support'),
(163, 13, 'INV-2025163', '2025-11-14', '2026-01-13', 77740.68, 'USD', 'Capital Markets', 'CC-3001', 'Paid', '2026-01-07', 'Consulting engagement - Phase 1'),
(164, 14, 'INV-2025164', '2026-06-24', '2026-07-24', 5048.52, 'USD', 'Legal', 'CC-2002', 'Pending', NULL, 'Implementation services'),
(165, 16, 'INV-2025165', '2025-08-08', '2025-09-22', 119725.33, 'USD', 'Investor Relations', 'CC-1002', 'Paid', '2025-09-18', 'Financial modeling support'),
(166, 11, 'INV-2025166', '2026-06-24', '2026-07-24', 119413.74, 'USD', 'Technology', 'CC-5001', 'Paid', '2026-07-22', 'Implementation services'),
(167, 14, 'INV-2025167', '2026-03-25', '2026-04-24', 324767.94, 'USD', 'Strategic Finance', 'CC-2001', 'Paid', '2026-04-17', 'Compliance monitoring'),
(168, 16, 'INV-2025168', '2025-09-02', '2025-10-17', 306688.73, 'USD', 'Investor Relations', 'CC-4001', 'Pending', NULL, 'Risk assessment report'),
(169, 17, 'INV-2025169', '2025-10-16', '2025-11-30', 417601.06, 'USD', 'Legal', 'CC-5001', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(170, 16, 'INV-2025170', '2025-09-14', '2025-10-14', 282159.22, 'USD', 'Strategic Finance', 'CC-2002', 'Paid', '2025-10-13', 'Annual license renewal'),
(171, 15, 'INV-2025171', '2025-06-14', '2025-07-29', 91271.11, 'USD', 'Legal', 'CC-4001', 'Paid', '2025-07-26', 'Regulatory filing support'),
(172, 2, 'INV-2025172', '2025-01-28', '2025-03-14', 59326.63, 'USD', 'Treasury', 'CC-1002', 'Pending', NULL, 'Regulatory filing support'),
(173, 11, 'INV-2025173', '2025-08-18', '2025-09-17', 111919.81, 'USD', 'Tax', 'CC-2002', 'Pending', NULL, 'Tax preparation services'),
(174, 16, 'INV-2025174', '2025-05-23', '2025-07-22', 58551.75, 'USD', 'Procurement', 'CC-1003', 'Paid', '2025-07-19', 'Compliance monitoring'),
(175, 4, 'INV-2025175', '2026-06-25', '2026-08-09', 75637.22, 'USD', 'Corporate Finance', 'CC-2001', 'Paid', '2026-08-09', 'Document processing services'),
(176, 4, 'INV-2025176', '2026-04-14', '2026-05-14', 308771.36, 'USD', 'Procurement', 'CC-2002', 'Paid', '2026-05-12', 'Document processing services'),
(177, 12, 'INV-2025177', '2025-01-02', '2025-03-03', 47234.82, 'USD', 'Investor Relations', 'CC-1002', 'Overdue', NULL, 'Financial modeling support'),
(178, 17, 'INV-2025178', '2026-01-05', '2026-02-04', 97918.21, 'USD', 'Legal', 'CC-1001', 'Paid', '2026-01-28', 'Cloud compute charges'),
(179, 1, 'INV-2025179', '2026-01-18', '2026-03-04', 86528.22, 'USD', 'Strategic Finance', 'CC-1002', 'Paid', '2026-02-22', 'Software maintenance'),
(180, 2, 'INV-2025180', '2025-12-07', '2026-01-06', 128790.11, 'USD', 'Strategic Finance', 'CC-4001', 'Pending', NULL, 'Tax preparation services'),
(181, 3, 'INV-2025181', '2025-07-06', '2025-08-05', 73713.92, 'USD', 'Procurement', 'CC-2001', 'Paid', '2025-08-05', 'Quarterly advisory retainer'),
(182, 17, 'INV-2025182', '2025-11-20', '2026-01-04', 63701.78, 'USD', 'Treasury', 'CC-2001', 'Disputed', NULL, 'Platform access fee'),
(183, 11, 'INV-2025183', '2026-01-01', '2026-01-31', 246628.12, 'USD', 'Corporate Finance', 'CC-4001', 'Paid', '2026-01-25', 'Cloud compute charges'),
(184, 16, 'INV-2025184', '2025-12-14', '2026-01-13', 283674.13, 'USD', 'Procurement', 'CC-1002', 'Pending', NULL, 'Document processing services'),
(185, 20, 'INV-2025185', '2025-03-22', '2025-05-06', 80642.25, 'USD', 'Capital Markets', 'CC-1002', 'Pending', NULL, 'Audit support services'),
(186, 15, 'INV-2025186', '2025-10-30', '2025-12-14', 42077.87, 'USD', 'Technology', 'CC-4001', 'Overdue', NULL, 'Regulatory filing support'),
(187, 12, 'INV-2025187', '2026-04-03', '2026-05-03', 69001.56, 'USD', 'Technology', 'CC-1001', 'Overdue', NULL, 'Annual license renewal'),
(188, 17, 'INV-2025188', '2026-02-20', '2026-04-06', 36123.48, 'USD', 'Capital Markets', 'CC-4001', 'Paid', '2026-03-28', 'Quarterly advisory retainer'),
(189, 8, 'INV-2025189', '2025-05-10', '2025-06-09', 96022.17, 'USD', 'Strategic Finance', 'CC-5001', 'Pending', NULL, 'Quarterly advisory retainer'),
(190, 15, 'INV-2025190', '2025-06-07', '2025-08-06', 84598.44, 'USD', 'Strategic Finance', 'CC-1003', 'Pending', NULL, 'Financial modeling support'),
(191, 11, 'INV-2025191', '2026-01-11', '2026-02-25', 61661.0, 'USD', 'Corporate Finance', 'CC-4001', 'Paid', '2026-02-23', 'Financial modeling support'),
(192, 4, 'INV-2025192', '2026-02-01', '2026-04-02', 146556.69, 'USD', 'Corporate Finance', 'CC-5001', 'Pending', NULL, 'Platform access fee'),
(193, 4, 'INV-2025193', '2026-05-18', '2026-06-17', 454405.56, 'USD', 'Capital Markets', 'CC-1002', 'Paid', '2026-06-10', 'Audit support services'),
(194, 3, 'INV-2025194', '2025-12-22', '2026-02-20', 433112.92, 'USD', 'Legal', 'CC-1003', 'Pending', NULL, 'Regulatory filing support'),
(195, 4, 'INV-2025195', '2026-06-05', '2026-07-05', 59565.68, 'USD', 'Investor Relations', 'CC-1001', 'Paid', '2026-06-28', 'Regulatory filing support'),
(196, 18, 'INV-2025196', '2026-01-13', '2026-02-27', 16904.15, 'USD', 'Capital Markets', 'CC-4001', 'Paid', '2026-02-21', 'Financial modeling support'),
(197, 19, 'INV-2025197', '2026-02-25', '2026-04-11', 339052.37, 'USD', 'Tax', 'CC-4001', 'Paid', '2026-04-04', 'Financial modeling support'),
(198, 18, 'INV-2025198', '2025-12-19', '2026-01-18', 108064.83, 'USD', 'Technology', 'CC-1001', 'Paid', '2026-01-10', 'Data feed - monthly'),
(199, 10, 'INV-2025199', '2026-06-15', '2026-07-15', 81003.86, 'USD', 'Capital Markets', 'CC-3001', 'Paid', '2026-07-12', 'Financial modeling support'),
(200, 9, 'INV-2025200', '2025-10-18', '2025-11-17', 31729.99, 'USD', 'Investor Relations', 'CC-2002', 'Pending', NULL, 'Professional development');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(201, 6, 'INV-2025201', '2025-04-06', '2025-06-05', 43214.56, 'USD', 'Technology', 'CC-5001', 'Paid', '2025-05-27', 'Audit support services'),
(202, 3, 'INV-2025202', '2025-02-12', '2025-03-14', 395131.55, 'USD', 'Accounting', 'CC-3002', 'Pending', NULL, 'Professional development'),
(203, 18, 'INV-2025203', '2025-02-01', '2025-03-18', 412109.67, 'USD', 'Corporate Finance', 'CC-3002', 'Pending', NULL, 'Platform access fee'),
(204, 2, 'INV-2025204', '2026-04-10', '2026-05-10', 258998.97, 'USD', 'Capital Markets', 'CC-3001', 'Disputed', NULL, 'Professional development'),
(205, 11, 'INV-2025205', '2025-05-28', '2025-07-12', 33126.15, 'USD', 'Strategic Finance', 'CC-3001', 'Overdue', NULL, 'Financial modeling support'),
(206, 8, 'INV-2025206', '2025-04-19', '2025-06-03', 67234.18, 'USD', 'Procurement', 'CC-1003', 'Paid', '2025-05-31', 'Data feed - monthly'),
(207, 13, 'INV-2025207', '2025-02-21', '2025-04-07', 62443.43, 'USD', 'Technology', 'CC-1003', 'Overdue', NULL, 'Audit support services'),
(208, 6, 'INV-2025208', '2025-11-17', '2025-12-17', 188843.22, 'USD', 'Procurement', 'CC-1001', 'Disputed', NULL, 'Annual license renewal'),
(209, 15, 'INV-2025209', '2026-02-07', '2026-04-08', 71896.16, 'USD', 'Investor Relations', 'CC-4001', 'Paid', '2026-04-04', 'Professional development'),
(210, 18, 'INV-2025210', '2026-04-27', '2026-06-11', 447105.08, 'USD', 'Accounting', 'CC-3002', 'Paid', '2026-06-06', 'Regulatory filing support'),
(211, 2, 'INV-2025211', '2025-02-16', '2025-04-02', 90949.68, 'USD', 'Technology', 'CC-1002', 'Paid', '2025-03-29', 'Cloud compute charges'),
(212, 18, 'INV-2025212', '2026-06-01', '2026-07-16', 32601.52, 'USD', 'Corporate Finance', 'CC-3002', 'Paid', '2026-07-15', 'Regulatory filing support'),
(213, 12, 'INV-2025213', '2025-12-14', '2026-02-12', 230624.19, 'USD', 'Capital Markets', 'CC-1001', 'Paid', '2026-02-12', 'Quarterly advisory retainer'),
(214, 11, 'INV-2025214', '2025-05-21', '2025-07-20', 37660.7, 'USD', 'Procurement', 'CC-4002', 'Disputed', NULL, 'Consulting engagement - Phase 1'),
(215, 11, 'INV-2025215', '2025-12-02', '2026-01-31', 382693.71, 'USD', 'Capital Markets', 'CC-2002', 'Overdue', NULL, 'Software maintenance'),
(216, 17, 'INV-2025216', '2025-12-11', '2026-02-09', 184905.75, 'USD', 'Legal', 'CC-1001', 'Disputed', NULL, 'Regulatory filing support'),
(217, 4, 'INV-2025217', '2025-12-06', '2026-02-04', 376395.9, 'USD', 'Treasury', 'CC-1001', 'Pending', NULL, 'Professional development'),
(218, 19, 'INV-2025218', '2026-05-01', '2026-06-15', 312585.47, 'USD', 'Technology', 'CC-4002', 'Paid', '2026-06-13', 'Professional development'),
(219, 8, 'INV-2025219', '2026-01-25', '2026-02-24', 48100.69, 'USD', 'Accounting', 'CC-3001', 'Paid', '2026-02-17', 'Document processing services'),
(220, 7, 'INV-2025220', '2025-06-05', '2025-07-20', 381126.77, 'USD', 'Treasury', 'CC-1001', 'Disputed', NULL, 'Consulting engagement - Phase 1'),
(221, 18, 'INV-2025221', '2026-06-16', '2026-07-16', 191188.67, 'USD', 'Strategic Finance', 'CC-1003', 'Disputed', NULL, 'Risk assessment report'),
(222, 18, 'INV-2025222', '2026-06-30', '2026-08-14', 136518.88, 'USD', 'Strategic Finance', 'CC-2001', 'Pending', NULL, 'API usage charges'),
(223, 10, 'INV-2025223', '2025-11-02', '2025-12-02', 270051.39, 'USD', 'Corporate Finance', 'CC-3001', 'Paid', '2025-11-25', 'Compliance monitoring'),
(224, 4, 'INV-2025224', '2025-10-08', '2025-11-22', 227539.61, 'USD', 'Technology', 'CC-3001', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(225, 10, 'INV-2025225', '2025-10-25', '2025-11-24', 345187.42, 'USD', 'Tax', 'CC-4001', 'Pending', NULL, 'Storage and archival services'),
(226, 9, 'INV-2025226', '2025-07-26', '2025-09-24', 34749.6, 'USD', 'Legal', 'CC-5001', 'Pending', NULL, 'Software maintenance'),
(227, 2, 'INV-2025227', '2025-09-03', '2025-10-03', 73621.0, 'USD', 'Legal', 'CC-3001', 'Paid', '2025-09-27', 'Tax preparation services'),
(228, 5, 'INV-2025228', '2025-04-13', '2025-06-12', 470764.44, 'USD', 'Accounting', 'CC-4001', 'Paid', '2025-06-05', 'Storage and archival services'),
(229, 10, 'INV-2025229', '2025-10-22', '2025-12-06', 154499.09, 'USD', 'Accounting', 'CC-1003', 'Paid', '2025-12-06', 'Document processing services'),
(230, 13, 'INV-2025230', '2025-06-30', '2025-07-30', 482959.12, 'USD', 'Procurement', 'CC-1001', 'Paid', '2025-07-26', 'Monthly subscription fee'),
(231, 20, 'INV-2025231', '2025-11-02', '2026-01-01', 71498.13, 'USD', 'Tax', 'CC-4002', 'Pending', NULL, 'Financial modeling support'),
(232, 17, 'INV-2025232', '2026-05-21', '2026-06-20', 48606.44, 'USD', 'Procurement', 'CC-1002', 'Pending', NULL, 'Audit support services'),
(233, 15, 'INV-2025233', '2025-06-16', '2025-08-15', 4014.01, 'USD', 'Corporate Finance', 'CC-2002', 'Paid', '2025-08-10', 'Software maintenance'),
(234, 20, 'INV-2025234', '2025-07-17', '2025-08-16', 89032.0, 'USD', 'Treasury', 'CC-1002', 'Overdue', NULL, 'Implementation services'),
(235, 11, 'INV-2025235', '2025-05-24', '2025-07-08', 65565.93, 'USD', 'Investor Relations', 'CC-4001', 'Paid', '2025-07-05', 'API usage charges'),
(236, 19, 'INV-2025236', '2025-12-04', '2026-01-18', 65757.51, 'USD', 'Technology', 'CC-2001', 'Paid', '2026-01-13', 'Quarterly advisory retainer'),
(237, 10, 'INV-2025237', '2025-05-02', '2025-06-16', 465397.71, 'USD', 'Capital Markets', 'CC-2002', 'Overdue', NULL, 'Data feed - monthly'),
(238, 20, 'INV-2025238', '2025-10-30', '2025-12-14', 265181.85, 'USD', 'Investor Relations', 'CC-5001', 'Paid', '2025-12-07', 'Regulatory filing support'),
(239, 18, 'INV-2025239', '2026-03-02', '2026-05-01', 356153.86, 'USD', 'Procurement', 'CC-1002', 'Paid', '2026-04-22', 'Financial modeling support'),
(240, 12, 'INV-2025240', '2026-04-03', '2026-06-02', 15908.63, 'USD', 'Tax', 'CC-4002', 'Paid', '2026-05-25', 'Storage and archival services'),
(241, 11, 'INV-2025241', '2025-06-03', '2025-07-03', 29501.89, 'USD', 'Legal', 'CC-2001', 'Disputed', NULL, 'Software maintenance'),
(242, 17, 'INV-2025242', '2026-05-16', '2026-06-15', 280961.53, 'USD', 'Procurement', 'CC-5001', 'Paid', '2026-06-08', 'Quarterly advisory retainer'),
(243, 10, 'INV-2025243', '2026-04-19', '2026-06-18', 63987.08, 'USD', 'Accounting', 'CC-1001', 'Overdue', NULL, 'Storage and archival services'),
(244, 14, 'INV-2025244', '2025-03-16', '2025-04-15', 77115.03, 'USD', 'Strategic Finance', 'CC-4001', 'Paid', '2025-04-14', 'Quarterly advisory retainer'),
(245, 6, 'INV-2025245', '2025-10-21', '2025-12-05', 93928.0, 'USD', 'Capital Markets', 'CC-3002', 'Overdue', NULL, 'Risk assessment report'),
(246, 3, 'INV-2025246', '2026-01-22', '2026-03-08', 206496.45, 'USD', 'Legal', 'CC-4002', 'Paid', '2026-03-06', 'Cloud compute charges'),
(247, 8, 'INV-2025247', '2026-06-26', '2026-07-26', 258351.76, 'USD', 'Accounting', 'CC-3002', 'Paid', '2026-07-18', 'Compliance monitoring'),
(248, 8, 'INV-2025248', '2026-01-24', '2026-02-23', 39202.78, 'USD', 'Procurement', 'CC-2001', 'Pending', NULL, 'Data feed - monthly'),
(249, 14, 'INV-2025249', '2025-02-02', '2025-04-03', 60546.24, 'USD', 'Technology', 'CC-1002', 'Paid', '2025-04-02', 'Professional development'),
(250, 20, 'INV-2025250', '2025-02-04', '2025-03-21', 231019.41, 'USD', 'Accounting', 'CC-4002', 'Paid', '2025-03-18', 'Storage and archival services');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(251, 17, 'INV-2025251', '2025-02-27', '2025-03-29', 379182.87, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2025-03-24', 'Professional development'),
(252, 10, 'INV-2025252', '2025-11-25', '2025-12-25', 173819.26, 'USD', 'Capital Markets', 'CC-5001', 'Paid', '2025-12-17', 'Implementation services'),
(253, 16, 'INV-2025253', '2026-03-14', '2026-05-13', 352104.14, 'USD', 'Accounting', 'CC-4002', 'Pending', NULL, 'Audit support services'),
(254, 5, 'INV-2025254', '2026-03-03', '2026-04-17', 46377.81, 'USD', 'Corporate Finance', 'CC-4002', 'Overdue', NULL, 'Tax preparation services'),
(255, 10, 'INV-2025255', '2025-09-04', '2025-10-04', 303073.68, 'USD', 'Capital Markets', 'CC-3002', 'Disputed', NULL, 'Compliance monitoring'),
(256, 13, 'INV-2025256', '2026-06-27', '2026-07-27', 51232.51, 'USD', 'Investor Relations', 'CC-1002', 'Pending', NULL, 'Risk assessment report'),
(257, 18, 'INV-2025257', '2026-01-15', '2026-02-14', 67481.17, 'USD', 'Investor Relations', 'CC-5001', 'Paid', '2026-02-04', 'Professional development'),
(258, 7, 'INV-2025258', '2025-02-10', '2025-03-12', 441263.23, 'USD', 'Technology', 'CC-2002', 'Paid', '2025-03-07', 'Monthly subscription fee'),
(259, 4, 'INV-2025259', '2025-08-05', '2025-09-04', 366695.86, 'USD', 'Procurement', 'CC-2001', 'Paid', '2025-08-29', 'Compliance monitoring'),
(260, 13, 'INV-2025260', '2025-11-26', '2026-01-10', 77451.36, 'USD', 'Procurement', 'CC-3001', 'Pending', NULL, 'Financial modeling support'),
(261, 4, 'INV-2025261', '2026-05-25', '2026-07-09', 216817.21, 'USD', 'Procurement', 'CC-3002', 'Pending', NULL, 'Quarterly advisory retainer'),
(262, 5, 'INV-2025262', '2025-08-15', '2025-10-14', 312814.35, 'USD', 'Accounting', 'CC-3002', 'Pending', NULL, 'Platform access fee'),
(263, 11, 'INV-2025263', '2025-06-06', '2025-07-06', 160578.51, 'USD', 'Investor Relations', 'CC-4002', 'Overdue', NULL, 'Audit support services'),
(264, 16, 'INV-2025264', '2025-09-21', '2025-11-05', 208479.28, 'USD', 'Procurement', 'CC-4002', 'Paid', '2025-11-03', 'Tax preparation services'),
(265, 2, 'INV-2025265', '2025-07-08', '2025-09-06', 83448.69, 'USD', 'Legal', 'CC-1001', 'Paid', '2025-08-27', 'Monthly subscription fee'),
(266, 8, 'INV-2025266', '2026-02-27', '2026-03-29', 2780.79, 'USD', 'Tax', 'CC-4001', 'Paid', '2026-03-21', 'Regulatory filing support'),
(267, 20, 'INV-2025267', '2025-03-03', '2025-05-02', 4425.08, 'USD', 'Procurement', 'CC-4002', 'Disputed', NULL, 'Compliance monitoring'),
(268, 1, 'INV-2025268', '2026-02-26', '2026-03-28', 179009.84, 'USD', 'Legal', 'CC-4002', 'Pending', NULL, 'Document processing services'),
(269, 4, 'INV-2025269', '2025-07-03', '2025-08-02', 60621.72, 'USD', 'Legal', 'CC-4002', 'Paid', '2025-07-24', 'API usage charges'),
(270, 13, 'INV-2025270', '2025-12-29', '2026-02-12', 256548.99, 'USD', 'Tax', 'CC-2001', 'Pending', NULL, 'Training and certification'),
(271, 3, 'INV-2025271', '2025-11-04', '2026-01-03', 219726.31, 'USD', 'Accounting', 'CC-1001', 'Paid', '2025-12-27', 'Monthly subscription fee'),
(272, 16, 'INV-2025272', '2025-06-25', '2025-07-25', 436082.14, 'USD', 'Treasury', 'CC-1002', 'Pending', NULL, 'Financial modeling support'),
(273, 7, 'INV-2025273', '2025-02-13', '2025-03-15', 68138.22, 'USD', 'Technology', 'CC-1002', 'Disputed', NULL, 'API usage charges'),
(274, 11, 'INV-2025274', '2025-02-03', '2025-03-05', 388514.51, 'USD', 'Accounting', 'CC-1002', 'Paid', '2025-02-27', 'Platform access fee'),
(275, 8, 'INV-2025275', '2025-06-16', '2025-08-15', 293253.09, 'USD', 'Technology', 'CC-3002', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(276, 12, 'INV-2025276', '2025-03-22', '2025-05-21', 427403.6, 'USD', 'Accounting', 'CC-5001', 'Paid', '2025-05-16', 'Professional development'),
(277, 1, 'INV-2025277', '2026-02-11', '2026-03-28', 210115.04, 'USD', 'Corporate Finance', 'CC-3002', 'Disputed', NULL, 'Document processing services'),
(278, 19, 'INV-2025278', '2025-07-10', '2025-09-08', 182920.77, 'USD', 'Treasury', 'CC-1002', 'Paid', '2025-09-05', 'Annual license renewal'),
(279, 13, 'INV-2025279', '2025-10-02', '2025-11-01', 79511.22, 'USD', 'Capital Markets', 'CC-1002', 'Overdue', NULL, 'Annual license renewal'),
(280, 15, 'INV-2025280', '2025-01-06', '2025-02-20', 26006.74, 'USD', 'Strategic Finance', 'CC-1002', 'Pending', NULL, 'Implementation services'),
(281, 18, 'INV-2025281', '2026-03-18', '2026-05-02', 26271.59, 'USD', 'Legal', 'CC-1002', 'Overdue', NULL, 'Regulatory filing support'),
(282, 20, 'INV-2025282', '2025-04-06', '2025-06-05', 3578.98, 'USD', 'Strategic Finance', 'CC-3002', 'Overdue', NULL, 'Cloud compute charges'),
(283, 18, 'INV-2025283', '2025-03-28', '2025-05-27', 126275.79, 'USD', 'Investor Relations', 'CC-2002', 'Paid', '2025-05-23', 'API usage charges'),
(284, 3, 'INV-2025284', '2026-05-20', '2026-06-19', 69352.49, 'USD', 'Capital Markets', 'CC-2002', 'Overdue', NULL, 'Tax preparation services'),
(285, 9, 'INV-2025285', '2025-03-20', '2025-05-04', 137996.7, 'USD', 'Investor Relations', 'CC-1002', 'Disputed', NULL, 'Consulting engagement - Phase 1'),
(286, 13, 'INV-2025286', '2025-11-08', '2025-12-08', 198293.77, 'USD', 'Strategic Finance', 'CC-3001', 'Overdue', NULL, 'Document processing services'),
(287, 11, 'INV-2025287', '2025-05-20', '2025-07-04', 129936.77, 'USD', 'Technology', 'CC-3001', 'Paid', '2025-06-28', 'Platform access fee'),
(288, 8, 'INV-2025288', '2026-05-18', '2026-07-17', 70434.89, 'USD', 'Strategic Finance', 'CC-3002', 'Overdue', NULL, 'Regulatory filing support'),
(289, 7, 'INV-2025289', '2025-04-27', '2025-06-26', 297544.62, 'USD', 'Technology', 'CC-2001', 'Paid', '2025-06-19', 'Risk assessment report'),
(290, 3, 'INV-2025290', '2025-10-26', '2025-12-25', 35225.19, 'USD', 'Treasury', 'CC-2002', 'Disputed', NULL, 'Training and certification'),
(291, 5, 'INV-2025291', '2025-09-16', '2025-11-15', 18954.3, 'USD', 'Treasury', 'CC-5001', 'Overdue', NULL, 'Tax preparation services'),
(292, 17, 'INV-2025292', '2026-02-15', '2026-04-16', 211788.27, 'USD', 'Treasury', 'CC-5001', 'Paid', '2026-04-08', 'Annual license renewal'),
(293, 12, 'INV-2025293', '2025-04-22', '2025-05-22', 340264.04, 'USD', 'Capital Markets', 'CC-3002', 'Paid', '2025-05-12', 'Audit support services'),
(294, 1, 'INV-2025294', '2026-03-17', '2026-04-16', 55889.27, 'USD', 'Tax', 'CC-4002', 'Pending', NULL, 'Compliance monitoring'),
(295, 12, 'INV-2025295', '2025-08-15', '2025-09-29', 314865.48, 'USD', 'Treasury', 'CC-4002', 'Disputed', NULL, 'Consulting engagement - Phase 1'),
(296, 16, 'INV-2025296', '2025-12-20', '2026-01-19', 482777.54, 'USD', 'Tax', 'CC-1002', 'Pending', NULL, 'Consulting engagement - Phase 1'),
(297, 11, 'INV-2025297', '2025-12-23', '2026-02-06', 206735.13, 'USD', 'Procurement', 'CC-4001', 'Paid', '2026-02-05', 'Risk assessment report'),
(298, 10, 'INV-2025298', '2025-11-23', '2025-12-23', 6134.99, 'USD', 'Accounting', 'CC-1002', 'Paid', '2025-12-18', 'Implementation services'),
(299, 6, 'INV-2025299', '2025-09-07', '2025-11-06', 83081.92, 'USD', 'Legal', 'CC-4001', 'Paid', '2025-10-31', 'Training and certification'),
(300, 6, 'INV-2025300', '2026-02-19', '2026-04-20', 99197.8, 'USD', 'Capital Markets', 'CC-5001', 'Overdue', NULL, 'Storage and archival services');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(301, 14, 'INV-2025301', '2026-04-06', '2026-06-05', 142603.02, 'USD', 'Treasury', 'CC-5001', 'Paid', '2026-06-04', 'Data feed - monthly'),
(302, 11, 'INV-2025302', '2025-07-11', '2025-08-25', 28931.77, 'USD', 'Investor Relations', 'CC-4001', 'Disputed', NULL, 'Financial modeling support'),
(303, 13, 'INV-2025303', '2025-11-17', '2026-01-16', 206566.09, 'USD', 'Technology', 'CC-4001', 'Overdue', NULL, 'Professional development'),
(304, 10, 'INV-2025304', '2025-06-26', '2025-08-25', 190933.59, 'USD', 'Technology', 'CC-2002', 'Paid', '2025-08-22', 'Data feed - monthly'),
(305, 5, 'INV-2025305', '2025-07-07', '2025-08-21', 112040.28, 'USD', 'Legal', 'CC-3002', 'Overdue', NULL, 'Document processing services'),
(306, 18, 'INV-2025306', '2025-07-10', '2025-08-24', 113133.44, 'USD', 'Capital Markets', 'CC-4001', 'Paid', '2025-08-19', 'Professional development'),
(307, 1, 'INV-2025307', '2025-02-24', '2025-04-10', 49184.56, 'USD', 'Procurement', 'CC-4002', 'Paid', '2025-04-04', 'Financial modeling support'),
(308, 16, 'INV-2025308', '2026-05-22', '2026-07-06', 87201.78, 'USD', 'Treasury', 'CC-1001', 'Disputed', NULL, 'Training and certification'),
(309, 9, 'INV-2025309', '2025-10-27', '2025-11-26', 42468.14, 'USD', 'Investor Relations', 'CC-4001', 'Pending', NULL, 'Software maintenance'),
(310, 17, 'INV-2025310', '2026-05-23', '2026-07-22', 67338.28, 'USD', 'Tax', 'CC-3001', 'Paid', '2026-07-14', 'Compliance monitoring'),
(311, 15, 'INV-2025311', '2025-02-12', '2025-04-13', 96087.4, 'USD', 'Legal', 'CC-2001', 'Paid', '2025-04-03', 'Platform access fee'),
(312, 9, 'INV-2025312', '2025-02-03', '2025-03-20', 497280.96, 'USD', 'Strategic Finance', 'CC-2001', 'Paid', '2025-03-17', 'Software maintenance'),
(313, 20, 'INV-2025313', '2025-12-26', '2026-02-24', 403182.19, 'USD', 'Treasury', 'CC-1001', 'Paid', '2026-02-21', 'Software maintenance'),
(314, 9, 'INV-2025314', '2025-12-26', '2026-02-24', 81251.58, 'USD', 'Technology', 'CC-2002', 'Paid', '2026-02-20', 'Software maintenance'),
(315, 4, 'INV-2025315', '2025-10-01', '2025-11-30', 496618.8, 'USD', 'Capital Markets', 'CC-1003', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(316, 11, 'INV-2025316', '2025-09-13', '2025-10-13', 309841.49, 'USD', 'Investor Relations', 'CC-2002', 'Overdue', NULL, 'Document processing services'),
(317, 3, 'INV-2025317', '2026-01-20', '2026-03-06', 175201.56, 'USD', 'Tax', 'CC-3001', 'Overdue', NULL, 'Risk assessment report'),
(318, 19, 'INV-2025318', '2026-05-15', '2026-06-29', 256302.17, 'USD', 'Accounting', 'CC-3001', 'Paid', '2026-06-19', 'Annual license renewal'),
(319, 14, 'INV-2025319', '2026-02-12', '2026-03-14', 67499.94, 'USD', 'Investor Relations', 'CC-2002', 'Disputed', NULL, 'Audit support services'),
(320, 16, 'INV-2025320', '2025-05-14', '2025-07-13', 11962.76, 'USD', 'Strategic Finance', 'CC-4001', 'Paid', '2025-07-03', 'Monthly subscription fee'),
(321, 15, 'INV-2025321', '2025-05-08', '2025-06-07', 242509.69, 'USD', 'Procurement', 'CC-2002', 'Paid', '2025-06-05', 'Implementation services'),
(322, 12, 'INV-2025322', '2025-10-08', '2025-11-07', 93275.02, 'USD', 'Corporate Finance', 'CC-1003', 'Paid', '2025-10-28', 'Quarterly advisory retainer'),
(323, 10, 'INV-2025323', '2026-02-10', '2026-04-11', 366664.12, 'USD', 'Investor Relations', 'CC-1001', 'Overdue', NULL, 'Storage and archival services'),
(324, 5, 'INV-2025324', '2026-05-04', '2026-06-03', 250280.09, 'USD', 'Technology', 'CC-3001', 'Paid', '2026-06-03', 'Data feed - monthly'),
(325, 5, 'INV-2025325', '2026-03-09', '2026-05-08', 57622.24, 'USD', 'Procurement', 'CC-1002', 'Paid', '2026-05-07', 'Data feed - monthly'),
(326, 10, 'INV-2025326', '2025-11-17', '2026-01-01', 388921.01, 'USD', 'Capital Markets', 'CC-1003', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(327, 19, 'INV-2025327', '2025-03-12', '2025-05-11', 375094.41, 'USD', 'Accounting', 'CC-1003', 'Paid', '2025-05-01', 'Document processing services'),
(328, 3, 'INV-2025328', '2026-03-30', '2026-04-29', 315308.26, 'USD', 'Tax', 'CC-3001', 'Paid', '2026-04-23', 'Document processing services'),
(329, 8, 'INV-2025329', '2025-11-19', '2025-12-19', 62417.67, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2025-12-10', 'Professional development'),
(330, 1, 'INV-2025330', '2025-10-19', '2025-12-18', 279285.15, 'USD', 'Corporate Finance', 'CC-2002', 'Paid', '2025-12-12', 'Quarterly advisory retainer'),
(331, 13, 'INV-2025331', '2025-09-03', '2025-10-18', 317268.4, 'USD', 'Tax', 'CC-1001', 'Paid', '2025-10-10', 'Regulatory filing support'),
(332, 13, 'INV-2025332', '2025-11-21', '2025-12-21', 91670.41, 'USD', 'Technology', 'CC-1003', 'Overdue', NULL, 'Tax preparation services'),
(333, 19, 'INV-2025333', '2025-03-16', '2025-04-15', 65915.23, 'USD', 'Tax', 'CC-1001', 'Paid', '2025-04-15', 'Cloud compute charges'),
(334, 17, 'INV-2025334', '2026-06-03', '2026-07-18', 87092.52, 'USD', 'Treasury', 'CC-4002', 'Overdue', NULL, 'Compliance monitoring'),
(335, 3, 'INV-2025335', '2025-06-06', '2025-07-21', 141438.87, 'USD', 'Corporate Finance', 'CC-4002', 'Paid', '2025-07-19', 'Audit support services'),
(336, 3, 'INV-2025336', '2026-02-05', '2026-04-06', 430910.65, 'USD', 'Corporate Finance', 'CC-1001', 'Overdue', NULL, 'Training and certification'),
(337, 4, 'INV-2025337', '2025-03-30', '2025-05-14', 77667.87, 'USD', 'Procurement', 'CC-1003', 'Paid', '2025-05-04', 'Data feed - monthly'),
(338, 5, 'INV-2025338', '2025-01-13', '2025-03-14', 206017.31, 'USD', 'Accounting', 'CC-2002', 'Paid', '2025-03-06', 'Implementation services'),
(339, 9, 'INV-2025339', '2026-01-16', '2026-02-15', 84085.25, 'USD', 'Tax', 'CC-2002', 'Paid', '2026-02-09', 'Financial modeling support'),
(340, 19, 'INV-2025340', '2025-03-07', '2025-04-21', 212055.75, 'USD', 'Tax', 'CC-4001', 'Disputed', NULL, 'Software maintenance'),
(341, 6, 'INV-2025341', '2025-06-20', '2025-08-04', 353354.19, 'USD', 'Corporate Finance', 'CC-2001', 'Paid', '2025-08-03', 'Financial modeling support'),
(342, 1, 'INV-2025342', '2025-01-03', '2025-02-02', 222340.76, 'USD', 'Investor Relations', 'CC-1003', 'Paid', '2025-01-31', 'Quarterly advisory retainer'),
(343, 11, 'INV-2025343', '2026-03-06', '2026-04-05', 193970.81, 'USD', 'Investor Relations', 'CC-1002', 'Overdue', NULL, 'Software maintenance'),
(344, 17, 'INV-2025344', '2026-01-17', '2026-02-16', 56184.67, 'USD', 'Accounting', 'CC-1001', 'Paid', '2026-02-08', 'Cloud compute charges'),
(345, 10, 'INV-2025345', '2025-03-12', '2025-04-26', 22053.19, 'USD', 'Corporate Finance', 'CC-4001', 'Pending', NULL, 'Monthly subscription fee'),
(346, 10, 'INV-2025346', '2026-01-13', '2026-02-12', 159162.8, 'USD', 'Technology', 'CC-3001', 'Pending', NULL, 'Software maintenance'),
(347, 18, 'INV-2025347', '2026-05-21', '2026-06-20', 2091.28, 'USD', 'Investor Relations', 'CC-1001', 'Paid', '2026-06-14', 'Training and certification'),
(348, 1, 'INV-2025348', '2025-12-21', '2026-02-19', 219323.67, 'USD', 'Strategic Finance', 'CC-1002', 'Paid', '2026-02-15', 'Storage and archival services'),
(349, 14, 'INV-2025349', '2026-06-27', '2026-07-27', 114068.07, 'USD', 'Procurement', 'CC-1002', 'Paid', '2026-07-23', 'Quarterly advisory retainer'),
(350, 14, 'INV-2025350', '2025-08-26', '2025-10-25', 88206.09, 'USD', 'Strategic Finance', 'CC-1002', 'Disputed', NULL, 'Financial modeling support');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(351, 13, 'INV-2025351', '2025-05-17', '2025-07-16', 483898.22, 'USD', 'Tax', 'CC-2002', 'Paid', '2025-07-13', 'API usage charges'),
(352, 11, 'INV-2025352', '2025-11-19', '2026-01-03', 68352.99, 'USD', 'Strategic Finance', 'CC-1002', 'Disputed', NULL, 'Storage and archival services'),
(353, 4, 'INV-2025353', '2025-05-20', '2025-07-19', 41511.56, 'USD', 'Capital Markets', 'CC-3001', 'Paid', '2025-07-12', 'Document processing services'),
(354, 12, 'INV-2025354', '2025-05-04', '2025-07-03', 77422.78, 'USD', 'Investor Relations', 'CC-2002', 'Disputed', NULL, 'Data feed - monthly'),
(355, 10, 'INV-2025355', '2025-04-03', '2025-05-03', 54147.69, 'USD', 'Technology', 'CC-1003', 'Paid', '2025-04-28', 'Annual license renewal'),
(356, 13, 'INV-2025356', '2025-09-12', '2025-10-27', 167075.06, 'USD', 'Legal', 'CC-1001', 'Paid', '2025-10-25', 'Cloud compute charges'),
(357, 18, 'INV-2025357', '2026-04-09', '2026-06-08', 411753.54, 'USD', 'Investor Relations', 'CC-1002', 'Paid', '2026-06-06', 'Monthly subscription fee'),
(358, 5, 'INV-2025358', '2025-03-05', '2025-04-04', 93373.82, 'USD', 'Investor Relations', 'CC-1002', 'Overdue', NULL, 'Software maintenance'),
(359, 1, 'INV-2025359', '2025-09-23', '2025-10-23', 249544.1, 'USD', 'Tax', 'CC-1002', 'Paid', '2025-10-21', 'Audit support services'),
(360, 15, 'INV-2025360', '2025-05-06', '2025-06-05', 244920.37, 'USD', 'Accounting', 'CC-4001', 'Paid', '2025-05-30', 'Monthly subscription fee'),
(361, 14, 'INV-2025361', '2026-01-27', '2026-03-28', 54071.67, 'USD', 'Capital Markets', 'CC-1003', 'Pending', NULL, 'API usage charges'),
(362, 5, 'INV-2025362', '2025-10-14', '2025-11-28', 274501.22, 'USD', 'Accounting', 'CC-4001', 'Paid', '2025-11-20', 'Quarterly advisory retainer'),
(363, 13, 'INV-2025363', '2025-03-31', '2025-05-15', 50264.72, 'USD', 'Capital Markets', 'CC-4002', 'Overdue', NULL, 'Training and certification'),
(364, 12, 'INV-2025364', '2025-01-20', '2025-03-06', 86336.51, 'USD', 'Procurement', 'CC-5001', 'Disputed', NULL, 'Financial modeling support'),
(365, 9, 'INV-2025365', '2025-11-26', '2026-01-10', 80059.95, 'USD', 'Capital Markets', 'CC-1001', 'Paid', '2026-01-07', 'API usage charges'),
(366, 17, 'INV-2025366', '2025-03-01', '2025-04-15', 95060.45, 'USD', 'Strategic Finance', 'CC-2001', 'Paid', '2025-04-05', 'API usage charges'),
(367, 19, 'INV-2025367', '2025-02-27', '2025-03-29', 496193.86, 'USD', 'Treasury', 'CC-1003', 'Pending', NULL, 'Implementation services'),
(368, 11, 'INV-2025368', '2025-08-31', '2025-10-30', 208256.97, 'USD', 'Strategic Finance', 'CC-5001', 'Paid', '2025-10-21', 'Consulting engagement - Phase 1'),
(369, 18, 'INV-2025369', '2025-07-12', '2025-08-26', 90615.82, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2025-08-23', 'Training and certification'),
(370, 16, 'INV-2025370', '2025-01-21', '2025-03-22', 140658.97, 'USD', 'Accounting', 'CC-1003', 'Pending', NULL, 'Audit support services'),
(371, 2, 'INV-2025371', '2025-07-01', '2025-08-15', 462750.87, 'USD', 'Accounting', 'CC-4002', 'Paid', '2025-08-14', 'Regulatory filing support'),
(372, 13, 'INV-2025372', '2025-03-16', '2025-04-30', 84471.99, 'USD', 'Technology', 'CC-1003', 'Paid', '2025-04-25', 'Implementation services'),
(373, 16, 'INV-2025373', '2026-03-24', '2026-05-23', 302889.79, 'USD', 'Strategic Finance', 'CC-3001', 'Paid', '2026-05-14', 'Training and certification'),
(374, 10, 'INV-2025374', '2025-06-29', '2025-08-13', 44838.22, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2025-08-13', 'Cloud compute charges'),
(375, 20, 'INV-2025375', '2025-02-03', '2025-03-05', 96849.6, 'USD', 'Strategic Finance', 'CC-1003', 'Paid', '2025-02-26', 'Audit support services'),
(376, 12, 'INV-2025376', '2025-03-21', '2025-04-20', 483385.83, 'USD', 'Strategic Finance', 'CC-3001', 'Paid', '2025-04-10', 'Risk assessment report'),
(377, 7, 'INV-2025377', '2025-01-12', '2025-02-26', 87945.05, 'USD', 'Investor Relations', 'CC-1001', 'Paid', '2025-02-25', 'Quarterly advisory retainer'),
(378, 14, 'INV-2025378', '2026-01-31', '2026-03-17', 220420.66, 'USD', 'Capital Markets', 'CC-4002', 'Overdue', NULL, 'Cloud compute charges'),
(379, 19, 'INV-2025379', '2025-04-14', '2025-05-29', 409637.55, 'USD', 'Investor Relations', 'CC-2002', 'Paid', '2025-05-29', 'Monthly subscription fee'),
(380, 4, 'INV-2025380', '2025-11-23', '2026-01-07', 42941.25, 'USD', 'Tax', 'CC-3002', 'Pending', NULL, 'Implementation services'),
(381, 3, 'INV-2025381', '2025-03-18', '2025-05-17', 244095.5, 'USD', 'Strategic Finance', 'CC-1003', 'Disputed', NULL, 'Professional development'),
(382, 2, 'INV-2025382', '2026-03-21', '2026-04-20', 51784.84, 'USD', 'Tax', 'CC-2001', 'Pending', NULL, 'Document processing services'),
(383, 10, 'INV-2025383', '2025-09-29', '2025-11-28', 24431.02, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2025-11-22', 'Compliance monitoring'),
(384, 2, 'INV-2025384', '2026-05-18', '2026-06-17', 182547.25, 'USD', 'Strategic Finance', 'CC-5001', 'Paid', '2026-06-07', 'Tax preparation services'),
(385, 1, 'INV-2025385', '2025-07-24', '2025-08-23', 489675.96, 'USD', 'Investor Relations', 'CC-1002', 'Paid', '2025-08-16', 'Platform access fee'),
(386, 16, 'INV-2025386', '2026-02-12', '2026-03-29', 224387.2, 'USD', 'Corporate Finance', 'CC-3002', 'Paid', '2026-03-24', 'Regulatory filing support'),
(387, 2, 'INV-2025387', '2025-07-11', '2025-08-25', 151809.03, 'USD', 'Corporate Finance', 'CC-2002', 'Disputed', NULL, 'Software maintenance'),
(388, 4, 'INV-2025388', '2025-03-05', '2025-04-04', 236293.99, 'USD', 'Tax', 'CC-5001', 'Pending', NULL, 'Training and certification'),
(389, 17, 'INV-2025389', '2025-03-04', '2025-04-18', 156038.91, 'USD', 'Treasury', 'CC-2002', 'Disputed', NULL, 'Annual license renewal'),
(390, 2, 'INV-2025390', '2026-02-09', '2026-04-10', 30510.33, 'USD', 'Legal', 'CC-1003', 'Paid', '2026-04-03', 'Implementation services'),
(391, 5, 'INV-2025391', '2025-08-05', '2025-09-04', 20052.95, 'USD', 'Accounting', 'CC-3002', 'Overdue', NULL, 'Storage and archival services'),
(392, 9, 'INV-2025392', '2025-06-01', '2025-07-31', 22213.35, 'USD', 'Strategic Finance', 'CC-3002', 'Paid', '2025-07-23', 'Compliance monitoring'),
(393, 17, 'INV-2025393', '2025-11-30', '2026-01-14', 330376.07, 'USD', 'Procurement', 'CC-3002', 'Paid', '2026-01-06', 'Data feed - monthly'),
(394, 5, 'INV-2025394', '2026-03-01', '2026-03-31', 303207.69, 'USD', 'Technology', 'CC-2002', 'Paid', '2026-03-30', 'Compliance monitoring'),
(395, 9, 'INV-2025395', '2025-12-19', '2026-02-02', 262870.98, 'USD', 'Treasury', 'CC-1003', 'Disputed', NULL, 'API usage charges'),
(396, 20, 'INV-2025396', '2026-02-17', '2026-03-19', 10176.24, 'USD', 'Technology', 'CC-3001', 'Overdue', NULL, 'Training and certification'),
(397, 16, 'INV-2025397', '2025-02-20', '2025-04-21', 5548.11, 'USD', 'Corporate Finance', 'CC-2002', 'Pending', NULL, 'Platform access fee'),
(398, 4, 'INV-2025398', '2025-10-15', '2025-11-29', 75469.87, 'USD', 'Investor Relations', 'CC-3001', 'Paid', '2025-11-22', 'API usage charges'),
(399, 3, 'INV-2025399', '2026-03-03', '2026-05-02', 53241.93, 'USD', 'Investor Relations', 'CC-3002', 'Disputed', NULL, 'Tax preparation services'),
(400, 2, 'INV-2025400', '2026-06-13', '2026-07-28', 16871.43, 'USD', 'Legal', 'CC-3002', 'Paid', '2026-07-20', 'Consulting engagement - Phase 1');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(401, 1, 'INV-2025401', '2026-06-21', '2026-08-20', 140327.05, 'USD', 'Capital Markets', 'CC-2001', 'Paid', '2026-08-20', 'Quarterly advisory retainer'),
(402, 12, 'INV-2025402', '2026-04-13', '2026-05-13', 92403.81, 'USD', 'Investor Relations', 'CC-4001', 'Pending', NULL, 'Financial modeling support'),
(403, 4, 'INV-2025403', '2026-02-11', '2026-04-12', 93430.46, 'USD', 'Accounting', 'CC-4001', 'Paid', '2026-04-03', 'Implementation services'),
(404, 18, 'INV-2025404', '2026-05-01', '2026-06-30', 41296.65, 'USD', 'Strategic Finance', 'CC-2002', 'Pending', NULL, 'Annual license renewal'),
(405, 13, 'INV-2025405', '2025-10-19', '2025-11-18', 400923.56, 'USD', 'Accounting', 'CC-2001', 'Paid', '2025-11-15', 'Training and certification'),
(406, 14, 'INV-2025406', '2025-07-31', '2025-09-14', 485212.26, 'USD', 'Legal', 'CC-1001', 'Paid', '2025-09-04', 'Tax preparation services'),
(407, 6, 'INV-2025407', '2025-05-16', '2025-07-15', 56330.62, 'USD', 'Technology', 'CC-2002', 'Paid', '2025-07-06', 'API usage charges'),
(408, 12, 'INV-2025408', '2026-03-10', '2026-04-24', 54943.16, 'USD', 'Procurement', 'CC-2002', 'Pending', NULL, 'Financial modeling support'),
(409, 4, 'INV-2025409', '2026-02-11', '2026-04-12', 317197.64, 'USD', 'Accounting', 'CC-2002', 'Pending', NULL, 'Platform access fee'),
(410, 3, 'INV-2025410', '2025-04-21', '2025-06-05', 437671.22, 'USD', 'Strategic Finance', 'CC-2002', 'Pending', NULL, 'Platform access fee'),
(411, 17, 'INV-2025411', '2025-07-12', '2025-08-11', 411063.69, 'USD', 'Investor Relations', 'CC-3002', 'Paid', '2025-08-02', 'Audit support services'),
(412, 1, 'INV-2025412', '2025-05-24', '2025-07-23', 65226.86, 'USD', 'Procurement', 'CC-3002', 'Pending', NULL, 'Cloud compute charges'),
(413, 2, 'INV-2025413', '2026-02-02', '2026-04-03', 86120.18, 'USD', 'Technology', 'CC-4002', 'Paid', '2026-03-31', 'Tax preparation services'),
(414, 10, 'INV-2025414', '2026-01-03', '2026-03-04', 73799.12, 'USD', 'Capital Markets', 'CC-1003', 'Paid', '2026-02-25', 'API usage charges'),
(415, 11, 'INV-2025415', '2025-07-07', '2025-09-05', 89143.21, 'USD', 'Tax', 'CC-3002', 'Paid', '2025-09-01', 'Audit support services'),
(416, 19, 'INV-2025416', '2026-01-16', '2026-03-02', 261741.46, 'USD', 'Corporate Finance', 'CC-5001', 'Disputed', NULL, 'Software maintenance'),
(417, 7, 'INV-2025417', '2025-03-14', '2025-04-28', 221751.15, 'USD', 'Legal', 'CC-3002', 'Paid', '2025-04-24', 'Quarterly advisory retainer'),
(418, 7, 'INV-2025418', '2025-06-04', '2025-07-04', 451780.31, 'USD', 'Strategic Finance', 'CC-4001', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(419, 6, 'INV-2025419', '2025-11-20', '2026-01-19', 83491.05, 'USD', 'Tax', 'CC-1003', 'Disputed', NULL, 'Audit support services'),
(420, 15, 'INV-2025420', '2025-03-01', '2025-03-31', 125872.59, 'USD', 'Corporate Finance', 'CC-4001', 'Paid', '2025-03-29', 'Annual license renewal'),
(421, 14, 'INV-2025421', '2025-05-13', '2025-07-12', 264830.12, 'USD', 'Treasury', 'CC-1001', 'Overdue', NULL, 'Quarterly advisory retainer'),
(422, 12, 'INV-2025422', '2025-07-24', '2025-09-22', 288965.2, 'USD', 'Accounting', 'CC-1001', 'Pending', NULL, 'Monthly subscription fee'),
(423, 12, 'INV-2025423', '2025-09-12', '2025-10-12', 26125.7, 'USD', 'Corporate Finance', 'CC-5001', 'Paid', '2025-10-04', 'Platform access fee'),
(424, 2, 'INV-2025424', '2025-06-21', '2025-07-21', 284129.79, 'USD', 'Corporate Finance', 'CC-4002', 'Pending', NULL, 'Audit support services'),
(425, 5, 'INV-2025425', '2026-03-21', '2026-05-20', 90133.1, 'USD', 'Strategic Finance', 'CC-2001', 'Disputed', NULL, 'Implementation services'),
(426, 8, 'INV-2025426', '2026-02-18', '2026-03-20', 53191.96, 'USD', 'Investor Relations', 'CC-5001', 'Paid', '2026-03-20', 'Financial modeling support'),
(427, 12, 'INV-2025427', '2025-06-23', '2025-07-23', 165105.13, 'USD', 'Accounting', 'CC-4002', 'Overdue', NULL, 'Professional development'),
(428, 2, 'INV-2025428', '2025-02-19', '2025-04-20', 12534.65, 'USD', 'Tax', 'CC-3002', 'Paid', '2025-04-19', 'Risk assessment report'),
(429, 18, 'INV-2025429', '2026-01-25', '2026-02-24', 142472.71, 'USD', 'Corporate Finance', 'CC-1001', 'Disputed', NULL, 'Platform access fee'),
(430, 4, 'INV-2025430', '2026-03-07', '2026-05-06', 365326.86, 'USD', 'Legal', 'CC-3002', 'Pending', NULL, 'Data feed - monthly'),
(431, 20, 'INV-2025431', '2026-06-08', '2026-08-07', 28946.13, 'USD', 'Tax', 'CC-1002', 'Pending', NULL, 'Tax preparation services'),
(432, 7, 'INV-2025432', '2025-07-23', '2025-09-21', 89801.5, 'USD', 'Corporate Finance', 'CC-2002', 'Paid', '2025-09-15', 'Implementation services'),
(433, 16, 'INV-2025433', '2025-02-10', '2025-04-11', 82985.6, 'USD', 'Investor Relations', 'CC-1001', 'Disputed', NULL, 'Monthly subscription fee'),
(434, 19, 'INV-2025434', '2025-04-02', '2025-05-02', 400786.8, 'USD', 'Procurement', 'CC-1002', 'Paid', '2025-05-01', 'API usage charges'),
(435, 10, 'INV-2025435', '2025-08-25', '2025-10-09', 12995.01, 'USD', 'Corporate Finance', 'CC-1003', 'Disputed', NULL, 'Quarterly advisory retainer'),
(436, 11, 'INV-2025436', '2025-10-25', '2025-12-09', 24202.12, 'USD', 'Treasury', 'CC-1001', 'Paid', '2025-12-09', 'Consulting engagement - Phase 1'),
(437, 12, 'INV-2025437', '2025-06-24', '2025-08-08', 91828.09, 'USD', 'Procurement', 'CC-3001', 'Pending', NULL, 'Implementation services'),
(438, 13, 'INV-2025438', '2025-04-27', '2025-06-11', 360456.09, 'USD', 'Procurement', 'CC-4001', 'Pending', NULL, 'Document processing services'),
(439, 5, 'INV-2025439', '2025-06-20', '2025-07-20', 26376.42, 'USD', 'Accounting', 'CC-4001', 'Paid', '2025-07-11', 'Software maintenance'),
(440, 20, 'INV-2025440', '2026-03-25', '2026-04-24', 438159.1, 'USD', 'Treasury', 'CC-1003', 'Pending', NULL, 'Tax preparation services'),
(441, 14, 'INV-2025441', '2026-05-15', '2026-06-14', 16302.34, 'USD', 'Procurement', 'CC-3001', 'Paid', '2026-06-04', 'Monthly subscription fee'),
(442, 19, 'INV-2025442', '2026-06-22', '2026-08-21', 351429.96, 'USD', 'Technology', 'CC-4002', 'Paid', '2026-08-16', 'Financial modeling support'),
(443, 8, 'INV-2025443', '2025-04-08', '2025-05-23', 338632.0, 'USD', 'Procurement', 'CC-1003', 'Pending', NULL, 'Compliance monitoring'),
(444, 6, 'INV-2025444', '2025-02-25', '2025-03-27', 441237.04, 'USD', 'Legal', 'CC-1002', 'Disputed', NULL, 'Tax preparation services'),
(445, 11, 'INV-2025445', '2025-11-25', '2025-12-25', 297723.01, 'USD', 'Corporate Finance', 'CC-3002', 'Paid', '2025-12-19', 'Training and certification'),
(446, 15, 'INV-2025446', '2025-03-22', '2025-05-06', 22460.96, 'USD', 'Technology', 'CC-4001', 'Disputed', NULL, 'Risk assessment report'),
(447, 16, 'INV-2025447', '2025-11-20', '2025-12-20', 66124.37, 'USD', 'Accounting', 'CC-1001', 'Paid', '2025-12-12', 'Annual license renewal'),
(448, 18, 'INV-2025448', '2025-11-08', '2026-01-07', 213504.11, 'USD', 'Investor Relations', 'CC-1001', 'Disputed', NULL, 'Training and certification'),
(449, 18, 'INV-2025449', '2026-04-11', '2026-05-26', 213482.55, 'USD', 'Technology', 'CC-4001', 'Disputed', NULL, 'Data feed - monthly'),
(450, 8, 'INV-2025450', '2025-04-10', '2025-06-09', 89107.18, 'USD', 'Accounting', 'CC-2002', 'Pending', NULL, 'Compliance monitoring');

INSERT INTO invoices (invoice_id, vendor_id, invoice_number, invoice_date, due_date, amount, currency, department, cost_center, status, payment_date, description) VALUES
(451, 4, 'INV-2025451', '2026-06-19', '2026-08-03', 419827.4, 'USD', 'Accounting', 'CC-1002', 'Paid', '2026-07-28', 'API usage charges'),
(452, 4, 'INV-2025452', '2025-07-20', '2025-08-19', 401639.18, 'USD', 'Treasury', 'CC-1002', 'Paid', '2025-08-14', 'Document processing services'),
(453, 19, 'INV-2025453', '2025-02-17', '2025-04-18', 315192.27, 'USD', 'Tax', 'CC-4002', 'Disputed', NULL, 'Consulting engagement - Phase 1'),
(454, 17, 'INV-2025454', '2026-05-26', '2026-06-25', 267319.38, 'USD', 'Accounting', 'CC-4002', 'Overdue', NULL, 'Implementation services'),
(455, 5, 'INV-2025455', '2025-06-27', '2025-08-26', 322772.35, 'USD', 'Tax', 'CC-3001', 'Overdue', NULL, 'Financial modeling support'),
(456, 20, 'INV-2025456', '2026-01-29', '2026-03-15', 99768.56, 'USD', 'Investor Relations', 'CC-3001', 'Pending', NULL, 'Platform access fee'),
(457, 5, 'INV-2025457', '2026-04-09', '2026-05-09', 296512.69, 'USD', 'Treasury', 'CC-3001', 'Pending', NULL, 'Compliance monitoring'),
(458, 7, 'INV-2025458', '2025-08-11', '2025-09-10', 464536.29, 'USD', 'Technology', 'CC-1003', 'Pending', NULL, 'Implementation services'),
(459, 11, 'INV-2025459', '2026-05-31', '2026-07-30', 312262.82, 'USD', 'Tax', 'CC-3002', 'Pending', NULL, 'Compliance monitoring'),
(460, 1, 'INV-2025460', '2025-10-20', '2025-12-04', 6805.4, 'USD', 'Legal', 'CC-1001', 'Paid', '2025-12-02', 'Quarterly advisory retainer'),
(461, 6, 'INV-2025461', '2025-07-24', '2025-09-07', 37033.88, 'USD', 'Corporate Finance', 'CC-1001', 'Pending', NULL, 'Platform access fee'),
(462, 2, 'INV-2025462', '2025-07-28', '2025-09-26', 26068.76, 'USD', 'Strategic Finance', 'CC-4002', 'Disputed', NULL, 'Training and certification'),
(463, 17, 'INV-2025463', '2026-02-03', '2026-03-05', 224399.59, 'USD', 'Corporate Finance', 'CC-3001', 'Paid', '2026-02-23', 'Compliance monitoring'),
(464, 9, 'INV-2025464', '2025-02-25', '2025-03-27', 460168.87, 'USD', 'Investor Relations', 'CC-3001', 'Disputed', NULL, 'Software maintenance'),
(465, 7, 'INV-2025465', '2025-07-21', '2025-09-19', 44767.76, 'USD', 'Corporate Finance', 'CC-1002', 'Disputed', NULL, 'Implementation services'),
(466, 17, 'INV-2025466', '2025-06-27', '2025-08-26', 10638.24, 'USD', 'Tax', 'CC-2002', 'Overdue', NULL, 'Compliance monitoring'),
(467, 6, 'INV-2025467', '2025-09-28', '2025-10-28', 1908.46, 'USD', 'Technology', 'CC-4001', 'Pending', NULL, 'Consulting engagement - Phase 1'),
(468, 11, 'INV-2025468', '2025-02-10', '2025-03-12', 331415.0, 'USD', 'Technology', 'CC-2002', 'Paid', '2025-03-02', 'Tax preparation services'),
(469, 11, 'INV-2025469', '2026-01-02', '2026-02-01', 284272.83, 'USD', 'Legal', 'CC-1003', 'Paid', '2026-01-24', 'Document processing services'),
(470, 12, 'INV-2025470', '2026-02-18', '2026-03-20', 198979.94, 'USD', 'Investor Relations', 'CC-2001', 'Paid', '2026-03-16', 'Professional development'),
(471, 18, 'INV-2025471', '2026-06-28', '2026-08-12', 250550.26, 'USD', 'Accounting', 'CC-5001', 'Paid', '2026-08-02', 'Professional development'),
(472, 11, 'INV-2025472', '2025-09-07', '2025-10-07', 96776.05, 'USD', 'Treasury', 'CC-2002', 'Paid', '2025-09-29', 'Monthly subscription fee'),
(473, 17, 'INV-2025473', '2026-06-14', '2026-07-29', 183395.29, 'USD', 'Legal', 'CC-2001', 'Disputed', NULL, 'Audit support services'),
(474, 4, 'INV-2025474', '2026-06-11', '2026-07-11', 144851.66, 'USD', 'Capital Markets', 'CC-2001', 'Paid', '2026-07-01', 'Document processing services'),
(475, 18, 'INV-2025475', '2025-04-17', '2025-05-17', 119189.56, 'USD', 'Treasury', 'CC-3001', 'Paid', '2025-05-10', 'Quarterly advisory retainer'),
(476, 2, 'INV-2025476', '2025-03-31', '2025-04-30', 308733.03, 'USD', 'Capital Markets', 'CC-2001', 'Pending', NULL, 'API usage charges'),
(477, 15, 'INV-2025477', '2026-02-22', '2026-04-08', 79442.86, 'USD', 'Treasury', 'CC-3002', 'Overdue', NULL, 'Data feed - monthly'),
(478, 20, 'INV-2025478', '2025-01-07', '2025-03-08', 82665.25, 'USD', 'Tax', 'CC-1002', 'Paid', '2025-02-28', 'Platform access fee'),
(479, 3, 'INV-2025479', '2025-11-05', '2026-01-04', 95662.69, 'USD', 'Corporate Finance', 'CC-1001', 'Disputed', NULL, 'Tax preparation services'),
(480, 8, 'INV-2025480', '2025-06-10', '2025-08-09', 432260.35, 'USD', 'Capital Markets', 'CC-2002', 'Overdue', NULL, 'Consulting engagement - Phase 1'),
(481, 12, 'INV-2025481', '2025-11-02', '2026-01-01', 31247.17, 'USD', 'Accounting', 'CC-5001', 'Paid', '2026-01-01', 'Professional development'),
(482, 18, 'INV-2025482', '2026-02-08', '2026-04-09', 52908.2, 'USD', 'Tax', 'CC-3001', 'Pending', NULL, 'Storage and archival services'),
(483, 17, 'INV-2025483', '2026-02-27', '2026-04-28', 46406.18, 'USD', 'Capital Markets', 'CC-2002', 'Paid', '2026-04-19', 'Storage and archival services'),
(484, 19, 'INV-2025484', '2025-04-28', '2025-05-28', 82915.06, 'USD', 'Accounting', 'CC-1002', 'Disputed', NULL, 'API usage charges'),
(485, 19, 'INV-2025485', '2025-04-11', '2025-05-11', 89606.02, 'USD', 'Procurement', 'CC-2001', 'Pending', NULL, 'Data feed - monthly'),
(486, 3, 'INV-2025486', '2025-10-19', '2025-12-18', 197755.74, 'USD', 'Investor Relations', 'CC-2002', 'Pending', NULL, 'Software maintenance'),
(487, 19, 'INV-2025487', '2025-06-06', '2025-08-05', 125887.78, 'USD', 'Strategic Finance', 'CC-3001', 'Pending', NULL, 'Training and certification'),
(488, 14, 'INV-2025488', '2025-08-15', '2025-10-14', 34009.31, 'USD', 'Corporate Finance', 'CC-3001', 'Pending', NULL, 'Tax preparation services'),
(489, 12, 'INV-2025489', '2026-04-19', '2026-06-03', 129096.57, 'USD', 'Corporate Finance', 'CC-5001', 'Disputed', NULL, 'Annual license renewal'),
(490, 18, 'INV-2025490', '2025-10-15', '2025-11-14', 331978.5, 'USD', 'Investor Relations', 'CC-1002', 'Pending', NULL, 'Monthly subscription fee'),
(491, 1, 'INV-2025491', '2026-06-04', '2026-08-03', 145742.31, 'USD', 'Technology', 'CC-1001', 'Overdue', NULL, 'Compliance monitoring'),
(492, 18, 'INV-2025492', '2025-09-24', '2025-11-23', 91771.75, 'USD', 'Procurement', 'CC-5001', 'Paid', '2025-11-20', 'Platform access fee'),
(493, 17, 'INV-2025493', '2025-05-18', '2025-07-02', 99497.9, 'USD', 'Legal', 'CC-1001', 'Paid', '2025-06-24', 'Training and certification'),
(494, 5, 'INV-2025494', '2025-06-19', '2025-08-18', 45196.72, 'USD', 'Procurement', 'CC-1003', 'Paid', '2025-08-09', 'Tax preparation services'),
(495, 8, 'INV-2025495', '2026-01-03', '2026-02-02', 16183.86, 'USD', 'Procurement', 'CC-2001', 'Paid', '2026-01-28', 'Quarterly advisory retainer'),
(496, 12, 'INV-2025496', '2025-07-31', '2025-09-29', 446698.39, 'USD', 'Treasury', 'CC-1001', 'Disputed', NULL, 'Audit support services'),
(497, 17, 'INV-2025497', '2025-04-16', '2025-06-15', 306572.07, 'USD', 'Corporate Finance', 'CC-3002', 'Pending', NULL, 'Cloud compute charges'),
(498, 3, 'INV-2025498', '2026-01-10', '2026-03-11', 94394.03, 'USD', 'Legal', 'CC-2001', 'Pending', NULL, 'Financial modeling support'),
(499, 12, 'INV-2025499', '2026-02-20', '2026-04-06', 52968.96, 'USD', 'Procurement', 'CC-1003', 'Disputed', NULL, 'Risk assessment report'),
(500, 3, 'INV-2025500', '2025-06-19', '2025-07-19', 53273.52, 'USD', 'Legal', 'CC-1003', 'Pending', NULL, 'Implementation services');

-- Vendor Catalog (20 rows)
INSERT INTO vendor_catalog (vendor_id, vendor_name, category, contract_status, contract_start_date, contract_end_date, annual_spend_budget, payment_terms, risk_rating) VALUES
(1, 'Deloitte LLP', 'Professional Services', 'Active', '2024-01-01', '2026-12-31', 2500000.00, 'Net 45', 'Low'),
(2, 'KPMG Advisory', 'Professional Services', 'Active', '2024-06-01', '2026-05-31', 1800000.00, 'Net 30', 'Low'),
(3, 'AWS (Amazon Web Services)', 'Cloud Infrastructure', 'Active', '2023-07-01', '2026-06-30', 4200000.00, 'Net 30', 'Low'),
(4, 'Snowflake Inc', 'Cloud Infrastructure', 'Active', '2025-01-01', '2027-12-31', 850000.00, 'Net 30', 'Low'),
(5, 'Bloomberg LP', 'Market Data', 'Active', '2024-03-01', '2027-02-28', 1200000.00, 'Net 30', 'Low'),
(6, 'Refinitiv (LSEG)', 'Market Data', 'Active', '2024-09-01', '2026-08-31', 780000.00, 'Net 45', 'Medium'),
(7, 'Iron Mountain', 'Document Storage', 'Active', '2023-01-01', '2026-12-31', 320000.00, 'Net 60', 'Low'),
(8, 'Brex Inc', 'Corporate Cards', 'Active', '2025-03-01', '2027-02-28', 150000.00, 'Net 30', 'Medium'),
(9, 'Workday Inc', 'HR & Finance Systems', 'Active', '2024-01-01', '2026-12-31', 950000.00, 'Net 30', 'Low'),
(10, 'Salesforce Inc', 'CRM', 'Active', '2024-06-01', '2027-05-31', 680000.00, 'Net 30', 'Low'),
(11, 'Coupa Software', 'Procurement', 'Active', '2025-01-01', '2027-12-31', 420000.00, 'Net 30', 'Medium'),
(12, 'DocuSign Inc', 'Contract Management', 'Active', '2024-04-01', '2026-03-31', 95000.00, 'Net 30', 'Low'),
(13, 'Moody''s Analytics', 'Risk & Compliance', 'Active', '2024-01-01', '2026-12-31', 560000.00, 'Net 45', 'Low'),
(14, 'LexisNexis Risk', 'Risk & Compliance', 'Active', '2025-06-01', '2027-05-31', 340000.00, 'Net 30', 'Medium'),
(15, 'Wolters Kluwer', 'Tax & Regulatory', 'Active', '2024-09-01', '2026-08-31', 275000.00, 'Net 30', 'Low'),
(16, 'Thomson Reuters', 'Tax & Regulatory', 'Active', '2023-07-01', '2026-06-30', 410000.00, 'Net 45', 'Low'),
(17, 'Vertex Inc', 'Tax Technology', 'Active', '2025-01-01', '2027-12-31', 180000.00, 'Net 30', 'Medium'),
(18, 'BlackLine Inc', 'Accounting Automation', 'Active', '2024-03-01', '2026-02-28', 220000.00, 'Net 30', 'Low'),
(19, 'Anaplan Inc', 'Financial Planning', 'Expiring', '2023-06-01', '2026-05-31', 380000.00, 'Net 30', 'Medium'),
(20, 'Stripe Inc', 'Payment Processing', 'Active', '2025-01-01', '2027-12-31', 95000.00, 'Net 30', 'Low');

-- Loan Originations (652 monthly rows)
INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-07-01', NULL, 12, 15, 7, 8, 34383.5),
('2025-07-01', NULL, 5, 40, 30, 10, 1179079.09),
('2025-07-01', NULL, 6, 20, 12, 8, 397347.46),
('2025-07-01', 'East', 1, 1075, 673, 402, 12017818.5),
('2025-07-01', 'East', 10, 1398, 731, 667, 3728591.93),
('2025-07-01', 'East', 11, 1393, 810, 583, 4111148.5),
('2025-07-01', 'East', 12, 1381, 602, 779, 3061412.01),
('2025-07-01', 'East', 2, 1082, 623, 459, 11568257.75),
('2025-07-01', 'East', 3, 1077, 514, 563, 9106107.34),
('2025-07-01', 'East', 4, 720, 495, 225, 17131074.14),
('2025-07-01', 'East', 5, 691, 477, 214, 16704416.45),
('2025-07-01', 'East', 6, 724, 455, 269, 15850244.77),
('2025-07-01', 'East', 7, 473, 243, 230, 68590408.09),
('2025-07-01', 'East', 8, 486, 249, 237, 70743241.45),
('2025-07-01', 'East', 9, 469, 219, 250, 59948103.51),
('2025-07-01', 'Midwest', 1, 777, 488, 289, 8659594.34),
('2025-07-01', 'Midwest', 10, 1042, 552, 490, 2716848.1),
('2025-07-01', 'Midwest', 11, 1045, 611, 434, 3080392.47),
('2025-07-01', 'Midwest', 12, 1008, 443, 565, 2225481.03),
('2025-07-01', 'Midwest', 2, 805, 451, 354, 8263926.24),
('2025-07-01', 'Midwest', 3, 790, 366, 424, 6829265.1),
('2025-07-01', 'Midwest', 4, 535, 367, 168, 12725008.85),
('2025-07-01', 'Midwest', 5, 523, 354, 169, 12266603.99),
('2025-07-01', 'Midwest', 6, 522, 321, 201, 10901509.84),
('2025-07-01', 'Midwest', 7, 328, 167, 161, 48402630.5),
('2025-07-01', 'Midwest', 8, 327, 170, 157, 47904635.33),
('2025-07-01', 'Midwest', 9, 325, 147, 178, 41238755.51),
('2025-07-01', 'South', 1, 941, 604, 337, 10569774.21),
('2025-07-01', 'South', 10, 1165, 614, 551, 3122154.83),
('2025-07-01', 'South', 11, 1112, 651, 461, 3266333.79),
('2025-07-01', 'South', 12, 1116, 484, 632, 2398829.47),
('2025-07-01', 'South', 2, 898, 515, 383, 9103834.91),
('2025-07-01', 'South', 3, 921, 431, 490, 7611450.0),
('2025-07-01', 'South', 4, 565, 396, 169, 13515947.02),
('2025-07-01', 'South', 5, 572, 399, 173, 14127966.65),
('2025-07-01', 'South', 6, 581, 365, 216, 12697738.71),
('2025-07-01', 'South', 7, 376, 193, 183, 53298522.1),
('2025-07-01', 'South', 8, 371, 192, 179, 53786611.41),
('2025-07-01', 'South', 9, 393, 181, 212, 50850253.47),
('2025-07-01', 'West', 1, 1212, 770, 442, 13508910.22),
('2025-07-01', 'West', 10, 1484, 785, 699, 3950388.58),
('2025-07-01', 'West', 11, 1493, 864, 629, 4274386.34),
('2025-07-01', 'West', 12, 1461, 648, 813, 3241913.64),
('2025-07-01', 'West', 2, 1236, 700, 536, 13067350.73),
('2025-07-01', 'West', 3, 1226, 587, 639, 10629851.99),
('2025-07-01', 'West', 4, 795, 559, 236, 19474842.86),
('2025-07-01', 'West', 5, 806, 569, 237, 20608895.92),
('2025-07-01', 'West', 6, 802, 499, 303, 17409670.92),
('2025-07-01', 'West', 7, 525, 274, 251, 76657190.78),
('2025-07-01', 'West', 8, 521, 275, 246, 77755494.04);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-07-01', 'West', 9, 496, 230, 266, 64142471.52),
('2025-08-01', NULL, 4, 99, 70, 29, 2394368.79),
('2025-08-01', NULL, 7, 21, 11, 10, 3516203.59),
('2025-08-01', 'East', 1, 1102, 695, 407, 12658978.57),
('2025-08-01', 'East', 10, 1390, 736, 654, 3708343.14),
('2025-08-01', 'East', 11, 1308, 776, 532, 3936335.36),
('2025-08-01', 'East', 12, 1352, 601, 751, 3064143.98),
('2025-08-01', 'East', 2, 1061, 610, 451, 11019670.9),
('2025-08-01', 'East', 3, 1081, 516, 565, 9219898.99),
('2025-08-01', 'East', 4, 691, 485, 206, 17673503.09),
('2025-08-01', 'East', 5, 722, 508, 214, 17539914.36),
('2025-08-01', 'East', 6, 727, 459, 268, 15722041.62),
('2025-08-01', 'East', 7, 454, 237, 217, 66599744.28),
('2025-08-01', 'East', 8, 453, 235, 218, 65507763.67),
('2025-08-01', 'East', 9, 442, 202, 240, 56858331.47),
('2025-08-01', 'Midwest', 1, 794, 495, 299, 9044340.33),
('2025-08-01', 'Midwest', 10, 952, 503, 449, 2514566.76),
('2025-08-01', 'Midwest', 11, 950, 566, 384, 2880676.97),
('2025-08-01', 'Midwest', 12, 953, 417, 536, 2136101.68),
('2025-08-01', 'Midwest', 2, 754, 417, 337, 7452029.26),
('2025-08-01', 'Midwest', 3, 750, 351, 399, 6323610.18),
('2025-08-01', 'Midwest', 4, 509, 352, 157, 12528596.73),
('2025-08-01', 'Midwest', 5, 500, 346, 154, 12316702.64),
('2025-08-01', 'Midwest', 6, 521, 321, 200, 11332798.14),
('2025-08-01', 'Midwest', 7, 324, 165, 159, 44626654.07),
('2025-08-01', 'Midwest', 8, 333, 168, 165, 46651869.49),
('2025-08-01', 'Midwest', 9, 329, 146, 183, 40823339.09),
('2025-08-01', 'South', 1, 884, 556, 328, 9763708.73),
('2025-08-01', 'South', 10, 1125, 598, 527, 2904754.38),
('2025-08-01', 'South', 11, 1101, 635, 466, 3133334.36),
('2025-08-01', 'South', 12, 1080, 474, 606, 2283201.06),
('2025-08-01', 'South', 2, 880, 503, 377, 9008278.09),
('2025-08-01', 'South', 3, 849, 398, 451, 7273108.98),
('2025-08-01', 'South', 4, 535, 377, 158, 13670880.83),
('2025-08-01', 'South', 5, 560, 386, 174, 13615449.77),
('2025-08-01', 'South', 6, 572, 361, 211, 12398157.91),
('2025-08-01', 'South', 7, 357, 183, 174, 52139368.68),
('2025-08-01', 'South', 8, 372, 194, 178, 55360712.35),
('2025-08-01', 'South', 9, 370, 169, 201, 47175098.1),
('2025-08-01', 'West', 1, 1122, 720, 402, 12599976.75),
('2025-08-01', 'West', 10, 1526, 812, 714, 4024919.35),
('2025-08-01', 'West', 11, 1461, 863, 598, 4299341.09),
('2025-08-01', 'West', 12, 1453, 630, 823, 3076277.32),
('2025-08-01', 'West', 2, 1157, 655, 502, 11676579.19),
('2025-08-01', 'West', 3, 1170, 556, 614, 10007779.6),
('2025-08-01', 'West', 4, 764, 532, 232, 18315876.24),
('2025-08-01', 'West', 5, 766, 536, 230, 18775258.72),
('2025-08-01', 'West', 6, 764, 482, 282, 16407316.13),
('2025-08-01', 'West', 7, 504, 260, 244, 71638611.81),
('2025-08-01', 'West', 8, 486, 251, 235, 69446963.31);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-08-01', 'West', 9, 502, 234, 268, 65631800.46),
('2025-09-01', NULL, 1, 15, 9, 6, 165302.42),
('2025-09-01', NULL, 10, 87, 49, 38, 237241.4),
('2025-09-01', NULL, 11, 14, 8, 6, 40351.48),
('2025-09-01', NULL, 3, 52, 26, 26, 535935.01),
('2025-09-01', NULL, 4, 25, 18, 7, 710195.01),
('2025-09-01', NULL, 8, 16, 9, 7, 2891828.98),
('2025-09-01', NULL, 9, 9, 4, 5, 1146536.68),
('2025-09-01', 'East', 1, 1024, 663, 361, 11901724.76),
('2025-09-01', 'East', 10, 1265, 672, 593, 3303412.36),
('2025-09-01', 'East', 11, 1253, 747, 506, 3692026.08),
('2025-09-01', 'East', 12, 1299, 562, 737, 2808139.16),
('2025-09-01', 'East', 2, 1014, 579, 435, 10281760.46),
('2025-09-01', 'East', 3, 955, 451, 504, 7953434.51),
('2025-09-01', 'East', 4, 656, 453, 203, 16456387.67),
('2025-09-01', 'East', 5, 689, 481, 208, 16633973.66),
('2025-09-01', 'East', 6, 694, 438, 256, 15240980.51),
('2025-09-01', 'East', 7, 324, 162, 162, 44913766.35),
('2025-09-01', 'East', 8, 327, 164, 163, 45858497.26),
('2025-09-01', 'East', 9, 346, 160, 186, 46051938.57),
('2025-09-01', 'Midwest', 1, 749, 474, 275, 8570051.72),
('2025-09-01', 'Midwest', 10, 936, 492, 444, 2456659.66),
('2025-09-01', 'Midwest', 11, 951, 559, 392, 2854891.76),
('2025-09-01', 'Midwest', 12, 966, 422, 544, 2114980.49),
('2025-09-01', 'Midwest', 2, 750, 425, 325, 7770428.4),
('2025-09-01', 'Midwest', 3, 742, 347, 395, 6064936.63),
('2025-09-01', 'Midwest', 4, 501, 344, 157, 11862825.45),
('2025-09-01', 'Midwest', 5, 512, 362, 150, 12467414.42),
('2025-09-01', 'Midwest', 6, 502, 314, 188, 10482056.04),
('2025-09-01', 'Midwest', 7, 233, 114, 119, 32454981.01),
('2025-09-01', 'Midwest', 8, 241, 119, 122, 32818702.24),
('2025-09-01', 'Midwest', 9, 246, 105, 141, 29296988.46),
('2025-09-01', 'South', 1, 811, 508, 303, 9222693.97),
('2025-09-01', 'South', 10, 990, 525, 465, 2559333.79),
('2025-09-01', 'South', 11, 1061, 624, 437, 3108937.4),
('2025-09-01', 'South', 12, 1080, 475, 605, 2328859.5),
('2025-09-01', 'South', 2, 841, 476, 365, 8411164.08),
('2025-09-01', 'South', 3, 848, 394, 454, 6908260.25),
('2025-09-01', 'South', 4, 556, 388, 168, 13147376.92),
('2025-09-01', 'South', 5, 537, 373, 164, 12765949.55),
('2025-09-01', 'South', 6, 570, 358, 212, 12599302.99),
('2025-09-01', 'South', 7, 277, 137, 140, 38349394.16),
('2025-09-01', 'South', 8, 273, 138, 135, 39142999.07),
('2025-09-01', 'South', 9, 278, 127, 151, 35193890.11),
('2025-09-01', 'West', 1, 1143, 735, 408, 13617448.88),
('2025-09-01', 'West', 10, 1368, 727, 641, 3576408.44),
('2025-09-01', 'West', 11, 1431, 850, 581, 4177482.85),
('2025-09-01', 'West', 12, 1436, 629, 807, 3009576.42),
('2025-09-01', 'West', 2, 1121, 635, 486, 11612281.74),
('2025-09-01', 'West', 3, 1155, 549, 606, 9970487.2);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-09-01', 'West', 4, 747, 525, 222, 17933252.65),
('2025-09-01', 'West', 5, 746, 523, 223, 18800399.96),
('2025-09-01', 'West', 6, 774, 490, 284, 17225880.97),
('2025-09-01', 'West', 7, 361, 182, 179, 52493895.67),
('2025-09-01', 'West', 8, 376, 192, 184, 54637748.12),
('2025-09-01', 'West', 9, 361, 161, 200, 45375696.96),
('2025-10-01', NULL, 1, 36, 23, 13, 432840.87),
('2025-10-01', NULL, 10, 20, 11, 9, 53158.52),
('2025-10-01', NULL, 12, 14, 6, 8, 27291.43),
('2025-10-01', NULL, 3, 34, 17, 17, 308073.42),
('2025-10-01', NULL, 5, 27, 20, 7, 781097.61),
('2025-10-01', NULL, 6, 19, 12, 7, 469139.87),
('2025-10-01', NULL, 8, 13, 7, 6, 1759472.54),
('2025-10-01', 'East', 1, 1029, 654, 375, 11926427.73),
('2025-10-01', 'East', 10, 1399, 738, 661, 3662461.77),
('2025-10-01', 'East', 11, 1358, 796, 562, 3969071.37),
('2025-10-01', 'East', 12, 1325, 590, 735, 2938801.22),
('2025-10-01', 'East', 2, 1077, 617, 460, 11186179.03),
('2025-10-01', 'East', 3, 1119, 520, 599, 9286250.49),
('2025-10-01', 'East', 4, 726, 508, 218, 17263001.44),
('2025-10-01', 'East', 5, 720, 509, 211, 18147200.31),
('2025-10-01', 'East', 6, 721, 451, 270, 16537380.68),
('2025-10-01', 'East', 7, 362, 188, 174, 52197735.49),
('2025-10-01', 'East', 8, 354, 182, 172, 49770549.94),
('2025-10-01', 'East', 9, 370, 165, 205, 46731125.75),
('2025-10-01', 'Midwest', 1, 787, 496, 291, 9201928.63),
('2025-10-01', 'Midwest', 10, 1012, 533, 479, 2579549.91),
('2025-10-01', 'Midwest', 11, 1003, 598, 405, 2942594.77),
('2025-10-01', 'Midwest', 12, 1019, 443, 576, 2173354.24),
('2025-10-01', 'Midwest', 2, 772, 441, 331, 8022479.5),
('2025-10-01', 'Midwest', 3, 757, 350, 407, 6391668.11),
('2025-10-01', 'Midwest', 4, 511, 352, 159, 12549332.07),
('2025-10-01', 'Midwest', 5, 511, 351, 160, 11957948.81),
('2025-10-01', 'Midwest', 6, 519, 319, 200, 11298768.48),
('2025-10-01', 'Midwest', 7, 256, 127, 129, 35440089.37),
('2025-10-01', 'Midwest', 8, 256, 126, 130, 35457784.86),
('2025-10-01', 'Midwest', 9, 262, 116, 146, 31497073.09),
('2025-10-01', 'South', 1, 880, 549, 331, 9895457.75),
('2025-10-01', 'South', 10, 1159, 604, 555, 3080548.83),
('2025-10-01', 'South', 11, 1096, 645, 451, 3147484.57),
('2025-10-01', 'South', 12, 1115, 479, 636, 2437743.43),
('2025-10-01', 'South', 2, 915, 520, 395, 9579596.38),
('2025-10-01', 'South', 3, 892, 424, 468, 7563348.36),
('2025-10-01', 'South', 4, 615, 432, 183, 15084946.25),
('2025-10-01', 'South', 5, 594, 415, 179, 14015206.19),
('2025-10-01', 'South', 6, 558, 339, 219, 12270510.07),
('2025-10-01', 'South', 7, 289, 142, 147, 39662083.9),
('2025-10-01', 'South', 8, 271, 137, 134, 38711971.08),
('2025-10-01', 'South', 9, 283, 125, 158, 33216978.41),
('2025-10-01', 'West', 1, 1169, 756, 413, 13633899.33);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-10-01', 'West', 10, 1471, 769, 702, 3798868.0),
('2025-10-01', 'West', 11, 1507, 883, 624, 4400913.93),
('2025-10-01', 'West', 12, 1472, 647, 825, 3326908.38),
('2025-10-01', 'West', 2, 1214, 704, 510, 12825037.84),
('2025-10-01', 'West', 3, 1215, 571, 644, 10126110.24),
('2025-10-01', 'West', 4, 797, 567, 230, 20037670.87),
('2025-10-01', 'West', 5, 776, 546, 230, 19134820.51),
('2025-10-01', 'West', 6, 777, 494, 283, 17830880.15),
('2025-10-01', 'West', 7, 397, 206, 191, 57737468.43),
('2025-10-01', 'West', 8, 378, 192, 186, 54611770.43),
('2025-10-01', 'West', 9, 391, 175, 216, 50632439.6),
('2025-11-01', NULL, 12, 18, 7, 11, 34344.24),
('2025-11-01', NULL, 3, 41, 20, 21, 354731.86),
('2025-11-01', NULL, 6, 19, 12, 7, 423647.34),
('2025-11-01', NULL, 7, 13, 7, 6, 2072693.39),
('2025-11-01', NULL, 8, 11, 6, 5, 1915597.8),
('2025-11-01', 'East', 1, 1001, 650, 351, 11772789.56),
('2025-11-01', 'East', 10, 1304, 695, 609, 3456587.6),
('2025-11-01', 'East', 11, 1302, 777, 525, 3864162.31),
('2025-11-01', 'East', 12, 1289, 553, 736, 2751533.24),
('2025-11-01', 'East', 2, 1028, 584, 444, 10431862.6),
('2025-11-01', 'East', 3, 1046, 493, 553, 8632124.19),
('2025-11-01', 'East', 4, 678, 468, 210, 16386640.36),
('2025-11-01', 'East', 5, 665, 460, 205, 16395223.86),
('2025-11-01', 'East', 6, 621, 394, 227, 13765151.81),
('2025-11-01', 'East', 7, 347, 178, 169, 49895862.57),
('2025-11-01', 'East', 8, 343, 176, 167, 48469331.56),
('2025-11-01', 'East', 9, 327, 146, 181, 41954142.75),
('2025-11-01', 'Midwest', 1, 729, 459, 270, 8331298.99),
('2025-11-01', 'Midwest', 10, 920, 482, 438, 2386336.26),
('2025-11-01', 'Midwest', 11, 924, 535, 389, 2703403.25),
('2025-11-01', 'Midwest', 12, 943, 409, 534, 2092277.29),
('2025-11-01', 'Midwest', 2, 744, 414, 330, 7496529.55),
('2025-11-01', 'Midwest', 3, 753, 350, 403, 6269227.81),
('2025-11-01', 'Midwest', 4, 486, 334, 152, 11602288.15),
('2025-11-01', 'Midwest', 5, 522, 364, 158, 12509854.76),
('2025-11-01', 'Midwest', 6, 482, 301, 181, 10372252.18),
('2025-11-01', 'Midwest', 7, 231, 111, 120, 31339615.29),
('2025-11-01', 'Midwest', 8, 234, 113, 121, 31953468.47),
('2025-11-01', 'Midwest', 9, 237, 103, 134, 28876256.69),
('2025-11-01', 'South', 1, 843, 527, 316, 9364391.3),
('2025-11-01', 'South', 10, 1081, 562, 519, 2801860.22),
('2025-11-01', 'South', 11, 1036, 603, 433, 3034768.57),
('2025-11-01', 'South', 12, 1080, 467, 613, 2342022.89),
('2025-11-01', 'South', 2, 823, 466, 357, 8310783.94),
('2025-11-01', 'South', 3, 860, 411, 449, 7323080.9),
('2025-11-01', 'South', 4, 540, 374, 166, 13340778.35),
('2025-11-01', 'South', 5, 569, 399, 170, 14079547.72),
('2025-11-01', 'South', 6, 533, 328, 205, 11550174.22),
('2025-11-01', 'South', 7, 268, 132, 136, 37307048.7);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-11-01', 'South', 8, 281, 141, 140, 40116419.69),
('2025-11-01', 'South', 9, 264, 117, 147, 33108395.35),
('2025-11-01', 'West', 1, 1109, 712, 397, 12730207.78),
('2025-11-01', 'West', 10, 1384, 738, 646, 3678450.32),
('2025-11-01', 'West', 11, 1389, 820, 569, 4069359.28),
('2025-11-01', 'West', 12, 1400, 612, 788, 3002627.25),
('2025-11-01', 'West', 2, 1130, 644, 486, 11372048.0),
('2025-11-01', 'West', 3, 1086, 512, 574, 9447394.8),
('2025-11-01', 'West', 4, 714, 499, 215, 17299169.61),
('2025-11-01', 'West', 5, 751, 524, 227, 18128513.62),
('2025-11-01', 'West', 6, 723, 456, 267, 16521002.65),
('2025-11-01', 'West', 7, 369, 189, 180, 53417939.79),
('2025-11-01', 'West', 8, 360, 181, 179, 50048934.59),
('2025-11-01', 'West', 9, 352, 160, 192, 43894974.43),
('2025-12-01', NULL, 1, 38, 25, 13, 421796.99),
('2025-12-01', NULL, 3, 48, 24, 24, 452931.39),
('2025-12-01', NULL, 4, 62, 44, 18, 1412482.71),
('2025-12-01', NULL, 5, 10, 7, 3, 227708.18),
('2025-12-01', NULL, 8, 17, 8, 9, 2122626.16),
('2025-12-01', NULL, 9, 9, 4, 5, 1195256.31),
('2025-12-01', 'East', 1, 1041, 666, 375, 12420714.19),
('2025-12-01', 'East', 10, 1324, 708, 616, 3362947.54),
('2025-12-01', 'East', 11, 1359, 804, 555, 3980881.49),
('2025-12-01', 'East', 12, 1389, 604, 785, 3005048.63),
('2025-12-01', 'East', 2, 1078, 613, 465, 11158474.33),
('2025-12-01', 'East', 3, 1055, 495, 560, 8947313.82),
('2025-12-01', 'East', 4, 707, 492, 215, 16613040.53),
('2025-12-01', 'East', 5, 706, 495, 211, 17777986.35),
('2025-12-01', 'East', 6, 699, 441, 258, 15638096.55),
('2025-12-01', 'East', 7, 349, 180, 169, 49929525.54),
('2025-12-01', 'East', 8, 347, 177, 170, 48452030.49),
('2025-12-01', 'East', 9, 347, 155, 192, 42269706.85),
('2025-12-01', 'Midwest', 1, 768, 480, 288, 8815325.21),
('2025-12-01', 'Midwest', 10, 1022, 534, 488, 2652275.32),
('2025-12-01', 'Midwest', 11, 981, 573, 408, 2900310.19),
('2025-12-01', 'Midwest', 12, 986, 429, 557, 2158306.15),
('2025-12-01', 'Midwest', 2, 781, 440, 341, 8272510.98),
('2025-12-01', 'Midwest', 3, 746, 352, 394, 6679028.29),
('2025-12-01', 'Midwest', 4, 512, 358, 154, 12754027.72),
('2025-12-01', 'Midwest', 5, 507, 349, 158, 11788283.9),
('2025-12-01', 'Midwest', 6, 511, 313, 198, 10686872.28),
('2025-12-01', 'Midwest', 7, 244, 119, 125, 32560797.1),
('2025-12-01', 'Midwest', 8, 245, 121, 124, 35506605.38),
('2025-12-01', 'Midwest', 9, 249, 109, 140, 30441268.32),
('2025-12-01', 'South', 1, 830, 519, 311, 9413741.66),
('2025-12-01', 'South', 10, 1127, 580, 547, 2899241.58),
('2025-12-01', 'South', 11, 1050, 615, 435, 3025742.06),
('2025-12-01', 'South', 12, 1083, 466, 617, 2268595.09),
('2025-12-01', 'South', 2, 862, 494, 368, 9086140.76),
('2025-12-01', 'South', 3, 888, 415, 473, 7640345.3);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2025-12-01', 'South', 4, 585, 406, 179, 14596959.64),
('2025-12-01', 'South', 5, 599, 417, 182, 14432371.94),
('2025-12-01', 'South', 6, 587, 366, 221, 12639688.79),
('2025-12-01', 'South', 7, 275, 133, 142, 36435015.32),
('2025-12-01', 'South', 8, 272, 134, 138, 37922297.68),
('2025-12-01', 'South', 9, 273, 122, 151, 34012344.91),
('2025-12-01', 'West', 1, 1162, 743, 419, 13329457.56),
('2025-12-01', 'West', 10, 1420, 760, 660, 3857837.73),
('2025-12-01', 'West', 11, 1500, 890, 610, 4483096.1),
('2025-12-01', 'West', 12, 1437, 630, 807, 3157802.33),
('2025-12-01', 'West', 2, 1168, 661, 507, 11740430.92),
('2025-12-01', 'West', 3, 1106, 530, 576, 9548452.45),
('2025-12-01', 'West', 4, 746, 517, 229, 18526729.32),
('2025-12-01', 'West', 5, 759, 525, 234, 17681511.44),
('2025-12-01', 'West', 6, 769, 479, 290, 16941717.93),
('2025-12-01', 'West', 7, 370, 186, 184, 52338574.27),
('2025-12-01', 'West', 8, 356, 184, 172, 51398525.93),
('2025-12-01', 'West', 9, 387, 175, 212, 48413930.36),
('2026-01-01', NULL, 10, 59, 29, 30, 162023.95),
('2026-01-01', NULL, 12, 33, 13, 20, 65656.6),
('2026-01-01', NULL, 2, 28, 16, 12, 277376.01),
('2026-01-01', NULL, 3, 44, 19, 25, 365364.0),
('2026-01-01', NULL, 7, 10, 5, 5, 1490180.44),
('2026-01-01', NULL, 8, 5, 2, 3, 588579.72),
('2026-01-01', 'East', 1, 773, 487, 286, 8684622.02),
('2026-01-01', 'East', 10, 1359, 718, 641, 3563059.95),
('2026-01-01', 'East', 11, 1400, 832, 568, 4232418.77),
('2026-01-01', 'East', 12, 1358, 592, 766, 2987589.16),
('2026-01-01', 'East', 2, 760, 425, 335, 7659573.92),
('2026-01-01', 'East', 3, 743, 353, 390, 6348103.68),
('2026-01-01', 'East', 4, 735, 519, 216, 18019152.22),
('2026-01-01', 'East', 5, 747, 517, 230, 18339815.53),
('2026-01-01', 'East', 6, 704, 441, 263, 15047019.03),
('2026-01-01', 'East', 7, 368, 187, 181, 53534739.76),
('2026-01-01', 'East', 8, 358, 179, 179, 51005204.6),
('2026-01-01', 'East', 9, 343, 157, 186, 43563411.86),
('2026-01-01', 'Midwest', 1, 557, 351, 206, 6324902.32),
('2026-01-01', 'Midwest', 10, 998, 523, 475, 2628750.81),
('2026-01-01', 'Midwest', 11, 1027, 593, 434, 3035515.04),
('2026-01-01', 'Midwest', 12, 988, 425, 563, 2149110.0),
('2026-01-01', 'Midwest', 2, 548, 307, 241, 5607652.2),
('2026-01-01', 'Midwest', 3, 531, 246, 285, 4459960.63),
('2026-01-01', 'Midwest', 4, 524, 366, 158, 12769408.1),
('2026-01-01', 'Midwest', 5, 544, 373, 171, 12866633.38),
('2026-01-01', 'Midwest', 6, 518, 323, 195, 11070133.23),
('2026-01-01', 'Midwest', 7, 270, 132, 138, 36040612.55),
('2026-01-01', 'Midwest', 8, 249, 119, 130, 34280743.41),
('2026-01-01', 'Midwest', 9, 251, 108, 143, 29966221.48),
('2026-01-01', 'South', 1, 656, 408, 248, 7622669.63),
('2026-01-01', 'South', 10, 1152, 608, 544, 2963241.8);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-01-01', 'South', 11, 1143, 673, 470, 3338723.37),
('2026-01-01', 'South', 12, 1148, 498, 650, 2451605.29),
('2026-01-01', 'South', 2, 618, 349, 269, 6283538.41),
('2026-01-01', 'South', 3, 591, 281, 310, 4993504.65),
('2026-01-01', 'South', 4, 587, 406, 181, 14268854.67),
('2026-01-01', 'South', 5, 573, 400, 173, 13695414.01),
('2026-01-01', 'South', 6, 592, 368, 224, 12979141.66),
('2026-01-01', 'South', 7, 274, 134, 140, 37780370.91),
('2026-01-01', 'South', 8, 276, 135, 141, 38552797.96),
('2026-01-01', 'South', 9, 290, 133, 157, 36674806.58),
('2026-01-01', 'West', 1, 871, 559, 312, 9693134.51),
('2026-01-01', 'West', 10, 1491, 781, 710, 3958799.31),
('2026-01-01', 'West', 11, 1561, 919, 642, 4583365.2),
('2026-01-01', 'West', 12, 1533, 683, 850, 3334322.57),
('2026-01-01', 'West', 2, 840, 488, 352, 8791846.15),
('2026-01-01', 'West', 3, 825, 383, 442, 6936492.79),
('2026-01-01', 'West', 4, 791, 561, 230, 18936144.01),
('2026-01-01', 'West', 5, 823, 576, 247, 19632268.71),
('2026-01-01', 'West', 6, 803, 501, 302, 17902265.21),
('2026-01-01', 'West', 7, 395, 201, 194, 57003895.16),
('2026-01-01', 'West', 8, 390, 200, 190, 55848132.93),
('2026-01-01', 'West', 9, 410, 186, 224, 53495937.8),
('2026-02-01', NULL, 1, 32, 21, 11, 329230.16),
('2026-02-01', NULL, 2, 6, 3, 3, 50106.52),
('2026-02-01', NULL, 3, 15, 6, 9, 113012.07),
('2026-02-01', NULL, 6, 27, 18, 9, 695896.36),
('2026-02-01', 'East', 1, 653, 404, 249, 7182764.11),
('2026-02-01', 'East', 10, 1255, 666, 589, 3423270.45),
('2026-02-01', 'East', 11, 1205, 713, 492, 3547285.32),
('2026-02-01', 'East', 12, 1189, 525, 664, 2601933.61),
('2026-02-01', 'East', 2, 648, 365, 283, 6379058.93),
('2026-02-01', 'East', 3, 654, 305, 349, 5654518.57),
('2026-02-01', 'East', 4, 658, 455, 203, 16208924.86),
('2026-02-01', 'East', 5, 650, 458, 192, 15882185.75),
('2026-02-01', 'East', 6, 663, 413, 250, 14641293.71),
('2026-02-01', 'East', 7, 311, 158, 153, 43854955.38),
('2026-02-01', 'East', 8, 319, 165, 154, 45182908.9),
('2026-02-01', 'East', 9, 320, 142, 178, 38704426.42),
('2026-02-01', 'Midwest', 1, 484, 300, 184, 5321335.14),
('2026-02-01', 'Midwest', 10, 878, 455, 423, 2290050.59),
('2026-02-01', 'Midwest', 11, 876, 505, 371, 2551435.8),
('2026-02-01', 'Midwest', 12, 922, 401, 521, 1953562.28),
('2026-02-01', 'Midwest', 2, 500, 278, 222, 4926225.59),
('2026-02-01', 'Midwest', 3, 487, 220, 267, 3960074.45),
('2026-02-01', 'Midwest', 4, 457, 314, 143, 10909707.54),
('2026-02-01', 'Midwest', 5, 450, 312, 138, 11183456.72),
('2026-02-01', 'Midwest', 6, 471, 296, 175, 10359024.94),
('2026-02-01', 'Midwest', 7, 226, 110, 116, 30416792.13),
('2026-02-01', 'Midwest', 8, 225, 112, 113, 31188157.86),
('2026-02-01', 'Midwest', 9, 230, 97, 133, 27342087.51);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-02-01', 'South', 1, 533, 333, 200, 5994148.28),
('2026-02-01', 'South', 10, 990, 521, 469, 2621719.03),
('2026-02-01', 'South', 11, 975, 565, 410, 2841856.88),
('2026-02-01', 'South', 12, 1002, 438, 564, 2148245.09),
('2026-02-01', 'South', 2, 549, 306, 243, 5440390.41),
('2026-02-01', 'South', 3, 543, 250, 293, 4568662.15),
('2026-02-01', 'South', 4, 517, 365, 152, 13341598.79),
('2026-02-01', 'South', 5, 522, 362, 160, 12489515.93),
('2026-02-01', 'South', 6, 537, 338, 199, 11622982.22),
('2026-02-01', 'South', 7, 258, 126, 132, 35514015.44),
('2026-02-01', 'South', 8, 258, 127, 131, 34975419.65),
('2026-02-01', 'South', 9, 252, 114, 138, 31927065.09),
('2026-02-01', 'West', 1, 799, 499, 300, 8689393.54),
('2026-02-01', 'West', 10, 1278, 674, 604, 3387933.51),
('2026-02-01', 'West', 11, 1347, 795, 552, 3975930.79),
('2026-02-01', 'West', 12, 1342, 594, 748, 2887735.23),
('2026-02-01', 'West', 2, 729, 412, 317, 7337947.81),
('2026-02-01', 'West', 3, 757, 356, 401, 6476949.58),
('2026-02-01', 'West', 4, 722, 506, 216, 17779014.37),
('2026-02-01', 'West', 5, 712, 493, 219, 17563114.66),
('2026-02-01', 'West', 6, 682, 424, 258, 14536014.64),
('2026-02-01', 'West', 7, 335, 171, 164, 48740135.61),
('2026-02-01', 'West', 8, 339, 171, 168, 49310211.88),
('2026-02-01', 'West', 9, 352, 160, 192, 44104375.29),
('2026-03-01', NULL, 1, 174, 109, 65, 1936579.29),
('2026-03-01', NULL, 10, 304, 158, 146, 778028.42),
('2026-03-01', NULL, 11, 140, 80, 60, 382216.25),
('2026-03-01', NULL, 12, 198, 84, 114, 440585.8),
('2026-03-01', NULL, 2, 286, 155, 131, 2703418.55),
('2026-03-01', NULL, 3, 228, 108, 120, 1935661.26),
('2026-03-01', NULL, 4, 265, 190, 75, 6960394.26),
('2026-03-01', NULL, 5, 184, 131, 53, 4741806.4),
('2026-03-01', NULL, 6, 210, 130, 80, 4466310.45),
('2026-03-01', NULL, 7, 173, 87, 86, 23754449.26),
('2026-03-01', NULL, 8, 121, 63, 58, 17462468.57),
('2026-03-01', NULL, 9, 113, 51, 62, 14763180.32),
('2026-03-01', 'East', 1, 610, 388, 222, 6956725.85),
('2026-03-01', 'East', 10, 1163, 605, 558, 3010097.13),
('2026-03-01', 'East', 11, 1205, 713, 492, 3577482.4),
('2026-03-01', 'East', 12, 1273, 555, 718, 2705225.05),
('2026-03-01', 'East', 2, 629, 348, 281, 6238205.78),
('2026-03-01', 'East', 3, 708, 325, 383, 5999522.92),
('2026-03-01', 'East', 4, 598, 416, 182, 14543823.01),
('2026-03-01', 'East', 5, 636, 444, 192, 15739840.94),
('2026-03-01', 'East', 6, 643, 406, 237, 14360197.28),
('2026-03-01', 'East', 7, 289, 149, 140, 42008590.43),
('2026-03-01', 'East', 8, 300, 151, 149, 40949743.24),
('2026-03-01', 'East', 9, 313, 142, 171, 39528746.42),
('2026-03-01', 'Midwest', 1, 539, 331, 208, 5952253.38),
('2026-03-01', 'Midwest', 10, 898, 473, 425, 2398935.19);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-03-01', 'Midwest', 11, 966, 560, 406, 2823897.26),
('2026-03-01', 'Midwest', 12, 970, 423, 547, 2170006.37),
('2026-03-01', 'Midwest', 2, 485, 270, 215, 5031078.2),
('2026-03-01', 'Midwest', 3, 481, 217, 264, 3918665.36),
('2026-03-01', 'Midwest', 4, 469, 320, 149, 11047472.11),
('2026-03-01', 'Midwest', 5, 480, 330, 150, 11502581.67),
('2026-03-01', 'Midwest', 6, 428, 265, 163, 9501811.88),
('2026-03-01', 'Midwest', 7, 234, 115, 119, 30857875.14),
('2026-03-01', 'Midwest', 8, 232, 113, 119, 31831571.64),
('2026-03-01', 'Midwest', 9, 236, 101, 135, 29317823.71),
('2026-03-01', 'South', 1, 556, 349, 207, 6371814.56),
('2026-03-01', 'South', 10, 997, 514, 483, 2595430.79),
('2026-03-01', 'South', 11, 1050, 611, 439, 2954320.91),
('2026-03-01', 'South', 12, 920, 406, 514, 2054619.66),
('2026-03-01', 'South', 2, 562, 313, 249, 5714992.44),
('2026-03-01', 'South', 3, 543, 253, 290, 4514059.22),
('2026-03-01', 'South', 4, 550, 383, 167, 12969833.3),
('2026-03-01', 'South', 5, 549, 374, 175, 12500093.19),
('2026-03-01', 'South', 6, 521, 327, 194, 11529295.39),
('2026-03-01', 'South', 7, 220, 109, 111, 30573716.98),
('2026-03-01', 'South', 8, 253, 122, 131, 33606745.6),
('2026-03-01', 'South', 9, 246, 108, 138, 29923574.08),
('2026-03-01', 'West', 1, 780, 495, 285, 9141626.18),
('2026-03-01', 'West', 10, 1312, 695, 617, 3510547.6),
('2026-03-01', 'West', 11, 1414, 829, 585, 4081723.18),
('2026-03-01', 'West', 12, 1399, 618, 781, 3178827.36),
('2026-03-01', 'West', 2, 686, 391, 295, 7107755.49),
('2026-03-01', 'West', 3, 707, 328, 379, 5782437.98),
('2026-03-01', 'West', 4, 642, 448, 194, 15393799.04),
('2026-03-01', 'West', 5, 658, 461, 197, 16537468.09),
('2026-03-01', 'West', 6, 707, 444, 263, 15749072.13),
('2026-03-01', 'West', 7, 303, 156, 147, 43583685.91),
('2026-03-01', 'West', 8, 324, 168, 156, 46803900.68),
('2026-03-01', 'West', 9, 328, 155, 173, 44187448.78),
('2026-04-01', NULL, 1, 460, 296, 164, 5462400.26),
('2026-04-01', NULL, 10, 451, 235, 216, 1191502.86),
('2026-04-01', NULL, 11, 391, 230, 161, 1081814.93),
('2026-04-01', NULL, 12, 236, 104, 132, 517275.21),
('2026-04-01', NULL, 2, 410, 230, 180, 4296722.94),
('2026-04-01', NULL, 3, 299, 139, 160, 2649943.88),
('2026-04-01', NULL, 4, 240, 162, 78, 5519360.9),
('2026-04-01', NULL, 5, 228, 159, 69, 5403509.49),
('2026-04-01', NULL, 6, 265, 166, 99, 5881857.78),
('2026-04-01', NULL, 7, 74, 36, 38, 10226918.2),
('2026-04-01', NULL, 8, 128, 65, 63, 18415768.67),
('2026-04-01', NULL, 9, 88, 37, 51, 10675223.52),
('2026-04-01', 'East', 1, 987, 626, 361, 11315277.93),
('2026-04-01', 'East', 10, 1295, 695, 600, 3510225.14),
('2026-04-01', 'East', 11, 1261, 746, 515, 3875298.68),
('2026-04-01', 'East', 12, 1302, 581, 721, 2901625.67);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-04-01', 'East', 2, 981, 550, 431, 9798082.88),
('2026-04-01', 'East', 3, 966, 462, 504, 8327484.08),
('2026-04-01', 'East', 4, 855, 602, 253, 20746795.33),
('2026-04-01', 'East', 5, 933, 655, 278, 23305780.91),
('2026-04-01', 'East', 6, 949, 600, 349, 21223394.56),
('2026-04-01', 'East', 7, 299, 153, 146, 41670035.74),
('2026-04-01', 'East', 8, 284, 144, 140, 39010978.35),
('2026-04-01', 'East', 9, 357, 161, 196, 46211069.35),
('2026-04-01', 'Midwest', 1, 659, 408, 251, 7388028.16),
('2026-04-01', 'Midwest', 10, 856, 450, 406, 2246487.12),
('2026-04-01', 'Midwest', 11, 932, 542, 390, 2681842.53),
('2026-04-01', 'Midwest', 12, 942, 413, 529, 2073536.84),
('2026-04-01', 'Midwest', 2, 629, 351, 278, 6383922.82),
('2026-04-01', 'Midwest', 3, 771, 361, 410, 6339122.34),
('2026-04-01', 'Midwest', 4, 672, 471, 201, 16448413.54),
('2026-04-01', 'Midwest', 5, 652, 450, 202, 15807610.12),
('2026-04-01', 'Midwest', 6, 664, 416, 248, 14716784.06),
('2026-04-01', 'Midwest', 7, 229, 114, 115, 32371833.42),
('2026-04-01', 'Midwest', 8, 203, 100, 103, 28935341.87),
('2026-04-01', 'Midwest', 9, 222, 97, 125, 26893809.02),
('2026-04-01', 'South', 1, 815, 514, 301, 9386867.66),
('2026-04-01', 'South', 10, 1069, 561, 508, 2746479.65),
('2026-04-01', 'South', 11, 953, 559, 394, 2870240.19),
('2026-04-01', 'South', 12, 897, 387, 510, 1872635.87),
('2026-04-01', 'South', 2, 826, 465, 361, 8382615.75),
('2026-04-01', 'South', 3, 714, 341, 373, 6206071.14),
('2026-04-01', 'South', 4, 793, 557, 236, 19385234.51),
('2026-04-01', 'South', 5, 786, 551, 235, 19059704.65),
('2026-04-01', 'South', 6, 775, 486, 289, 17154966.07),
('2026-04-01', 'South', 7, 263, 130, 133, 36819195.31),
('2026-04-01', 'South', 8, 249, 119, 130, 33220658.78),
('2026-04-01', 'South', 9, 272, 124, 148, 33816419.04),
('2026-04-01', 'West', 1, 966, 621, 345, 11069216.37),
('2026-04-01', 'West', 10, 1211, 640, 571, 3283101.76),
('2026-04-01', 'West', 11, 1278, 755, 523, 3756698.54),
('2026-04-01', 'West', 12, 1453, 643, 810, 3241531.41),
('2026-04-01', 'West', 2, 1006, 567, 439, 10426407.2),
('2026-04-01', 'West', 3, 1128, 545, 583, 9775736.31),
('2026-04-01', 'West', 4, 977, 685, 292, 23846191.14),
('2026-04-01', 'West', 5, 930, 653, 277, 23414858.99),
('2026-04-01', 'West', 6, 955, 605, 350, 21013842.77),
('2026-04-01', 'West', 7, 351, 177, 174, 49636082.67),
('2026-04-01', 'West', 8, 358, 185, 173, 51669347.86),
('2026-04-01', 'West', 9, 344, 161, 183, 45260103.27),
('2026-05-01', NULL, 12, 49, 22, 27, 115499.55),
('2026-05-01', NULL, 3, 14, 7, 7, 135542.42),
('2026-05-01', NULL, 4, 36, 24, 12, 854701.93),
('2026-05-01', NULL, 5, 9, 6, 3, 198612.77),
('2026-05-01', NULL, 6, 14, 8, 6, 279854.27),
('2026-05-01', NULL, 7, 18, 9, 9, 2540446.39);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-05-01', NULL, 8, 12, 6, 6, 1820006.71),
('2026-05-01', 'East', 1, 1073, 677, 396, 11972471.59),
('2026-05-01', 'East', 10, 1315, 693, 622, 3473870.16),
('2026-05-01', 'East', 11, 1325, 783, 542, 3944936.98),
('2026-05-01', 'East', 12, 1312, 582, 730, 2887663.25),
('2026-05-01', 'East', 2, 1136, 654, 482, 12081536.33),
('2026-05-01', 'East', 3, 1049, 491, 558, 8842875.5),
('2026-05-01', 'East', 4, 1006, 712, 294, 25896412.35),
('2026-05-01', 'East', 5, 1031, 724, 307, 25074192.18),
('2026-05-01', 'East', 6, 951, 606, 345, 21151397.4),
('2026-05-01', 'East', 7, 419, 212, 207, 59149963.29),
('2026-05-01', 'East', 8, 474, 242, 232, 67475582.54),
('2026-05-01', 'East', 9, 435, 203, 232, 56606667.97),
('2026-05-01', 'Midwest', 1, 764, 482, 282, 8628606.59),
('2026-05-01', 'Midwest', 10, 962, 505, 457, 2563087.6),
('2026-05-01', 'Midwest', 11, 967, 561, 406, 2815111.89),
('2026-05-01', 'Midwest', 12, 982, 425, 557, 2104641.13),
('2026-05-01', 'Midwest', 2, 746, 426, 320, 7596927.62),
('2026-05-01', 'Midwest', 3, 748, 350, 398, 6514145.4),
('2026-05-01', 'Midwest', 4, 725, 506, 219, 16908132.02),
('2026-05-01', 'Midwest', 5, 738, 521, 217, 18273457.25),
('2026-05-01', 'Midwest', 6, 715, 442, 273, 15691966.86),
('2026-05-01', 'Midwest', 7, 322, 164, 158, 44165302.35),
('2026-05-01', 'Midwest', 8, 321, 163, 158, 46033117.12),
('2026-05-01', 'Midwest', 9, 326, 145, 181, 39488650.64),
('2026-05-01', 'South', 1, 887, 563, 324, 10108695.17),
('2026-05-01', 'South', 10, 1079, 562, 517, 2736993.6),
('2026-05-01', 'South', 11, 1099, 650, 449, 3269113.06),
('2026-05-01', 'South', 12, 1140, 500, 640, 2539781.02),
('2026-05-01', 'South', 2, 857, 492, 365, 8756710.0),
('2026-05-01', 'South', 3, 884, 413, 471, 7398725.55),
('2026-05-01', 'South', 4, 845, 601, 244, 19564486.16),
('2026-05-01', 'South', 5, 819, 573, 246, 19985198.87),
('2026-05-01', 'South', 6, 827, 520, 307, 18307123.15),
('2026-05-01', 'South', 7, 363, 186, 177, 52866727.62),
('2026-05-01', 'South', 8, 367, 186, 181, 52908127.01),
('2026-05-01', 'South', 9, 360, 161, 199, 45084126.31),
('2026-05-01', 'West', 1, 1225, 785, 440, 14255904.0),
('2026-05-01', 'West', 10, 1480, 773, 707, 3879710.28),
('2026-05-01', 'West', 11, 1436, 838, 598, 3951685.41),
('2026-05-01', 'West', 12, 1462, 641, 821, 3327835.35),
('2026-05-01', 'West', 2, 1128, 645, 483, 10891816.26),
('2026-05-01', 'West', 3, 1164, 563, 601, 9726625.99),
('2026-05-01', 'West', 4, 1096, 774, 322, 25854398.17),
('2026-05-01', 'West', 5, 1048, 743, 305, 22955460.96),
('2026-05-01', 'West', 6, 1076, 670, 406, 23202643.0),
('2026-05-01', 'West', 7, 491, 258, 233, 72780450.27),
('2026-05-01', 'West', 8, 517, 269, 248, 75075973.39),
('2026-05-01', 'West', 9, 488, 229, 259, 64040285.01),
('2026-06-01', NULL, 10, 44, 22, 22, 124310.46);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-06-01', NULL, 12, 33, 14, 19, 79580.41),
('2026-06-01', NULL, 2, 39, 23, 16, 472543.2),
('2026-06-01', NULL, 3, 53, 26, 27, 501200.97),
('2026-06-01', NULL, 7, 16, 8, 8, 2365577.78),
('2026-06-01', 'East', 1, 1032, 642, 390, 11296109.8),
('2026-06-01', 'East', 10, 1301, 679, 622, 3412527.44),
('2026-06-01', 'East', 11, 1261, 743, 518, 3674070.24),
('2026-06-01', 'East', 12, 1297, 564, 733, 2839296.67),
('2026-06-01', 'East', 2, 1046, 605, 441, 10719590.68),
('2026-06-01', 'East', 3, 993, 481, 512, 8704368.07),
('2026-06-01', 'East', 4, 943, 658, 285, 23597644.31),
('2026-06-01', 'East', 5, 960, 684, 276, 24013727.24),
('2026-06-01', 'East', 6, 959, 605, 354, 21948292.98),
('2026-06-01', 'East', 7, 405, 208, 197, 56509993.64),
('2026-06-01', 'East', 8, 454, 234, 220, 64452009.17),
('2026-06-01', 'East', 9, 426, 201, 225, 56103909.03),
('2026-06-01', 'Midwest', 1, 730, 461, 269, 8296238.17),
('2026-06-01', 'Midwest', 10, 974, 514, 460, 2631350.85),
('2026-06-01', 'Midwest', 11, 904, 538, 366, 2671845.7),
('2026-06-01', 'Midwest', 12, 890, 387, 503, 1979589.69),
('2026-06-01', 'Midwest', 2, 774, 435, 339, 7862152.48),
('2026-06-01', 'Midwest', 3, 736, 336, 400, 5950208.6),
('2026-06-01', 'Midwest', 4, 675, 476, 199, 16897976.48),
('2026-06-01', 'Midwest', 5, 690, 482, 208, 17266322.55),
('2026-06-01', 'Midwest', 6, 709, 445, 264, 15670186.31),
('2026-06-01', 'Midwest', 7, 323, 165, 158, 47204521.75),
('2026-06-01', 'Midwest', 8, 313, 158, 155, 46072254.47),
('2026-06-01', 'Midwest', 9, 310, 139, 171, 38660676.49),
('2026-06-01', 'South', 1, 834, 532, 302, 9451675.63),
('2026-06-01', 'South', 10, 1032, 544, 488, 2682151.85),
('2026-06-01', 'South', 11, 1037, 614, 423, 3087069.35),
('2026-06-01', 'South', 12, 1066, 476, 590, 2491401.56),
('2026-06-01', 'South', 2, 801, 453, 348, 8299593.87),
('2026-06-01', 'South', 3, 844, 396, 448, 7084966.41),
('2026-06-01', 'South', 4, 778, 541, 237, 19217744.0),
('2026-06-01', 'South', 5, 797, 564, 233, 20046154.04),
('2026-06-01', 'South', 6, 783, 488, 295, 17112742.27),
('2026-06-01', 'South', 7, 350, 178, 172, 49647700.23),
('2026-06-01', 'South', 8, 366, 189, 177, 53833437.72),
('2026-06-01', 'South', 9, 359, 161, 198, 45119480.65),
('2026-06-01', 'West', 1, 1076, 691, 385, 12238433.08),
('2026-06-01', 'West', 10, 1411, 739, 672, 3714861.99),
('2026-06-01', 'West', 11, 1461, 854, 607, 4184769.88),
('2026-06-01', 'West', 12, 1393, 611, 782, 3039297.78),
('2026-06-01', 'West', 2, 1087, 621, 466, 11003347.91),
('2026-06-01', 'West', 3, 1047, 493, 554, 8673278.25),
('2026-06-01', 'West', 4, 1016, 709, 307, 24611498.5),
('2026-06-01', 'West', 5, 1028, 723, 305, 25461433.69),
('2026-06-01', 'West', 6, 1035, 653, 382, 22657025.04),
('2026-06-01', 'West', 7, 470, 238, 232, 67234826.07);

INSERT INTO loan_originations (date, region, product_id, applications, approvals, denials, funded_amount) VALUES
('2026-06-01', 'West', 8, 483, 249, 234, 70646552.61),
('2026-06-01', 'West', 9, 486, 228, 258, 62512216.95);

-- Loan Performance (900 rows)
INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-01-01', 1, '2022-Q1', 885018, 48, 1, 0, 0, 1322.39),
('2026-01-01', 1, '2022-Q2', 933697, 50, 1, 0, 0, 808.7),
('2026-01-01', 1, '2022-Q3', 1305692, 71, 1, 0, 0, 716.15),
('2026-01-01', 1, '2022-Q4', 1339870, 73, 1, 0, 0, 1610.26),
('2026-01-01', 1, '2023-Q1', 1367703, 73, 2, 0, 0, 1005.32),
('2026-01-01', 1, '2023-Q2', 1135056, 62, 1, 0, 0, 964.23),
('2026-01-01', 1, '2023-Q3', 1615531, 88, 1, 0, 0, 2065.68),
('2026-01-01', 1, '2023-Q4', 1839457, 100, 2, 0, 0, 2511.38),
('2026-01-01', 1, '2024-Q1', 1404202, 77, 1, 0, 0, 1615.07),
('2026-01-01', 1, '2024-Q2', 1694345, 92, 2, 0, 0, 1097.09),
('2026-01-01', 1, '2024-Q3', 2214265, 120, 2, 1, 0, 3236.39),
('2026-01-01', 1, '2024-Q4', 1751729, 94, 2, 1, 0, 1656.09),
('2026-01-01', 2, '2022-Q1', 746745, 38, 2, 1, 0, 2563.24),
('2026-01-01', 2, '2022-Q2', 920421, 47, 3, 1, 0, 3559.27),
('2026-01-01', 2, '2022-Q3', 1007084, 50, 3, 2, 0, 5035.39),
('2026-01-01', 2, '2022-Q4', 1344529, 66, 5, 2, 1, 6615.96),
('2026-01-01', 2, '2023-Q1', 1166005, 59, 3, 1, 1, 4463.53),
('2026-01-01', 2, '2023-Q2', 1563935, 79, 4, 2, 1, 11688.42),
('2026-01-01', 2, '2023-Q3', 1287443, 65, 4, 1, 1, 6896.01),
('2026-01-01', 2, '2023-Q4', 1636743, 82, 5, 2, 1, 6950.85),
('2026-01-01', 2, '2024-Q1', 1610511, 82, 4, 2, 1, 9110.4),
('2026-01-01', 2, NULL, 1928656, 98, 5, 3, 1, 13850.0),
('2026-01-01', 2, '2024-Q3', 2128465, 108, 6, 3, 1, 9811.17),
('2026-01-01', 2, '2024-Q4', 2214101, 114, 6, 2, 1, 6731.82),
('2026-01-01', 3, '2022-Q1', 1026419, 44, 8, 4, 1, 19438.96),
('2026-01-01', 3, '2022-Q2', 914962, 39, 5, 4, 2, 12124.27),
('2026-01-01', 3, '2022-Q3', 1026938, 45, 8, 2, 2, 15312.59),
('2026-01-01', 3, '2022-Q4', 1094257, 47, 8, 3, 2, 20193.29),
('2026-01-01', 3, '2023-Q1', 1098169, 49, 8, 3, 1, 19876.1),
('2026-01-01', 3, '2023-Q2', 1581821, 67, 12, 6, 2, 26687.79),
('2026-01-01', 3, '2023-Q3', 1534056, 69, 10, 4, 2, 17885.94),
('2026-01-01', 3, '2023-Q4', 1422649, 61, 11, 4, 3, 18169.06),
('2026-01-01', 3, '2024-Q1', 1415990, 64, 8, 4, 2, 17862.87),
('2026-01-01', 3, '2024-Q2', 1541251, 68, 10, 4, 3, 28639.7),
('2026-01-01', 3, '2024-Q3', 1947242, 91, 10, 5, 2, 25704.36),
('2026-01-01', 3, '2024-Q4', 1604394, 72, 11, 4, 2, 26364.81),
('2026-01-01', 4, '2022-Q1', 2197097, 61, 1, 0, 0, 1710.88),
('2026-01-01', 4, '2022-Q2', 2029884, 56, 1, 0, 0, 2917.62),
('2026-01-01', 4, '2022-Q3', 2248252, 63, 1, 0, 0, 2965.42),
('2026-01-01', 4, '2022-Q4', 2572891, 72, 1, 0, 0, 3286.7),
('2026-01-01', 4, '2023-Q1', 2770736, 77, 2, 0, 0, 4094.9),
('2026-01-01', 4, '2023-Q2', 3249371, 90, 1, 1, 0, 1876.21),
('2026-01-01', 4, '2023-Q3', 4252411, 118, 2, 1, 0, 2720.17),
('2026-01-01', 4, '2023-Q4', 4485370, 124, 3, 1, 0, 5390.1),
('2026-01-01', 4, '2024-Q1', 3751214, 106, 1, 0, 0, 3429.55),
('2026-01-01', 4, '2024-Q2', 5151526, 144, 2, 1, 0, 5047.0),
('2026-01-01', 4, '2024-Q3', 5651626, 156, 4, 1, 0, 7958.94),
('2026-01-01', 4, '2024-Q4', 5894877, 164, 3, 1, 0, 6827.59),
('2026-01-01', 5, '2022-Q1', 2089843, 58, 1, 0, 0, 1798.14),
('2026-01-01', 5, '2022-Q2', 2620040, 73, 1, 0, 0, 2706.16);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-01-01', 5, '2022-Q3', 3239396, 89, 2, 1, 0, 2528.03),
('2026-01-01', 5, '2022-Q4', 2701553, 75, 2, 0, 0, 1569.89),
('2026-01-01', 5, '2023-Q1', 3360811, 95, 1, 0, 0, 4701.85),
('2026-01-01', 5, '2023-Q2', 3339579, 93, 2, 0, 0, 2732.58),
('2026-01-01', 5, '2023-Q3', 3597661, 101, 1, 0, 0, 2232.84),
('2026-01-01', 5, '2023-Q4', 3565499, 99, 2, 0, 0, 4394.76),
('2026-01-01', 5, '2024-Q1', 4612445, 127, 3, 1, 0, 3729.11),
('2026-01-01', 5, '2024-Q2', 4396950, 123, 1, 1, 0, 5707.07),
('2026-01-01', 5, '2024-Q3', 5178860, 143, 3, 1, 0, 6429.88),
('2026-01-01', 5, '2024-Q4', 5443014, 153, 2, 0, 0, 8136.92),
('2026-01-01', 6, '2022-Q1', 2258720, 59, 4, 1, 0, 6806.57),
('2026-01-01', 6, '2022-Q2', 2088205, 53, 4, 1, 1, 14704.69),
('2026-01-01', 6, '2022-Q3', 2521124, 66, 4, 1, 1, 10252.29),
('2026-01-01', 6, '2022-Q4', 3540018, 94, 4, 2, 1, 14605.59),
('2026-01-01', 6, '2023-Q1', 2710556, 72, 3, 2, 0, 7321.22),
('2026-01-01', 6, '2023-Q2', 4120324, 108, 5, 3, 1, 22260.76),
('2026-01-01', 6, '2023-Q3', 4393684, 116, 6, 2, 1, 30000.67),
('2026-01-01', 6, '2023-Q4', 4446048, 116, 8, 2, 1, 32244.04),
('2026-01-01', 6, '2024-Q1', 4816904, 127, 5, 4, 1, 12250.07),
('2026-01-01', 6, '2024-Q2', 4255997, 109, 7, 4, 1, 24768.28),
('2026-01-01', 6, '2024-Q3', 5022314, 129, 9, 3, 2, 24929.2),
('2026-01-01', 6, '2024-Q4', 4567583, 121, 5, 3, 1, 21786.84),
('2026-01-01', 7, '2022-Q1', 7288413, 26, 0, 0, 0, 6597.88),
('2026-01-01', 7, '2022-Q2', 8193909, 29, 0, 0, 0, 7316.98),
('2026-01-01', 7, '2022-Q3', 7207933, 25, 0, 0, 0, 7301.01),
('2026-01-01', 7, '2022-Q4', 10674181, 38, 0, 0, 0, 9416.17),
('2026-01-01', 7, '2023-Q1', 8382835, 29, 0, 0, 0, 6862.94),
('2026-01-01', 7, '2023-Q2', 12129754, 42, 1, 0, 0, 15567.0),
('2026-01-01', 7, '2023-Q3', 11295621, 40, 0, 0, 0, 9557.12),
('2026-01-01', 7, '2023-Q4', 10139620, 35, 1, 0, 0, 13955.96),
('2026-01-01', 7, '2024-Q1', 13614208, 47, 1, 0, 0, 17692.14),
('2026-01-01', 7, '2024-Q2', 11827297, 42, 0, 0, 0, 9209.77),
('2026-01-01', 7, '2024-Q3', 16789248, 58, 1, 0, 0, 11304.57),
('2026-01-01', 7, '2024-Q4', 17963910, 63, 1, 0, 0, 20315.51),
('2026-01-01', 8, '2022-Q1', 7416557, 26, 0, 0, 0, 4819.25),
('2026-01-01', 8, '2022-Q2', 8557206, 30, 0, 0, 0, 9835.42),
('2026-01-01', 8, '2022-Q3', 7239291, 25, 0, 0, 0, 7514.62),
('2026-01-01', 8, '2022-Q4', 7726972, 27, 0, 0, 0, 9244.99),
('2026-01-01', 8, '2023-Q1', 8383506, 29, 0, 0, 0, 8238.02),
('2026-01-01', 8, '2023-Q2', 10553173, 37, 0, 0, 0, 11939.54),
('2026-01-01', 8, '2023-Q3', 9395189, 33, 0, 0, 0, 4856.75),
('2026-01-01', 8, '2023-Q4', 10139938, 36, 0, 0, 0, 7220.07),
('2026-01-01', 8, '2024-Q1', 11454418, 40, 0, 0, 0, 11447.7),
('2026-01-01', 8, '2024-Q2', 11691048, 41, 0, 0, 0, 13168.73),
('2026-01-01', 8, '2024-Q3', 15939975, 55, 1, 0, 0, 8283.45),
('2026-01-01', 8, '2024-Q4', 12798650, 45, 0, 0, 0, 13886.75),
('2026-01-01', 9, '2022-Q1', 6976248, 23, 1, 0, 0, 35271.81),
('2026-01-01', 9, '2022-Q2', 7904762, 26, 2, 0, 0, 27318.56),
('2026-01-01', 9, '2022-Q3', 9325144, 31, 2, 0, 0, 28795.8),
('2026-01-01', 9, '2022-Q4', 9962339, 34, 1, 0, 0, 55086.14);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-01-01', 9, '2023-Q1', 8122403, 27, 1, 1, 0, 60287.41),
('2026-01-01', 9, '2023-Q2', 8878674, 30, 1, 0, 0, 37703.25),
('2026-01-01', 9, '2023-Q3', 10368063, 35, 2, 0, 0, 54437.39),
('2026-01-01', 9, '2023-Q4', 12260828, 39, 3, 1, 0, 38246.35),
('2026-01-01', 9, '2024-Q1', 11138010, 37, 1, 1, 0, 63909.41),
('2026-01-01', 9, '2024-Q2', 13234436, 44, 2, 1, 0, 50774.36),
('2026-01-01', 9, '2024-Q3', 15351530, 50, 3, 1, 0, 85588.01),
('2026-01-01', 9, '2024-Q4', 14571284, 49, 2, 1, 0, 100838.54),
('2026-01-01', 10, '2022-Q1', 411135, 75, 4, 2, 1, 1198.48),
('2026-01-01', 10, '2022-Q2', 472518, 84, 6, 3, 1, 1413.5),
('2026-01-01', 10, '2022-Q3', 502407, 89, 7, 3, 1, 2901.57),
('2026-01-01', 10, '2022-Q4', 523430, 94, 6, 3, 1, 3316.27),
('2026-01-01', 10, '2023-Q1', 425884, 79, 5, 1, 0, 1509.47),
('2026-01-01', 10, '2023-Q2', 562936, 102, 7, 2, 1, 2303.57),
('2026-01-01', 10, '2023-Q3', 597690, 109, 7, 2, 1, 2137.91),
('2026-01-01', 10, '2023-Q4', 513376, 95, 4, 2, 1, 1684.23),
('2026-01-01', 10, '2024-Q1', 758935, 135, 10, 4, 2, 3181.39),
('2026-01-01', 10, '2024-Q2', 766725, 143, 6, 2, 2, 4003.93),
('2026-01-01', 10, '2024-Q3', 620769, 114, 6, 3, 1, 1939.91),
('2026-01-01', 10, '2024-Q4', 672409, 123, 7, 3, 1, 3378.33),
('2026-01-01', 11, '2022-Q1', 362451, 71, 1, 0, 0, 261.22),
('2026-01-01', 11, '2022-Q2', 420857, 82, 1, 1, 0, 586.2),
('2026-01-01', 11, '2022-Q3', 355855, 70, 1, 0, 0, 378.4),
('2026-01-01', 11, '2022-Q4', 397741, 78, 1, 0, 0, 251.49),
('2026-01-01', 11, '2023-Q1', 428545, 83, 2, 0, 0, 339.47),
('2026-01-01', 11, '2023-Q2', 583653, 113, 2, 1, 0, 383.08),
('2026-01-01', 11, '2023-Q3', 663104, 129, 2, 1, 0, 815.38),
('2026-01-01', 11, '2023-Q4', 720946, 141, 2, 1, 0, 716.53),
('2026-01-01', 11, '2024-Q1', 566057, 111, 2, 0, 0, 470.02),
('2026-01-01', 11, '2024-Q2', 766178, 150, 2, 1, 0, 894.48),
('2026-01-01', 11, '2024-Q3', 848160, 164, 4, 1, 0, 873.27),
('2026-01-01', 11, '2024-Q4', 743365, 145, 2, 1, 0, 534.65),
('2026-01-01', 12, '2022-Q1', 417394, 65, 11, 5, 2, 5291.67),
('2026-01-01', 12, '2022-Q2', 429758, 68, 8, 5, 4, 4496.42),
('2026-01-01', 12, '2022-Q3', 520999, 82, 14, 5, 3, 6800.74),
('2026-01-01', 12, '2022-Q4', 531313, 84, 11, 7, 4, 4984.58),
('2026-01-01', 12, '2023-Q1', 495848, 77, 14, 5, 3, 5718.94),
('2026-01-01', 12, '2023-Q2', 639770, 102, 14, 8, 3, 8687.72),
('2026-01-01', 12, '2023-Q3', 607914, 100, 11, 7, 3, 10198.58),
('2026-01-01', 12, '2023-Q4', 657396, 106, 15, 6, 4, 14505.25),
('2026-01-01', 12, '2024-Q1', 797734, 135, 13, 7, 4, 12149.06),
('2026-01-01', 12, '2024-Q2', 813826, 133, 20, 6, 3, 12592.77),
('2026-01-01', 12, '2024-Q3', 899723, 148, 14, 11, 6, 8256.64),
('2026-01-01', 12, '2024-Q4', 936396, 151, 24, 8, 4, 20312.21),
('2026-02-01', 1, '2022-Q1', 740405, 41, 0, 0, 0, 574.03),
('2026-02-01', 1, '2022-Q2', 0, 0, 1, 0, 0, 961.66),
('2026-02-01', 1, '2022-Q3', 1105107, 60, 1, 0, 0, 1618.87),
('2026-02-01', 1, '2022-Q4', 1021686, 55, 1, 0, 0, 782.62),
('2026-02-01', 1, '2023-Q1', 1511796, 81, 1, 1, 0, 1801.1),
('2026-02-01', 1, '2023-Q2', 1285872, 70, 1, 0, 0, 1891.03);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-02-01', 1, '2023-Q3', 1414043, 76, 2, 0, 0, 1365.1),
('2026-02-01', 1, '2023-Q4', 1841226, 100, 2, 0, 0, 1106.66),
('2026-02-01', 1, '2024-Q1', 1885842, 102, 2, 0, 0, 1228.88),
('2026-02-01', 1, '2024-Q2', 1529067, 82, 2, 0, 0, 2186.28),
('2026-02-01', 1, '2024-Q3', 2149459, 117, 1, 1, 0, 2251.7),
('2026-02-01', 1, '2024-Q4', 2272125, 124, 2, 0, 0, 3081.5),
('2026-02-01', 2, '2022-Q1', 1026464, 52, 4, 1, 0, 3930.55),
('2026-02-01', 2, '2022-Q2', 910010, 46, 3, 1, 0, 6153.49),
('2026-02-01', 2, '2022-Q3', 1213449, 61, 3, 2, 1, 5988.01),
('2026-02-01', 2, '2022-Q4', 0, 0, 3, 1, 0, 3047.52),
('2026-02-01', 2, '2023-Q1', 1422735, 74, 3, 1, 1, 6532.55),
('2026-02-01', 2, '2023-Q2', 1286187, 64, 4, 2, 1, 6296.35),
('2026-02-01', 2, '2023-Q3', 1798678, 89, 6, 3, 1, 13397.31),
('2026-02-01', 2, '2023-Q4', 1747793, 89, 6, 1, 1, 12465.23),
('2026-02-01', 2, '2024-Q1', 1855811, 94, 5, 3, 1, 10342.24),
('2026-02-01', 2, '2024-Q2', 1627909, 84, 3, 3, 0, 5189.15),
('2026-02-01', 2, '2024-Q3', 1565418, 79, 4, 2, 1, 11691.91),
('2026-02-01', 2, '2024-Q4', 1860583, 97, 4, 2, 0, 5761.21),
('2026-02-01', 3, '2022-Q1', 776119, 28, 8, 5, 2, 18961.28),
('2026-02-01', 3, '2022-Q2', 931128, 31, 12, 5, 3, 11558.37),
('2026-02-01', 3, '2022-Q3', 986903, 37, 11, 4, 2, 19390.42),
('2026-02-01', 3, '2022-Q4', 1105073, 43, 9, 7, 2, 34388.47),
('2026-02-01', 3, '2023-Q1', 1047277, 42, 9, 4, 3, 12325.18),
('2026-02-01', 3, '2023-Q2', 1161645, 41, 13, 7, 3, 27872.12),
('2026-02-01', 3, '2023-Q3', 1232444, 48, 9, 8, 3, 39474.55),
('2026-02-01', 3, '2023-Q4', 1288836, 47, 14, 6, 4, 21109.56),
('2026-02-01', 3, '2024-Q1', 1837735, 70, 15, 11, 6, 44243.99),
('2026-02-01', 3, '2024-Q2', 1702750, 69, 11, 10, 4, 37695.28),
('2026-02-01', 3, '2024-Q3', 1928710, 79, 14, 10, 4, 33891.08),
('2026-02-01', 3, '2024-Q4', 2077981, 81, 17, 12, 5, 55467.81),
('2026-02-01', 4, '2022-Q1', 2461558, 68, 2, 0, 0, 2238.78),
('2026-02-01', 4, '2022-Q2', 0, 0, 2, 0, 0, 3489.43),
('2026-02-01', 4, '2022-Q3', 0, 0, 1, 0, 0, 4446.32),
('2026-02-01', 4, '2022-Q4', 0, 0, 2, 1, 0, 4270.1),
('2026-02-01', 4, '2023-Q1', 3589210, 99, 2, 1, 0, 3346.33),
('2026-02-01', 4, '2023-Q2', 3215500, 89, 2, 0, 0, 4389.55),
('2026-02-01', 4, '2023-Q3', 3130940, 88, 1, 0, 0, 1835.3),
('2026-02-01', 4, '2023-Q4', 4054563, 112, 2, 1, 0, 2967.88),
('2026-02-01', 4, '2024-Q1', 4932792, 137, 2, 1, 0, 5018.8),
('2026-02-01', 4, '2024-Q2', 5130915, 143, 2, 1, 0, 4646.97),
('2026-02-01', 4, '2024-Q3', 4910993, 137, 2, 1, 0, 6038.62),
('2026-02-01', 4, '2024-Q4', 4274009, 119, 2, 1, 0, 4151.64),
('2026-02-01', 5, '2022-Q1', 1962752, 55, 1, 0, 0, 1956.68),
('2026-02-01', 5, '2022-Q2', 2491699, 70, 1, 0, 0, 3591.82),
('2026-02-01', 5, '2022-Q3', 3117713, 87, 2, 0, 0, 3446.05),
('2026-02-01', 5, '2022-Q4', 3506752, 97, 3, 0, 0, 4483.43),
('2026-02-01', 5, '2023-Q1', 3876701, 106, 3, 1, 0, 4639.31),
('2026-02-01', 5, '2023-Q2', 3311147, 91, 2, 1, 0, 2551.51),
('2026-02-01', 5, '2023-Q3', 3413312, 94, 2, 1, 0, 4131.7),
('2026-02-01', 5, '2023-Q4', 3216553, 90, 1, 0, 0, 3101.0);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-02-01', 5, '2024-Q1', 4039072, 113, 2, 0, 0, 3261.29),
('2026-02-01', 5, '2024-Q2', 4488293, 125, 2, 1, 0, 3960.46),
('2026-02-01', 5, '2024-Q3', 4510551, 124, 3, 1, 0, 2576.36),
('2026-02-01', 5, '2024-Q4', 5532710, 154, 3, 1, 0, 6851.25),
('2026-02-01', 6, '2022-Q1', 0, 0, 3, 2, 0, 9736.87),
('2026-02-01', 6, '2022-Q2', 2350692, 61, 3, 2, 1, 11697.13),
('2026-02-01', 6, '2022-Q3', 2786358, 72, 4, 2, 1, 7381.54),
('2026-02-01', 6, '2022-Q4', 3100629, 79, 6, 2, 1, 21654.16),
('2026-02-01', 6, '2023-Q1', 3705793, 96, 5, 3, 1, 25562.42),
('2026-02-01', 6, '2023-Q2', 3032873, 78, 6, 1, 1, 15995.75),
('2026-02-01', 6, '2023-Q3', 4097868, 106, 7, 3, 1, 28340.46),
('2026-02-01', 6, '2023-Q4', 3697370, 96, 6, 2, 1, 9866.0),
('2026-02-01', 6, '2024-Q1', 4373252, 113, 7, 3, 1, 15105.96),
('2026-02-01', 6, '2024-Q2', 3870936, 101, 6, 2, 1, 21042.16),
('2026-02-01', 6, '2024-Q3', 5470457, 147, 6, 2, 1, 40012.84),
('2026-02-01', 6, '2024-Q4', 5188303, 135, 8, 4, 1, 28470.99),
('2026-02-01', 7, '2022-Q1', 0, 0, 0, 0, 0, 6420.49),
('2026-02-01', 7, '2022-Q2', 6634310, 23, 0, 0, 0, 7956.51),
('2026-02-01', 7, '2022-Q3', 8063263, 28, 0, 0, 0, 5795.56),
('2026-02-01', 7, '2022-Q4', 7667530, 27, 0, 0, 0, 4439.3),
('2026-02-01', 7, '2023-Q1', 11473090, 40, 0, 0, 0, 13895.31),
('2026-02-01', 7, '2023-Q2', 8981541, 32, 0, 0, 0, 11756.58),
('2026-02-01', 7, '2023-Q3', 11653404, 41, 0, 0, 0, 11464.04),
('2026-02-01', 7, '2023-Q4', 10579485, 37, 0, 0, 0, 12622.6),
('2026-02-01', 7, '2024-Q1', 10221722, 36, 0, 0, 0, 10286.66),
('2026-02-01', 7, '2024-Q2', 12133197, 42, 1, 0, 0, 9660.78),
('2026-02-01', 7, '2024-Q3', 11622071, 41, 0, 0, 0, 12548.51),
('2026-02-01', 7, '2024-Q4', 13349357, 46, 1, 0, 0, 7292.38),
('2026-02-01', 8, '2022-Q1', 6698237, 23, 0, 0, 0, 6717.33),
('2026-02-01', 8, '2022-Q2', 0, 0, 0, 0, 0, 9210.85),
('2026-02-01', 8, '2022-Q3', 0, 0, 0, 0, 0, 4571.92),
('2026-02-01', 8, '2022-Q4', 0, 0, 0, 0, 0, 11179.89),
('2026-02-01', 8, '2023-Q1', 9264234, 33, 0, 0, 0, 11797.78),
('2026-02-01', 8, '2023-Q2', 11896161, 42, 0, 0, 0, 13180.08),
('2026-02-01', 8, '2023-Q3', 13165615, 46, 1, 0, 0, 14757.25),
('2026-02-01', 8, '2023-Q4', 10576567, 37, 0, 0, 0, 10035.25),
('2026-02-01', 8, '2024-Q1', 11560055, 40, 1, 0, 0, 10263.92),
('2026-02-01', 8, '2024-Q2', 15151808, 54, 0, 0, 0, 15299.54),
('2026-02-01', 8, '2024-Q3', 15052561, 53, 0, 0, 0, 15446.86),
('2026-02-01', 8, '2024-Q4', 13304898, 47, 0, 0, 0, 12898.04),
('2026-02-01', 9, '2022-Q1', 5680393, 19, 1, 0, 0, 29960.65),
('2026-02-01', 9, '2022-Q2', 8108847, 27, 1, 0, 0, 45457.61),
('2026-02-01', 9, '2022-Q3', 8861454, 29, 1, 1, 0, 59282.58),
('2026-02-01', 9, '2022-Q4', 7392421, 25, 1, 0, 0, 40509.94),
('2026-02-01', 9, '2023-Q1', 11562052, 37, 3, 1, 0, 42632.46),
('2026-02-01', 9, '2023-Q2', 12093393, 40, 2, 1, 0, 89894.6),
('2026-02-01', 9, '2023-Q3', 12838869, 41, 3, 1, 0, 88878.18),
('2026-02-01', 9, '2023-Q4', 11565721, 38, 2, 1, 0, 44875.61),
('2026-02-01', 9, '2024-Q1', 10598887, 36, 1, 0, 0, 57434.23),
('2026-02-01', 9, '2024-Q2', 14093440, 46, 3, 1, 0, 42842.65);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-02-01', 9, '2024-Q3', 13040347, 43, 2, 1, 0, 68831.86),
('2026-02-01', 9, '2024-Q4', 15231971, 51, 2, 1, 0, 98560.02),
('2026-02-01', 10, '2022-Q1', 0, 0, 3, 1, 0, 2180.04),
('2026-02-01', 10, '2022-Q2', 421637, 75, 6, 2, 1, 1792.68),
('2026-02-01', 10, '2022-Q3', 0, 0, 5, 2, 1, 3659.59),
('2026-02-01', 10, '2022-Q4', 0, 0, 6, 4, 1, 3023.11),
('2026-02-01', 10, '2023-Q1', 479695, 86, 6, 2, 1, 1512.14),
('2026-02-01', 10, '2023-Q2', 450837, 81, 5, 3, 1, 2430.52),
('2026-02-01', 10, '2023-Q3', 588929, 105, 8, 3, 1, 3031.12),
('2026-02-01', 10, '2023-Q4', 583138, 105, 6, 3, 2, 2643.55),
('2026-02-01', 10, '2024-Q1', 803954, 147, 9, 3, 1, 4835.57),
('2026-02-01', 10, '2024-Q2', 781222, 140, 10, 4, 2, 2680.6),
('2026-02-01', 10, '2024-Q3', 785878, 143, 9, 4, 1, 5201.5),
('2026-02-01', 10, '2024-Q4', 752776, 137, 9, 3, 1, 5010.44),
('2026-02-01', 11, '2022-Q1', 0, 0, 1, 0, 0, 370.56),
('2026-02-01', 11, '2022-Q2', 420944, 81, 2, 1, 0, 537.01),
('2026-02-01', 11, '2022-Q3', 461011, 89, 3, 0, 0, 457.41),
('2026-02-01', 11, '2022-Q4', 0, 0, 1, 0, 0, 574.98),
('2026-02-01', 11, '2023-Q1', 609983, 118, 2, 1, 0, 469.34),
('2026-02-01', 11, '2023-Q2', 593644, 115, 2, 1, 0, 828.13),
('2026-02-01', 11, '2023-Q3', 644254, 125, 2, 1, 0, 898.94),
('2026-02-01', 11, '2023-Q4', 522195, 103, 1, 0, 0, 519.47),
('2026-02-01', 11, '2024-Q1', 650270, 128, 2, 0, 0, 360.66),
('2026-02-01', 11, '2024-Q2', 643004, 124, 3, 1, 0, 898.01),
('2026-02-01', 11, '2024-Q3', 650713, 126, 3, 1, 0, 765.33),
('2026-02-01', 11, '2024-Q4', 659738, 128, 2, 1, 0, 787.74),
('2026-02-01', 12, '2022-Q1', 372261, 49, 15, 7, 3, 10541.24),
('2026-02-01', 12, '2022-Q2', 0, 0, 13, 8, 5, 6803.49),
('2026-02-01', 12, '2022-Q3', 446004, 58, 17, 10, 4, 13276.05),
('2026-02-01', 12, '2022-Q4', 450489, 61, 13, 11, 5, 6783.42),
('2026-02-01', 12, '2023-Q1', 432035, 58, 17, 6, 5, 8232.53),
('2026-02-01', 12, '2023-Q2', 612914, 83, 24, 10, 5, 19997.74),
('2026-02-01', 12, '2023-Q3', 546225, 80, 15, 9, 5, 17330.81),
('2026-02-01', 12, '2023-Q4', 699878, 99, 24, 10, 6, 17561.89),
('2026-02-01', 12, '2024-Q1', 738967, 102, 21, 15, 9, 12071.06),
('2026-02-01', 12, '2024-Q2', 611267, 86, 19, 11, 6, 17989.21),
('2026-02-01', 12, '2024-Q3', 753483, 104, 28, 11, 7, 19743.25),
('2026-02-01', 12, NULL, 641260, 93, 18, 13, 4, 8604.42),
('2026-03-01', 1, '2022-Q1', 788488, 42, 1, 0, 0, 547.55),
('2026-03-01', 1, '2022-Q2', 831759, 45, 1, 0, 0, 884.11),
('2026-03-01', 1, '2022-Q3', 946248, 51, 1, 0, 0, 576.92),
('2026-03-01', 1, '2022-Q4', 1064279, 58, 1, 0, 0, 634.51),
('2026-03-01', 1, '2023-Q1', 1052498, 57, 1, 0, 0, 600.79),
('2026-03-01', 1, '2023-Q2', 1241195, 66, 2, 0, 0, 670.25),
('2026-03-01', 1, '2023-Q3', 1753083, 96, 1, 0, 0, 2328.6),
('2026-03-01', 1, '2023-Q4', 1471021, 80, 1, 0, 0, 998.06),
('2026-03-01', 1, '2024-Q1', 1983305, 107, 2, 1, 0, 2268.22),
('2026-03-01', 1, '2024-Q2', 2144607, 116, 2, 1, 0, 2225.19),
('2026-03-01', 1, '2024-Q3', 1976155, 108, 1, 0, 0, 2230.22),
('2026-03-01', 1, '2024-Q4', 2165020, 118, 2, 0, 0, 1893.99);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-03-01', 2, '2022-Q1', 1000382, 51, 3, 1, 0, 4855.42),
('2026-03-01', 2, '2022-Q2', 1098230, 55, 3, 2, 1, 9498.89),
('2026-03-01', 2, '2022-Q3', 988027, 50, 3, 1, 0, 4651.48),
('2026-03-01', 2, '2022-Q4', 1347700, 65, 6, 2, 1, 6899.31),
('2026-03-01', 2, '2023-Q1', 1281064, 64, 4, 2, 1, 7104.62),
('2026-03-01', 2, '2023-Q2', 1569729, 78, 6, 2, 1, 7918.92),
('2026-03-01', 2, '2023-Q3', 1306533, 64, 4, 3, 1, 6427.95),
('2026-03-01', 2, '2023-Q4', 1768260, 90, 5, 2, 1, 15110.71),
('2026-03-01', 2, '2024-Q1', 2025165, 101, 6, 4, 1, 13297.17),
('2026-03-01', 2, '2024-Q2', 1686622, 85, 4, 3, 1, 8383.63),
('2026-03-01', 2, '2024-Q3', 2086990, 103, 8, 3, 1, 10257.46),
('2026-03-01', 2, '2024-Q4', 2234749, 110, 8, 4, 2, 9142.36),
('2026-03-01', 3, '2022-Q1', 1048613, 37, 14, 4, 3, 29986.74),
('2026-03-01', 3, '2022-Q2', 1095072, 39, 12, 7, 2, 15022.97),
('2026-03-01', 3, '2022-Q3', 1115417, 37, 12, 8, 4, 27752.25),
('2026-03-01', 3, '2022-Q4', 989415, 37, 10, 5, 2, 17357.62),
('2026-03-01', 3, '2023-Q1', 1357228, 49, 16, 6, 4, 32028.36),
('2026-03-01', 3, '2023-Q2', 1538175, 54, 18, 8, 5, 40562.63),
('2026-03-01', 3, '2023-Q3', 1514525, 61, 11, 9, 3, 28364.83),
('2026-03-01', 3, '2023-Q4', 1864853, 72, 18, 9, 4, 22839.36),
('2026-03-01', 3, '2024-Q1', 1925886, 77, 14, 10, 5, 35687.96),
('2026-03-01', 3, '2024-Q2', 2047190, 82, 13, 12, 6, 31171.53),
('2026-03-01', 3, '2024-Q3', 2146242, 85, 18, 10, 6, 39114.42),
('2026-03-01', 3, '2024-Q4', 2171147, 94, 14, 8, 4, 27452.33),
('2026-03-01', 4, '2022-Q1', 1918016, 53, 1, 0, 0, 1127.39),
('2026-03-01', 4, '2022-Q2', 2346459, 66, 1, 0, 0, 1269.97),
('2026-03-01', 4, '2022-Q3', 2582831, 72, 1, 0, 0, 2034.68),
('2026-03-01', 4, '2022-Q4', 2607354, 72, 2, 0, 0, 3038.79),
('2026-03-01', 4, '2023-Q1', 3001954, 83, 2, 0, 0, 1768.48),
('2026-03-01', 4, '2023-Q2', 3234832, 90, 2, 0, 0, 3443.38),
('2026-03-01', 4, '2023-Q3', 3610942, 102, 1, 0, 0, 4198.92),
('2026-03-01', 4, '2023-Q4', 4420084, 122, 3, 1, 0, 4887.2),
('2026-03-01', 4, '2024-Q1', 3676156, 104, 1, 0, 0, 3186.45),
('2026-03-01', 4, '2024-Q2', 4393926, 122, 2, 1, 0, 3594.65),
('2026-03-01', 4, '2024-Q3', 5348560, 150, 2, 0, 0, 6290.88),
('2026-03-01', 4, '2024-Q4', 4455582, 126, 1, 0, 0, 4686.72),
('2026-03-01', 5, '2022-Q1', 2339289, 65, 1, 0, 0, 1767.75),
('2026-03-01', 5, '2022-Q2', 2756539, 75, 2, 1, 0, 3206.07),
('2026-03-01', 5, '2022-Q3', 2571011, 72, 1, 0, 0, 2078.35),
('2026-03-01', 5, '2022-Q4', 2636421, 74, 1, 0, 0, 2204.91),
('2026-03-01', 5, '2023-Q1', 3144554, 86, 2, 1, 0, 1865.22),
('2026-03-01', 5, '2023-Q2', 3649402, 101, 2, 1, 0, 4555.79),
('2026-03-01', 5, '2023-Q3', 3718275, 103, 3, 0, 0, 5428.06),
('2026-03-01', 5, '2023-Q4', 4545528, 127, 2, 0, 0, 5335.42),
('2026-03-01', 5, '2024-Q1', 4341226, 122, 2, 0, 0, 6480.89),
('2026-03-01', 5, '2024-Q2', 3925034, 110, 2, 0, 0, 4576.83),
('2026-03-01', 5, '2024-Q3', 5665102, 158, 2, 1, 0, 7047.32),
('2026-03-01', 5, '2024-Q4', 4407478, 123, 2, 0, 0, 4107.47),
('2026-03-01', 6, '2022-Q1', 2206487, 56, 5, 1, 1, 17259.67),
('2026-03-01', 6, '2022-Q2', 2356497, 60, 6, 1, 0, 20458.23);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-03-01', 6, '2022-Q3', 2993672, 76, 6, 2, 1, 25063.39),
('2026-03-01', 6, '2022-Q4', 2624959, 67, 4, 2, 1, 17586.63),
('2026-03-01', 6, '2023-Q1', 3377923, 85, 7, 2, 2, 12907.87),
('2026-03-01', 6, '2023-Q2', 3515178, 91, 5, 3, 1, 13550.61),
('2026-03-01', 6, '2023-Q3', 4360602, 111, 6, 5, 2, 19321.06),
('2026-03-01', 6, '2023-Q4', 3741271, 93, 7, 4, 2, 21758.32),
('2026-03-01', 6, '2024-Q1', 4768281, 123, 7, 4, 2, 22003.9),
('2026-03-01', 6, '2024-Q2', 3708448, 96, 6, 2, 1, 30487.36),
('2026-03-01', 6, '2024-Q3', 4823826, 126, 6, 3, 2, 29770.09),
('2026-03-01', 6, '2024-Q4', 4936443, 131, 6, 3, 1, 31818.29),
('2026-03-01', 7, '2022-Q1', 6227133, 22, 0, 0, 0, 6345.37),
('2026-03-01', 7, '2022-Q2', 6597420, 23, 0, 0, 0, 3877.85),
('2026-03-01', 7, '2022-Q3', 8797220, 31, 0, 0, 0, 6297.48),
('2026-03-01', 7, '2022-Q4', 7375379, 26, 0, 0, 0, 9248.83),
('2026-03-01', 7, '2023-Q1', 9343309, 33, 0, 0, 0, 9478.7),
('2026-03-01', 7, '2023-Q2', 10252954, 36, 0, 0, 0, 13261.44),
('2026-03-01', 7, '2023-Q3', 10361914, 37, 0, 0, 0, 13694.75),
('2026-03-01', 7, '2023-Q4', 10856712, 38, 0, 0, 0, 6003.42),
('2026-03-01', 7, '2024-Q1', 11368173, 40, 0, 0, 0, 16939.13),
('2026-03-01', 7, '2024-Q2', 12792243, 45, 0, 0, 0, 10840.12),
('2026-03-01', 7, '2024-Q3', 15875684, 55, 1, 0, 0, 22999.65),
('2026-03-01', 7, '2024-Q4', 15213857, 53, 1, 0, 0, 7666.29),
('2026-03-01', 8, '2022-Q1', 5909415, 21, 0, 0, 0, 4992.3),
('2026-03-01', 8, '2022-Q2', 7778091, 27, 0, 0, 0, 4000.39),
('2026-03-01', 8, '2022-Q3', 6934360, 24, 0, 0, 0, 4153.55),
('2026-03-01', 8, '2022-Q4', 8389633, 29, 0, 0, 0, 5684.33),
('2026-03-01', 8, '2023-Q1', 9390934, 33, 0, 0, 0, 13644.71),
('2026-03-01', 8, '2023-Q2', 10155587, 36, 0, 0, 0, 7397.19),
('2026-03-01', 8, '2023-Q3', 9490737, 33, 0, 0, 0, 11948.68),
('2026-03-01', 8, '2023-Q4', 13889511, 48, 1, 0, 0, 20757.71),
('2026-03-01', 8, '2024-Q1', 10564521, 37, 0, 0, 0, 10763.61),
('2026-03-01', 8, '2024-Q2', 13638537, 47, 1, 0, 0, 7823.71),
('2026-03-01', 8, '2024-Q3', 14713642, 52, 0, 0, 0, 16963.47),
('2026-03-01', 8, '2024-Q4', 12063676, 42, 1, 0, 0, 10425.18),
('2026-03-01', 9, '2022-Q1', 5633360, 19, 1, 0, 0, 35619.03),
('2026-03-01', 9, '2022-Q2', 8086749, 25, 2, 1, 0, 50639.85),
('2026-03-01', 9, '2022-Q3', 6688157, 21, 1, 1, 0, 58013.16),
('2026-03-01', 9, '2022-Q4', 10060882, 32, 3, 0, 0, 86500.46),
('2026-03-01', 9, '2023-Q1', 9709303, 31, 2, 1, 0, 69014.57),
('2026-03-01', 9, '2023-Q2', 10991664, 35, 3, 1, 0, 67304.79),
('2026-03-01', 9, '2023-Q3', 9854632, 32, 2, 1, 0, 59878.43),
('2026-03-01', 9, '2023-Q4', 12195737, 40, 2, 1, 0, 71426.32),
('2026-03-01', 9, '2024-Q1', 11373374, 37, 2, 1, 0, 99607.58),
('2026-03-01', 9, '2024-Q2', 14875715, 49, 3, 1, 0, 132100.58),
('2026-03-01', 9, '2024-Q3', 16679194, 56, 2, 1, 0, 128128.65),
('2026-03-01', 9, '2024-Q4', 15010134, 49, 3, 1, 0, 122617.31),
('2026-03-01', 10, '2022-Q1', 340439, 60, 5, 2, 1, 1378.67),
('2026-03-01', 10, '2022-Q2', 417086, 74, 6, 2, 1, 1632.61),
('2026-03-01', 10, '2022-Q3', 442366, 78, 6, 3, 1, 3112.72),
('2026-03-01', 10, '2022-Q4', 387727, 69, 4, 3, 1, 1687.43);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-03-01', 10, '2023-Q1', 418890, 75, 4, 3, 1, 3508.57),
('2026-03-01', 10, '2023-Q2', 512932, 91, 8, 2, 1, 2910.96),
('2026-03-01', 10, '2023-Q3', 670614, 120, 8, 4, 2, 5209.82),
('2026-03-01', 10, '2023-Q4', 523953, 94, 5, 4, 1, 1799.06),
('2026-03-01', 10, '2024-Q1', 600595, 106, 8, 4, 2, 1953.87),
('2026-03-01', 10, '2024-Q2', 804884, 141, 10, 6, 3, 6036.71),
('2026-03-01', 10, '2024-Q3', 725060, 130, 9, 4, 2, 6426.53),
('2026-03-01', 10, '2024-Q4', 832972, 151, 11, 3, 1, 7408.45),
('2026-03-01', 11, '2022-Q1', 398796, 77, 2, 0, 0, 259.02),
('2026-03-01', 11, '2022-Q2', 412000, 80, 2, 0, 0, 273.31),
('2026-03-01', 11, '2022-Q3', 374161, 72, 2, 0, 0, 452.75),
('2026-03-01', 11, '2022-Q4', 489442, 94, 2, 1, 0, 620.12),
('2026-03-01', 11, '2023-Q1', 491022, 95, 2, 1, 0, 341.19),
('2026-03-01', 11, '2023-Q2', 510670, 99, 2, 1, 0, 380.83),
('2026-03-01', 11, '2023-Q3', 595141, 116, 2, 1, 0, 418.62),
('2026-03-01', 11, '2023-Q4', 661484, 128, 3, 1, 0, 489.79),
('2026-03-01', 11, '2024-Q1', 659215, 128, 3, 0, 0, 629.46),
('2026-03-01', 11, '2024-Q2', 795501, 155, 3, 1, 0, 1150.55),
('2026-03-01', 11, '2024-Q3', 668855, 129, 3, 1, 0, 406.26),
('2026-03-01', 11, '2024-Q4', 738418, 144, 2, 1, 0, 489.33),
('2026-03-01', 12, '2022-Q1', 366331, 45, 17, 8, 3, 7569.16),
('2026-03-01', 12, '2022-Q2', 424746, 52, 18, 8, 6, 14262.31),
('2026-03-01', 12, '2022-Q3', 364794, 47, 13, 8, 4, 12135.77),
('2026-03-01', 12, '2022-Q4', 409448, 58, 11, 9, 3, 7733.93),
('2026-03-01', 12, '2023-Q1', 516484, 73, 18, 7, 5, 16050.25),
('2026-03-01', 12, '2023-Q2', 596995, 76, 25, 11, 7, 18575.21),
('2026-03-01', 12, '2023-Q3', 639339, 86, 25, 12, 4, 17904.64),
('2026-03-01', 12, '2023-Q4', 669689, 91, 25, 11, 6, 11839.24),
('2026-03-01', 12, '2024-Q1', 795994, 115, 26, 11, 7, 14169.7),
('2026-03-01', 12, '2024-Q2', 804259, 105, 32, 16, 7, 26365.21),
('2026-03-01', 12, '2024-Q3', 893986, 136, 24, 11, 7, 17429.31),
('2026-03-01', 12, '2024-Q4', 913569, 124, 33, 17, 8, 17333.44),
('2026-04-01', 1, '2022-Q1', 757745, 42, 0, 0, 0, 493.81),
('2026-04-01', 1, '2022-Q2', 933245, 50, 1, 0, 0, 595.55),
('2026-04-01', 1, '2022-Q3', 975720, 53, 1, 0, 0, 756.94),
('2026-04-01', 1, '2022-Q4', 1061104, 57, 1, 0, 0, 1036.86),
('2026-04-01', 1, '2023-Q1', 1192462, 65, 1, 0, 0, 1482.56),
('2026-04-01', 1, '2023-Q2', 1263427, 69, 1, 0, 0, 1479.71),
('2026-04-01', 1, '2023-Q3', 1445783, 79, 1, 0, 0, 1355.44),
('2026-04-01', 1, '2023-Q4', 1701088, 91, 2, 1, 0, 900.65),
('2026-04-01', 1, '2024-Q1', 1495408, 81, 2, 0, 0, 1909.07),
('2026-04-01', 1, '2024-Q2', 1893638, 103, 2, 0, 0, 1986.61),
('2026-04-01', 1, '2024-Q3', 2038814, 111, 2, 0, 0, 1951.5),
('2026-04-01', 1, NULL, 1538007, 84, 1, 0, 0, 1131.85),
('2026-04-01', 1, NULL, 1639832, 89, 2, 0, 0, 1338.6),
('2026-04-01', 2, '2022-Q1', 883223, 44, 2, 2, 1, 4283.43),
('2026-04-01', 2, '2022-Q2', 731419, 36, 3, 1, 0, 2901.71),
('2026-04-01', 2, NULL, 821335, 40, 3, 1, 1, 5708.1),
('2026-04-01', 2, '2022-Q4', 1164102, 60, 3, 1, 0, 3900.41),
('2026-04-01', 2, '2023-Q1', 1042911, 51, 4, 1, 1, 5196.79);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-04-01', 2, '2023-Q2', 1469329, 74, 4, 2, 1, 9101.55),
('2026-04-01', 2, '2023-Q3', 1327753, 65, 5, 2, 1, 10539.58),
('2026-04-01', 2, '2023-Q4', 1202468, 61, 3, 2, 0, 6906.5),
('2026-04-01', 2, '2024-Q1', 1770783, 91, 4, 2, 1, 8311.14),
('2026-04-01', 2, '2024-Q2', 1967121, 97, 7, 4, 1, 8084.15),
('2026-04-01', 2, '2024-Q3', 1915111, 97, 5, 3, 1, 14365.76),
('2026-04-01', 2, '2024-Q4', 1730109, 87, 5, 3, 1, 15538.51),
('2026-04-01', 2, '2025-Q1', 1751585, 90, 4, 2, 1, 8711.34),
('2026-04-01', 3, '2022-Q1', 840275, 31, 9, 4, 2, 21635.53),
('2026-04-01', 3, '2022-Q2', 1071018, 36, 13, 7, 3, 25356.61),
('2026-04-01', 3, '2022-Q3', 1112869, 37, 12, 8, 4, 24036.5),
('2026-04-01', 3, '2022-Q4', 1096180, 37, 14, 5, 4, 26971.18),
('2026-04-01', 3, '2023-Q1', 1267541, 47, 13, 6, 4, 28445.93),
('2026-04-01', 3, '2023-Q2', 1462527, 54, 15, 9, 3, 20032.11),
('2026-04-01', 3, '2023-Q3', 1487822, 51, 17, 9, 5, 45448.06),
('2026-04-01', 3, NULL, 1591439, 65, 12, 7, 4, 29510.35),
('2026-04-01', 3, NULL, 1354565, 55, 12, 5, 3, 19067.98),
('2026-04-01', 3, '2024-Q2', 1927778, 73, 21, 8, 5, 26989.44),
('2026-04-01', 3, '2024-Q3', 1660402, 67, 16, 6, 3, 43627.2),
('2026-04-01', 3, '2024-Q4', 1950428, 80, 15, 8, 5, 40223.66),
('2026-04-01', 3, '2025-Q1', 1668160, 70, 12, 6, 4, 50535.93),
('2026-04-01', 4, '2022-Q1', 2295384, 64, 1, 0, 0, 3371.71),
('2026-04-01', 4, '2022-Q2', 2509960, 70, 1, 0, 0, 3425.89),
('2026-04-01', 4, '2022-Q3', 2971867, 82, 1, 1, 0, 3516.23),
('2026-04-01', 4, '2022-Q4', 2880415, 81, 1, 0, 0, 2243.05),
('2026-04-01', 4, '2023-Q1', 3479703, 97, 1, 1, 0, 5137.45),
('2026-04-01', 4, '2023-Q2', 2989383, 83, 2, 0, 0, 2474.53),
('2026-04-01', 4, '2023-Q3', 3186425, 90, 1, 0, 0, 3794.9),
('2026-04-01', 4, '2023-Q4', 4434406, 122, 3, 1, 0, 6194.78),
('2026-04-01', 4, '2024-Q1', 3220624, 90, 2, 0, 0, 2051.73),
('2026-04-01', 4, '2024-Q2', 3681685, 103, 2, 0, 0, 2538.71),
('2026-04-01', 4, '2024-Q3', 5296295, 147, 3, 1, 0, 5952.19),
('2026-04-01', 4, '2024-Q4', 5611879, 157, 2, 1, 0, 5736.18),
('2026-04-01', 4, '2025-Q1', 5504336, 154, 2, 1, 0, 5360.76),
('2026-04-01', 5, '2022-Q1', 2264414, 63, 1, 0, 0, 1211.79),
('2026-04-01', 5, '2022-Q2', 2479030, 68, 2, 0, 0, 1602.42),
('2026-04-01', 5, '2022-Q3', 2046920, 57, 1, 0, 0, 2813.61),
('2026-04-01', 5, '2022-Q4', 2916992, 81, 2, 0, 0, 4223.63),
('2026-04-01', 5, '2023-Q1', 3293981, 91, 2, 1, 0, 1772.03),
('2026-04-01', 5, '2023-Q2', 2722585, 75, 2, 0, 0, 1542.31),
('2026-04-01', 5, '2023-Q3', 3689626, 102, 2, 1, 0, 3184.79),
('2026-04-01', 5, '2023-Q4', 3660756, 102, 2, 0, 0, 3998.27),
('2026-04-01', 5, '2024-Q1', 3404303, 94, 2, 1, 0, 2114.13),
('2026-04-01', 5, NULL, 4091413, 113, 2, 1, 0, 4427.04),
('2026-04-01', 5, '2024-Q3', 3669253, 102, 2, 0, 0, 5306.47),
('2026-04-01', 5, '2024-Q4', 4205700, 118, 2, 0, 0, 3070.98),
('2026-04-01', 5, '2025-Q1', 5388017, 149, 3, 1, 0, 4985.77),
('2026-04-01', 6, NULL, 1749253, 44, 4, 1, 0, 11524.2),
('2026-04-01', 6, '2022-Q2', 2183394, 55, 3, 3, 1, 6671.53),
('2026-04-01', 6, '2022-Q3', 2814328, 72, 5, 2, 1, 16202.95);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-04-01', 6, '2022-Q4', 2374415, 60, 5, 1, 1, 9064.73),
('2026-04-01', 6, '2023-Q1', 3120122, 78, 6, 4, 1, 12019.04),
('2026-04-01', 6, '2023-Q2', 3836511, 97, 9, 2, 1, 18325.44),
('2026-04-01', 6, '2023-Q3', 3988002, 104, 5, 3, 1, 12254.75),
('2026-04-01', 6, '2023-Q4', 3563340, 92, 6, 2, 1, 29068.06),
('2026-04-01', 6, '2024-Q1', 4711057, 116, 11, 5, 2, 23916.88),
('2026-04-01', 6, '2024-Q2', 4133980, 107, 7, 3, 1, 36411.81),
('2026-04-01', 6, '2024-Q3', 5143329, 133, 8, 3, 2, 34001.72),
('2026-04-01', 6, '2024-Q4', 4611101, 118, 9, 3, 1, 37021.67),
('2026-04-01', 6, '2025-Q1', 4280041, 113, 5, 3, 1, 38433.81),
('2026-04-01', 7, '2022-Q1', 5306434, 18, 0, 0, 0, 6893.14),
('2026-04-01', 7, '2022-Q2', 7862608, 28, 0, 0, 0, 10068.35),
('2026-04-01', 7, '2022-Q3', 7485439, 26, 0, 0, 0, 9738.33),
('2026-04-01', 7, '2022-Q4', 8937051, 31, 0, 0, 0, 13290.51),
('2026-04-01', 7, '2023-Q1', 10353369, 36, 0, 0, 0, 5819.88),
('2026-04-01', 7, '2023-Q2', 11159680, 39, 0, 0, 0, 8920.99),
('2026-04-01', 7, '2023-Q3', 10036429, 35, 0, 0, 0, 11070.81),
('2026-04-01', 7, '2023-Q4', 13196363, 47, 0, 0, 0, 11510.24),
('2026-04-01', 7, '2024-Q1', 10156703, 35, 1, 0, 0, 8287.77),
('2026-04-01', 7, '2024-Q2', 10942480, 39, 0, 0, 0, 13293.67),
('2026-04-01', 7, '2024-Q3', 15939524, 55, 1, 0, 0, 16456.77),
('2026-04-01', 7, '2024-Q4', 15087759, 53, 0, 0, 0, 14788.07),
('2026-04-01', 7, '2025-Q1', 13225889, 47, 0, 0, 0, 10624.98),
('2026-04-01', 8, '2022-Q1', 4921511, 17, 0, 0, 0, 2836.82),
('2026-04-01', 8, NULL, 6382701, 22, 0, 0, 0, 5531.11),
('2026-04-01', 8, '2022-Q3', 8513385, 30, 0, 0, 0, 11558.12),
('2026-04-01', 8, '2022-Q4', 7162376, 25, 0, 0, 0, 8288.6),
('2026-04-01', 8, '2023-Q1', 8388177, 29, 0, 0, 0, 9978.9),
('2026-04-01', 8, NULL, 10088421, 36, 0, 0, 0, 15076.61),
('2026-04-01', 8, '2023-Q3', 8723270, 31, 0, 0, 0, 11299.78),
('2026-04-01', 8, NULL, 11449872, 40, 0, 0, 0, 12166.66),
('2026-04-01', 8, NULL, 12836566, 44, 1, 0, 0, 7655.19),
('2026-04-01', 8, '2024-Q2', 10856363, 38, 0, 0, 0, 8192.49),
('2026-04-01', 8, '2024-Q3', 12079746, 43, 0, 0, 0, 15148.31),
('2026-04-01', 8, '2024-Q4', 13835312, 49, 0, 0, 0, 9763.72),
('2026-04-01', 8, '2025-Q1', 12232368, 43, 0, 0, 0, 14026.08),
('2026-04-01', 9, '2022-Q1', 6693089, 21, 1, 1, 0, 32236.59),
('2026-04-01', 9, NULL, 7949189, 26, 1, 1, 0, 68236.85),
('2026-04-01', 9, '2022-Q3', 7310670, 23, 2, 1, 0, 25475.39),
('2026-04-01', 9, '2022-Q4', 8887434, 28, 2, 1, 0, 33407.81),
('2026-04-01', 9, '2023-Q1', 9876617, 33, 1, 1, 0, 42534.8),
('2026-04-01', 9, '2023-Q2', 8580829, 28, 2, 0, 0, 44996.79),
('2026-04-01', 9, '2023-Q3', 9480701, 31, 1, 1, 0, 75583.32),
('2026-04-01', 9, '2023-Q4', 12996207, 43, 2, 1, 0, 114240.64),
('2026-04-01', 9, '2024-Q1', 11759641, 38, 2, 1, 0, 77918.49),
('2026-04-01', 9, '2024-Q2', 14726743, 47, 3, 2, 0, 122765.27),
('2026-04-01', 9, '2024-Q3', 11189078, 35, 3, 1, 0, 96804.41),
('2026-04-01', 9, '2024-Q4', 13053912, 43, 2, 1, 0, 66301.55),
('2026-04-01', 9, NULL, 15857764, 53, 2, 1, 0, 121608.3),
('2026-04-01', 10, '2022-Q1', 261233, 47, 3, 2, 0, 2061.71);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-04-01', 10, '2022-Q2', 405288, 73, 4, 3, 1, 3324.29),
('2026-04-01', 10, '2022-Q3', 474509, 81, 8, 3, 2, 4055.84),
('2026-04-01', 10, '2022-Q4', 352753, 62, 4, 3, 1, 2855.68),
('2026-04-01', 10, '2023-Q1', 536211, 95, 9, 2, 1, 3759.93),
('2026-04-01', 10, '2023-Q2', 546935, 99, 5, 4, 1, 3258.51),
('2026-04-01', 10, '2023-Q3', 550463, 99, 6, 4, 1, 2953.77),
('2026-04-01', 10, '2023-Q4', 550781, 98, 9, 2, 1, 2680.2),
('2026-04-01', 10, '2024-Q1', 635714, 116, 6, 4, 1, 2189.21),
('2026-04-01', 10, '2024-Q2', 586661, 105, 6, 4, 2, 5007.32),
('2026-04-01', 10, '2024-Q3', 738123, 130, 9, 6, 2, 3796.24),
('2026-04-01', 10, '2024-Q4', 909550, 161, 14, 4, 2, 5736.31),
('2026-04-01', 10, '2025-Q1', 706123, 127, 7, 5, 2, 2150.51),
('2026-04-01', 11, '2022-Q1', 300543, 59, 1, 0, 0, 331.86),
('2026-04-01', 11, '2022-Q2', 410193, 80, 1, 1, 0, 520.38),
('2026-04-01', 11, '2022-Q3', 363469, 71, 1, 0, 0, 334.37),
('2026-04-01', 11, '2022-Q4', 502069, 97, 2, 1, 0, 492.01),
('2026-04-01', 11, '2023-Q1', 479024, 92, 3, 0, 0, 646.98),
('2026-04-01', 11, '2023-Q2', 585113, 114, 3, 0, 0, 835.48),
('2026-04-01', 11, '2023-Q3', 619650, 121, 2, 0, 0, 562.54),
('2026-04-01', 11, NULL, 651512, 126, 3, 1, 0, 693.91),
('2026-04-01', 11, '2024-Q1', 525256, 104, 1, 0, 0, 684.39),
('2026-04-01', 11, '2024-Q2', 778110, 151, 3, 1, 0, 707.66),
('2026-04-01', 11, '2024-Q3', 758542, 147, 3, 1, 0, 638.35),
('2026-04-01', 11, '2024-Q4', 750319, 146, 3, 1, 0, 955.51),
('2026-04-01', 11, '2025-Q1', 940771, 185, 2, 1, 0, 1299.69),
('2026-04-01', 12, '2022-Q1', 309711, 45, 10, 4, 2, 5743.33),
('2026-04-01', 12, NULL, 371301, 45, 17, 9, 3, 12131.26),
('2026-04-01', 12, '2022-Q3', 451889, 61, 13, 10, 6, 5699.25),
('2026-04-01', 12, '2022-Q4', 427180, 53, 19, 8, 5, 7543.84),
('2026-04-01', 12, NULL, 473426, 61, 20, 7, 6, 14086.96),
('2026-04-01', 12, '2023-Q2', 488623, 69, 14, 10, 4, 15021.04),
('2026-04-01', 12, '2023-Q3', 597795, 78, 26, 8, 7, 16000.12),
('2026-04-01', 12, '2023-Q4', 657510, 89, 22, 14, 6, 13233.27),
('2026-04-01', 12, '2024-Q1', 626699, 90, 17, 11, 7, 8850.43),
('2026-04-01', 12, '2024-Q2', 670112, 93, 26, 9, 6, 16305.13),
('2026-04-01', 12, '2024-Q3', 793596, 112, 24, 17, 5, 12422.59),
('2026-04-01', 12, NULL, 637293, 88, 20, 13, 6, 16846.96),
('2026-04-01', 12, '2025-Q1', 924715, 133, 26, 19, 6, 11965.28),
('2026-05-01', 1, '2022-Q1', 672766, 36, 1, 0, 0, 351.93),
('2026-05-01', 1, '2022-Q2', 1024853, 55, 1, 0, 0, 775.15),
('2026-05-01', 1, '2022-Q3', 857338, 46, 1, 0, 0, 993.54),
('2026-05-01', 1, '2022-Q4', 1100264, 60, 1, 0, 0, 1147.55),
('2026-05-01', 1, '2023-Q1', 1182900, 64, 1, 0, 0, 1001.93),
('2026-05-01', 1, '2023-Q2', 1287457, 70, 1, 0, 0, 1295.36),
('2026-05-01', 1, '2023-Q3', 1380733, 75, 1, 0, 0, 1245.02),
('2026-05-01', 1, '2023-Q4', 1666158, 90, 1, 1, 0, 954.41),
('2026-05-01', 1, '2024-Q1', 1644493, 89, 2, 0, 0, 1938.71),
('2026-05-01', 1, '2024-Q2', 1500150, 82, 1, 0, 0, 1564.07),
('2026-05-01', 1, '2024-Q3', 1765983, 96, 2, 0, 0, 1813.23),
('2026-05-01', 1, '2024-Q4', 1710975, 94, 1, 0, 0, 1808.0);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-05-01', 1, '2025-Q1', 2077231, 113, 2, 0, 0, 2628.64),
('2026-05-01', 2, '2022-Q1', 941076, 49, 2, 1, 0, 3357.12),
('2026-05-01', 2, NULL, 1021201, 50, 4, 2, 0, 5655.25),
('2026-05-01', 2, '2022-Q3', 1134896, 55, 5, 2, 1, 3633.35),
('2026-05-01', 2, '2022-Q4', 926203, 48, 2, 1, 0, 5112.76),
('2026-05-01', 2, '2023-Q1', 1097639, 57, 2, 1, 0, 6568.5),
('2026-05-01', 2, '2023-Q2', 1078619, 53, 4, 1, 1, 5925.52),
('2026-05-01', 2, '2023-Q3', 1538608, 77, 5, 3, 0, 4763.83),
('2026-05-01', 2, '2023-Q4', 1395811, 70, 4, 2, 1, 10204.58),
('2026-05-01', 2, '2024-Q1', 1465035, 74, 5, 1, 1, 6661.75),
('2026-05-01', 2, '2024-Q2', 1404451, 72, 5, 1, 0, 7192.78),
('2026-05-01', 2, '2024-Q3', 2125750, 107, 7, 3, 1, 10616.2),
('2026-05-01', 2, '2024-Q4', 1924171, 98, 5, 2, 1, 12386.03),
('2026-05-01', 2, '2025-Q1', 1993956, 103, 4, 2, 1, 7095.48),
('2026-05-01', 3, '2022-Q1', 932906, 41, 5, 4, 1, 18196.36),
('2026-05-01', 3, '2022-Q2', 888055, 40, 4, 3, 2, 15740.19),
('2026-05-01', 3, '2022-Q3', 977261, 44, 5, 3, 2, 8428.92),
('2026-05-01', 3, '2022-Q4', 1281985, 59, 6, 4, 2, 11097.44),
('2026-05-01', 3, '2023-Q1', 1069811, 46, 9, 2, 2, 22218.03),
('2026-05-01', 3, '2023-Q2', 1440818, 63, 11, 4, 2, 18973.46),
('2026-05-01', 3, '2023-Q3', 1295399, 55, 9, 5, 2, 27626.48),
('2026-05-01', 3, '2023-Q4', 1508025, 65, 9, 6, 3, 17870.21),
('2026-05-01', 3, '2024-Q1', 1428971, 64, 10, 3, 2, 16292.6),
('2026-05-01', 3, '2024-Q2', 1474131, 63, 10, 5, 3, 29492.52),
('2026-05-01', 3, '2024-Q3', 2001449, 88, 14, 5, 4, 45003.12),
('2026-05-01', 3, '2024-Q4', 2157017, 98, 14, 4, 3, 24002.02),
('2026-05-01', 3, '2025-Q1', 1776505, 84, 7, 5, 2, 29496.2),
('2026-05-01', 4, '2022-Q1', 2267184, 63, 1, 0, 0, 3314.6),
('2026-05-01', 4, '2022-Q2', 2171383, 61, 1, 0, 0, 1411.47),
('2026-05-01', 4, '2022-Q3', 2488343, 70, 1, 0, 0, 1864.19),
('2026-05-01', 4, '2022-Q4', 3099838, 86, 2, 0, 0, 2181.29),
('2026-05-01', 4, '2023-Q1', 2892127, 80, 2, 0, 0, 2026.63),
('2026-05-01', 4, '2023-Q2', 3532857, 97, 2, 1, 0, 4119.86),
('2026-05-01', 4, '2023-Q3', 3782187, 106, 2, 0, 0, 3258.8),
('2026-05-01', 4, '2023-Q4', 4003673, 113, 1, 0, 0, 4078.57),
('2026-05-01', 4, '2024-Q1', 4313735, 121, 1, 1, 0, 5954.4),
('2026-05-01', 4, '2024-Q2', 4638073, 129, 2, 1, 0, 2909.52),
('2026-05-01', 4, '2024-Q3', 4226336, 119, 1, 0, 0, 5872.39),
('2026-05-01', 4, '2024-Q4', 5163658, 145, 2, 0, 0, 6179.89),
('2026-05-01', 4, '2025-Q1', 5733161, 159, 3, 1, 0, 8336.38),
('2026-05-01', 5, '2022-Q1', 1651221, 47, 0, 0, 0, 1176.9),
('2026-05-01', 5, '2022-Q2', 1819921, 50, 1, 0, 0, 2469.54),
('2026-05-01', 5, '2022-Q3', 2535188, 71, 1, 0, 0, 3248.96),
('2026-05-01', 5, '2022-Q4', 2568960, 71, 2, 0, 0, 1293.83),
('2026-05-01', 5, '2023-Q1', 3186283, 90, 1, 0, 0, 2678.26),
('2026-05-01', 5, '2023-Q2', 3084714, 86, 2, 0, 0, 1789.47),
('2026-05-01', 5, '2023-Q3', 3727608, 103, 2, 1, 0, 5530.96),
('2026-05-01', 5, '2023-Q4', 4333041, 120, 2, 1, 0, 5566.04),
('2026-05-01', 5, '2024-Q1', 3996465, 111, 3, 0, 0, 4400.07),
('2026-05-01', 5, '2024-Q2', 3878579, 109, 1, 0, 0, 2004.24);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-05-01', 5, '2024-Q3', 4650041, 129, 3, 0, 0, 6814.82),
('2026-05-01', 5, '2024-Q4', 4879175, 136, 3, 0, 0, 5403.28),
('2026-05-01', 5, '2025-Q1', 4008234, 112, 1, 1, 0, 4534.17),
('2026-05-01', 6, '2022-Q1', 2022848, 54, 2, 1, 0, 10724.24),
('2026-05-01', 6, '2022-Q2', 2470592, 64, 3, 2, 1, 17790.35),
('2026-05-01', 6, '2022-Q3', 2216520, 56, 5, 2, 0, 11291.61),
('2026-05-01', 6, '2022-Q4', 3008231, 77, 4, 3, 1, 22378.59),
('2026-05-01', 6, '2023-Q1', 2904299, 74, 5, 2, 1, 9575.86),
('2026-05-01', 6, '2023-Q2', 3644169, 94, 6, 3, 1, 16348.26),
('2026-05-01', 6, '2023-Q3', 2807340, 73, 4, 2, 1, 12060.03),
('2026-05-01', 6, '2023-Q4', 3455666, 89, 6, 3, 0, 15878.53),
('2026-05-01', 6, '2024-Q1', 4688718, 119, 8, 4, 2, 19141.42),
('2026-05-01', 6, '2024-Q2', 3590102, 95, 4, 2, 1, 19725.02),
('2026-05-01', 6, '2024-Q3', 3697248, 96, 6, 2, 1, 15722.22),
('2026-05-01', 6, '2024-Q4', 5561784, 148, 6, 3, 1, 13938.41),
('2026-05-01', 6, '2025-Q1', 5869276, 152, 10, 3, 2, 43833.36),
('2026-05-01', 7, '2022-Q1', 5122293, 18, 0, 0, 0, 5080.07),
('2026-05-01', 7, '2022-Q2', 6978207, 24, 0, 0, 0, 7262.38),
('2026-05-01', 7, '2022-Q3', 6496802, 23, 0, 0, 0, 6790.02),
('2026-05-01', 7, '2022-Q4', 9397517, 33, 0, 0, 0, 5918.92),
('2026-05-01', 7, '2023-Q1', 8746536, 31, 0, 0, 0, 7734.65),
('2026-05-01', 7, '2023-Q2', 8372321, 29, 0, 0, 0, 11222.68),
('2026-05-01', 7, '2023-Q3', 12475822, 44, 0, 0, 0, 14831.46),
('2026-05-01', 7, '2023-Q4', 9698485, 34, 0, 0, 0, 12029.86),
('2026-05-01', 7, '2024-Q1', 11829375, 42, 0, 0, 0, 7419.51),
('2026-05-01', 7, '2024-Q2', 11627622, 41, 0, 0, 0, 16901.11),
('2026-05-01', 7, '2024-Q3', 13583407, 48, 0, 0, 0, 17923.76),
('2026-05-01', 7, '2024-Q4', 14493033, 50, 1, 0, 0, 10944.23),
('2026-05-01', 7, '2025-Q1', 16451697, 57, 1, 0, 0, 11103.47),
('2026-05-01', 8, '2022-Q1', 5809725, 20, 0, 0, 0, 3340.09),
('2026-05-01', 8, '2022-Q2', 6084631, 21, 0, 0, 0, 8330.97),
('2026-05-01', 8, '2022-Q3', 6713596, 23, 0, 0, 0, 3928.42),
('2026-05-01', 8, '2022-Q4', 8751236, 31, 0, 0, 0, 10452.09),
('2026-05-01', 8, '2023-Q1', 9477871, 33, 0, 0, 0, 8015.66),
('2026-05-01', 8, '2023-Q2', 8466969, 30, 0, 0, 0, 8448.59),
('2026-05-01', 8, '2023-Q3', 11723102, 41, 0, 0, 0, 14707.35),
('2026-05-01', 8, '2023-Q4', 12746208, 45, 0, 0, 0, 17918.32),
('2026-05-01', 8, '2024-Q1', 14186536, 49, 1, 0, 0, 20246.35),
('2026-05-01', 8, '2024-Q2', 12115518, 42, 1, 0, 0, 10767.39),
('2026-05-01', 8, '2024-Q3', 12623283, 45, 0, 0, 0, 17382.45),
('2026-05-01', 8, '2024-Q4', 12734480, 45, 0, 0, 0, 11869.51),
('2026-05-01', 8, '2025-Q1', 15542294, 54, 1, 0, 0, 18694.86),
('2026-05-01', 9, '2022-Q1', 6121380, 20, 1, 0, 0, 41133.43),
('2026-05-01', 9, '2022-Q2', 7080162, 24, 1, 0, 0, 31073.52),
('2026-05-01', 9, '2022-Q3', 7134177, 24, 1, 0, 0, 37614.9),
('2026-05-01', 9, '2022-Q4', 9353290, 31, 2, 0, 0, 33195.84),
('2026-05-01', 9, '2023-Q1', 7827889, 26, 1, 0, 0, 53368.84),
('2026-05-01', 9, '2023-Q2', 11551724, 37, 3, 1, 0, 76987.0),
('2026-05-01', 9, '2023-Q3', 9549183, 32, 2, 0, 0, 26402.83),
('2026-05-01', 9, '2023-Q4', 12156523, 39, 3, 1, 0, 51010.06);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-05-01', 9, '2024-Q1', 11907855, 39, 2, 1, 0, 53818.02),
('2026-05-01', 9, '2024-Q2', 13313935, 45, 1, 1, 0, 53888.36),
('2026-05-01', 9, '2024-Q3', 14321511, 47, 3, 1, 0, 64582.99),
('2026-05-01', 9, '2024-Q4', 12013188, 39, 2, 1, 0, 45716.73),
('2026-05-01', 9, '2025-Q1', 14430200, 48, 2, 1, 0, 42593.39),
('2026-05-01', 10, '2022-Q1', 339292, 61, 3, 2, 1, 1875.08),
('2026-05-01', 10, '2022-Q2', 400967, 73, 4, 2, 1, 2765.83),
('2026-05-01', 10, '2022-Q3', 441094, 78, 7, 2, 1, 2915.29),
('2026-05-01', 10, '2022-Q4', 448102, 82, 4, 2, 1, 3304.18),
('2026-05-01', 10, '2023-Q1', 491819, 89, 6, 2, 1, 3408.04),
('2026-05-01', 10, '2023-Q2', 420826, 76, 5, 2, 1, 2156.81),
('2026-05-01', 10, '2023-Q3', 553286, 100, 6, 3, 1, 1837.88),
('2026-05-01', 10, '2023-Q4', 607747, 113, 5, 2, 1, 3687.53),
('2026-05-01', 10, '2024-Q1', 533331, 96, 7, 2, 1, 2966.58),
('2026-05-01', 10, '2024-Q2', 598952, 107, 7, 4, 1, 3281.41),
('2026-05-01', 10, '2024-Q3', 844218, 156, 6, 5, 1, 5281.87),
('2026-05-01', 10, '2024-Q4', 657280, 121, 6, 3, 1, 2866.96),
('2026-05-01', 10, '2025-Q1', 932844, 169, 11, 5, 1, 4829.19),
('2026-05-01', 11, '2022-Q1', 336609, 66, 1, 0, 0, 327.48),
('2026-05-01', 11, '2022-Q2', 333511, 65, 1, 0, 0, 233.58),
('2026-05-01', 11, '2022-Q3', 424127, 83, 1, 0, 0, 244.6),
('2026-05-01', 11, '2022-Q4', 470784, 92, 2, 0, 0, 353.74),
('2026-05-01', 11, '2023-Q1', 463641, 90, 1, 1, 0, 277.29),
('2026-05-01', 11, '2023-Q2', 556545, 108, 3, 0, 0, 492.49),
('2026-05-01', 11, '2023-Q3', 525245, 103, 2, 0, 0, 755.28),
('2026-05-01', 11, '2023-Q4', 593228, 115, 2, 1, 0, 883.3),
('2026-05-01', 11, '2024-Q1', 577923, 111, 3, 1, 0, 722.01),
('2026-05-01', 11, '2024-Q2', 567894, 112, 1, 0, 0, 634.77),
('2026-05-01', 11, '2024-Q3', 706222, 138, 3, 0, 0, 786.56),
('2026-05-01', 11, '2024-Q4', 650433, 127, 2, 1, 0, 967.7),
('2026-05-01', 11, '2025-Q1', 886353, 174, 2, 1, 0, 664.06),
('2026-05-01', 12, '2022-Q1', 285784, 45, 7, 3, 2, 3573.47),
('2026-05-01', 12, '2022-Q2', 324383, 50, 7, 5, 2, 3396.91),
('2026-05-01', 12, '2022-Q3', 432105, 65, 13, 6, 2, 9438.56),
('2026-05-01', 12, '2022-Q4', 464701, 74, 10, 6, 2, 9816.18),
('2026-05-01', 12, '2023-Q1', 493078, 79, 9, 8, 2, 11029.67),
('2026-05-01', 12, '2023-Q2', 416246, 66, 10, 4, 3, 8147.15),
('2026-05-01', 12, '2023-Q3', 509659, 82, 11, 6, 2, 5544.77),
('2026-05-01', 12, '2023-Q4', 542910, 87, 12, 5, 4, 8868.34),
('2026-05-01', 12, '2024-Q1', 726057, 113, 15, 11, 6, 7918.48),
('2026-05-01', 12, '2024-Q2', 724797, 113, 17, 10, 4, 6330.31),
('2026-05-01', 12, '2024-Q3', 813141, 127, 21, 10, 4, 11821.01),
('2026-05-01', 12, '2024-Q4', 772149, 125, 20, 6, 3, 14362.29),
('2026-05-01', 12, '2025-Q1', 908754, 148, 15, 11, 7, 18535.0),
('2026-06-01', 1, '2022-Q1', 877538, 47, 1, 0, 0, 922.22),
('2026-06-01', 1, '2022-Q2', 938862, 51, 1, 0, 0, 1221.55),
('2026-06-01', 1, '2022-Q3', 923457, 50, 1, 0, 0, 1158.92),
('2026-06-01', 1, '2022-Q4', 1315196, 72, 1, 0, 0, 1033.21),
('2026-06-01', 1, '2023-Q1', 1253377, 68, 1, 0, 0, 1692.31),
('2026-06-01', 1, '2023-Q2', 1090480, 59, 1, 0, 0, 1053.63);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-06-01', 1, '2023-Q3', 1636895, 89, 1, 0, 0, 1121.02),
('2026-06-01', 1, '2023-Q4', 1282144, 69, 2, 0, 0, 1645.04),
('2026-06-01', 1, '2024-Q1', 1758858, 95, 1, 1, 0, 2628.6),
('2026-06-01', 1, '2024-Q2', 1542628, 83, 2, 0, 0, 964.81),
('2026-06-01', 1, '2024-Q3', 1641779, 90, 1, 0, 0, 1826.52),
('2026-06-01', 1, '2024-Q4', 1845031, 101, 1, 0, 0, 1720.52),
('2026-06-01', 1, '2025-Q1', 2397951, 130, 3, 0, 0, 3064.84),
('2026-06-01', 2, '2022-Q1', 873017, 45, 2, 1, 0, 2311.6),
('2026-06-01', 2, '2022-Q2', 949369, 47, 3, 2, 0, 5651.83),
('2026-06-01', 2, '2022-Q3', 981520, 50, 3, 1, 0, 3521.75),
('2026-06-01', 2, '2022-Q4', 1012046, 52, 2, 2, 0, 2534.73),
('2026-06-01', 2, '2023-Q1', 1081521, 54, 3, 2, 1, 3731.11),
('2026-06-01', 2, '2023-Q2', 1269935, 62, 5, 2, 1, 7720.03),
('2026-06-01', 2, '2023-Q3', 1188684, 61, 4, 1, 0, 7704.04),
('2026-06-01', 2, '2023-Q4', 1576872, 79, 6, 1, 1, 8085.35),
('2026-06-01', 2, '2024-Q1', 1501615, 76, 4, 2, 1, 5706.63),
('2026-06-01', 2, '2024-Q2', 1436546, 72, 4, 2, 1, 9174.28),
('2026-06-01', 2, '2024-Q3', 2077021, 107, 5, 2, 1, 9905.35),
('2026-06-01', 2, '2024-Q4', 1713638, 88, 5, 2, 0, 8510.78),
('2026-06-01', 2, '2025-Q1', 1746950, 91, 5, 1, 0, 8347.99),
('2026-06-01', 3, '2022-Q1', 805717, 34, 6, 3, 1, 14355.63),
('2026-06-01', 3, '2022-Q2', 725616, 30, 6, 3, 1, 14921.7),
('2026-06-01', 3, '2022-Q3', 1004892, 41, 8, 4, 2, 16162.23),
('2026-06-01', 3, '2022-Q4', 1306002, 57, 8, 5, 2, 22070.71),
('2026-06-01', 3, '2023-Q1', 1267399, 55, 8, 5, 2, 15594.01),
('2026-06-01', 3, '2023-Q2', 1379768, 59, 10, 5, 2, 22498.98),
('2026-06-01', 3, '2023-Q3', 1621400, 74, 8, 5, 3, 35167.68),
('2026-06-01', 3, '2023-Q4', 1599194, 68, 12, 6, 2, 17972.78),
('2026-06-01', 3, '2024-Q1', 1763491, 81, 7, 7, 2, 25860.48),
('2026-06-01', 3, '2024-Q2', 1500078, 66, 9, 6, 2, 31900.76),
('2026-06-01', 3, '2024-Q3', 1817817, 86, 7, 5, 2, 19331.06),
('2026-06-01', 3, '2024-Q4', 2203638, 104, 9, 7, 2, 39163.1),
('2026-06-01', 3, '2025-Q1', 2022188, 94, 10, 4, 4, 26929.8),
('2026-06-01', 4, '2022-Q1', 1903185, 53, 1, 0, 0, 1597.96),
('2026-06-01', 4, '2022-Q2', 2033002, 57, 1, 0, 0, 2712.12),
('2026-06-01', 4, '2022-Q3', 2022965, 56, 1, 0, 0, 2536.36),
('2026-06-01', 4, '2022-Q4', 2603716, 73, 1, 0, 0, 1636.49),
('2026-06-01', 4, '2023-Q1', 3434247, 95, 2, 1, 0, 2929.55),
('2026-06-01', 4, '2023-Q2', 3071871, 86, 1, 0, 0, 2621.49),
('2026-06-01', 4, '2023-Q3', 2983887, 83, 2, 0, 0, 4103.72),
('2026-06-01', 4, '2023-Q4', 3694319, 103, 2, 0, 0, 3182.39),
('2026-06-01', 4, '2024-Q1', 4792557, 132, 3, 1, 0, 6223.91),
('2026-06-01', 4, '2024-Q2', 4797202, 134, 2, 1, 0, 5635.59),
('2026-06-01', 4, '2024-Q3', 3873548, 108, 2, 0, 0, 4128.09),
('2026-06-01', 4, '2024-Q4', 5525384, 154, 2, 1, 0, 7412.49),
('2026-06-01', 4, '2025-Q1', 4241905, 118, 2, 1, 0, 6177.47),
('2026-06-01', 5, '2022-Q1', 2219560, 61, 2, 0, 0, 3259.72),
('2026-06-01', 5, '2022-Q2', 2559416, 72, 1, 0, 0, 2785.98),
('2026-06-01', 5, '2022-Q3', 2656827, 74, 1, 0, 0, 2996.67),
('2026-06-01', 5, '2022-Q4', 3295205, 92, 2, 0, 0, 4916.59);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-06-01', 5, '2023-Q1', 2680760, 74, 2, 0, 0, 2214.22),
('2026-06-01', 5, '2023-Q2', 2841084, 80, 1, 0, 0, 2235.29),
('2026-06-01', 5, '2023-Q3', 4165185, 117, 2, 0, 0, 2896.22),
('2026-06-01', 5, '2023-Q4', 3548145, 98, 2, 1, 0, 2149.21),
('2026-06-01', 5, '2024-Q1', 4122882, 115, 2, 0, 0, 4088.2),
('2026-06-01', 5, '2024-Q2', 4817995, 134, 2, 1, 0, 2686.76),
('2026-06-01', 5, '2024-Q3', 4771496, 134, 2, 0, 0, 5525.58),
('2026-06-01', 5, '2024-Q4', 5371964, 149, 3, 1, 0, 7544.68),
('2026-06-01', 5, '2025-Q1', 5641339, 158, 2, 1, 0, 6261.36),
('2026-06-01', 6, '2022-Q1', 2262736, 58, 4, 2, 0, 12786.29),
('2026-06-01', 6, '2022-Q2', 1958175, 52, 2, 1, 0, 10190.48),
('2026-06-01', 6, '2022-Q3', 2090027, 54, 4, 1, 0, 10616.79),
('2026-06-01', 6, '2022-Q4', 2910410, 75, 4, 3, 1, 16147.68),
('2026-06-01', 6, '2023-Q1', 2423146, 61, 5, 2, 1, 12240.2),
('2026-06-01', 6, '2023-Q2', 3022034, 79, 4, 2, 1, 12799.57),
('2026-06-01', 6, '2023-Q3', 2943336, 76, 6, 2, 0, 20260.88),
('2026-06-01', 6, '2023-Q4', 3967699, 101, 8, 3, 1, 29536.05),
('2026-06-01', 6, '2024-Q1', 4732877, 123, 9, 2, 1, 31833.82),
('2026-06-01', 6, '2024-Q2', 3593688, 94, 4, 3, 1, 25367.46),
('2026-06-01', 6, '2024-Q3', 3939152, 103, 6, 2, 1, 19481.15),
('2026-06-01', 6, '2024-Q4', 3927659, 105, 4, 2, 1, 28579.83),
('2026-06-01', 6, '2025-Q1', 5291211, 139, 8, 3, 1, 28827.72),
('2026-06-01', 7, '2022-Q1', 7198246, 25, 0, 0, 0, 4991.34),
('2026-06-01', 7, '2022-Q2', 5438895, 19, 0, 0, 0, 4144.75),
('2026-06-01', 7, '2022-Q3', 7593569, 27, 0, 0, 0, 8572.07),
('2026-06-01', 7, NULL, 7546256, 26, 0, 0, 0, 5322.83),
('2026-06-01', 7, '2023-Q1', 9363487, 33, 0, 0, 0, 9922.42),
('2026-06-01', 7, '2023-Q2', 8106493, 28, 0, 0, 0, 5430.23),
('2026-06-01', 7, '2023-Q3', 10103114, 36, 0, 0, 0, 14630.5),
('2026-06-01', 7, '2023-Q4', 9145863, 32, 0, 0, 0, 8879.79),
('2026-06-01', 7, '2024-Q1', 13606593, 47, 1, 0, 0, 11735.97),
('2026-06-01', 7, '2024-Q2', 10910504, 38, 0, 0, 0, 8457.65),
('2026-06-01', 7, '2024-Q3', 13395709, 46, 1, 0, 0, 18739.16),
('2026-06-01', 7, '2024-Q4', 12307704, 43, 0, 0, 0, 8568.48),
('2026-06-01', 7, '2025-Q1', 15181626, 53, 1, 0, 0, 16079.86),
('2026-06-01', 8, '2022-Q1', 4958986, 17, 0, 0, 0, 3476.43),
('2026-06-01', 8, '2022-Q2', 7681333, 27, 0, 0, 0, 7834.92),
('2026-06-01', 8, '2022-Q3', 6073018, 21, 0, 0, 0, 6753.29),
('2026-06-01', 8, '2022-Q4', 7728707, 27, 0, 0, 0, 4715.17),
('2026-06-01', 8, NULL, 9927084, 34, 1, 0, 0, 12853.16),
('2026-06-01', 8, '2023-Q2', 10583115, 36, 1, 0, 0, 6192.34),
('2026-06-01', 8, '2023-Q3', 12189219, 42, 1, 0, 0, 15986.38),
('2026-06-01', 8, '2023-Q4', 12962330, 45, 1, 0, 0, 9593.68),
('2026-06-01', 8, '2024-Q1', 9653351, 34, 0, 0, 0, 6035.92),
('2026-06-01', 8, '2024-Q2', 11847122, 42, 0, 0, 0, 15685.12),
('2026-06-01', 8, '2024-Q3', 12721880, 45, 0, 0, 0, 14786.0),
('2026-06-01', 8, '2024-Q4', 13696422, 48, 0, 0, 0, 11251.51),
('2026-06-01', 8, '2025-Q1', 12866694, 44, 1, 0, 0, 13026.74),
('2026-06-01', 9, '2022-Q1', 5999769, 20, 1, 0, 0, 18771.55),
('2026-06-01', 9, '2022-Q2', 6686740, 22, 1, 0, 0, 23675.64);

INSERT INTO loan_performance (snapshot_date, product_id, vintage, outstanding_balance, current_count, dpd_30, dpd_60, dpd_90_plus, chargeoff_amount) VALUES
('2026-06-01', 9, '2022-Q3', 8548387, 29, 1, 0, 0, 27842.59),
('2026-06-01', 9, '2022-Q4', 8123164, 27, 1, 1, 0, 51774.1),
('2026-06-01', 9, '2023-Q1', 8919205, 28, 2, 1, 0, 61327.48),
('2026-06-01', 9, '2023-Q2', 8023560, 27, 1, 0, 0, 50674.43),
('2026-06-01', 9, '2023-Q3', 9010760, 29, 2, 1, 0, 56106.42),
('2026-06-01', 9, '2023-Q4', 12244116, 40, 2, 1, 0, 83655.89),
('2026-06-01', 9, '2024-Q1', 12071731, 41, 1, 1, 0, 44810.57),
('2026-06-01', 9, '2024-Q2', 14873055, 49, 3, 1, 0, 82400.77),
('2026-06-01', 9, '2024-Q3', 13776538, 47, 2, 0, 0, 84803.48),
('2026-06-01', 9, '2024-Q4', 14465709, 48, 2, 1, 0, 81112.13),
('2026-06-01', 9, '2025-Q1', 12001008, 40, 2, 0, 0, 86513.85),
('2026-06-01', 10, '2022-Q1', 284247, 51, 64, 58, 0, 812.3),
('2026-06-01', 10, '2022-Q2', 338321, 61, 81, 73, 0, 964.74),
('2026-06-01', 10, '2022-Q3', 386685, 69, 5, 2, 1, 2582.76),
('2026-06-01', 10, '2022-Q4', 473891, 85, 6, 2, 1, 2022.11),
('2026-06-01', 10, '2023-Q1', 396943, 73, 4, 2, 0, 2408.85),
('2026-06-01', 10, '2023-Q2', 477448, 88, 4, 2, 1, 2348.04),
('2026-06-01', 10, '2023-Q3', 522452, 94, 7, 2, 1, 2696.77),
('2026-06-01', 10, '2023-Q4', 491449, 89, 6, 2, 1, 3352.45),
('2026-06-01', 10, '2024-Q1', 690128, 125, 151, 142, 2, 3593.38),
('2026-06-01', 10, '2024-Q2', 793263, 146, 7, 3, 2, 5394.12),
('2026-06-01', 10, '2024-Q3', 844252, 151, 10, 5, 2, 5824.62),
('2026-06-01', 10, '2024-Q4', 843684, 156, 184, 172, 2, 3783.54),
('2026-06-01', 10, '2025-Q1', 952688, 174, 10, 4, 2, 6731.95),
('2026-06-01', 11, '2022-Q1', 376833, 74, 1, 0, 0, 329.22),
('2026-06-01', 11, '2022-Q2', 384749, 74, 2, 0, 0, 435.57),
('2026-06-01', 11, '2022-Q3', 395810, 77, 2, 0, 0, 333.62),
('2026-06-01', 11, '2022-Q4', 375260, 73, 84, 81, 0, 292.39),
('2026-06-01', 11, '2023-Q1', 446041, 87, 2, 0, 0, 607.73),
('2026-06-01', 11, '2023-Q2', 448024, 87, 2, 0, 0, 543.26),
('2026-06-01', 11, '2023-Q3', 592328, 116, 2, 0, 0, 859.37),
('2026-06-01', 11, '2023-Q4', 589957, 115, 2, 0, 0, 615.51),
('2026-06-01', 11, '2024-Q1', 758377, 147, 166, 157, 0, 1112.8),
('2026-06-01', 11, '2024-Q2', 596084, 116, 2, 1, 0, 332.39),
('2026-06-01', 11, '2024-Q3', 721938, 141, 2, 1, 0, 912.22),
('2026-06-01', 11, '2024-Q4', 763535, 150, 2, 0, 0, 1001.76),
('2026-06-01', 11, '2025-Q1', 803883, 156, 173, 165, 0, 736.07),
('2026-06-01', 12, '2022-Q1', 293583, 46, 77, 62, 2, 4679.17),
('2026-06-01', 12, '2022-Q2', 296595, 49, 6, 3, 1, 5142.54),
('2026-06-01', 12, '2022-Q3', 424854, 68, 9, 4, 3, 4246.26),
('2026-06-01', 12, '2022-Q4', 430477, 68, 8, 7, 3, 7758.88),
('2026-06-01', 12, '2023-Q1', 556603, 84, 15, 8, 4, 4240.34),
('2026-06-01', 12, '2023-Q2', 540321, 85, 13, 7, 3, 12136.51),
('2026-06-01', 12, '2023-Q3', 626970, 101, 11, 9, 4, 10158.43),
('2026-06-01', 12, '2023-Q4', 652871, 104, 15, 7, 4, 8264.47),
('2026-06-01', 12, '2024-Q1', 698404, 116, 11, 7, 5, 9390.26),
('2026-06-01', 12, '2024-Q2', 699862, 115, 12, 8, 4, 9513.67),
('2026-06-01', 12, '2024-Q3', 798190, 134, 11, 10, 4, 17579.81),
('2026-06-01', 12, '2024-Q4', 839264, 138, 18, 6, 5, 16973.55),
('2026-06-01', 12, '2025-Q1', 873741, 146, 15, 7, 6, 14272.91);


-- ============================================================
-- 6. Grants for Semantic View
-- ============================================================

USE ROLE ACCOUNTADMIN;
GRANT CREATE SEMANTIC VIEW ON SCHEMA sofi_finance_hol.financial TO ROLE finance_hol_admin;

-- Enable cross-region inference (needed for Cortex AI functions)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

USE ROLE finance_hol_admin;
USE WAREHOUSE finance_hol_wh;
USE DATABASE sofi_finance_hol;
USE SCHEMA financial;

-- ============================================================
-- 7. Verify Data
-- ============================================================

SELECT 'PRODUCTS' AS tbl, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'EARNINGS_TRANSCRIPTS', COUNT(*) FROM earnings_transcripts
UNION ALL
SELECT 'INVOICES', COUNT(*) FROM invoices
UNION ALL
SELECT 'VENDOR_CATALOG', COUNT(*) FROM vendor_catalog
UNION ALL
SELECT 'LOAN_ORIGINATIONS', COUNT(*) FROM loan_originations
UNION ALL
SELECT 'LOAN_PERFORMANCE', COUNT(*) FROM loan_performance;

-- ============================================================
-- 8. Set Defaults
-- ============================================================

ALTER USER IDENTIFIER($current_user) SET DEFAULT_ROLE = 'FINANCE_HOL_ADMIN';
ALTER USER IDENTIFIER($current_user) SET DEFAULT_WAREHOUSE = 'FINANCE_HOL_WH';

SELECT 'Bootstrap complete! Data loaded, defaults set.' AS status;

-- ============================================================
-- STOP HERE — Run the next two blocks SEPARATELY
-- (Snowsight cannot mix CALL statements with other SQL)
-- ============================================================

-- ============================================================
-- Step 2: Deploy Semantic View (run separately after bootstrap)
-- ============================================================

USE ROLE finance_hol_admin;
USE WAREHOUSE finance_hol_wh;
USE DATABASE sofi_finance_hol;
USE SCHEMA financial;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'SOFI_FINANCE_HOL.FINANCIAL',
  $$
name: FINANCE_ANALYTICS
description: "Semantic view for analyzing SoFi financial data including earnings, invoices, vendor management, loan originations, and portfolio performance."

tables:
  - name: EARNINGS_TRANSCRIPTS
    description: Quarterly earnings call data for fintech companies including revenue, EPS, growth metrics, and forward guidance.
    base_table:
      database: SOFI_FINANCE_HOL
      schema: FINANCIAL
      table: EARNINGS_TRANSCRIPTS
    dimensions:
      - name: COMPANY
        description: Company name (Coinbase, Robinhood, LendingClub, Marqeta)
        expr: COMPANY
        data_type: VARCHAR
        synonyms:
          - firm
          - organization
      - name: TICKER
        description: Stock ticker symbol
        expr: TICKER
        data_type: VARCHAR
      - name: QUARTER
        description: Fiscal quarter (Q1, Q2, Q3, Q4)
        expr: QUARTER
        data_type: VARCHAR
      - name: KEY_THEMES
        description: Semicolon-separated list of key themes discussed on the call
        expr: KEY_THEMES
        data_type: VARCHAR
      - name: FORWARD_GUIDANCE
        description: Management forward-looking guidance or outlook statement
        expr: FORWARD_GUIDANCE
        data_type: VARCHAR
        synonyms:
          - outlook
          - guidance
    time_dimensions:
      - name: CALL_DATE
        description: Date the earnings call took place
        expr: CALL_DATE
        data_type: DATE
    facts:
      - name: TRANSCRIPT_ID
        description: Unique identifier for each earnings transcript record
        expr: TRANSCRIPT_ID
        data_type: NUMBER
      - name: FISCAL_YEAR
        description: Fiscal year
        expr: FISCAL_YEAR
        data_type: NUMBER
      - name: REVENUE_MILLIONS
        description: Total revenue in millions of USD
        expr: REVENUE_MILLIONS
        data_type: NUMBER
        synonyms:
          - sales
          - top line
          - total revenue
      - name: EPS
        description: Diluted earnings per share
        expr: EPS
        data_type: NUMBER
        synonyms:
          - earnings per share
          - diluted eps
      - name: YOY_REVENUE_GROWTH_PCT
        description: Year-over-year revenue growth percentage
        expr: YOY_REVENUE_GROWTH_PCT
        data_type: NUMBER
        synonyms:
          - revenue growth
          - yoy growth
      - name: ACTIVE_USERS_MILLIONS
        description: Active users or customers in millions (NULL for B2B companies like Marqeta)
        expr: ACTIVE_USERS_MILLIONS
        data_type: NUMBER
        synonyms:
          - users
          - customers
          - MAU
      - name: SENTIMENT_SCORE
        description: Overall sentiment score from 0 (negative) to 1 (positive)
        expr: SENTIMENT_SCORE
        data_type: NUMBER
    metrics:
      - name: AVG_REVENUE
        description: Average quarterly revenue in millions
        expr: AVG(REVENUE_MILLIONS)
      - name: TOTAL_TRANSCRIPTS
        description: Count of earnings transcripts
        expr: COUNT(*)

  - name: INVOICES
    description: Finance department invoices from vendors including amounts, dates, departments, and payment status.
    base_table:
      database: SOFI_FINANCE_HOL
      schema: FINANCIAL
      table: INVOICES
    dimensions:
      - name: INVOICE_NUMBER
        description: Invoice reference number
        expr: INVOICE_NUMBER
        data_type: VARCHAR
      - name: CURRENCY
        description: Currency code (always USD)
        expr: CURRENCY
        data_type: VARCHAR
      - name: DEPARTMENT
        description: Department that incurred the expense
        expr: DEPARTMENT
        data_type: VARCHAR
        synonyms:
          - team
          - group
          - business unit
      - name: COST_CENTER
        description: Cost center code
        expr: COST_CENTER
        data_type: VARCHAR
      - name: STATUS
        description: Payment status (Paid, Pending, Overdue, Disputed)
        expr: STATUS
        data_type: VARCHAR
        synonyms:
          - payment status
        is_enum: true
        sample_values:
          - Paid
          - Pending
          - Overdue
          - Disputed
      - name: DESCRIPTION
        description: Invoice line item description
        expr: DESCRIPTION
        data_type: VARCHAR
    time_dimensions:
      - name: INVOICE_DATE
        description: Date the invoice was issued
        expr: INVOICE_DATE
        data_type: DATE
      - name: DUE_DATE
        description: Payment due date
        expr: DUE_DATE
        data_type: DATE
      - name: PAYMENT_DATE
        description: Date payment was made (NULL if unpaid)
        expr: PAYMENT_DATE
        data_type: DATE
    facts:
      - name: INVOICE_ID
        description: Unique invoice identifier
        expr: INVOICE_ID
        data_type: NUMBER
      - name: VENDOR_ID
        description: Foreign key to vendor_catalog
        expr: VENDOR_ID
        data_type: NUMBER
      - name: AMOUNT
        description: Invoice amount in USD
        expr: AMOUNT
        data_type: NUMBER
        synonyms:
          - total
          - invoice total
          - spend
          - cost
    metrics:
      - name: TOTAL_INVOICE_AMOUNT
        description: Sum of all invoice amounts
        expr: SUM(AMOUNT)
      - name: AVG_INVOICE_AMOUNT
        description: Average invoice amount
        expr: AVG(AMOUNT)
      - name: INVOICE_COUNT
        description: Number of invoices
        expr: COUNT(*)

  - name: VENDOR_CATALOG
    description: Vendor master list with contract details, spend budgets, and risk ratings.
    base_table:
      database: SOFI_FINANCE_HOL
      schema: FINANCIAL
      table: VENDOR_CATALOG
    primary_key:
      columns:
        - VENDOR_ID
    dimensions:
      - name: VENDOR_NAME
        description: Vendor company name
        expr: VENDOR_NAME
        data_type: VARCHAR
        synonyms:
          - supplier
          - provider
      - name: CATEGORY
        description: Vendor category (Professional Services, Cloud Infrastructure, Market Data, etc.)
        expr: CATEGORY
        data_type: VARCHAR
        synonyms:
          - type
          - vendor type
      - name: CONTRACT_STATUS
        description: Contract status (Active, Expiring)
        expr: CONTRACT_STATUS
        data_type: VARCHAR
        is_enum: true
        sample_values:
          - Active
          - Expiring
      - name: PAYMENT_TERMS
        description: Payment terms (Net 30, Net 45, Net 60)
        expr: PAYMENT_TERMS
        data_type: VARCHAR
      - name: RISK_RATING
        description: Vendor risk rating (Low, Medium, High)
        expr: RISK_RATING
        data_type: VARCHAR
        is_enum: true
        sample_values:
          - Low
          - Medium
          - High
    time_dimensions:
      - name: CONTRACT_START_DATE
        description: Contract effective start date
        expr: CONTRACT_START_DATE
        data_type: DATE
      - name: CONTRACT_END_DATE
        description: Contract expiration date
        expr: CONTRACT_END_DATE
        data_type: DATE
    facts:
      - name: VENDOR_ID
        description: Unique vendor identifier
        expr: VENDOR_ID
        data_type: NUMBER
      - name: ANNUAL_SPEND_BUDGET
        description: Approved annual spend budget for this vendor
        expr: ANNUAL_SPEND_BUDGET
        data_type: NUMBER
        synonyms:
          - budget
          - approved spend

  - name: LOAN_ORIGINATIONS
    description: Monthly loan application and funding data by region and product.
    base_table:
      database: SOFI_FINANCE_HOL
      schema: FINANCIAL
      table: LOAN_ORIGINATIONS
    dimensions:
      - name: REGION
        description: Geographic region
        expr: REGION
        data_type: VARCHAR
    time_dimensions:
      - name: DATE
        description: Date of the origination activity
        expr: DATE
        data_type: DATE
    facts:
      - name: PRODUCT_ID
        description: Foreign key to products table
        expr: PRODUCT_ID
        data_type: NUMBER
      - name: APPLICATIONS
        description: Number of loan applications received
        expr: APPLICATIONS
        data_type: NUMBER
        synonyms:
          - apps
          - applications received
      - name: APPROVALS
        description: Number of applications approved
        expr: APPROVALS
        data_type: NUMBER
      - name: DENIALS
        description: Number of applications denied
        expr: DENIALS
        data_type: NUMBER
      - name: FUNDED_AMOUNT
        description: Total dollar amount funded
        expr: FUNDED_AMOUNT
        data_type: NUMBER
        synonyms:
          - amount funded
          - origination volume
          - funding
    metrics:
      - name: TOTAL_FUNDED
        description: Total funded amount
        expr: SUM(FUNDED_AMOUNT)
      - name: TOTAL_APPLICATIONS
        description: Total applications received
        expr: SUM(APPLICATIONS)
      - name: APPROVAL_RATE
        description: Approval rate as a percentage
        expr: ROUND(SUM(APPROVALS) * 100.0 / NULLIF(SUM(APPLICATIONS), 0), 2)

  - name: LOAN_PERFORMANCE
    description: Monthly portfolio performance snapshots showing delinquency by product and vintage.
    base_table:
      database: SOFI_FINANCE_HOL
      schema: FINANCIAL
      table: LOAN_PERFORMANCE
    dimensions:
      - name: VINTAGE
        description: Origination vintage cohort
        expr: VINTAGE
        data_type: VARCHAR
    time_dimensions:
      - name: SNAPSHOT_DATE
        description: Month-end snapshot date
        expr: SNAPSHOT_DATE
        data_type: DATE
    facts:
      - name: PRODUCT_ID
        description: Foreign key to products table
        expr: PRODUCT_ID
        data_type: NUMBER
      - name: OUTSTANDING_BALANCE
        description: Total outstanding loan balance
        expr: OUTSTANDING_BALANCE
        data_type: NUMBER
        synonyms:
          - balance
          - exposure
      - name: CURRENT_COUNT
        description: Number of loans that are current (not delinquent)
        expr: CURRENT_COUNT
        data_type: NUMBER
      - name: DPD_30
        description: Number of loans 30 days past due
        expr: DPD_30
        data_type: NUMBER
        synonyms:
          - 30 day delinquency
          - early delinquency
      - name: DPD_60
        description: Number of loans 60 days past due
        expr: DPD_60
        data_type: NUMBER
      - name: DPD_90_PLUS
        description: Number of loans 90+ days past due
        expr: DPD_90_PLUS
        data_type: NUMBER
        synonyms:
          - serious delinquency
          - 90 day delinquency
          - late stage
      - name: CHARGEOFF_AMOUNT
        description: Dollar amount charged off
        expr: CHARGEOFF_AMOUNT
        data_type: NUMBER
        synonyms:
          - losses
          - write-offs
          - charge-offs
    metrics:
      - name: TOTAL_BALANCE
        description: Total outstanding balance
        expr: SUM(OUTSTANDING_BALANCE)
      - name: DELINQUENCY_RATE
        description: Percentage of loans 90+ days past due
        expr: ROUND(SUM(DPD_90_PLUS) * 100.0 / NULLIF(SUM(CURRENT_COUNT + DPD_30 + DPD_60 + DPD_90_PLUS), 0), 2)

  - name: PRODUCTS
    description: Financial product catalog with risk tier classifications.
    base_table:
      database: SOFI_FINANCE_HOL
      schema: FINANCIAL
      table: PRODUCTS
    primary_key:
      columns:
        - PRODUCT_ID
    dimensions:
      - name: PRODUCT_NAME
        description: Product display name
        expr: PRODUCT_NAME
        data_type: VARCHAR
      - name: CATEGORY
        description: Product category (Personal Loan, Home Loan, Credit Card, etc.)
        expr: CATEGORY
        data_type: VARCHAR
      - name: RISK_TIER
        description: Risk classification tier (Prime, Near-prime, Subprime)
        expr: RISK_TIER
        data_type: VARCHAR
        is_enum: true
        sample_values:
          - Prime
          - Near-prime
          - Subprime
    time_dimensions:
      - name: LAUNCH_DATE
        description: Date the product was launched
        expr: LAUNCH_DATE
        data_type: DATE
    facts:
      - name: PRODUCT_ID
        description: Unique product identifier
        expr: PRODUCT_ID
        data_type: NUMBER

relationships:
  - name: invoices_to_vendors
    left_table: INVOICES
    right_table: VENDOR_CATALOG
    relationship_columns:
      - left_column: VENDOR_ID
        right_column: VENDOR_ID
  - name: originations_to_products
    left_table: LOAN_ORIGINATIONS
    right_table: PRODUCTS
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID
  - name: performance_to_products
    left_table: LOAN_PERFORMANCE
    right_table: PRODUCTS
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID

verified_queries:
  - name: total_invoice_spend_by_department
    question: What is the total invoice spend by department?
    sql: |
      SELECT department, SUM(amount) AS total_spend
      FROM sofi_finance_hol.financial.invoices
      GROUP BY department
      ORDER BY total_spend DESC
    use_as_onboarding_question: true

  - name: overdue_invoices_by_vendor
    question: Which vendors have overdue invoices?
    sql: |
      SELECT v.vendor_name, COUNT(*) AS overdue_count, SUM(i.amount) AS overdue_amount
      FROM sofi_finance_hol.financial.invoices i
      JOIN sofi_finance_hol.financial.vendor_catalog v ON i.vendor_id = v.vendor_id
      WHERE i.status = 'Overdue'
      GROUP BY v.vendor_name
      ORDER BY overdue_amount DESC
    use_as_onboarding_question: true

  - name: quarterly_revenue_comparison
    question: Compare quarterly revenue across all companies
    sql: |
      SELECT company, quarter, fiscal_year, revenue_millions
      FROM sofi_finance_hol.financial.earnings_transcripts
      ORDER BY fiscal_year, quarter, company

  - name: delinquency_rate_by_product
    question: What is the delinquency rate by product?
    sql: |
      SELECT p.product_name, p.risk_tier,
        SUM(lp.dpd_90_plus) AS total_90_plus,
        SUM(lp.current_count + lp.dpd_30 + lp.dpd_60 + lp.dpd_90_plus) AS total_loans,
        ROUND(SUM(lp.dpd_90_plus) * 100.0 / NULLIF(SUM(lp.current_count + lp.dpd_30 + lp.dpd_60 + lp.dpd_90_plus), 0), 2) AS delinquency_rate_pct
      FROM sofi_finance_hol.financial.loan_performance lp
      JOIN sofi_finance_hol.financial.products p ON lp.product_id = p.product_id
      GROUP BY p.product_name, p.risk_tier
      ORDER BY delinquency_rate_pct DESC

  - name: monthly_origination_trend
    question: What is the trend in loan originations over time?
    sql: |
      SELECT DATE_TRUNC('month', date) AS month, SUM(funded_amount) AS total_funded
      FROM sofi_finance_hol.financial.loan_originations
      GROUP BY month
      ORDER BY month
    use_as_onboarding_question: true
$$,
  FALSE
);

SELECT 'Semantic view FINANCE_ANALYTICS created!' AS status;

-- ============================================================
-- CoWork Setup
-- ============================================================
-- Enable Snowflake Intelligence (CoWork) and create the agent.
-- The agent can live in any database — we put it in SOFI_FINANCE_HOL.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- Enable CoWork on this account
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Grant agent creation in our database
GRANT CREATE AGENT ON SCHEMA sofi_finance_hol.financial TO ROLE finance_hol_admin;

USE ROLE finance_hol_admin;
USE WAREHOUSE finance_hol_wh;
USE DATABASE sofi_finance_hol;
USE SCHEMA financial;

CREATE OR REPLACE AGENT sofi_finance_hol.financial.finance_assistant
  COMMENT = 'Finance Research Assistant for SoFi HOL'
  FROM SPECIFICATION
  $$
models:
  orchestration: auto

instructions:
  response: |
    You are a finance research assistant. Your data includes SoFi financial operations (invoices, vendors, loans, products) as well as earnings transcripts from fintech competitors (Coinbase, Robinhood, LendingClub, Marqeta).
    Always try the finance_analyst tool before saying data is unavailable.
    When presenting numbers, use appropriate formatting (commas for thousands, 2 decimal places for currency).
    If a question is ambiguous, ask for clarification before querying.
  orchestration: |
    Use the finance_analyst tool for ALL questions about invoices, vendors, earnings, loans, products, financial metrics, revenue, and competitor data. Always attempt a query before concluding data is unavailable.

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "finance_analyst"
      description: "Answers questions about financial data including invoices, vendors, earnings transcripts (Coinbase, Robinhood, LendingClub, Marqeta), loan originations, loan performance, and products. Use this tool for any question about financial metrics, revenue, trends, or comparisons — including competitor earnings data."
  - tool_spec:
      type: "data_to_chart"
      name: "data_to_chart"
      description: "Generates visualizations from query results. Use when the user asks for a chart, graph, or visual."

tool_resources:
  finance_analyst:
    semantic_view: "SOFI_FINANCE_HOL.FINANCIAL.FINANCE_ANALYTICS"
    execution_environment:
      type: "warehouse"
      warehouse: "FINANCE_HOL_WH"
  $$;

-- Make the agent visible in CoWork
USE ROLE ACCOUNTADMIN;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT sofi_finance_hol.financial.finance_assistant;

SELECT 'CoWork enabled and agent created!' AS status;

-- ============================================================
-- Final Verification
-- ============================================================

SELECT * FROM (
  SELECT 'Role: FINANCE_HOL_ADMIN' AS object, 'Created' AS status
  UNION ALL SELECT 'Warehouse: FINANCE_HOL_WH', 'Created'
  UNION ALL SELECT 'Database: SOFI_FINANCE_HOL', 'Created'
  UNION ALL SELECT 'Schema: FINANCIAL', 'Created'
  UNION ALL SELECT 'Table: PRODUCTS (' || (SELECT COUNT(*) FROM sofi_finance_hol.financial.products) || ' rows)', 'Created'
  UNION ALL SELECT 'Table: EARNINGS_TRANSCRIPTS (' || (SELECT COUNT(*) FROM sofi_finance_hol.financial.earnings_transcripts) || ' rows)', 'Created'
  UNION ALL SELECT 'Table: INVOICES (' || (SELECT COUNT(*) FROM sofi_finance_hol.financial.invoices) || ' rows)', 'Created'
  UNION ALL SELECT 'Table: VENDOR_CATALOG (' || (SELECT COUNT(*) FROM sofi_finance_hol.financial.vendor_catalog) || ' rows)', 'Created'
  UNION ALL SELECT 'Table: LOAN_ORIGINATIONS (' || (SELECT COUNT(*) FROM sofi_finance_hol.financial.loan_originations) || ' rows)', 'Created'
  UNION ALL SELECT 'Table: LOAN_PERFORMANCE (' || (SELECT COUNT(*) FROM sofi_finance_hol.financial.loan_performance) || ' rows)', 'Created'
  UNION ALL SELECT 'Semantic View: FINANCE_ANALYTICS', 'Created'
  UNION ALL SELECT 'Agent: FINANCE_ASSISTANT', 'Created'
  UNION ALL SELECT 'CoWork: Enabled', 'Created'
  UNION ALL SELECT 'Tags: domain, source_system, data_sensitivity, refresh_frequency', 'Created'
  UNION ALL SELECT 'Contacts: finance_data_team, finance_data_support, finance_security_compliance', 'Created'
);
