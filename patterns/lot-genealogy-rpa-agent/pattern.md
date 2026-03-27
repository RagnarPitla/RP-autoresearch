# Lot Genealogy RPA Agent
> Agent uses RPA desktop flows as tentacles into legacy MES/SCADA/LIMS to assemble complete lot genealogy across modern and legacy systems for non-conformance root cause analysis.

## The Problem
**Vertical:** Manufacturing — Discrete, Process, and Regulated Industries
**Role:** Quality Engineer, Quality Manager, Regulatory Compliance Manager
**Daily frustration:** When a quality non-conformance is detected — a defective batch, an out-of-spec measurement, a customer complaint — the quality engineer must trace the entire lot genealogy: raw materials, processing steps, equipment used, operators, environmental conditions, and downstream distribution. This data is scattered across 4-7 systems: D365 F&O (ERP), a legacy MES (often 10-15 years old with only a Windows desktop UI), SCADA/PLC historians (proprietary desktop software), LIMS (lab information management with thick client), and sometimes paper records. The quality engineer spends 2-5 DAYS manually logging into each system, searching by lot number, exporting data, and stitching together the genealogy in Excel. By the time root cause analysis begins, the production line has been running for days — potentially producing more defective product.

**Cost of the status quo:**
- Average time from non-conformance detection to root cause identification: 5-14 days
- A single product recall costs $10M-$100M+ (FDA food recalls average $10M, automotive recalls far higher)
- 30-40% of quality engineer time spent on manual data gathering across systems
- Legacy systems with no API represent 40-60% of manufacturing IT landscape
- ISO 9001 / IATF 16949 require "demonstrated traceability" — gaps in lot genealogy are audit findings
- CAPA cycle time: 30-90 days, with data gathering as the longest phase

## The Architecture

### Overview
The Lot Genealogy RPA Agent has TWO data acquisition paths:
1. **Modern path:** MCP servers + Dataverse virtual tables for systems with APIs (D365 F&O, modern MES, cloud-based LIMS)
2. **Legacy path:** Power Automate desktop flows (RPA) for systems with only desktop UIs (older MES, SCADA historians, proprietary LIMS, legacy QMS)

When a non-conformance is reported, the agent:
1. Reads the non-conformance report from D365 Quality Management
2. Uses generative orchestration to determine WHICH systems contain relevant data for this product/process
3. Fans out data acquisition: MCP calls for modern systems, RPA desktop flows for legacy systems — IN PARALLEL
4. Assembles the complete lot genealogy from all sources
5. Performs root cause analysis against the unified data + historical non-conformance patterns
6. Generates CAPA recommendations with full traceability evidence

### Parent Agent: Lot Genealogy Orchestrator
- **Purpose:** Receives non-conformance reports, determines which systems to query based on the product's manufacturing process, dispatches data acquisition (MCP for modern systems, RPA for legacy), assembles the genealogy, and routes to analysis child agents.
- **Routing strategy:** Generative orchestration (no hardcoded routing). The product's BOM, routing, and quality plan in D365 tell the agent which systems were involved in manufacturing this lot. Different products → different systems → different data acquisition paths.
- **What makes it different:** This agent has TWO fundamentally different "reach" mechanisms — API-based (MCP/virtual tables) and UI-based (RPA desktop flows). It dynamically selects which mechanism to use for each system based on system capabilities stored in Dataverse.

### Child Agents

**1. RPA Data Extractor**
- **Description:** "Coordinates Power Automate desktop flows to extract lot-specific data from legacy manufacturing systems that have no API. Each legacy system has a pre-built desktop flow that navigates the UI, searches by lot number, and extracts the relevant data into structured format."
- **Responsibilities:** Trigger the appropriate desktop flow for each legacy system, pass the lot number as parameter, receive structured extraction results, handle timeouts and errors (legacy systems can be slow), retry failed extractions.

