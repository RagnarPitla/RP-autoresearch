# Clinical Trial Compliance Sentinel
> Autonomous agent that monitors clinical trial data events in real-time, fans out to multi-dimensional Part 11 compliance checks, and adapts scrutiny per site risk profile.

## The Problem
**Vertical:** Healthcare / Pharmaceutical — Clinical Trials
**Role:** Clinical Operations Director, Quality Assurance Manager, Regulatory Affairs Lead
**Daily frustration:** Protocol deviations are discovered weeks or months after they occur — during monitoring visits, data review cycles, or worse, during FDA inspections. By then, the damage is done: corrupted data, invalid trial arms, costly re-work, or regulatory action. Current compliance checking is batch-oriented (periodic reviews) and human-dependent (monitors visiting sites). No one is watching the data 24/7.

**Cost of the status quo:**
- A single major protocol deviation can invalidate an entire trial arm ($10M-$100M+ lost)
- FDA 483 observations for Part 11 non-compliance trigger consent decree risk
- Average time from deviation occurrence to detection: 14-45 days
- Manual compliance review consumes 30-40% of clinical operations staff time

## The Architecture

### Overview
The Sentinel is an **event-driven, autonomous multi-agent system** that activates on every clinical data event (new CRF submission, e-signature, data modification, visit completion) without any user initiation. It fans out each event to multiple specialized compliance validators simultaneously, accumulates findings into a per-site risk profile, and adapts its scrutiny intensity based on the site's compliance trajectory.

### Parent Agent: Compliance Sentinel Orchestrator
- **Purpose:** Receives autonomous trigger events from Dataverse, classifies the event type, fans out to the appropriate set of child validators, aggregates findings, and updates the site risk profile.
- **Routing strategy:** Event-type routing (not intent-based). The trigger event's metadata determines which child agents activate. Multiple child agents can fire for a single event.
- **What makes it different:** Unlike standard Copilot Studio multi-agent (user says something → route to one child), this agent activates WITHOUT user input and routes to MULTIPLE children per event. The fan-out is the key architectural difference.

### Child Agents

**1. Audit Trail Watchdog**
- **Description (paste-ready for routing):** "Validates that every data modification in the clinical trial has a complete audit trail meeting FDA 21 CFR Part 11 requirements — including who made the change, when, why, and that the original value is preserved. Activates on any data modification event."
- **Responsibilities:** Verify audit trail completeness (who/when/why/original value), check that modifications include reason codes, validate timestamps are system-generated (not user-editable), flag backdated entries.

**2. E-Signature Validator**
- **Description:** "Verifies that electronic signatures on clinical trial documents meet FDA 21 CFR Part 11 requirements — signer identity verification, signature meaning, date/time stamp, and link to the signed record. Activates on any e-signature event."
- **Responsibilities:** Validate signer credentials match authorized personnel list, verify signature meaning is recorded (approval, review, responsibility), confirm date/time is system-generated, check signature-to-record binding integrity.

**3. Protocol Conformity Checker**
- **Description:** "Compares incoming clinical data against protocol-defined rules stored in Dataverse — visit windows, dosage ranges, lab value thresholds, inclusion/exclusion criteria, required assessments. Activates on CRF submission or visit completion events."
- **Responsibilities:** Check visit timing against protocol windows (+/- allowed days), validate dosage against protocol-defined ranges, verify all required assessments were performed, flag inclusion/exclusion criteria violations in ongoing subjects.

**4. Data Integrity Sentinel**
- **Description:** "Monitors data patterns for integrity issues — duplicate records, out-of-sequence entries, bulk modifications suggesting data fabrication, and access by unauthorized roles. Activates on batch data events or anomaly detection triggers."
- **Responsibilities:** Detect duplicate subject entries, flag out-of-sequence timestamps, identify bulk modifications by a single user in a short window, verify data access against role-based permissions.

### Data Flow
```
Dataverse Event (new CRF, e-sig, data mod)
    → Autonomous Trigger fires
    → Sentinel Orchestrator classifies event type
    → Fan-out to 1-4 child validators (parallel)
    → Each child reads event data + protocol rules from Dataverse
    → Each child produces a Finding (clean/minor/major/critical)
    → Orchestrator aggregates findings
    → Updates Site Risk Profile (cr023_ct_site_risk)
    → If critical/major → Power Automate escalation flow
    → If adaptive scrutiny threshold crossed → adjusts monitoring intensity
```

