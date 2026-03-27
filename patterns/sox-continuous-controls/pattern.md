# SOX Continuous Controls Agent
> Agent spans native Dataverse tables (control framework) and virtual tables (live D365 F&O data) to continuously test 100% of financial transactions against SOX controls — no data extraction, no sampling.

## The Problem
**Vertical:** Financial Services / Public Company Finance
**Role:** Internal Audit Director, SOX Compliance Manager, CFO, External Auditor
**Daily frustration:** SOX control testing has been stuck in the 1990s: auditors pull sample data from the ERP, analyze it offline in spreadsheets or ACL/IDEA, document findings in SharePoint, and report results weeks later. The sample size? 25-40 transactions per control. The testing frequency? Quarterly or annually. Meanwhile, the company processes millions of transactions. By 2026, regulators are calling this approach a "red flag" — if you CAN analyze 100% of transactions, why are you sampling?

**Cost of the status quo:**
- Average SOX compliance cost for large companies: $1.5M-$5M/year
- 60-70% of that cost is manual testing labor
- Sample-based testing misses 99%+ of transactions — anomalies hide in the untested majority
- Financial close cycle: 10-15 business days, with SOX testing as a bottleneck
- Restatement risk from missed control failures: average $2.8M impact + stock price decline
- 2026 reality: "Death of the random sample" — regulators expect continuous, 100% transaction analysis

## The Architecture

### Overview
The SOX Continuous Controls Agent operates across TWO data paradigms simultaneously:
1. **Native Dataverse tables** store the CONTROL FRAMEWORK — control definitions, test procedures, evidence requirements, schedules, findings, and remediation workflows
2. **Virtual tables** provide REAL-TIME ACCESS to D365 F&O financial data — journal entries, purchase orders, invoices, payments, approvals — without any data extraction or replication

The agent reads control definitions from native tables, then tests them against live ERP data via virtual tables. This eliminates the data extraction bottleneck, ensures freshness (always testing current data), and enables continuous rather than periodic testing.

### Parent Agent: SOX Control Orchestrator
- **Purpose:** Reads the control catalog from Dataverse, determines which controls to test based on schedule and risk priority, dispatches control tests to child agents, aggregates findings, and manages the remediation lifecycle.
- **Routing strategy:** Risk-prioritized scheduling. Controls are tested on a rotation based on their risk level and last test date. High-risk controls test daily, medium weekly, low monthly. All controls test 100% of transactions in their scope — no sampling.
- **What makes it different:** This agent spans two fundamentally different data layers — native Dataverse (where the framework lives) and virtual tables (where the live data lives). The boundary between "what the control says" and "what the data shows" dissolves into a single query context.

### Child Agents

**1. Transaction Pattern Tester**
- **Description:** "Tests financial transaction controls by querying live D365 F&O data through virtual tables and comparing patterns against control definitions in native Dataverse tables. Handles controls like: segregation of duties, approval thresholds, journal entry authorization, duplicate payment detection, three-way match verification."
- **Responsibilities:** Execute SQL-like queries against virtual tables (journal lines, vendor invoices, PO receipts), compare against control criteria (approval limits, authorized approvers, matching tolerances), generate evidence of pass/fail for every transaction.

**2. Access Control Auditor**
- **Description:** "Tests user access and segregation of duties controls by reading security role assignments from D365 F&O virtual tables and comparing against the authorized access matrix in native Dataverse tables. Detects conflicts, excessive privileges, and unauthorized role changes."
- **Responsibilities:** Query D365 security roles, duties, and privileges via virtual tables. Compare against the authorized access matrix in native Dataverse. Detect SOD conflicts (e.g., same user can create and approve POs). Flag role changes since last test.

**3. Financial Close Validator**
- **Description:** "Tests financial close controls by verifying reconciliations, accruals, reserves, and intercompany eliminations against expected patterns and thresholds. Reads live trial balance and subledger data through virtual tables."
- **Responsibilities:** Verify account reconciliations are complete and timely, test accrual calculations against historical patterns, check intercompany balances net to zero, validate reserve adequacy against policy.

**4. Evidence Documenter**
- **Description:** "Generates audit-ready evidence packages for each control test. Packages include: control description, test procedure, population tested (100%), exceptions found, evidence screenshots (virtual table query results), timestamps, and remediation status."
- **Responsibilities:** Format test results into auditor-consumable evidence packages. Generate statistics (population size, exception rate, trend vs prior period). Link evidence to specific control IDs for audit trail. Store packages in Dataverse for external auditor access.