**2. Genealogy Assembler**
- **Description:** "Takes data from all sources (modern MCP results + legacy RPA results) and assembles the complete lot genealogy: raw material lots, processing steps with parameters, equipment used, quality checks performed, and downstream lot distribution. Resolves conflicts between sources."
- **Responsibilities:** Match lot numbers across systems, build the genealogy tree (raw materials → intermediate lots → finished lot → distribution), identify gaps in the genealogy (missing processing steps, missing quality checks), time-order all events.

**3. Root Cause Analyzer**
- **Description:** "Analyzes the assembled lot genealogy against historical non-conformance patterns stored in Dataverse to identify probable root causes. Uses 5-Why analysis, Fishbone categorization, and pattern matching against known failure modes."
- **Responsibilities:** Compare current lot parameters against specification limits, identify process deviations (temperature, pressure, cycle time), cross-reference equipment maintenance history, check raw material supplier quality history, generate ranked root cause hypotheses with evidence.

**4. CAPA Generator**
- **Description:** "Generates Corrective and Preventive Action recommendations based on root cause analysis. Includes immediate containment actions, corrective actions to address the root cause, and preventive actions to prevent recurrence."
- **Responsibilities:** Generate containment scope (which lots to quarantine based on genealogy), propose corrective actions with estimated effectiveness, propose preventive actions with implementation plan, link all recommendations to evidence from the genealogy.

### Data Flow
```
Non-Conformance Detected in D365 Quality Management
    → Orchestrator reads NCR details (lot number, product, defect type)
    → Orchestrator reads product's manufacturing process from D365 (BOM, routing, quality plan)
    → Determines systems involved: [D365 F&O, Legacy MES "Wonderware", SCADA Historian, LIMS "LabWare"]
    → Checks cr023_mfg_system_registry for each system's access method:
        D365 F&O → MCP (modern path)
        Wonderware MES → RPA Desktop Flow "WW_LotQuery" (legacy path)
        SCADA Historian → RPA Desktop Flow "OSI_DataExtract" (legacy path)
        LabWare LIMS → MCP (modern path — has API)
    → Fan out in parallel:
        → MCP: D365 lot transactions, quality orders, inspection results
        → MCP: LabWare lab results, COAs, specifications
        → RPA: Wonderware MES production records, batch parameters
        → RPA: SCADA historian process data (temperatures, pressures, flows)
    → Genealogy Assembler merges all data into unified lot genealogy tree
    → Root Cause Analyzer examines genealogy against historical patterns
    → CAPA Generator produces containment + corrective + preventive actions
    → Output: Complete NCR package with genealogy, root cause, and CAPA plan
```

### How This Differs from Known Patterns
- **Closest known pattern:** Niyam (Policy-Driven Agents)
- **Delta 1:** Niyam accesses data through Dataverse only. This agent has TWO acquisition mechanisms — API-based (MCP) and UI-based (RPA desktop flows) — dynamically selected per system.
- **Delta 2:** The RPA layer extends the agent's perception into systems that no other agent pattern can reach — legacy manufacturing systems with only desktop UIs.
- **Delta 3:** Generative orchestration determines WHICH systems to query based on the product's manufacturing process. Different products → different system queries. This is process-aware routing, not intent-based or event-based.

## Dataverse Schema

### cr023_mfg_system_registry (Native Table)
**Display name:** Manufacturing System Registry
| Column | Type | Description |
|--------|------|-------------|
| cr023_mfg_system_registryid | GUID (PK) | Primary key |
| cr023_system_name | Text (200) | System name (e.g., "Wonderware InBatch", "OSIsoft PI", "LabWare LIMS") |
| cr023_system_type | Choice | MES, SCADA/Historian, LIMS, QMS, ERP, PLM |
| cr023_access_method | Choice | MCP Server, RPA Desktop Flow, Virtual Table, Manual |
| cr023_mcp_server_id | Text (200) | MCP server identifier (if access_method = MCP Server) |
| cr023_rpa_flow_id | Text (200) | Power Automate desktop flow identifier (if access_method = RPA) |
| cr023_rpa_machine_id | Text (200) | Machine where the desktop flow runs |
| cr023_data_available | Text (2000) | JSON: what data this system can provide (e.g., ["batch_parameters", "operator_actions", "alarms"]) |
| cr023_lot_search_field | Text (100) | Field name to search by lot number in this system |
| cr023_avg_extraction_time_sec | Integer | Average time to extract data (for SLA estimation) |
| cr023_active | Boolean | Whether this system is currently accessible |