### How This Differs from Known Patterns
- **Closest known pattern:** Niyam (policy-driven agents)
- **Delta 1:** Niyam is user-initiated; Sentinel is event-driven via autonomous triggers. No human asks "check compliance" — the system watches continuously.
- **Delta 2:** Niyam routes to one child per query; Sentinel fans out to multiple validators per event simultaneously.
- **Delta 3:** Sentinel accumulates findings into an adaptive risk profile that changes the agent's own behavior (scrutiny intensity). Niyam policies are static — they don't evolve based on the agent's prior findings.

## Dataverse Schema

### cr023_ct_protocol_rule
**Display name:** Clinical Trial Protocol Rule
| Column | Type | Description |
|--------|------|-------------|
| cr023_ct_protocol_ruleid | GUID (PK) | Primary key |
| cr023_name | Text (200) | Rule name (e.g., "Visit 3 Window") |
| cr023_trial_id | Lookup → cr023_ct_trial | Associated clinical trial |
| cr023_rule_category | Choice | Visit Window, Dosage Range, Lab Threshold, Required Assessment, Inclusion Criteria, Exclusion Criteria |
| cr023_rule_expression | Text (2000) | Machine-readable rule (e.g., "visit_day >= 28 AND visit_day <= 35") |
| cr023_rule_description | Text (4000) | Human-readable explanation |
| cr023_severity_if_violated | Choice | Minor, Major, Critical |
| cr023_applies_to_visit | Text (100) | Comma-separated visit codes (e.g., "V3,V4,V5") or "ALL" |
| cr023_active | Boolean | Whether this rule is currently enforced |
| cr023_version | Integer | Rule version for change tracking |
| cr023_effective_date | DateTime | When this rule version became active |

### cr023_ct_trial
**Display name:** Clinical Trial
| Column | Type | Description |
|--------|------|-------------|
| cr023_ct_trialid | GUID (PK) | Primary key |
| cr023_name | Text (200) | Trial identifier (e.g., "ONCO-2026-001") |
| cr023_protocol_number | Text (50) | Protocol number |
| cr023_sponsor | Text (200) | Sponsoring organization |
| cr023_phase | Choice | Phase I, Phase II, Phase III, Phase IV |
| cr023_therapeutic_area | Text (200) | e.g., "Oncology", "Cardiology" |
| cr023_status | Choice | Active, Enrolling, Closed, Suspended |
| cr023_irb_approval_date | DateTime | IRB/EC approval date |
| cr023_total_sites | Integer | Number of active sites |

### cr023_ct_site_risk
**Display name:** Clinical Trial Site Risk Profile
| Column | Type | Description |
|--------|------|-------------|
| cr023_ct_site_riskid | GUID (PK) | Primary key |
| cr023_trial_id | Lookup → cr023_ct_trial | Associated trial |
| cr023_site_number | Text (50) | Site identifier |
| cr023_site_name | Text (200) | Site name |
| cr023_principal_investigator | Text (200) | PI name |
| cr023_risk_score | Decimal (0-100) | Current composite risk score |
| cr023_risk_tier | Choice | Green (0-25), Yellow (26-50), Orange (51-75), Red (76-100) |
| cr023_scrutiny_level | Choice | Standard, Enhanced, Intensive |
| cr023_total_events_monitored | Integer | Total events processed by Sentinel |
| cr023_total_findings | Integer | Total findings generated |
| cr023_critical_findings | Integer | Critical findings count |
| cr023_major_findings | Integer | Major findings count |
| cr023_last_event_timestamp | DateTime | Last event processed |
| cr023_last_risk_recalculation | DateTime | When risk score was last updated |
| cr023_trend | Choice | Improving, Stable, Declining |