### Data Flow
```
SOX Control Orchestrator reads control catalog (native Dataverse)
    → Determines today's test schedule (risk-prioritized)
    → For each control to test:
        → Reads control definition (native table: cr023_sox_control)
        → Reads test procedure (native table: cr023_sox_test_procedure)
        → Routes to appropriate child agent
        → Child agent queries live D365 F&O data (VIRTUAL tables)
        → Child compares live data against control criteria
        → ALL transactions in scope are tested (no sampling)
        → Generates findings: {pass_count, fail_count, exceptions: [...]}
    → Evidence Documenter packages results
    → If exceptions found: create finding in cr023_sox_finding (native table)
    → If finding is material: trigger Power Automate escalation
    → Update control test history in cr023_sox_test_result
```

### How This Differs from Known Patterns
- **Closest known pattern:** Niyam (Policy-Driven Agents) + Compliance Sentinel
- **Delta 1:** Niyam uses only native Dataverse tables. This agent uses BOTH native AND virtual tables — two different data paradigms with different characteristics (native = stored, virtual = real-time pass-through).
- **Delta 2:** The Compliance Sentinel is event-driven (reacts to triggers). This is schedule-driven and proactive — it tests controls on a risk-prioritized rotation, not waiting for events.
- **Delta 3:** Virtual tables eliminate data extraction/replication — the agent reads LIVE ERP data through Dataverse's virtual entity layer. No ETL, no staleness, no data warehouse. This is architecturally unique.

## Dataverse Schema

### cr023_sox_control (Native Table)
**Display name:** SOX Control
| Column | Type | Description |
|--------|------|-------------|
| cr023_sox_controlid | GUID (PK) | Primary key |
| cr023_control_id | Text (50) | Control identifier (e.g., "AP-001", "JE-003", "SC-012") |
| cr023_name | Text (200) | Control name (e.g., "Three-Way Match for AP Invoices") |
| cr023_category | Choice | Transaction Processing, Financial Close, IT General Controls, Access Controls, Management Review |
| cr023_risk_level | Choice | High, Medium, Low |
| cr023_description | Text (4000) | What this control does and why it matters |
| cr023_control_owner | Lookup → systemuser | Business owner responsible |
| cr023_test_frequency | Choice | Daily, Weekly, Monthly, Quarterly |
| cr023_last_tested | DateTime | When this control was last tested |
| cr023_last_test_result | Choice | Pass, Fail, Exception, Not Tested |
| cr023_exception_count_ytd | Integer | Year-to-date exception count |
| cr023_material_weakness_risk | Boolean | Whether failure could constitute a material weakness |
| cr023_active | Boolean | Whether this control is currently in scope |

### cr023_sox_test_procedure (Native Table)
**Display name:** SOX Test Procedure
| Column | Type | Description |
|--------|------|-------------|
| cr023_sox_test_procedureid | GUID (PK) | Primary key |
| cr023_control_id | Lookup → cr023_sox_control | Associated control |
| cr023_procedure_name | Text (200) | Test procedure name |
| cr023_virtual_table_source | Text (200) | D365 F&O virtual table to query (e.g., "mserp_vendorinvoicejour") |
| cr023_query_filter | Text (2000) | Filter criteria for the virtual table query (e.g., "posted_date >= @test_period_start") |
| cr023_assertion_type | Choice | Completeness, Accuracy, Authorization, Timeliness, Segregation of Duties |
| cr023_assertion_expression | Text (2000) | Test assertion (e.g., "invoice_amount <= po_amount * 1.10 AND receipt_exists = true") |
| cr023_exception_criteria | Text (2000) | What constitutes a test exception |
| cr023_evidence_fields | Text (1000) | Which fields to capture as evidence (comma-separated) |
| cr023_child_agent | Choice | Transaction Pattern Tester, Access Control Auditor, Financial Close Validator |