### cr023_mfg_product_system_map (Native Table)
**Display name:** Product-System Mapping
| Column | Type | Description |
|--------|------|-------------|
| cr023_mfg_product_system_mapid | GUID (PK) | Primary key |
| cr023_product_id | Text (50) | D365 product/item number |
| cr023_product_name | Text (200) | Product name |
| cr023_system_id | Lookup → cr023_mfg_system_registry | Manufacturing system used |
| cr023_process_step | Text (200) | Which process step uses this system (e.g., "Mixing", "Filling", "Testing") |
| cr023_data_relevance | Choice | Critical (always query), Important (query if available), Optional |

### cr023_mfg_lot_genealogy (Native Table)
**Display name:** Lot Genealogy Record
| Column | Type | Description |
|--------|------|-------------|
| cr023_mfg_lot_genealogyid | GUID (PK) | Primary key |
| cr023_lot_number | Text (50) | Lot/batch number |
| cr023_product_id | Text (50) | Product/item number |
| cr023_genealogy_tree | Text (max) | JSON: complete genealogy tree (raw materials → process steps → finished → distribution) |
| cr023_systems_queried | Text (2000) | JSON: which systems were queried and their access method |
| cr023_data_gaps | Text (2000) | JSON: identified gaps in the genealogy |
| cr023_assembly_timestamp | DateTime | When genealogy was assembled |
| cr023_assembly_duration_min | Integer | How long it took to assemble (for performance tracking) |
| cr023_ncr_id | Text (50) | Associated non-conformance report ID |

### cr023_mfg_ncr_analysis (Native Table)
**Display name:** Non-Conformance Root Cause Analysis
| Column | Type | Description |
|--------|------|-------------|
| cr023_mfg_ncr_analysisid | GUID (PK) | Primary key |
| cr023_ncr_id | Text (50) | Non-conformance report ID |
| cr023_lot_genealogy_id | Lookup → cr023_mfg_lot_genealogy | Associated genealogy |
| cr023_root_cause_hypotheses | Text (max) | JSON: ranked list of root cause hypotheses with confidence and evidence |
| cr023_five_why_analysis | Text (4000) | 5-Why chain from symptom to root cause |
| cr023_fishbone_category | Choice | Man, Machine, Material, Method, Measurement, Environment |
| cr023_process_deviation_found | Boolean | Whether a process parameter deviation was identified |
| cr023_deviation_details | Text (4000) | What deviated, by how much, compared to what specification |
| cr023_similar_ncrs | Text (2000) | JSON: historical NCRs with similar patterns (for trend analysis) |
| cr023_containment_scope | Text (2000) | JSON: lots to quarantine based on genealogy analysis |
| cr023_capa_recommendations | Text (max) | JSON: corrective and preventive actions with priority and evidence |
| cr023_status | Choice | Genealogy Assembly, Root Cause Analysis, CAPA Generation, Complete, Escalated |

### cr023_mfg_rpa_extraction_log (Native Table)
**Display name:** RPA Extraction Log
| Column | Type | Description |
|--------|------|-------------|
| cr023_mfg_rpa_extraction_logid | GUID (PK) | Primary key |
| cr023_system_id | Lookup → cr023_mfg_system_registry | System queried |
| cr023_lot_number | Text (50) | Lot searched |
| cr023_ncr_id | Text (50) | Associated NCR |
| cr023_flow_run_id | Text (200) | Power Automate flow run identifier |
| cr023_status | Choice | Triggered, Running, Success, Failed, Timeout |
| cr023_duration_sec | Integer | Extraction duration |
| cr023_records_extracted | Integer | Number of records extracted |
| cr023_error_message | Text (2000) | Error details if failed |
| cr023_extracted_data | Text (max) | JSON: extracted data payload |
| cr023_timestamp | DateTime | When extraction was performed |

