# KYC Jurisdiction Mesh
> Agent dynamically selects jurisdiction-specific MCP servers based on customer geography, fans out KYC checks in parallel, and merges results with conflict resolution.

## The Problem
**Vertical:** Financial Services — Banking / Fintech
**Role:** KYC Analyst, Compliance Officer, Head of Financial Crime
**Daily frustration:** A multinational bank onboarding a corporate customer with operations in the EU, US, and Singapore must satisfy three different regulatory regimes simultaneously — each with different document requirements, UBO thresholds, sanctions lists, PEP databases, and reporting cadences. Today, KYC analysts manually navigate a patchwork of systems: check OFAC for US sanctions, EU consolidated sanctions list for Europe, MAS lists for Singapore, then reconcile conflicting requirements (EU says UBO threshold is 25%, US says "substantial control" which may be lower). This manual multi-jurisdictional compliance takes 30-90 days per corporate onboarding and consumes 40-60% of compliance staff time.

**Cost of the status quo:**
- Average corporate KYC onboarding: 30-90 days across jurisdictions
- KYC remediation costs: $60M-$500M for major banks (per Fenergo data)
- EMEA regulatory penalties up 767% in 2025 vs prior year
- 40-60% of compliance analyst time spent on manual multi-jurisdiction reconciliation
- "Multi-jurisdictional inconsistency will no longer be tolerated" — 2026 regulatory theme
- EU AMLA (Anti-Money Laundering Authority) begins centralized supervision in 2026
- US FinCEN shifting to demonstrable risk-based effectiveness, not checkbox compliance

## The Architecture

### Overview
The Jurisdiction Mesh mirrors the real-world regulatory topology: each jurisdiction's compliance data and rules live in a SEPARATE MCP server (because they ARE separate systems — OFAC, EU sanctions, UK FCA, MAS, local beneficial ownership registries). The agent doesn't try to unify everything into one database. Instead, it:

1. Determines which jurisdictions are relevant for this customer (domicile, operations, transaction corridors, correspondent banks)
2. Dynamically activates the appropriate jurisdiction-specific MCP servers
3. Fans out KYC checks to all relevant MCP servers in PARALLEL
4. Merges results into a composite compliance profile
5. Where requirements conflict, applies Dataverse-stored resolution policies (typically "highest bar" — apply the strictest requirement)
6. Generates a unified onboarding package that satisfies ALL relevant jurisdictions simultaneously

### Parent Agent: KYC Jurisdiction Router
- **Purpose:** Receives customer onboarding requests, determines the regulatory geography, activates the right MCP servers, orchestrates parallel KYC checks, and merges results using conflict resolution policies.
- **Routing strategy:** Geography-based MCP routing. The customer's jurisdictional footprint determines which MCP servers activate. This is DATA SOURCE routing, not task routing.
- **What makes it different:** Standard multi-agent patterns route to child agents by domain/task. This routes to EXTERNAL MCP SERVERS by jurisdiction, running them in parallel, and adds a merge/conflict-resolution layer that doesn't exist in any known pattern.

### Child Agents

**1. Jurisdiction Mapper**
- **Description:** "Analyzes a customer's corporate structure, operations, and transaction patterns to determine all applicable regulatory jurisdictions. Returns a jurisdiction set with confidence levels and rationale for each. Used before MCP fan-out to ensure no jurisdiction is missed."
- **Responsibilities:** Parse corporate structure (parent, subsidiaries, branches by country), identify transaction corridors (where money flows), determine correspondent banking relationships, flag jurisdictions with enhanced due diligence requirements.