### cr023_sox_test_result (Native Table)
**Display name:** SOX Test Result
| Column | Type | Description |
|--------|------|-------------|
| cr023_sox_test_resultid | GUID (PK) | Primary key |
| cr023_control_id | Lookup → cr023_sox_control | Control tested |
| cr023_procedure_id | Lookup → cr023_sox_test_procedure | Procedure executed |
| cr023_test_date | DateTime | When test was executed |
| cr023_population_count | Integer | Total transactions in scope (100% — no sampling) |
| cr023_pass_count | Integer | Transactions that passed the assertion |
| cr023_exception_count | Integer | Transactions that failed the assertion |
| cr023_exception_rate | Decimal | exception_count / population_count |
| cr023_result | Choice | Pass (0 exceptions), Pass with Exceptions (< threshold), Fail (>= threshold) |
| cr023_exception_threshold_pct | Decimal | What rate of exceptions constitutes a failure |
| cr023_evidence_package_url | Text (500) | Link to evidence package in Dataverse/SharePoint |
| cr023_trend_vs_prior | Choice | Improving, Stable, Worsening |
| cr023_prior_period_exception_rate | Decimal | Last test's exception rate for comparison |
| cr023_tested_by | Text (100) | "SOX Continuous Controls Agent" (for audit trail) |

### cr023_sox_finding (Native Table)
**Display name:** SOX Control Finding
| Column | Type | Description |
|--------|------|-------------|
| cr023_sox_findingid | GUID (PK) | Primary key |
| cr023_control_id | Lookup → cr023_sox_control | Control that failed |
| cr023_test_result_id | Lookup → cr023_sox_test_result | Associated test result |
| cr023_severity | Choice | Deficiency, Significant Deficiency, Material Weakness |
| cr023_status | Choice | Open, Under Remediation, Remediated, Accepted Risk, Escalated |
| cr023_description | Text (4000) | What was found |
| cr023_root_cause | Text (2000) | Suspected root cause |
| cr023_impact_estimate | Currency | Estimated financial impact |
| cr023_remediation_plan | Text (4000) | What needs to be fixed |
| cr023_remediation_owner | Lookup → systemuser | Who is responsible for fixing |
| cr023_remediation_due_date | DateTime | When remediation must be complete |
| cr023_detected_on | DateTime | When the agent detected this |
| cr023_remediated_on | DateTime | When confirmed remediated |
| cr023_auditor_reviewed | Boolean | Whether external auditor has reviewed |

### cr023_sox_access_matrix (Native Table)
**Display name:** SOX Authorized Access Matrix
| Column | Type | Description |
|--------|------|-------------|
| cr023_sox_access_matrixid | GUID (PK) | Primary key |
| cr023_role_name | Text (200) | D365 F&O security role name |
| cr023_authorized_duties | Text (4000) | JSON array of authorized duties for this role |
| cr023_sod_conflict_roles | Text (2000) | Comma-separated roles that conflict with this one (SOD) |
| cr023_max_approval_limit | Currency | Maximum approval amount for this role |
| cr023_requires_secondary_approval | Boolean | Whether transactions need secondary approval |
| cr023_last_access_review | DateTime | When this role's access was last reviewed |
| cr023_approved_by | Lookup → systemuser | Who approved this access definition |

### Virtual Tables (D365 F&O — no Dataverse storage, real-time pass-through)
These are NOT created in Dataverse — they already exist as virtual entities from D365 F&O:
- `mserp_vendorinvoicejour` — Vendor invoice journal (for AP controls)
- `mserp_ledgerjournaltable` / `mserp_ledgerjournaltrans` — General ledger journal entries (for JE controls)
- `mserp_purchline` / `mserp_purchtable` — Purchase orders (for procurement controls)
- `mserp_vendtrans` — Vendor transactions (for payment controls)
- `mserp_custtrans` — Customer transactions (for revenue controls)
- `mserp_securityuserrole` — User-role assignments (for access controls)
- `mserp_securityduty` / `mserp_securityprivilege` — Security duty/privilege definitions
- `mserp_generalledgerentry` — Trial balance data (for financial close controls)

## MCP Configuration

### D365 F&O Financial Data MCP Server
- **Purpose:** Supplemental access to D365 F&O data entities not available as virtual tables, or for complex queries that span multiple entities
- **Tools exposed:**
  - `getJournalEntriesByPeriod` — Retrieve journal entries for a fiscal period with all line details
  - `getApprovalHistory` — Retrieve the approval chain for a specific document (PO, invoice, journal)
  - `getSecurityRoleAssignments` — Retrieve all users assigned to a specific security role
  - `getVendorPayments` — Retrieve vendor payment transactions with bank details
  - `getIntercompanyBalances` — Retrieve intercompany balances for elimination verification
- **Connection:** D365 F&O OData API via MCP adapter with read-only service account
- **Usage:** Child agents use MCP tools when virtual table queries alone don't provide sufficient context (e.g., approval history chains)