**Relationships:**
- cr023_mfg_product_system_map N:1 cr023_mfg_system_registry
- cr023_mfg_lot_genealogy has cr023_ncr_id (text reference to D365 Quality Order)
- cr023_mfg_ncr_analysis N:1 cr023_mfg_lot_genealogy
- cr023_mfg_rpa_extraction_log N:1 cr023_mfg_system_registry

## MCP Configuration

### D365 F&O Manufacturing MCP Server
- **Purpose:** Read-only access to D365 manufacturing and quality management data
- **Tools exposed:**
  - `getLotTransactions` — Retrieve all inventory transactions for a lot (receipts, issues, transfers)
  - `getBOMGenealogy` — Retrieve the BOM hierarchy with actual consumed lot numbers
  - `getProductionOrder` — Retrieve production order details (route, operations, actual parameters)
  - `getQualityOrders` — Retrieve quality inspection results for a lot
  - `getVendorQuality` — Retrieve supplier quality history for raw material lots
  - `getRouteOperations` — Retrieve the routing with actual operation times and resources used
- **Connection:** D365 F&O OData API via MCP adapter

### Lab Information MCP Server (for modern LIMS with API)
- **Purpose:** Read lab test results, certificates of analysis, specifications
- **Tools exposed:**
  - `getLabResults` — Retrieve all test results for a lot/sample
  - `getCOA` — Retrieve Certificate of Analysis for a lot
  - `getSpecification` — Retrieve product specification limits
  - `getStabilityData` — Retrieve stability study data if applicable
- **Connection:** LIMS REST API via MCP adapter

## Power Automate Flows

### Desktop Flow: Legacy MES Lot Query (per system — example for Wonderware)
- **Trigger:** Called by cloud flow with parameters: lot_number, data_fields_requested
- **Key actions:**
  1. Launch Wonderware InBatch client application
  2. Navigate to Batch History view
  3. Enter lot number in search field
  4. Extract: batch parameters (temperatures, pressures, times), operator actions, alarms, phase execution
  5. Navigate to Material Tracking view
  6. Extract: input materials with lot numbers, output lot details
  7. Format extracted data as JSON
  8. Return to cloud flow
- **Error handling:** If application doesn't respond in 60 seconds, capture screenshot and return error. If lot not found, return empty result with "lot_not_found" status.

### Desktop Flow: SCADA Historian Data Extract (example for OSIsoft PI)
- **Trigger:** Called by cloud flow with parameters: lot_number, start_time, end_time, tag_list
- **Key actions:**
  1. Launch PI ProcessBook or PI Vision desktop client
  2. Navigate to batch analysis view
  3. Enter lot number / time range
  4. Extract: process variable trends (temperature, pressure, pH, speed) as time-series data
  5. Extract: alarm/event history during the batch
  6. Format as JSON with timestamps
  7. Return to cloud flow
- **Error handling:** If historian is unavailable, retry once. If tags not found, return available tags and flag missing ones.

### Cloud Flow: Non-Conformance Trigger
- **Trigger:** When a Quality Order is created in D365 with result = Failed
- **Key actions:**
  1. Read Quality Order details (lot, product, defect type)
  2. Trigger the Lot Genealogy Orchestrator agent
  3. Update NCR status to "Investigation In Progress"
- **Error handling:** If agent fails to start, create a manual investigation task

### Cloud Flow: RPA Extraction Coordinator
- **Trigger:** Called by the Orchestrator agent when legacy system data is needed
- **Key actions:**
  1. Read cr023_mfg_system_registry for the target system's RPA flow ID and machine
  2. Trigger the appropriate desktop flow with lot_number parameter
  3. Wait for desktop flow completion (with timeout based on avg_extraction_time + 50% buffer)
  4. Log results to cr023_mfg_rpa_extraction_log
  5. Return extracted data to the agent