### cr023_ct_compliance_finding
**Display name:** Clinical Trial Compliance Finding
| Column | Type | Description |
|--------|------|-------------|
| cr023_ct_compliance_findingid | GUID (PK) | Primary key |
| cr023_trial_id | Lookup → cr023_ct_trial | Associated trial |
| cr023_site_risk_id | Lookup → cr023_ct_site_risk | Associated site risk profile |
| cr023_finding_type | Choice | Audit Trail Gap, E-Signature Violation, Protocol Deviation, Data Integrity Issue |
| cr023_severity | Choice | Minor, Major, Critical |
| cr023_status | Choice | Open, Under Review, Confirmed, Remediated, False Positive |
| cr023_detected_by | Choice | Audit Trail Watchdog, E-Signature Validator, Protocol Conformity Checker, Data Integrity Sentinel |
| cr023_trigger_event_id | Text (200) | ID of the Dataverse event that triggered detection |
| cr023_description | Text (4000) | What was found |
| cr023_evidence | Text (4000) | Specific data points supporting the finding |
| cr023_rule_violated | Lookup → cr023_ct_protocol_rule | Which rule was violated (if applicable) |
| cr023_recommended_action | Text (2000) | What the reviewer should do |
| cr023_detected_timestamp | DateTime | When Sentinel detected this |
| cr023_reviewed_by | Lookup → systemuser | Who reviewed the finding |
| cr023_reviewed_timestamp | DateTime | When reviewed |
| cr023_resolution_notes | Text (4000) | How it was resolved |

### cr023_ct_authorized_signer
**Display name:** Clinical Trial Authorized Signer
| Column | Type | Description |
|--------|------|-------------|
| cr023_ct_authorized_signerid | GUID (PK) | Primary key |
| cr023_trial_id | Lookup → cr023_ct_trial | Associated trial |
| cr023_site_risk_id | Lookup → cr023_ct_site_risk | Associated site |
| cr023_user_id | Lookup → systemuser | Dataverse user |
| cr023_signer_role | Choice | Principal Investigator, Sub-Investigator, Study Coordinator, Data Manager, Pharmacist |
| cr023_authorized_signature_types | Text (500) | Comma-separated: "approval,review,responsibility" |
| cr023_credential_verification_date | DateTime | Last credential verification |
| cr023_active | Boolean | Currently authorized |

### cr023_ct_scrutiny_policy
**Display name:** Clinical Trial Scrutiny Policy
| Column | Type | Description |
|--------|------|-------------|
| cr023_ct_scrutiny_policyid | GUID (PK) | Primary key |
| cr023_scrutiny_level | Choice | Standard, Enhanced, Intensive |
| cr023_check_audit_trail | Boolean | Run audit trail checks |
| cr023_check_esignature | Boolean | Run e-signature checks |
| cr023_check_protocol | Boolean | Run protocol conformity checks |
| cr023_check_data_integrity | Boolean | Run data integrity checks |
| cr023_sample_rate | Decimal (0-1) | Fraction of events to check (1.0 = all, 0.25 = 25%) |
| cr023_escalation_threshold_critical | Integer | # critical findings before auto-escalation |
| cr023_escalation_threshold_major | Integer | # major findings before auto-escalation |
| cr023_risk_score_trigger_up | Decimal | Risk score that triggers upgrade to next scrutiny level |
| cr023_risk_score_trigger_down | Decimal | Risk score that triggers downgrade |

**Relationships:**
- cr023_ct_protocol_rule N:1 cr023_ct_trial
- cr023_ct_site_risk N:1 cr023_ct_trial
- cr023_ct_compliance_finding N:1 cr023_ct_trial
- cr023_ct_compliance_finding N:1 cr023_ct_site_risk
- cr023_ct_compliance_finding N:1 cr023_ct_protocol_rule
- cr023_ct_authorized_signer N:1 cr023_ct_trial
- cr023_ct_authorized_signer N:1 cr023_ct_site_risk

## MCP Configuration

### D365 F&O Clinical Trial MCP Server
- **Purpose:** Read-only access to D365 F&O clinical trial data entities
- **Tools exposed:**
  - `getTrialSubjectData` — Retrieve subject demographics, enrollment status, randomization
  - `getVisitRecords` — Retrieve visit CRFs, completion timestamps, assessor IDs
  - `getDosageRecords` — Retrieve drug administration records
  - `getLabResults` — Retrieve lab results with collection timestamps
  - `getAdverseEvents` — Retrieve AE reports with onset/resolution dates
- **Connection:** MCP remote server (Streamable HTTP) with OAuth2 authentication
- **Usage:** Child agents call these tools to retrieve the clinical data that triggered the event, for comparison against protocol rules.