### Dataverse Control Framework MCP Server
- **Purpose:** Read/write access to the SOX control framework in native Dataverse tables
- **Tools exposed:**
  - `getControlsBySchedule` — Retrieve controls due for testing today based on frequency and last_tested
  - `getTestProcedure` — Retrieve the test procedure for a specific control
  - `createTestResult` — Write a test result after execution
  - `createFinding` — Write a new finding when exceptions exceed threshold
  - `getAccessMatrix` — Retrieve the authorized access matrix for SOD testing
  - `updateControlStatus` — Update a control's last_tested and result
- **Connection:** Dataverse Web API with application user credentials
- **Usage:** Orchestrator reads the control catalog; Evidence Documenter writes results and findings

## Power Automate Flows

### Flow 1: Daily Test Schedule Trigger
- **Trigger:** Recurrence — every business day at 05:00 UTC (before business hours)
- **Key actions:**
  1. Query cr023_sox_control for all controls where test_frequency matches today's schedule
  2. Prioritize by risk_level (High first) and days_since_last_test (longest first)
  3. Trigger the SOX Control Orchestrator agent with the day's test queue
  4. Log the scheduled test count to a daily tracking table
- **Error handling:** If agent fails to start, retry once; if still fails, send alert to Internal Audit Director

### Flow 2: Material Weakness Escalation
- **Trigger:** When cr023_sox_finding is created with severity = Material Weakness
- **Key actions:**
  1. IMMEDIATELY notify: CFO, Internal Audit Director, External Audit Partner
  2. Create an urgent remediation task with 48-hour SLA
  3. Freeze the affected process area (if configured) pending review
  4. Schedule emergency Audit Committee briefing
  5. Log escalation to regulatory communication tracker
- **Error handling:** Material weakness notifications MUST go through. Triple-redundant delivery (email + Teams + phone call trigger)

### Flow 3: Remediation SLA Tracker
- **Trigger:** When cr023_sox_finding is created with status = Open
- **Key actions:**
  1. Calculate SLA based on severity: Material Weakness = 48h, Significant Deficiency = 7 days, Deficiency = 30 days
  2. At 50% SLA: reminder to remediation_owner
  3. At 75% SLA: escalation to control_owner
  4. At 100% SLA: escalation to Internal Audit Director
  5. When status → Remediated: trigger re-test of the control to verify fix
- **Error handling:** SLA tracking continues even if notifications fail; escalation chain always executes

### Flow 4: Quarterly Audit Package Generation
- **Trigger:** Recurrence — end of each fiscal quarter
- **Key actions:**
  1. Aggregate all test results for the quarter by control category
  2. Calculate: tests executed, population tested, exception rates, trends
  3. Compile all open findings with remediation status
  4. Generate executive summary: material weaknesses, significant deficiencies, key risks
  5. Package for external auditor review: full evidence trail, test documentation, finding history
  6. Store in SharePoint with appropriate access controls for audit team
- **Error handling:** If aggregation fails, generate partial report with data gaps identified

## Agent Instructions (Paste-Ready)

### Parent Agent: SOX Control Orchestrator

```
You are the SOX Continuous Controls Agent — you test internal controls over financial reporting by reading control definitions from native Dataverse tables and testing them against live D365 F&O data through virtual tables.

## Your Role
Each business day, you:
1. Read the day's test queue from cr023_sox_control (controls due for testing based on schedule and risk priority)
2. For each control:
   a. Read the test procedure from cr023_sox_test_procedure
   b. Note which virtual table to query and what assertion to test
   c. Route to the appropriate child agent (Transaction Pattern Tester, Access Control Auditor, or Financial Close Validator)
   d. Receive results: population_count, pass_count, exception_count, exception_details
   e. Determine result: Pass (0 exceptions), Pass with Exceptions (rate < threshold), or Fail (rate >= threshold)
   f. Send to Evidence Documenter for packaging
   g. If Fail: create a finding in cr023_sox_finding
3. Update cr023_sox_control with last_tested and last_test_result
4. At end of run: generate daily summary with total controls tested, exceptions found, findings created

## The Dual-Paradigm Architecture
You operate across two data layers:
- **Native Dataverse tables** (cr023_sox_*): Your control framework. Control definitions, test procedures, results, findings. This is YOUR data — you read and write it.
- **Virtual tables** (mserp_*): Live D365 F&O data. Vendor invoices, journal entries, purchase orders, security roles. This is the LIVE SYSTEM — you only READ it. You NEVER modify financial data.

The power: you can cross-reference a control definition (native) against live financial data (virtual) in a single context. No data extraction. No staleness. No sampling.

## Testing Protocol
1. ALWAYS test 100% of transactions in scope — NEVER sample
2. For each test, record: population_count (total transactions examined), not just exceptions
3. Compare exception_rate against the control's exception_threshold_pct
4. Calculate trend_vs_prior by comparing against the most recent cr023_sox_test_result
5. If trend is Worsening AND exception_rate > threshold: flag as potential emerging risk

## Critical Rules
- NEVER modify D365 F&O data through virtual tables. Read-only access to financial data.
- NEVER skip a control on the test schedule. If a virtual table query fails, log the error and retry once. If still failing, log as "Not Tested — System Error" and alert the IT team.
- ALWAYS include the population count in results. Auditors need to know you tested ALL transactions, not a sample.
- ALWAYS store evidence. Every test must produce an evidence package that an external auditor can review.
- Treat every finding as a potential SEC filing exhibit. Be precise, factual, and evidence-based.
- If you detect a pattern that could be a material weakness (e.g., >5% exception rate on a high-risk control, or same exception recurring for 3+ test cycles): escalate immediately, don't wait for the next scheduled test.
```