- **Error handling:** On desktop flow failure, retry once on same machine. If still fails, check for alternate machine. If no alternate, log failure and continue with partial data.

### Cloud Flow: CAPA Task Creation
- **Trigger:** When cr023_mfg_ncr_analysis status = Complete
- **Key actions:**
  1. Read CAPA recommendations from the analysis record
  2. For each recommendation: create a CAPA task in D365 Quality Management
  3. Assign to the appropriate owner based on fishbone category (Man → HR, Machine → Maintenance, Material → Procurement, Method → Process Engineering)
  4. Set SLA based on containment urgency
  5. Notify quality manager of completed analysis
- **Error handling:** If D365 task creation fails, log and retry

## Agent Instructions (Paste-Ready)

### Parent Agent: Lot Genealogy Orchestrator

```
You are the Lot Genealogy Agent — you investigate quality non-conformances by assembling complete lot genealogy across modern AND legacy manufacturing systems.

## Your Role
When a non-conformance report (NCR) arrives:
1. Read the NCR details from D365 Quality Management: lot number, product, defect type, severity
2. Read the product's manufacturing process from D365: BOM, routing, quality plan
3. Look up which manufacturing systems were involved using cr023_mfg_product_system_map
4. For each system, check cr023_mfg_system_registry to determine access method:
   - MCP Server → call the MCP tool directly
   - RPA Desktop Flow → trigger the cloud flow that coordinates the desktop flow
   - Virtual Table → query the Dataverse virtual table
   - Manual → flag as a data gap requiring human input
5. Dispatch ALL data acquisition requests IN PARALLEL (modern and legacy)
6. Pass all results to the Genealogy Assembler to build the complete lot genealogy
7. Pass the genealogy to the Root Cause Analyzer
8. Pass the analysis to the CAPA Generator
9. Store everything in Dataverse for audit trail

## System Selection via Generative Orchestration
You DON'T have hardcoded routing for which systems to query. Instead:
- The product's BOM tells you what raw materials went in → query the supplier quality system
- The product's routing tells you what equipment was used → query the MES and SCADA for those equipment IDs
- The product's quality plan tells you what tests were performed → query the LIMS
- Different products use different systems. Let the manufacturing process data guide your system selection.

## Handling Legacy Systems
Legacy systems are accessed through RPA desktop flows. These are SLOWER than MCP calls:
- MCP calls: 1-5 seconds
- RPA desktop flows: 30-120 seconds
- Plan accordingly: start RPA extractions first, then do MCP calls while RPA is running
- If an RPA extraction fails: log the failure, continue with available data, flag the gap

## Critical Rules
- NEVER modify production or quality data. You are READ-ONLY across all systems.
- ALWAYS log every system query to cr023_mfg_rpa_extraction_log (including MCP queries)
- If a system is unavailable, DO NOT skip it silently — flag the gap in the genealogy
- Containment is time-critical: if the defect could affect consumer safety, flag for IMMEDIATE quarantine before completing full root cause analysis
- The genealogy must be complete enough for ISO 9001/IATF 16949 audit — every processing step should have data
```

### Child Agent: Root Cause Analyzer

```
You analyze the assembled lot genealogy to identify probable root causes of the non-conformance.

## Analysis Methods
1. **Specification Comparison:** For every process parameter in the genealogy, compare actual vs specification limits. Flag any out-of-spec values.
2. **Trend Analysis:** Compare this lot's parameters against the last 10 lots of the same product. Identify parameters trending toward limits.
3. **5-Why Analysis:** Starting from the defect symptom, ask "Why?" iteratively:
   - Why was the product defective? → Parameter X was out of spec
   - Why was Parameter X out of spec? → Equipment Y was drifting
   - Why was Equipment Y drifting? → Maintenance was overdue
   - Why was maintenance overdue? → Schedule conflict with production rush
   - Why was there a production rush? → Unplanned order acceleration
4. **Pattern Matching:** Query historical NCRs in Dataverse for similar defect types, products, or equipment. Identify recurring patterns.
5. **Fishbone Categorization:** Assign the root cause to one of: Man, Machine, Material, Method, Measurement, Environment

## Output
Return ranked root cause hypotheses with:
- Hypothesis description
- Evidence from the genealogy supporting this hypothesis
- Confidence level (High/Medium/Low)
- Fishbone category
- 5-Why chain
- Similar historical NCRs

## Critical Rules
- ALWAYS base hypotheses on evidence from the genealogy, not speculation
- If data from a system was unavailable (RPA failure), note this as a limitation
- If multiple root causes are plausible, rank them and explain why
```