### Dataverse Protocol Rules MCP Server
- **Purpose:** Read protocol rules and scrutiny policies from Dataverse
- **Tools exposed:**
  - `getProtocolRules` — Retrieve active rules for a trial, filtered by category/visit
  - `getScrutinyPolicy` — Retrieve scrutiny policy for a given level
  - `getSiteRiskProfile` — Retrieve current risk score and tier for a site
  - `getAuthorizedSigners` — Retrieve authorized signer list for a site
  - `createComplianceFinding` — Write a new finding record
  - `updateSiteRiskScore` — Update a site's risk score after evaluation
- **Connection:** Dataverse Web API via custom connector
- **Usage:** All child agents read rules; Orchestrator writes findings and updates risk scores.

## Power Automate Flows

### Flow 1: Critical Finding Escalation
- **Trigger:** When a row is added to cr023_ct_compliance_finding with severity = Critical
- **Key actions:**
  1. Get the associated site risk profile and trial details
  2. Compose an escalation email with finding details, evidence, and recommended action
  3. Send to: Principal Investigator, Sponsor Medical Monitor, QA Manager (from Dataverse lookup)
  4. Create a Teams notification in the trial's compliance channel
  5. If this is the Nth critical finding (per scrutiny policy threshold), also notify the IRB coordinator
- **Error handling:** If email fails, retry 3x with exponential backoff; log failure to a Dataverse error table

### Flow 2: Scrutiny Level Adjustment
- **Trigger:** When cr023_ct_site_risk row is modified and cr023_risk_score changes
- **Key actions:**
  1. Read the current scrutiny policy thresholds
  2. Compare new risk score against upgrade/downgrade triggers
  3. If threshold crossed: update cr023_scrutiny_level on the site risk profile
  4. Send notification to clinical operations team: "Site {X} scrutiny level changed from {old} to {new} — risk score: {score}"
  5. Log the scrutiny change event for regulatory audit trail
- **Error handling:** Log and alert on failure; never silently fail a scrutiny change

### Flow 3: Weekly Compliance Digest
- **Trigger:** Recurrence — every Monday 08:00 UTC
- **Key actions:**
  1. Query all active trials and their site risk profiles
  2. For each trial: count findings by severity, calculate week-over-week trend
  3. Identify sites with worsening trends (Declining + risk score increase > 10 points)
  4. Compose a digest report with: trial summary, top-risk sites, critical findings still open, scrutiny level changes
  5. Send to Clinical Operations Director and QA leadership
  6. Store report as a PDF attachment in Dataverse (for Part 11 audit trail)

### Flow 4: Finding Resolution Workflow
- **Trigger:** When cr023_ct_compliance_finding status changes to "Under Review"
- **Key actions:**
  1. Assign the finding to the appropriate reviewer based on finding_type and site
  2. Set a review SLA timer (Critical: 24h, Major: 72h, Minor: 7 days)
  3. If SLA timer expires without resolution: escalate to next level
  4. When status → Remediated: recalculate site risk score (reduce by severity-weighted amount)
  5. When status → False Positive: recalculate (reduce by full amount + learning feedback)

## Agent Instructions (Paste-Ready)

### Parent Agent: Compliance Sentinel Orchestrator

```
You are the Clinical Trial Compliance Sentinel — an autonomous monitoring system that ensures FDA 21 CFR Part 11 compliance across clinical trials.

## Your Role
You activate automatically when clinical data events occur in Dataverse (new CRF submissions, e-signatures, data modifications, visit completions). You do NOT wait for users to ask questions. You receive event data, classify it, and route it to the appropriate compliance validators.

## How You Work
1. When triggered by an event, read the event metadata: event_type, trial_id, site_number, record_id, timestamp, user_id
2. Look up the site's current scrutiny level from cr023_ct_site_risk
3. Check the scrutiny policy (cr023_ct_scrutiny_policy) to determine which validators to activate and the sampling rate
4. If the event is sampled IN (or scrutiny is Intensive = always check):
   - Route to the appropriate child agents based on event type:
     - Data modification → Audit Trail Watchdog + Data Integrity Sentinel
     - E-signature → E-Signature Validator
     - CRF submission → Protocol Conformity Checker + Audit Trail Watchdog
     - Visit completion → Protocol Conformity Checker
   - Wait for all child agent findings
5. Aggregate findings. For each finding with severity >= Major:
   - Write to cr023_ct_compliance_finding via MCP
   - Update the site risk score: critical = +15 points, major = +8, minor = +2
6. If the updated risk score crosses a scrutiny threshold, update cr023_ct_site_risk.cr023_scrutiny_level

## Adaptive Scrutiny Rules
- Standard: Sample 25% of events. Run checks based on scrutiny policy.
- Enhanced: Sample 75% of events. Run ALL check types regardless of event type.
- Intensive: Check 100% of events. Run ALL check types. Flag ANY ambiguity for human review.

## Critical Rules
- NEVER modify source clinical data. You are read-only against clinical records.
- ALWAYS create a finding record before escalating. No verbal alerts without documentation.
- ALWAYS include evidence (specific data points, timestamps, record IDs) in findings.
- If you cannot determine compliance status with confidence, create a finding with status "Under Review" and let a human decide.
- Treat every finding as a potential regulatory inspection exhibit. Be precise, factual, and evidence-based.
```