### Child Agent: Transaction Pattern Tester

```
You test financial transaction controls by querying live D365 F&O data through virtual tables.

## What You Test
For each control test procedure you receive:
1. Read cr023_virtual_table_source to know which D365 F&O virtual table to query
2. Read cr023_query_filter to apply the appropriate date/entity filter
3. Query the virtual table for ALL transactions matching the filter (100% — no sampling)
4. For each transaction, evaluate the cr023_assertion_expression:
   - Three-way match: invoice_amount <= po_amount * tolerance AND receipt_exists
   - Approval threshold: if amount > threshold, approved_by is not null AND approver has authority
   - Duplicate detection: no other transaction with same vendor + amount + date within N days
   - Timeliness: posted_date <= document_date + allowed_days
5. Classify each transaction as Pass or Exception
6. For exceptions, capture the cr023_evidence_fields values

## Virtual Table Queries
You query these virtual tables (examples):
- mserp_vendorinvoicejour: Vendor invoices (AP controls)
- mserp_ledgerjournaltrans: Journal entry lines (JE controls)
- mserp_purchline: Purchase order lines (procurement controls)
- mserp_vendtrans: Vendor payment transactions (payment controls)

## Output
Return:
- population_count: total transactions examined
- pass_count: transactions meeting all assertions
- exception_count: transactions failing one or more assertions
- exceptions: array of [{transaction_id, field_values, assertion_failed, evidence}]
- query_execution_time_ms: for performance tracking

## Critical Rules
- ALWAYS query virtual tables with the correct date filter — never test outside the defined period
- ALWAYS capture evidence fields for exceptions — the evidence IS the audit trail
- If a virtual table query returns >100,000 records, batch the assertion checks and report progress
- If an assertion expression is ambiguous, flag it as "Assertion Unclear — Human Review Required"
```

### Child Agent: Access Control Auditor

```
You test user access and segregation of duties controls by comparing D365 F&O security role data (virtual tables) against the authorized access matrix (native Dataverse tables).

## What You Test
1. Segregation of Duties (SOD):
   - Query mserp_securityuserrole for all user-role assignments
   - For each user, check if they hold roles listed in cr023_sod_conflict_roles
   - Any user holding two conflicting roles is an exception
2. Excessive Privilege:
   - Compare actual role assignments against cr023_sox_access_matrix
   - Flag users with roles beyond their authorized level
3. Approval Authority:
   - Verify users approving transactions have the authority level in cr023_max_approval_limit
   - Cross-reference against actual approved transaction amounts from virtual tables
4. Role Change Detection:
   - Compare current role assignments against the last test snapshot
   - Flag new role additions, especially to sensitive roles

## Output
Return:
- population_count: total users examined
- sod_conflicts: [{user, role1, role2, conflict_type}]
- excessive_privilege: [{user, actual_roles, authorized_roles}]
- unauthorized_approvals: [{user, transaction_id, amount, authority_limit}]
- role_changes: [{user, role_added, role_removed, date}]
```

### Child Agent: Financial Close Validator

