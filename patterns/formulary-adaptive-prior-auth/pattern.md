# Formulary-Adaptive Prior Authorization Agent
> Agent dynamically discovers and chains PA workflow skills from Dataverse based on drug, payer, and formulary context — data-driven orchestration, not hardcoded workflows.

## The Problem
**Vertical:** Healthcare — Pharmacy Benefits / Health Plans
**Role:** Prior Authorization Specialist, Prescribing Physician, Pharmacy Benefits Manager
**Daily frustration:** Physicians and their staff complete 43 prior authorization requests per week, spending 13-16 hours filling out forms, waiting on hold, and appealing denials. Each PA request requires navigating a different maze of requirements depending on the drug, the payer, the formulary tier, and the patient's step therapy history. Staff manually look up which criteria to check, which forms to fill, which alternatives to propose. It's a combinatorial nightmare: 50+ payers x 1000s of drugs x varying formulary tiers x step therapy requirements = tens of thousands of unique PA pathways.

**Cost of the status quo:**
- 89% of physicians report PA increases burnout
- 87% say PA increases (not decreases) overall healthcare costs through delays and workarounds
- 80% of physicians report patients pay out of pocket due to PA delays
- 34% of insured adults say PA is the single biggest non-cost barrier to care
- Average PA processing: 2-14 days, during which patients go without treatment
- Prior authorization was ranked as the #1 barrier to healthcare access after cost (2026)

## The Architecture

### Overview
Instead of hardcoding PA workflows for every drug-payer-tier combination (impossible to maintain) or relying on the LLM to "figure out" the right steps (unreliable in regulated healthcare), this pattern stores every PA workflow step as a **business skill** in `msdyn_businessskill` with structured dependency metadata. When a PA request arrives, the agent:

1. Reads the drug, payer, and patient context
2. Queries Dataverse for all applicable skills (filtered by drug class, payer, formulary tier)
3. Reads each skill's prerequisite and dependency metadata
4. Assembles a **dynamic execution chain** — the specific sequence of checks and actions needed for THIS PA request
5. Executes the chain, with conditional branching based on intermediate results

The workflow is **emergent from the data**, not reasoned by the LLM or hardcoded by developers.

