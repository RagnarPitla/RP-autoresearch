# KYC Jurisdiction Mesh — YouTube Script Outline

## Target Length: 10-12 minutes

---

## 1. VIRAL HOOK (0:00 - 0:15)

"A corporate client has operations in three countries. Your KYC analyst needs to check three different sanctions lists, three different UBO registries, and reconcile three sets of conflicting requirements. Today, that takes 90 days. What if an AI agent could query all three jurisdictions in parallel, merge the conflicting results, and produce a unified compliance profile in minutes?"

---

## 2. PROBLEM SETUP (0:15 - 3:00)

### The Pain

- Walk through a real scenario: "Acme Corp, incorporated in Delaware, subsidiary in Frankfurt, branch in Singapore, UBO who's British living in Dubai"
- "That's five regulatory regimes. Each one has its own sanctions list, its own UBO threshold, its own document requirements."
- Show the analyst's workflow:
  - Log into OFAC screening tool → check SDN list
  - Log into EU sanctions screening → check consolidated list
  - Log into MAS screening → check Singapore lists
  - Cross-reference UBO against each jurisdiction's threshold
  - Reconcile conflicts in Excel
  - Document everything for audit trail

### The Numbers

- Average corporate KYC onboarding: 30-90 days across jurisdictions
- KYC remediation costs: $60M-$500M per bank
- EMEA regulatory penalties up 767% in 2025
- EU AMLA starts centralized supervision in 2026
- "Multi-jurisdictional inconsistency will no longer be tolerated" — that's the regulatory theme of 2026

### The Core Tension

"The regulatory data is distributed by design. OFAC maintains its list. The EU maintains theirs. MAS maintains theirs. You can't centralize them without losing currency and authority. So how do you build an agent that works ACROSS them?"

---

## 3. PATTERN REVEAL (3:00 - 6:30)

### "Here's what I built."

**On-screen: Mesh topology diagram building up**

1. **Jurisdiction Mapping**
   - Child agent analyzes the customer's corporate structure
   - Determines ALL applicable jurisdictions: domicile, subsidiaries, UBO nationalities, transaction corridors
   - "It's not just where you're incorporated. It's where you operate, where your money flows, where your beneficial owners live."

2. **Dynamic MCP Server Selection**
   - Each jurisdiction has its own MCP server in Dataverse: `cr023_kyc_jurisdiction`
   - US KYC MCP: OFAC, FinCEN, state registries
   - EU KYC MCP: EU sanctions, AMLA registry, member state UBO
   - SG KYC MCP: MAS lists, ACRA registry
   - UK KYC MCP: OFSI, Companies House
   - "The agent reads the jurisdiction configuration from Dataverse and dynamically connects to the right MCP servers. New jurisdiction? Add a row and configure the MCP server. Zero code changes."

3. **Parallel Fan-Out**
   - ALL jurisdiction MCP checks run simultaneously
   - "This isn't sequential — US, then EU, then Singapore. It's US AND EU AND Singapore, all at once."
   - Sanctions and PEP screening are blocking — if ANY jurisdiction returns a hit, everything stops

4. **Conflict Resolution Layer (the new primitive)**
   - Walk through a real conflict:
     - US UBO: "substantial control" (could be 10-25%)
     - EU UBO: 25% ownership
     - How does the agent decide?
   - `cr023_kyc_conflict_policy` table: UBO conflicts → "Highest Bar" → use the strictest threshold
   - "Every resolution is logged with the policy ID, the rationale, and the input from each jurisdiction."
   - "When the regulator asks 'why 10%?' — there's a traceable answer."

5. **Risk Assessment**
   - Multi-dimensional scoring: sanctions, PEP, geographic, industry, transaction patterns, complexity
   - EDD triggers automatically if risk score > 50 or specific conditions are met

---

## 4. LIVE DEMO SCENARIO (6:30 - 8:30)

### Scenario: Onboarding "Acme Corp" — US + EU + Singapore

1. "Onboarding request for Acme Corp. Jurisdiction Mapper analyzes: US (incorporated), EU (Frankfurt subsidiary), Singapore (branch office)."
2. "Three MCP servers activate in parallel."
3. **US MCP returns:** "OFAC — clear. FinCEN — UBO identified at 18% ownership. Docs needed: EIN certificate, Delaware good standing."
4. **EU MCP returns:** "EU sanctions — clear. AMLA registry — UBO at 18% ownership, meets 25% threshold? No, but German member state requires 10% for specific entity types. Docs needed: Commercial register extract."
5. **SG MCP returns:** "MAS — clear. ACRA — registered foreign company confirmed. Docs needed: ACRA certificate, director ID copies."
6. "Requirement Merger detects conflict: US 'substantial control' vs EU 25% vs Germany 10%. Applies Highest Bar policy → use 10% threshold. UBO at 18% IS a beneficial owner under the strictest interpretation."
7. "Documents merged (union of all): Delaware good standing + German commercial register + ACRA certificate + director IDs."
8. "Risk Assessor: composite score 34 (Medium). Three jurisdictions, no sanctions hits, no PEP. Standard monitoring sufficient."
9. "Unified onboarding package generated. One package satisfies all three jurisdictions."

**Key visual: Show the three parallel MCP results converging into one merged profile.**

---

## 5. WHY THIS MATTERS (8:30 - 10:30)

### Three big ideas

1. **Mirror the topology, don't fight it**
   - "Every other KYC product tries to centralize regulatory data into one system. That creates a stale copy."
   - "This pattern says: the data authority IS distributed. Mirror that in your architecture. One MCP server per jurisdiction."
   - "The Dynamic MCP Mesh keeps each data source authoritative while the agent handles the complexity."

2. **Conflict resolution as a first-class primitive**
   - "When jurisdictions conflict — and they always do — you need structured resolution policies, not ad-hoc analyst judgment."
   - "Dataverse-stored policies make every resolution auditable, consistent, and reviewable."
   - "That's what regulators are demanding in 2026: demonstrable, risk-based, consistent decision-making."

3. **The pattern generalizes beyond KYC**
   - "Any domain with distributed authority needs this pattern."
   - "Multi-jurisdictional tax compliance. International trade compliance. Multi-regulator reporting in insurance."
   - "Anywhere the data CAN'T be centralized because the authoritative sources are independent — you need a mesh, not a monolith."

---

## 6. CLOSE (10:30 - 11:30)

"KYC is a $500M problem per bank. Most of that cost is human analysts manually navigating distributed regulatory systems. This pattern puts an agent layer on top of the real topology — parallel, auditable, and adaptive to any jurisdiction combination."

"Next video: the Lot Genealogy RPA Agent — an agent that extends its perception into legacy manufacturing systems using RPA desktop flows. If you've ever had to trace a defective batch through seven different systems including a 15-year-old MES with only a Windows desktop UI... you'll want to see this one."

"Subscribe and comment: what's the jurisdiction combination that gives YOUR compliance team the most headaches?"

---

## Production Notes

- **Diagrams needed:** Mesh topology with MCP nodes per jurisdiction, parallel fan-out visualization, conflict resolution flow, risk scoring dimensions
- **Screen recording:** Walk through Dataverse tables for jurisdiction config, conflict policies, customer profiles
- **B-roll ideas:** Global map with jurisdiction highlights, compliance dashboards, banking imagery
- **Thumbnail concept:** "3 Regulators, 1 Agent" or "90 Days → 9 Minutes" with global banking imagery