```
You test financial close controls by verifying reconciliations, accruals, and intercompany eliminations against expected patterns using live trial balance data from virtual tables.

## What You Test
1. Account Reconciliation Completeness:
   - Verify all balance sheet accounts have been reconciled within the allowed window
   - Flag accounts with balances but no reconciliation evidence
2. Accrual Reasonableness:
   - Compare current period accruals against historical patterns (3-period moving average)
   - Flag accruals that deviate by more than the configured threshold (typically 20%)
3. Intercompany Eliminations:
   - Verify intercompany receivables and payables net to zero
   - Flag any net intercompany balance exceeding the threshold
4. Unusual Journal Entries:
   - Flag journal entries posted after the close date
   - Flag round-number entries above materiality threshold
   - Flag entries by users who don't typically post journals (role-based analysis)

## Output
Return test results for each financial close control with: accounts tested, exceptions found, evidence, and trend analysis.
```

## Testing Scenarios

| # | User Utterance / Event | Expected Behavior | What to Verify |
|---|----------------------|-------------------|----------------|
| 1 | Daily 05:00 UTC trigger fires | Orchestrator loads day's test queue, prioritized by risk level | High-risk controls tested first, all scheduled controls covered |
| 2 | Three-way match control test: 50,000 invoices in period | All 50,000 tested. 23 exceptions found (0.046% rate, below 1% threshold) | Population = 50,000 (not 25), result = Pass with Exceptions |
| 3 | SOD check: user has both "Create PO" and "Approve PO" roles | SOD conflict detected, exception created with both role names | Finding references specific user ID and conflicting roles |
| 4 | Journal entry control: 3 entries posted after close date by non-finance user | Exceptions flagged with full evidence: entry IDs, post dates, user ID, amounts | Evidence package includes all relevant fields |
| 5 | Accrual for marketing expense is 45% above 3-period average | Exception flagged: "Accrual deviation of 45% exceeds 20% threshold" | Includes current amount, average, and percentage deviation |
| 6 | Intercompany balances: $12M receivable vs $11.8M payable (net $200K) | Net imbalance flagged if above materiality threshold | Evidence includes both sides, net amount, and threshold |
| 7 | Control test with >5% exception rate on high-risk control | Finding created with severity = Significant Deficiency. Escalation triggered. | Material Weakness Escalation flow fires, CFO notified |
| 8 | Same control fails for 3 consecutive test cycles | Agent flags "recurring exception pattern — potential material weakness" | Trend analysis shows Worsening, automatic severity upgrade |
| 9 | Virtual table query fails (D365 F&O maintenance window) | Control logged as "Not Tested — System Error", IT team alerted, retry scheduled | Error logged, control not marked as Pass, retry within 4 hours |
| 10 | Quarter-end audit package generation | All test results, findings, and evidence compiled into auditor-ready package | Package includes 100% testing evidence, exception trends, finding resolutions |

## Why This Is Novel

- **Closest known pattern:** Niyam (Policy-Driven Agents) + Clinical Trial Compliance Sentinel
- **Architectural delta:**
  1. **Dual-Paradigm Data Access:** No existing pattern spans both native Dataverse tables AND virtual tables simultaneously. Native tables hold the governance framework (control definitions, findings); virtual tables provide real-time pass-through to the controlled system (D365 F&O). This is a new data architecture for agent-based compliance.
  2. **Proactive Scheduled Testing vs Event-Driven:** The Compliance Sentinel reacts to events. This agent proactively tests controls on a risk-prioritized schedule — it doesn't wait for something to happen, it continuously verifies that everything IS happening correctly.
  3. **100% Population Testing:** Traditional SOX testing samples 25-40 transactions. This agent tests 100% of transactions through virtual table queries — a fundamental shift enabled by the virtual table's real-time data access without ETL overhead.
  4. **No Data Replication:** Unlike patterns that copy data into Dataverse for analysis, virtual tables mean the agent reads live ERP data in-place. Zero staleness, zero ETL, zero data duplication. The data stays in D365 F&O; the agent reads it through the virtual entity layer.
- **Why you can't build this with Niyam as-is:** Niyam stores policies in native Dataverse tables and reads from them. It has no concept of virtual tables or dual-paradigm data access. The ability to query live D365 F&O data through virtual tables without replication is what makes continuous 100% testing feasible — you can't do that with native Dataverse tables alone (you'd need to replicate millions of transactions).
- **What new primitive this introduces:** **Dual-Paradigm Control Architecture** — an agent system where the governance/framework layer lives in native Dataverse tables (mutable, agent-managed) and the controlled system's data is accessed through virtual tables (real-time, read-only, zero-replication). This separation enables continuous compliance monitoring against live systems without the traditional ETL bottleneck.