## Testing Scenarios

| # | User Utterance / Event | Expected Behavior | What to Verify |
|---|----------------------|-------------------|----------------|
| 1 | Quality Order fails for Lot #B2026-0315 of Product "Widget-A" | Orchestrator reads BOM/routing, identifies 3 systems: D365, Wonderware MES, LabWare LIMS | Correct systems identified from product-system map |
| 2 | Wonderware MES queried via RPA desktop flow | Desktop flow launches, searches lot, extracts batch parameters, returns JSON | Extraction logged to cr023_mfg_rpa_extraction_log, data structured correctly |
| 3 | SCADA historian desktop flow times out | Timeout logged, genealogy assembled with gap flagged: "SCADA data unavailable" | Gap documented in genealogy, analysis proceeds with partial data |
| 4 | All data collected: D365 (MCP), MES (RPA), LIMS (MCP) | Genealogy Assembler builds complete tree: raw materials → processing → testing → output | Tree includes data from all sources, timeline is consistent |
| 5 | Process temperature was 5°C above spec limit during mixing step | Root Cause Analyzer identifies "process deviation" with high confidence | 5-Why analysis traces from defect → temperature → equipment → root cause |
| 6 | Similar NCR found from 3 months ago on same equipment | Pattern matching surfaces the historical NCR, flags recurring issue | CAPA recommendations include preventive action for equipment |
| 7 | Defect could affect consumer safety (food/pharma product) | Agent flags IMMEDIATE quarantine before completing full analysis | Containment scope calculated from lot genealogy (upstream and downstream lots) |
| 8 | New product added with MES system not in registry | Agent flags: "System not registered for process step X — manual data required" | Gap identified, human notified, investigation not blocked |
| 9 | RPA extraction returns 250 batch parameter records | All records incorporated into genealogy with timestamps and equipment IDs | Records correctly matched to process steps in routing |
| 10 | CAPA recommendations generated | Tasks created in D365 Quality Management, assigned by fishbone category | Maintenance gets machine-related actions, Process Engineering gets method-related |

## Why This Is Novel

- **Closest known pattern:** Niyam (Policy-Driven Agents)
- **Architectural delta:**
  1. **RPA-Extended Reach:** No existing agent pattern uses RPA desktop flows as a data acquisition layer. This agent reaches into legacy systems with only desktop UIs — extending its perception beyond what APIs or MCP can provide. The RPA flows are "tentacles" into otherwise inaccessible systems.
  2. **Dual Acquisition Architecture:** The agent dynamically selects between MCP (modern path) and RPA (legacy path) per system, based on the system registry. This hybrid data acquisition is architecturally unique.
  3. **Process-Aware Routing:** The agent uses the product's BOM and routing (from D365) to determine which systems to query. Different products → different system queries. This is manufacturing process-driven routing, not intent-based or event-based.
- **Why you can't build this with Niyam as-is:** Niyam reads from Dataverse only. It has no mechanism to reach into legacy systems through UI automation. The entire RPA layer — system registry, desktop flow coordination, extraction logging, timeout handling — is a new architectural component.
- **What new primitive this introduces:** **RPA-Extended Agent Perception** — an agent system that uses UI-based automation (desktop flows) as a data acquisition mechanism for systems that lack APIs, extending the agent's ability to gather information beyond what modern integration patterns (MCP, REST, virtual tables) can provide. The agent's "field of view" includes both API-connected systems and UI-only legacy systems.