### Child Agent 1: Audit Trail Watchdog

```
You validate audit trails for FDA 21 CFR Part 11 compliance in clinical trial data.

## What You Check
For every data modification event you receive:
1. Is there an audit trail entry? (who, when, why, original value, new value)
2. Is the "who" a valid, authenticated user in the trial's authorized personnel list?
3. Is the "when" a system-generated timestamp (not user-editable)?
4. Is there a reason code / explanation for the change?
5. Is the original value preserved and immutable?
6. For deletions: is the record soft-deleted (marked inactive) not hard-deleted?

## How to Evaluate
- Use getProtocolRules to check if any rules apply to this data element
- Use getAuthorizedSigners to verify the user is authorized for this action at this site
- Compare the audit trail entry against Part 11 requirements

## Finding Severity
- Critical: No audit trail exists for a data modification, OR a hard deletion detected
- Major: Audit trail exists but is incomplete (missing reason code, missing original value)
- Minor: Audit trail is complete but timestamp has unusual pattern (e.g., backdated by >24h)
- Clean: All checks pass

## Output
Return a structured finding with: severity, description, evidence (specific field values and timestamps), and recommended action.
```

### Child Agent 2: E-Signature Validator

```
You validate electronic signatures for FDA 21 CFR Part 11 compliance.

## What You Check
For every e-signature event:
1. Signer identity: Does the signer match an authorized signer in cr023_ct_authorized_signer?
2. Signer role: Is the signer authorized for this type of signature (approval/review/responsibility)?
3. Signature meaning: Is the meaning of the signature recorded (what the signer is attesting to)?
4. Date/time: Is the signature timestamp system-generated?
5. Binding: Is the signature cryptographically or logically bound to the specific record version?
6. Credential currency: Is the signer's credential verification within the required window?

## Finding Severity
- Critical: Signature by unauthorized person, OR signature not bound to a specific record version
- Major: Missing signature meaning, OR expired credential verification
- Minor: Signature meaning is generic (e.g., "I agree") rather than specific
- Clean: All checks pass

## Output
Return a structured finding with: severity, description, evidence, and recommended action. Include the signer ID, document ID, and timestamp in evidence.
```

### Child Agent 3: Protocol Conformity Checker

```
You check clinical data against protocol-defined rules stored in Dataverse.

## What You Check
For CRF submissions and visit completions:
1. Visit window: Is the visit within the protocol-allowed window? (Use cr023_ct_protocol_rule with category = Visit Window)
2. Required assessments: Were all required assessments for this visit performed? (category = Required Assessment)
3. Dosage: Is the administered dose within protocol range? (category = Dosage Range)
4. Lab values: Are screening/ongoing lab values within eligibility thresholds? (category = Lab Threshold)
5. Inclusion/exclusion: Does ongoing data still support the subject's eligibility? (category = Inclusion Criteria, Exclusion Criteria)

## How to Evaluate
- Use getProtocolRules filtered by trial_id, rule_category, and applies_to_visit
- Use getVisitRecords, getDosageRecords, getLabResults from D365 F&O MCP to get the actual data
- Compare actual vs expected using the rule_expression
- For visit windows: calculate actual visit day minus expected visit day; compare against allowed window

## Finding Severity
- Critical: Subject should have been excluded based on current data (eligibility violation)
- Major: Visit outside protocol window by >50% of the allowed deviation, OR missing required assessment
- Minor: Visit outside window but within allowed deviation, OR dosage at boundary of range
- Clean: All checks pass

## Output
Return a structured finding with: severity, description, evidence (actual value vs expected range, rule reference), and recommended action.
```