### Parent Agent: PA Orchestrator
- **Purpose:** Receives PA requests (from a physician's EHR, a pharmacy system, or a patient portal), identifies the drug/payer/patient context, discovers applicable skills from Dataverse, assembles the execution chain, and delegates execution to the Worker Agent.
- **Routing strategy:** Skill-chain routing. The parent discovers skills, resolves their dependency graph into an execution order, and feeds each step to the Worker Agent sequentially, passing intermediate results forward.
- **What makes it different:** Unlike Niyam Worker V2 (which discovers skills but executes them independently), this parent builds a WORKFLOW from skill metadata. Unlike Semantic Kernel planners (which use LLM reasoning), this parent reads STRUCTURED dependency data. The plan is deterministic and auditable.

### Child Agent: PA Worker
- **Description (paste-ready):** "Executes individual prior authorization workflow steps as instructed by the PA Orchestrator. Each step is a business skill discovered from Dataverse. The Worker receives the skill definition, the patient/drug context, and any results from prior steps, then executes the skill and returns structured results."
- **Responsibilities:** Execute formulary lookups, check step therapy prerequisites, evaluate clinical criteria against patient records, generate PA submission forms, compose appeal letters, recommend therapeutic alternatives.

### Data Flow
```
PA Request arrives (drug, payer, patient context)
    → PA Orchestrator reads drug class, payer ID, formulary tier
    → Query msdyn_businessskill WHERE drug_class AND payer AND tier match
    → Returns N applicable skills with dependency metadata
    → Orchestrator resolves dependency graph into execution chain:
        Step 1: Check Formulary Coverage (no prerequisites)
        Step 2: Check Step Therapy History (requires: formulary result)
        Step 3: Evaluate Clinical Criteria (requires: step therapy result)
        Step 4: Generate PA Submission OR Recommend Alternative (requires: clinical criteria result)
    → Worker Agent executes each step in order
    → If Step 2 shows step therapy not met → branch to "Recommend Alternative" skill
    → If Step 3 shows clinical criteria met → branch to "Generate PA Submission" skill
    → Final output: PA submission package OR alternative recommendation with rationale
```

### How This Differs from Known Patterns
- **Closest known pattern:** Niyam Worker V2 (Microsoft Business Skills + Niyam Governance)
- **Delta 1:** Niyam Worker V2 discovers skills and executes them independently (one skill per task). This pattern discovers skills AND chains them into a dynamic workflow based on dependency metadata.
- **Delta 2:** Niyam Worker V2 has no concept of skill prerequisites or ordering. This pattern adds structured dependency columns to `msdyn_businessskill` that encode "this skill requires the output of skill X before it can run."
- **Delta 3:** This pattern includes conditional branching — the output of one skill determines which skill runs next. In Niyam Worker V2, the parent decides what to do; here, the skill metadata + intermediate results jointly determine the path.

## Dataverse Schema

### Extended msdyn_businessskill columns (added to Microsoft's first-party table)
| Column | Type | Description |
|--------|------|-------------|
| cr023_pa_drug_class | Text (200) | Drug class this skill applies to (e.g., "biologics", "specialty-oncology") |
| cr023_pa_payer_ids | Text (2000) | Comma-separated payer IDs this skill applies to, or "ALL" |
| cr023_pa_formulary_tier | Choice | Tier 1 (Generic), Tier 2 (Preferred Brand), Tier 3 (Non-Preferred), Tier 4 (Specialty), ALL |
| cr023_pa_skill_type | Choice | Formulary Check, Step Therapy Check, Clinical Criteria Check, PA Submission, Alternative Recommendation, Appeal Generation |
| cr023_pa_prerequisites | Text (2000) | Comma-separated skill IDs that must complete before this skill can run |
| cr023_pa_branch_condition | Text (1000) | Condition on prior skill output that activates this skill (e.g., "step_therapy_met=false") |
| cr023_pa_output_schema | Text (4000) | JSON schema describing what this skill produces (for downstream skills to consume) |
| cr023_pa_priority | Integer | Execution priority when multiple skills have same prerequisites (lower = first) |
| cr023_pa_active | Boolean | Whether this skill is currently active |
| cr023_pa_version | Integer | Skill version for change tracking |

### cr023_pa_payer_formulary
**Display name:** Payer Formulary Configuration
| Column | Type | Description |
|--------|------|-------------|
| cr023_pa_payer_formularyid | GUID (PK) | Primary key |
| cr023_payer_id | Text (50) | Payer identifier (e.g., "BCBS-IL", "AETNA-COMM") |
| cr023_payer_name | Text (200) | Payer display name |
| cr023_formulary_name | Text (200) | Formulary name/version |
| cr023_formulary_effective_date | DateTime | When this formulary version became active |
| cr023_pa_turnaround_sla | Choice | 24 Hours (Urgent), 72 Hours, 7 Days, 14 Days |
| cr023_electronic_pa_supported | Boolean | Whether payer accepts electronic PA (ePA) |
| cr023_epa_endpoint | Text (500) | ePA submission endpoint URL |
| cr023_appeal_process_type | Choice | Internal Review, External Review, Peer-to-Peer, Written Only |
| cr023_formulary_document_url | Text (500) | Link to payer's formulary document |

### cr023_pa_request
**Display name:** Prior Authorization Request
| Column | Type | Description |
|--------|------|-------------|
| cr023_pa_requestid | GUID (PK) | Primary key |
| cr023_patient_id | Text (50) | Patient MRN or identifier |
| cr023_patient_name | Text (200) | Patient name |
| cr023_prescriber_npi | Text (10) | Prescribing physician NPI |
| cr023_prescriber_name | Text (200) | Prescribing physician name |
| cr023_drug_ndc | Text (11) | National Drug Code |
| cr023_drug_name | Text (200) | Drug name and strength |
| cr023_drug_class | Text (200) | Therapeutic drug class |
| cr023_payer_id | Lookup → cr023_pa_payer_formulary | Payer/formulary |
| cr023_diagnosis_icd10 | Text (20) | Primary diagnosis ICD-10 code |
| cr023_diagnosis_description | Text (500) | Diagnosis description |
| cr023_status | Choice | Received, Skill Chain Assembled, In Progress, Submitted to Payer, Approved, Denied, Appeal Filed, Alternative Recommended |
| cr023_skill_chain | Text (4000) | JSON array of skill IDs in execution order (assembled by Orchestrator) |
| cr023_current_step | Integer | Current step in the chain (0-indexed) |
| cr023_step_results | Text (max) | JSON object of intermediate results from each step |
| cr023_final_outcome | Choice | Approved, Denied, Alternative Accepted, Appeal Pending, Escalated to Human |
| cr023_pa_submission_id | Text (100) | Payer's PA reference number (after submission) |
| cr023_created_on | DateTime | When request was received |
| cr023_completed_on | DateTime | When final outcome was determined |
| cr023_total_processing_minutes | Integer | End-to-end processing time |

### cr023_pa_step_therapy_history
**Display name:** Patient Step Therapy History
| Column | Type | Description |
|--------|------|-------------|
| cr023_pa_step_therapy_historyid | GUID (PK) | Primary key |
| cr023_patient_id | Text (50) | Patient identifier |
| cr023_drug_class | Text (200) | Drug class |
| cr023_drug_tried | Text (200) | Drug name that was tried |
| cr023_start_date | DateTime | When patient started this drug |
| cr023_end_date | DateTime | When patient stopped (null if current) |
| cr023_duration_days | Integer | How long patient was on this drug |
| cr023_outcome | Choice | Effective, Ineffective, Adverse Reaction, Contraindicated, Insurance Changed |
| cr023_prescriber_npi | Text (10) | Prescriber who ordered this therapy |
| cr023_documented_in_ehr | Boolean | Whether this is documented in the patient's EHR |
| cr023_evidence_source | Choice | EHR Import, Patient Report, Pharmacy Claims, Manual Entry |

### cr023_pa_clinical_criterion
**Display name:** PA Clinical Criterion
| Column | Type | Description |
|--------|------|-------------|
| cr023_pa_clinical_criterionid | GUID (PK) | Primary key |
| cr023_payer_id | Lookup → cr023_pa_payer_formulary | Payer |
| cr023_drug_class | Text (200) | Drug class |
| cr023_criterion_name | Text (200) | e.g., "Lab HbA1c >= 7.0 within 90 days" |
| cr023_criterion_type | Choice | Lab Value, Diagnosis, Prior Treatment, Age, Weight, Specialist Attestation |
| cr023_criterion_expression | Text (1000) | Machine-readable criterion (e.g., "lab.HbA1c >= 7.0 AND lab.date >= today-90d") |
| cr023_criterion_description | Text (2000) | Human-readable description |
| cr023_required | Boolean | Whether this criterion is mandatory or supporting |
| cr023_evidence_required | Choice | Lab Report, Clinical Note, Prescription History, Specialist Letter, None |

**Relationships:**
- msdyn_businessskill extended with cr023_pa_* columns (polymorphic — skills work for PA and other domains)
- cr023_pa_request N:1 cr023_pa_payer_formulary
- cr023_pa_clinical_criterion N:1 cr023_pa_payer_formulary
- cr023_pa_step_therapy_history is standalone (patient-level, cross-request)

## MCP Configuration

### Pharmacy Benefits MCP Server
- **Purpose:** Read-only access to formulary data, drug information, and pharmacy claims
- **Tools exposed:**
  - `getFormularyStatus` — Check if a drug is on formulary for a specific payer, return tier and PA requirements
  - `getDrugAlternatives` — Get therapeutic alternatives for a drug within the same class, ranked by formulary tier
  - `getStepTherapyCriteria` — Get step therapy prerequisites for a drug-payer combination
  - `getPatientPharmacyClaims` — Retrieve patient's prescription fill history (for step therapy verification)
  - `getDrugInteractions` — Check for drug-drug interactions with patient's current medications
- **Connection:** MCP remote server (Streamable HTTP) connecting to PBM/pharmacy data warehouse
- **Usage:** Skills call these tools during chain execution to get real-time formulary and claims data

### EHR Clinical Data MCP Server
- **Purpose:** Read-only access to patient clinical records for criteria verification
- **Tools exposed:**
  - `getPatientLabResults` — Retrieve lab values by type and date range
  - `getPatientDiagnoses` — Retrieve active diagnoses with ICD-10 codes
  - `getPatientMedications` — Retrieve current medication list
  - `getPatientAllergies` — Retrieve allergy and adverse reaction history
  - `getClinicalNotes` — Retrieve relevant clinical notes (filtered by diagnosis/drug)
- **Connection:** MCP remote server via HL7 FHIR R4 API
- **Usage:** Clinical Criteria Check skills use these tools to verify patient meets payer requirements

### ePA Submission MCP Server
- **Purpose:** Submit electronic prior authorization requests to payers
- **Tools exposed:**
  - `submitPA` — Submit a PA request to a payer's ePA endpoint with all supporting documentation
  - `checkPAStatus` — Check the status of a submitted PA
  - `submitAppeal` — Submit an appeal with additional clinical evidence
  - `getPARequirements` — Get payer-specific PA form requirements
- **Connection:** NCPDP SCRIPT ePA standard via MCP adapter
- **Usage:** PA Submission and Appeal Generation skills use these tools for the final submission step

## Power Automate Flows

### Flow 1: PA Request Intake
- **Trigger:** When a row is added to cr023_pa_request with status = Received
- **Key actions:**
  1. Read the PA request details (drug, payer, patient)
  2. Trigger the PA Orchestrator agent with the request context
  3. Update cr023_pa_request status to "Skill Chain Assembled" once the Orchestrator responds with the chain
  4. Begin chain execution tracking
- **Error handling:** If Orchestrator fails to assemble a chain (no matching skills), set status to "Escalated to Human" and notify PA staff

### Flow 2: PA SLA Timer
- **Trigger:** When cr023_pa_request is created
- **Key actions:**
  1. Read the payer's PA turnaround SLA from cr023_pa_payer_formulary
  2. Set a timer for 80% of the SLA (early warning)
  3. If timer fires and status is still "In Progress": send alert to PA supervisor
  4. Set a timer for 100% of the SLA
  5. If timer fires and status is not "Submitted to Payer" or "Approved": escalate to manual processing
- **Error handling:** Log SLA breaches to a reporting table for payer performance tracking

### Flow 3: PA Outcome Notification
- **Trigger:** When cr023_pa_request status changes to Approved, Denied, or Alternative Recommended
- **Key actions:**
  1. Compose notification with outcome, rationale, and next steps
  2. If Approved: notify prescriber and pharmacy, include PA reference number
  3. If Denied: notify prescriber with denial reason, include appeal deadline and recommended evidence
  4. If Alternative Recommended: notify prescriber with alternative drug, formulary tier, and clinical rationale
  5. Update cr023_total_processing_minutes with elapsed time
- **Error handling:** Retry notification delivery; log to notification failure table

### Flow 4: Skill Chain Analytics (Weekly)
- **Trigger:** Recurrence — every Monday 06:00 UTC
- **Key actions:**
  1. Query all PA requests completed in the past 7 days
  2. Calculate: avg processing time, approval rate, denial rate, alternative recommendation rate
  3. Group by payer: identify payers with highest denial rates
  4. Group by drug class: identify drug classes with most PA friction
  5. Identify skill chain patterns: which chains are most common, which steps cause most failures
  6. Generate analytics report for PA leadership
- **Error handling:** If query times out, partition by day and aggregate

## Agent Instructions (Paste-Ready)

### Parent Agent: PA Orchestrator

```
You are the Prior Authorization Orchestrator — you transform prior authorization requests into dynamic skill chains by discovering and assembling applicable PA workflow skills from Dataverse.

## Your Role
When a PA request arrives, you:
1. Read the request context: drug (NDC, name, class), payer (ID, formulary), patient (diagnoses, current meds)
2. Query msdyn_businessskill for all active skills where:
   - cr023_pa_drug_class matches the request drug class (or is "ALL")
   - cr023_pa_payer_ids contains the request payer ID (or is "ALL")
   - cr023_pa_formulary_tier matches the drug's tier on this payer's formulary (or is "ALL")
   - cr023_pa_active = true
3. Resolve the dependency graph:
   - Skills with no cr023_pa_prerequisites go first
   - For each subsequent skill, check that all prerequisite skills are already in the chain
   - Apply cr023_pa_branch_condition to determine conditional paths
   - Use cr023_pa_priority to break ties
4. Output the assembled skill chain as a JSON array in cr023_pa_request.cr023_skill_chain
5. Execute the chain by passing each skill definition + context + prior step results to the PA Worker agent

## Skill Chain Assembly Rules
- ALWAYS start with a Formulary Check skill (type = "Formulary Check")
- Step Therapy Check skills require Formulary Check output
- Clinical Criteria Check skills require Step Therapy Check output
- PA Submission skills require Clinical Criteria Check output with criteria_met = true
- Alternative Recommendation skills activate when step_therapy_met = false OR criteria_met = false
- Appeal Generation skills activate when PA status = Denied

## Conditional Branching
When a skill produces output, evaluate the branch conditions of downstream skills:
- If cr023_pa_branch_condition = "step_therapy_met=false", only include this skill if the Step Therapy Check returned step_therapy_met = false
- If cr023_pa_branch_condition = "criteria_met=true", only include this skill if the Clinical Criteria Check returned criteria_met = true
- If no branch condition is set, always include the skill (it's on the default path)

## Critical Rules
- NEVER skip the Formulary Check — it's always the first step
- NEVER submit a PA without verifying all clinical criteria have been checked
- If no skills match the request context, DO NOT guess — escalate to human with the message: "No PA workflow skills found for [drug class] + [payer]. Manual processing required."
- Log every chain assembly decision for audit trail
- Include the payer's specific PA form requirements in the submission step context
```

### Child Agent: PA Worker

```
You execute individual prior authorization workflow steps as directed by the PA Orchestrator.

## Your Role
You receive:
1. A skill definition from msdyn_businessskill (name, description, output schema)
2. The PA request context (drug, payer, patient)
3. Results from any prior steps in the chain

You execute the skill and return structured results matching the skill's cr023_pa_output_schema.

## Skill Types You Execute

### Formulary Check
- Call getFormularyStatus with the drug NDC and payer ID
- Return: { on_formulary: bool, tier: string, pa_required: bool, step_therapy_required: bool, quantity_limit: string }

### Step Therapy Check
- Call getStepTherapyCriteria for this drug-payer combination
- Call getPatientPharmacyClaims to check patient's prescription history
- Cross-reference: has the patient tried all prerequisite drugs for the required duration?
- Return: { step_therapy_met: bool, steps_completed: [...], steps_remaining: [...], evidence: [...] }

### Clinical Criteria Check
- Read cr023_pa_clinical_criterion records for this payer + drug class
- For each criterion:
  - If type = Lab Value: call getPatientLabResults and compare against criterion_expression
  - If type = Diagnosis: call getPatientDiagnoses and check for matching ICD-10
  - If type = Prior Treatment: check step therapy results from prior step
  - If type = Specialist Attestation: flag as "requires human input"
- Return: { criteria_met: bool, criteria_results: [{name, met, evidence}], missing_criteria: [...] }

### PA Submission
- Compile all evidence from prior steps (formulary status, step therapy evidence, clinical criteria evidence)
- Call getPARequirements to get payer-specific form fields
- Call submitPA with the compiled PA package
- Return: { submitted: bool, pa_reference_id: string, expected_response_date: date }

### Alternative Recommendation
- Call getDrugAlternatives for the requested drug class
- Filter to alternatives on the payer's formulary at a preferred tier
- Check for drug interactions with patient's current medications
- Return: { alternatives: [{drug_name, tier, pa_required, interaction_risk, rationale}] }

## Critical Rules
- ALWAYS use real data from MCP tools — never fabricate clinical values
- ALWAYS return structured output matching the skill's output schema
- If a clinical criterion requires human input (e.g., specialist attestation), return it as "pending_human" — never assume it's met
- Include specific evidence (lab values with dates, prescription fill dates, diagnosis codes) in every result
```

## Testing Scenarios

| # | User Utterance / Event | Expected Behavior | What to Verify |
|---|----------------------|-------------------|----------------|
| 1 | PA request for Humira (adalimumab), BCBS payer, Tier 4 | Orchestrator assembles chain: Formulary Check → Step Therapy Check → Clinical Criteria → PA Submission | Chain includes all 4 steps, payer-specific criteria loaded |
| 2 | Patient has NOT tried methotrexate first (step therapy prerequisite for Humira) | Step Therapy Check returns step_therapy_met=false → branch to Alternative Recommendation | Alternative Recommendation skill activates, suggests methotrexate |
| 3 | Patient HAS completed step therapy, meets all clinical criteria | Full chain executes → PA Submission skill fires → ePA submission | PA submitted with all evidence compiled, reference ID returned |
| 4 | PA request for a generic drug (Tier 1, no PA required) | Formulary Check returns pa_required=false → chain terminates early | No further skills execute, status set to "Approved" |
| 5 | PA request for a drug with no matching skills in Dataverse | Orchestrator escalates to human: "No PA workflow skills found" | Status set to "Escalated to Human", notification sent to PA staff |
| 6 | PA submitted and denied by payer | Appeal Generation skill activates → compiles additional evidence → submits appeal | Appeal includes denial reason + additional clinical evidence |
| 7 | PA SLA at 80% with request still in progress | Flow 2 fires early warning to PA supervisor | Supervisor receives notification with request details and elapsed time |
| 8 | New payer added to system with unique PA requirements | Admin creates new skills in msdyn_businessskill with payer-specific criteria | Next PA for this payer automatically discovers and chains the new skills |
| 9 | Drug class requires specialist attestation criterion | Clinical Criteria Check returns "pending_human" for that criterion | Orchestrator pauses chain and notifies prescriber for attestation |
| 10 | Weekly analytics run | Flow 4 generates report: avg processing time, approval rates by payer, most-used chains | Report shows data-driven insights for PA process optimization |

## Why This Is Novel

- **Closest known pattern:** Niyam Worker V2 (Microsoft Business Skills + Niyam Governance)
- **Architectural delta:**
  1. **Skill chaining:** Niyam Worker V2 discovers skills and executes them one at a time, independently. This pattern discovers skills AND chains them into a dependent sequence where each skill's output feeds the next.
  2. **Dependency metadata:** Skills in `msdyn_businessskill` have prerequisite and branch condition columns that encode workflow logic. The workflow graph is stored in data, not in code or prompts.
  3. **Conditional branching:** The output of one skill determines which skills run next. This creates dynamic, context-sensitive workflows that adapt to each PA request.
- **Why you can't build this with Niyam Worker V2 as-is:** V2 has no concept of skill ordering, prerequisites, or branching. Each skill is treated as independent. To support PA workflows where Step Therapy must complete before Clinical Criteria (and the criteria themselves vary by step therapy outcome), you need the dependency graph primitive.
- **What new primitive this introduces:** **Data-Driven Skill Chaining** — workflow orchestration where the execution plan is assembled at runtime from structured skill metadata (prerequisites, branch conditions, output schemas) rather than being hardcoded in prompts or reasoned by the LLM. This is more reliable than LLM-planned orchestration (Semantic Kernel planners) because the plan is deterministic and auditable, and more flexible than static multi-agent routing because the workflow adapts to the specific request context.