**2. Requirement Merger**
- **Description:** "Takes KYC check results from multiple jurisdiction-specific MCP servers and merges them into a unified compliance profile. Resolves conflicts using Dataverse resolution policies. Generates the composite requirement set that satisfies all jurisdictions."
- **Responsibilities:** Identify overlapping requirements, detect conflicts (different UBO thresholds, different document types), apply resolution policies, generate gap analysis (what's still needed), produce unified onboarding checklist.

**3. Risk Assessor**
- **Description:** "Evaluates the composite KYC profile against the bank's internal risk appetite. Scores the customer across dimensions: sanctions exposure, PEP proximity, geographic risk, industry risk, transaction pattern risk. Determines enhanced due diligence triggers."
- **Responsibilities:** Calculate composite risk score, determine if EDD (Enhanced Due Diligence) is required, identify specific risk factors that need human review, generate risk rationale for audit trail.

### Data Flow
```
Customer Onboarding Request
    → Jurisdiction Mapper analyzes corporate structure
    → Returns: {US, EU, Singapore} with confidence scores
    → KYC Router activates MCP servers:
        → US KYC MCP (OFAC, FinCEN, state registries) [parallel]
        → EU KYC MCP (EU sanctions, AMLA registry, member state UBO) [parallel]
        → SG KYC MCP (MAS lists, ACRA registry, SG sanctions) [parallel]
    → Each MCP returns jurisdiction-specific results:
        → US: {sanctions_clear, ubo_threshold: "substantial_control", docs_required: [...]}
        → EU: {sanctions_clear, ubo_threshold: 25%, docs_required: [...]}
        → SG: {sanctions_clear, ubo_threshold: 25%, docs_required: [...]}
    → Requirement Merger:
        → Conflict: US "substantial control" vs EU/SG 25% → apply highest bar
        → Merge document requirements (union of all jurisdictions)
        → Generate composite requirement set
    → Risk Assessor scores composite profile
    → Output: Unified onboarding package + risk score + gap analysis
```

### How This Differs from Known Patterns
- **Closest known pattern:** Niyam (Policy-Driven Agents)
- **Delta 1:** Niyam stores all policies in ONE Dataverse. The Jurisdiction Mesh distributes regulatory intelligence across MULTIPLE external MCP servers — each jurisdiction is a separate service.
- **Delta 2:** Niyam routes to child agents by task/domain. This routes to MCP SERVERS by geography — data source routing, not task routing.
- **Delta 3:** Niyam doesn't have a merge/conflict-resolution layer. When multiple jurisdictions return conflicting requirements, the Mesh applies structured resolution policies. This is a new orchestration primitive.

## Dataverse Schema

### cr023_kyc_jurisdiction
**Display name:** KYC Jurisdiction Configuration
| Column | Type | Description |
|--------|------|-------------|
| cr023_kyc_jurisdictionid | GUID (PK) | Primary key |
| cr023_name | Text (100) | Jurisdiction code (e.g., "US", "EU", "SG", "UK", "AE") |
| cr023_display_name | Text (200) | Full name (e.g., "United States", "European Union") |
| cr023_regulatory_body | Text (200) | Primary regulator (e.g., "FinCEN", "EU AMLA", "MAS") |
| cr023_mcp_server_id | Text (200) | MCP server identifier for this jurisdiction |
| cr023_mcp_endpoint | Text (500) | MCP server endpoint URL |
| cr023_ubo_threshold_pct | Decimal | UBO ownership threshold (e.g., 25.0) |
| cr023_ubo_threshold_description | Text (500) | Qualitative threshold description (e.g., "substantial control") |
| cr023_edd_triggers | Text (2000) | JSON array of conditions that trigger EDD for this jurisdiction |
| cr023_required_document_types | Text (2000) | JSON array of required document types for onboarding |
| cr023_sanctions_list_name | Text (200) | Sanctions list identifier (e.g., "OFAC SDN", "EU Consolidated") |
| cr023_pep_database | Text (200) | PEP database identifier |
| cr023_reporting_cadence | Choice | Real-time, Daily, Weekly, Monthly, Quarterly |
| cr023_data_retention_years | Integer | Required data retention period |
| cr023_active | Boolean | Whether this jurisdiction is currently configured |

### cr023_kyc_conflict_policy
**Display name:** KYC Conflict Resolution Policy
| Column | Type | Description |
|--------|------|-------------|
| cr023_kyc_conflict_policyid | GUID (PK) | Primary key |
| cr023_conflict_type | Choice | UBO Threshold, Document Requirement, Data Retention, Reporting Cadence, Sanctions Screening, PEP Screening, EDD Trigger |
| cr023_resolution_strategy | Choice | Highest Bar (strictest), Union (all requirements), Jurisdiction Priority, Custom |
| cr023_jurisdiction_priority_order | Text (500) | Comma-separated jurisdiction codes for priority resolution |
| cr023_custom_resolution_logic | Text (2000) | Custom resolution rule (for Complex strategy) |
| cr023_description | Text (1000) | Human-readable explanation of this policy |
| cr023_last_reviewed | DateTime | When this policy was last reviewed by compliance |
| cr023_approved_by | Lookup → systemuser | Compliance officer who approved |

### cr023_kyc_customer_profile
**Display name:** KYC Customer Profile
| Column | Type | Description |
|--------|------|-------------|
| cr023_kyc_customer_profileid | GUID (PK) | Primary key |
| cr023_customer_name | Text (500) | Legal entity name |
| cr023_customer_type | Choice | Individual, Corporate, Trust, Fund, Government Entity |
| cr023_domicile_jurisdiction | Lookup → cr023_kyc_jurisdiction | Primary domicile |
| cr023_applicable_jurisdictions | Text (1000) | JSON array of all applicable jurisdiction IDs |
| cr023_jurisdiction_rationale | Text (4000) | Why each jurisdiction applies (for audit trail) |
| cr023_composite_risk_score | Decimal (0-100) | Overall risk score after multi-jurisdiction assessment |
| cr023_risk_tier | Choice | Low, Medium, High, Prohibited |
| cr023_edd_required | Boolean | Whether enhanced due diligence is needed |
| cr023_edd_triggers | Text (2000) | Which factors triggered EDD |
| cr023_status | Choice | Initiated, Jurisdiction Mapping, MCP Checks In Progress, Merging Results, Risk Assessment, Pending Review, Approved, Rejected, Remediation Required |
| cr023_composite_requirements | Text (max) | JSON: merged requirement set from all jurisdictions |
| cr023_conflicts_detected | Text (4000) | JSON: list of conflicts and how they were resolved |
| cr023_gap_analysis | Text (4000) | JSON: documents/checks still needed |
| cr023_onboarding_package_url | Text (500) | Link to generated onboarding package |
| cr023_created_on | DateTime | When onboarding was initiated |
| cr023_completed_on | DateTime | When onboarding was completed |
| cr023_analyst_assigned | Lookup → systemuser | KYC analyst responsible |

### cr023_kyc_mcp_result
**Display name:** KYC MCP Check Result
| Column | Type | Description |
|--------|------|-------------|
| cr023_kyc_mcp_resultid | GUID (PK) | Primary key |
| cr023_customer_profile_id | Lookup → cr023_kyc_customer_profile | Associated customer |
| cr023_jurisdiction_id | Lookup → cr023_kyc_jurisdiction | Which jurisdiction's MCP was queried |
| cr023_check_type | Choice | Sanctions Screening, PEP Screening, UBO Verification, Document Verification, Registry Lookup, Transaction Pattern Analysis |
| cr023_result_status | Choice | Clear, Hit, Partial Match, Error, Timeout |
| cr023_result_detail | Text (max) | Full result payload from MCP server |
| cr023_confidence_score | Decimal (0-1) | Confidence in the result |
| cr023_requires_human_review | Boolean | Whether this result needs analyst review |
| cr023_human_review_reason | Text (1000) | Why human review is needed |
| cr023_checked_at | DateTime | When the check was performed |
| cr023_mcp_response_time_ms | Integer | MCP server response time for performance tracking |

### cr023_kyc_ubo_record
**Display name:** KYC Ultimate Beneficial Owner
| Column | Type | Description |
|--------|------|-------------|
| cr023_kyc_ubo_recordid | GUID (PK) | Primary key |
| cr023_customer_profile_id | Lookup → cr023_kyc_customer_profile | Associated customer |
| cr023_ubo_name | Text (200) | UBO full name |
| cr023_ubo_nationality | Text (100) | Nationality |
| cr023_ownership_pct | Decimal | Ownership percentage |
| cr023_control_type | Choice | Direct Ownership, Indirect Ownership, Voting Rights, Management Control, Other |
| cr023_meets_threshold | Text (1000) | JSON: {jurisdiction: bool} — which jurisdictions' thresholds this UBO meets |
| cr023_pep_status | Choice | Not PEP, PEP, PEP Associate, Former PEP |
| cr023_sanctions_status | Choice | Clear, Hit, Partial Match |
| cr023_verified_via | Text (500) | Source of verification (registry name, document type) |

**Relationships:**
- cr023_kyc_customer_profile N:1 cr023_kyc_jurisdiction (domicile)
- cr023_kyc_mcp_result N:1 cr023_kyc_customer_profile
- cr023_kyc_mcp_result N:1 cr023_kyc_jurisdiction
- cr023_kyc_ubo_record N:1 cr023_kyc_customer_profile

## MCP Configuration

### US KYC MCP Server
- **Purpose:** US regulatory compliance checks
- **Tools exposed:**
  - `screenOFAC` — Screen entity/individuals against OFAC SDN and Consolidated lists
  - `checkFinCEN` — Query FinCEN beneficial ownership database (Corporate Transparency Act)
  - `getStateRegistry` — Query state-level business registration (Secretary of State)
  - `screenUSPEP` — Screen against US politically exposed persons database
  - `getUSDocRequirements` — Return US-specific document requirements for entity type
- **Connection:** MCP remote server (Streamable HTTP) with API key authentication

### EU KYC MCP Server
- **Purpose:** EU regulatory compliance checks (AMLA harmonized)
- **Tools exposed:**
  - `screenEUSanctions` — Screen against EU Consolidated Sanctions List
  - `queryAMLARegistry` — Query EU AMLA centralized beneficial ownership registry
  - `getMemberStateUBO` — Query member state UBO registers (company register APIs)
  - `screenEUPEP` — Screen against EU PEP databases
  - `getEUDocRequirements` — Return EU/AMLA document requirements
  - `checkGDPRConsent` — Verify data processing consent status for EU data subjects
- **Connection:** MCP remote server with OAuth2 + EU data residency compliance

### Singapore KYC MCP Server
- **Purpose:** Singapore/APAC regulatory compliance checks
- **Tools exposed:**
  - `screenMAS` — Screen against MAS sanctions and terrorism financing lists
  - `queryACRA` — Query ACRA (Accounting and Corporate Regulatory Authority) registry
  - `screenSGPEP` — Screen against Singapore PEP database
  - `getSGDocRequirements` — Return MAS-specific documentation requirements
  - `checkCDDRequirements` — Customer Due Diligence requirements per MAS Notice 626
- **Connection:** MCP remote server with SingPass/CorpPass authentication

### UK KYC MCP Server
- **Purpose:** UK regulatory compliance checks (post-Brexit regime)
- **Tools exposed:**
  - `screenUKSanctions` — Screen against OFSI (Office of Financial Sanctions Implementation) list
  - `queryCompaniesHouse` — Query UK Companies House for company/director/PSC data
  - `screenUKPEP` — Screen against UK PEP database
  - `getUKDocRequirements` — Return FCA-specific document requirements
- **Connection:** MCP remote server with API key authentication

## Power Automate Flows

### Flow 1: Onboarding Initiation
- **Trigger:** When a row is added to cr023_kyc_customer_profile with status = Initiated
- **Key actions:**
  1. Trigger the KYC Jurisdiction Router agent with customer details
  2. Update status to "Jurisdiction Mapping"
  3. Once Jurisdiction Mapper returns applicable jurisdictions, update cr023_applicable_jurisdictions
  4. Update status to "MCP Checks In Progress"
  5. The agent handles MCP fan-out from here
- **Error handling:** If Jurisdiction Mapper returns empty set, flag for manual review

### Flow 2: Sanctions Hit Escalation
- **Trigger:** When cr023_kyc_mcp_result is created with result_status = Hit AND check_type = Sanctions Screening
- **Key actions:**
  1. IMMEDIATELY notify the compliance team via Teams and email
  2. Freeze the onboarding process (update customer status to "Pending Review")
  3. Create a case in the bank's case management system
  4. Assign to senior analyst based on jurisdiction
  5. If hit is OFAC: also notify BSA/AML officer (US regulatory requirement)
- **Error handling:** Sanctions hits NEVER auto-clear. Always require human confirmation.

### Flow 3: Periodic Re-screening
- **Trigger:** Recurrence — daily at 02:00 UTC
- **Key actions:**
  1. Query all approved customers where last screening > 24 hours ago
  2. For each customer: fan out to all applicable jurisdiction MCP servers for sanctions re-screening
  3. If new hit detected: trigger Flow 2 (Sanctions Hit Escalation)
  4. Log re-screening completion to audit trail
  5. Generate daily screening report for compliance dashboard
- **Error handling:** If MCP server is unavailable, retry after 1 hour; if still unavailable, alert operations

### Flow 4: Monthly Compliance Report
- **Trigger:** Recurrence — 1st of each month at 06:00 UTC
- **Key actions:**
  1. Aggregate all onboarding activity by jurisdiction
  2. Calculate: avg onboarding time, approval rate, rejection rate, EDD trigger rate
  3. Identify conflict resolution patterns (which conflicts occur most frequently)
  4. Track MCP server performance (response times, error rates)
  5. Generate report for Head of Financial Crime and regional compliance leads
- **Error handling:** If data aggregation fails, generate partial report with data quality warning

## Agent Instructions (Paste-Ready)

### Parent Agent: KYC Jurisdiction Router

```
You are the KYC Jurisdiction Router — you orchestrate multi-jurisdictional KYC/AML onboarding by dynamically selecting and querying jurisdiction-specific MCP servers.

## Your Role
When a customer onboarding request arrives, you:
1. Activate the Jurisdiction Mapper to determine all applicable regulatory jurisdictions
2. For each jurisdiction, look up the MCP server configuration from cr023_kyc_jurisdiction in Dataverse
3. Fan out KYC checks to ALL applicable jurisdiction MCP servers IN PARALLEL:
   - Sanctions screening (mandatory for every jurisdiction)
   - PEP screening (mandatory for every jurisdiction)
   - UBO verification (thresholds vary by jurisdiction)
   - Document requirement retrieval
   - Registry lookups (beneficial ownership, corporate registration)
4. Collect all results into cr023_kyc_mcp_result records
5. Pass all results to the Requirement Merger for conflict resolution and composite profile generation
6. Pass the merged profile to the Risk Assessor for scoring
7. Output: unified onboarding package with gap analysis

## MCP Server Selection Rules
- Read cr023_kyc_jurisdiction for each applicable jurisdiction
- Use cr023_mcp_server_id and cr023_mcp_endpoint to connect
- If a jurisdiction's MCP server is unavailable: log the error, continue with other jurisdictions, but FLAG the gap in the final profile
- NEVER skip a jurisdiction because its MCP is slow — wait for all results

## Parallel Execution
- ALL jurisdiction MCP checks run in parallel — do NOT sequence them
- Within each jurisdiction, sanctions and PEP screening run first (blocking), then other checks
- If ANY sanctions screening returns a "Hit": STOP all processing and escalate immediately

## Conflict Resolution
After all MCP results are collected, the Requirement Merger applies cr023_kyc_conflict_policy:
- UBO Threshold conflicts: apply "Highest Bar" (use strictest threshold across jurisdictions)
- Document Requirements: apply "Union" (require all documents from all jurisdictions)
- Data Retention: apply "Highest Bar" (use longest retention period)
- Reporting Cadence: apply "Highest Bar" (use most frequent cadence)
- If no policy exists for a conflict type: FLAG for human review, do not auto-resolve

## Critical Rules
- NEVER auto-clear a sanctions hit. Always escalate for human review.
- NEVER skip a jurisdiction in the applicable set. Every jurisdiction must be checked.
- ALWAYS log every MCP query and result to cr023_kyc_mcp_result for audit trail.
- If the Jurisdiction Mapper returns a jurisdiction for which no MCP server is configured: FLAG as a gap. Do NOT proceed without coverage for that jurisdiction.
- Include rationale for every decision in the audit trail. Regulators will ask "why."
```

### Child Agent: Jurisdiction Mapper

```
You analyze a customer's corporate structure to determine all applicable regulatory jurisdictions.

## What You Analyze
1. Customer domicile (country of incorporation)
2. Subsidiary and branch locations (every country where the entity operates)
3. Beneficial owners' nationalities and residencies
4. Transaction corridors (where the entity sends/receives money)
5. Correspondent banking relationships (which banks in which countries)
6. Industry-specific jurisdiction triggers (e.g., crypto activities trigger virtual asset provider jurisdictions)

## How to Determine Applicability
A jurisdiction is applicable if ANY of the following are true:
- The customer is incorporated there
- The customer has a physical presence (subsidiary, branch, representative office)
- A beneficial owner is a national or resident
- The customer regularly sends or receives funds through that jurisdiction
- The bank's own license in that jurisdiction covers this customer relationship
- The customer's industry triggers jurisdiction-specific regulations

## Output
Return a JSON array of applicable jurisdictions, each with:
- jurisdiction_code (e.g., "US", "EU", "SG")
- applicability_reason (why this jurisdiction applies)
- confidence (high/medium/low)
- edd_likely (boolean — whether this jurisdiction's factors suggest enhanced due diligence)

## Critical Rules
- When in doubt, INCLUDE the jurisdiction. Over-inclusion is safer than under-inclusion.
- EU member states are covered by the EU jurisdiction PLUS any member-state-specific requirements.
- US states with specific requirements (e.g., New York DFS) should be flagged separately.
```

### Child Agent: Requirement Merger

```
You merge KYC check results from multiple jurisdiction-specific MCP servers into a unified compliance profile.

## What You Do
1. Receive all cr023_kyc_mcp_result records for a customer
2. For each requirement type, compare across jurisdictions:
   - UBO thresholds: identify the strictest threshold
   - Document requirements: create the union set (all documents from all jurisdictions)
   - Sanctions results: ANY hit from ANY jurisdiction is a hit
   - PEP results: ANY PEP match from ANY jurisdiction is a match
3. Read cr023_kyc_conflict_policy for each conflict type
4. Apply the resolution strategy:
   - Highest Bar: use the strictest requirement
   - Union: require everything from every jurisdiction
   - Jurisdiction Priority: use the priority-ordered jurisdiction's requirement
   - Custom: apply the custom resolution logic
5. Generate the composite requirement set and gap analysis

## Output
Return:
- composite_requirements: merged requirement set satisfying all jurisdictions
- conflicts_detected: list of conflicts with resolution applied
- gap_analysis: what's still needed (missing documents, pending verifications)
- overall_status: ready_for_risk_assessment / has_gaps / has_hits

## Critical Rules
- NEVER resolve a sanctions conflict — any hit is a hit, period
- NEVER downgrade a requirement from one jurisdiction to match a weaker requirement from another
- Document every conflict resolution with the policy ID used and the rationale
```

### Child Agent: Risk Assessor

```
You evaluate the composite KYC profile and assign a risk score.

## Risk Dimensions
1. Sanctions Exposure (0-25 points): any hits, near-matches, high-risk jurisdictions
2. PEP Proximity (0-20 points): direct PEP, PEP associate, former PEP
3. Geographic Risk (0-20 points): FATF grey/blacklist countries, high-risk jurisdictions
4. Industry Risk (0-15 points): high-risk industries (crypto, gambling, arms, extractives)
5. Transaction Pattern Risk (0-10 points): unusual corridors, high-value, rapid movement
6. Complexity Risk (0-10 points): complex corporate structures, nominee arrangements, trusts

## Risk Tiers
- Low (0-25): Standard due diligence sufficient
- Medium (26-50): Enhanced monitoring recommended
- High (51-75): Enhanced due diligence required, senior approval needed
- Prohibited (76-100): Cannot onboard, escalate to Head of Financial Crime

## EDD Triggers
EDD is required if ANY of: risk score > 50, PEP match, FATF grey/blacklist country, complex nominee structures, sanctions near-match

## Output
Return: risk_score, risk_tier, edd_required, edd_triggers, risk_rationale (for each dimension), recommended_monitoring_level

## Critical Rules
- Be conservative: when in doubt, score higher
- ALWAYS include rationale for each dimension score — regulators require explainability
- NEVER auto-approve a High or Prohibited tier customer
```

## Testing Scenarios

| # | User Utterance / Event | Expected Behavior | What to Verify |
|---|----------------------|-------------------|----------------|
| 1 | Onboard "Acme Corp" incorporated in US, subsidiary in Germany, UBO in Singapore | Jurisdiction Mapper returns {US, EU, SG}. Three MCP servers queried in parallel. | All 3 jurisdictions checked, composite requirements merge correctly |
| 2 | US OFAC screening returns a sanctions hit | IMMEDIATE escalation. All other processing stops. Compliance team notified. | Sanctions hit flow fires within 1 minute, status frozen |
| 3 | EU UBO threshold is 25%, US requires "substantial control" (interpreted as 10-25%) | Conflict detected. Resolution policy applies "Highest Bar" → use 10% threshold | cr023_kyc_conflict_policy applied, rationale logged |
| 4 | Singapore MCP server is unavailable (timeout) | US and EU checks proceed. Gap flagged: "SG jurisdiction not verified — MCP unavailable" | Profile shows gap, analyst notified, onboarding not auto-approved |
| 5 | Customer has a UBO who is a PEP in the UK | PEP match flagged. EDD triggered. Risk score increases by 20 points. | EDD flag set, risk score reflects PEP dimension |
| 6 | Simple domestic-only customer (US only, no cross-border) | Only US MCP activated. No conflicts to resolve. Fast-track onboarding. | Single jurisdiction path is efficient, no unnecessary MCP calls |
| 7 | Customer in FATF grey-list jurisdiction (e.g., UAE) | Geographic risk scored at 15+/20. EDD mandatory. Specific UAE MCP server queried if configured. | Grey-list flag applied, EDD trigger documented |
| 8 | Daily re-screening detects new sanctions entry matching existing customer | Sanctions Hit Escalation fires. Customer relationship flagged for immediate review. | Existing customer frozen, case created, BSA officer notified |
| 9 | New jurisdiction (Brazil) added to system with MCP server configured | Next onboarding for a customer with Brazilian operations automatically includes BR MCP | No code changes needed — jurisdiction discovery is data-driven |
| 10 | Monthly compliance report generated | Report shows avg onboarding time by jurisdiction count, most common conflicts, MCP performance | Analytics provide actionable insights for process improvement |

## Why This Is Novel

- **Closest known pattern:** Niyam (Policy-Driven Agents)
- **Architectural delta:**
  1. **Multi-MCP topology:** Niyam stores all policies in ONE Dataverse instance. The Jurisdiction Mesh distributes regulatory intelligence across MULTIPLE external MCP servers — each jurisdiction is a separate service with its own data, APIs, and authentication.
  2. **Data source routing:** Niyam routes to child agents by task/domain. This routes to MCP SERVERS by regulatory geography. The customer's jurisdictional footprint determines which external services the agent connects to.
  3. **Parallel fan-out + merge:** Niyam doesn't fan out to multiple data sources simultaneously. The Mesh queries N MCP servers in parallel and has a dedicated Requirement Merger that reconciles conflicting results using structured conflict resolution policies.
- **Why you can't build this with Niyam as-is:** Niyam assumes one Dataverse holds all the rules. In cross-border KYC, the rules ARE in separate systems (OFAC is not the EU sanctions list is not MAS). You can't consolidate them into one Dataverse without losing currency, authority, and jurisdiction-specific nuance. The federated approach is architecturally necessary, not a design choice.
- **What new primitive this introduces:** **Dynamic MCP Mesh** — an agent system that mirrors an external topology (regulatory jurisdictions, geographic regions, organizational boundaries) in its MCP server connections. The MCP server selection is driven by the request's context (geography, entity type, risk factors), creating a dynamic, context-sensitive service mesh that adapts to each transaction.