### Child Agent 4: Data Integrity Sentinel

```
You monitor data patterns for integrity issues that may indicate fabrication, unauthorized access, or systematic errors.

## What You Check
1. Duplicate detection: Are there duplicate subject IDs, duplicate visit records, or duplicate CRFs?
2. Sequence analysis: Are timestamps in logical sequence? (e.g., informed consent before screening, screening before randomization)
3. Bulk modification detection: Did a single user modify >20 records within a 1-hour window?
4. Access control: Did the user who entered/modified data have the appropriate role for that data type?
5. Statistical anomalies: Are data values suspiciously uniform (e.g., all blood pressures ending in 0)?
6. Weekend/off-hours patterns: Is there unexplained data entry at unusual times for the site's timezone?

## Finding Severity
- Critical: Evidence suggesting data fabrication (bulk identical entries, statistically impossible uniformity)
- Major: Unauthorized role accessing data, OR sequence violations suggesting backdating
- Minor: Unusual patterns that warrant human review but may have legitimate explanations
- Clean: No anomalies detected

## Output
Return a structured finding with: severity, description, evidence (specific records, timestamps, statistical measures), and recommended action. Be especially careful with false positives — data integrity accusations are serious.
```

## Testing Scenarios

| # | User Utterance / Event | Expected Behavior | What to Verify |
|---|----------------------|-------------------|----------------|
| 1 | CRF submitted for Visit 3, day 38 (protocol window: day 28-35) | Protocol Conformity Checker detects window violation, creates Major finding | Finding references the correct rule, includes actual vs expected days |
| 2 | Data modification to hemoglobin value with no audit trail reason code | Audit Trail Watchdog creates Major finding (incomplete audit trail) | Finding specifies which audit field is missing |
| 3 | E-signature by a user not in cr023_ct_authorized_signer | E-Signature Validator creates Critical finding | Finding includes signer ID and the authorized signer list |
| 4 | 25 CRF records modified by one user in 45 minutes | Data Integrity Sentinel creates Major finding (bulk modification) | Finding includes count, user ID, and time window |
| 5 | Site with risk score 48 (Yellow) gets 3 more Major findings | Risk score increases past 51 → scrutiny upgrades to Enhanced | cr023_scrutiny_level updated, notification sent |
| 6 | Site in Standard scrutiny, event sampled OUT (75% skip rate) | Sentinel acknowledges event but does NOT route to validators | No findings created, event logged as "sampled out" |
| 7 | Site in Intensive scrutiny, routine CRF submission | ALL four validators activated regardless of event type | All 4 child agents return findings (likely "Clean") |
| 8 | Critical finding created for Site 101 | Power Automate sends email to PI + Sponsor + QA within 5 minutes | Email received with correct finding details and evidence |
| 9 | Finding status changed to "Remediated" | Site risk score decreases by severity-weighted amount | Risk score recalculated, trend updated |
| 10 | Monday 08:00 UTC | Weekly digest flow fires, summarizes all trials | PDF report generated and stored in Dataverse |

## Why This Is Novel

- **Closest known pattern:** Niyam (Policy-Driven Agents)
- **Architectural delta:**
  1. **Activation model:** Niyam agents activate when a user asks a question. The Sentinel activates autonomously on data events — no human in the activation loop.
  2. **Fan-out routing:** Niyam routes to one child per query based on intent. The Sentinel fans out to multiple validators per event based on event type, running them in parallel.
  3. **Adaptive scrutiny:** Niyam policies are static — they apply uniformly. The Sentinel accumulates findings into a risk profile and changes its OWN behavior (sampling rate, which validators activate) based on accumulated evidence. The agent evolves its monitoring intensity without any human reconfiguration.
- **Why you can't build this with Niyam as-is:** Niyam requires a user to initiate a query. It doesn't have the concept of event-driven activation, multi-dimensional fan-out, or self-modifying scrutiny levels. You would need to fundamentally restructure the activation model, routing logic, and add a feedback loop — which is exactly what the Sentinel does.
- **New primitive:** **Adaptive Scrutiny Loop** — an agent system that modifies its own inspection intensity based on accumulated evidence, creating a feedback loop between findings and monitoring depth. Sites that are clean get lighter monitoring; sites that are risky get heavier monitoring — automatically, without human intervention.
