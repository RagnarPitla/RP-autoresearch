# Formulary-Adaptive Prior Authorization Agent — YouTube Script Outline

## Target Length: 10-12 minutes

---

## 1. VIRAL HOOK (0:00 - 0:15)

"A physician just prescribed a biologic for their patient. The PA process will take 14 days. The patient will go without treatment for two weeks. What if an AI agent could assemble the exact PA workflow — formulary check, step therapy, clinical criteria, submission — in under 3 minutes, customized for this specific drug, this specific payer, this specific patient?"

---

## 2. PROBLEM SETUP (0:15 - 3:00)

### The Pain (make the viewer feel it)

- "43 prior authorization requests per physician per week. That's not a typo."
- Walk through what a PA specialist does today:
  - Look up the payer's formulary — is this drug covered? What tier?
  - Check step therapy requirements — has the patient tried the prerequisite drugs?
  - Gather clinical criteria — labs, diagnoses, specialist notes
  - Fill out the right form for this specific payer (every payer has different forms)
  - Submit, wait, get denied, appeal, wait again
- The combinatorial explosion: 50+ payers x 1000s of drugs x formulary tiers x step therapy = tens of thousands of unique pathways

### The Numbers

- 89% of physicians say PA increases burnout
- 80% report patients paying out of pocket due to PA delays
- PA ranked #1 barrier to healthcare access after cost (2026)
- Average processing: 2-14 days per request

### The Core Tension

"We have thousands of unique PA pathways. You can't hardcode them all — they change constantly. You can't let the LLM figure it out — this is healthcare, you need deterministic, auditable decisions. So what do you do?"

---

## 3. PATTERN REVEAL (3:00 - 6:30)

### "Here's what I built."

**On-screen: Architecture diagram building up**

1. **The Skill Library**
   - Every PA workflow step is a business skill in Microsoft's `msdyn_businessskill` table
   - Each skill is tagged: drug class, payer IDs, formulary tier, skill type
   - Each skill has: prerequisites (which skills must run first), branch conditions (when to activate), output schema
   - "The entire PA workflow graph lives in Dataverse. Not in code. Not in prompts. In structured data."

2. **The PA Orchestrator (Parent Agent)**
   - Receives a PA request: drug, payer, patient context
   - Queries Dataverse: "Give me all active skills for this drug class + this payer + this formulary tier"
   - Resolves the dependency graph: Formulary Check → Step Therapy → Clinical Criteria → Submission or Alternative
   - "The agent doesn't REASON about what to do. It READS what to do from the skill metadata."

3. **The PA Worker (Child Agent)**
   - Executes each skill in sequence
   - Calls MCP servers for real-time data:
     - Pharmacy Benefits MCP: formulary status, drug alternatives, patient claims history
     - EHR Clinical Data MCP: labs, diagnoses, medications (via FHIR)
     - ePA Submission MCP: submit to payer's electronic PA endpoint

4. **Conditional Branching**
   - "Here's where it gets interesting. The output of one skill determines which skill runs next."
   - Step therapy not met → branches to Alternative Recommendation
   - Clinical criteria met → branches to PA Submission
   - PA denied → branches to Appeal Generation
   - "The branching logic is in the skill metadata, not in the agent's reasoning."

---

## 4. LIVE DEMO SCENARIO (6:30 - 8:30)

### Scenario: PA request for Humira (adalimumab), BCBS payer, Tier 4

1. "PA request comes in. Humira, BCBS, diagnosis: rheumatoid arthritis."
2. "Orchestrator queries Dataverse: 4 skills found for biologics + BCBS + Tier 4."
3. "Skill chain assembled: Formulary Check → Step Therapy Check → Clinical Criteria Check → PA Submission"
4. "Step 1 — Formulary Check: Humira is Tier 4, PA required, step therapy required."
5. "Step 2 — Step Therapy Check: Has the patient tried methotrexate for 90+ days? Worker calls Pharmacy Benefits MCP, pulls claims history... Patient tried methotrexate for 45 days. NOT MET."
6. "Branch condition fires: step_therapy_met=false → Alternative Recommendation skill activates"
7. "Worker generates: 'Recommend completing methotrexate therapy (45 more days) before Humira. Alternative: sulfasalazine (Tier 2, no PA required).'"
8. "All evidence logged. Prescriber notified with options and clinical rationale."

### Contrast with the traditional path:
"Without this agent, that discovery — 'patient needs 45 more days of methotrexate' — would have taken the PA specialist 2-3 hours of phone calls, fax lookups, and payer hold times."

---

## 5. WHY THIS MATTERS (8:30 - 10:30)

### Three big ideas

1. **Data-driven orchestration vs LLM planning**
   - "Semantic Kernel planners let the LLM figure out what to do. That's creative, but not auditable."
   - "This pattern makes the workflow deterministic. The plan comes from structured metadata, not LLM reasoning."
   - "In healthcare, that's not optional. Regulators need to see WHY the agent recommended what it recommended."

2. **New payer? New drug? Just add skills.**
   - "A new payer joins with unique PA requirements. You don't change code. You create new skills in Dataverse with their criteria."
   - "Next PA request for that payer automatically discovers the new skills. Zero deployment."

3. **The primitive: Data-Driven Skill Chaining**
   - "This is the new building block I'm most excited about."
   - "Skills with prerequisites, branch conditions, and output schemas — stored in data, resolved at runtime."
   - "It's more reliable than LLM planning and more flexible than hardcoded workflows."
   - "And it applies way beyond healthcare: insurance claims processing, loan origination, regulatory submissions — any domain with complex, branching workflows that vary by context."

---

## 6. CLOSE (10:30 - 11:30)

"Prior authorization is a $40 billion problem in US healthcare. Most AI solutions are trying to make the chatbot smarter. This pattern says: make the workflow graph smarter instead."

"If you're building agents for healthcare — or any regulated industry with complex branching workflows — the skill chaining pattern is one to study."

"Next video: I'll show you the KYC Jurisdiction Mesh — an agent that dynamically selects which regulatory databases to query based on your customer's geography, runs them in parallel, and merges conflicting results. Same spirit, different vertical."

"Subscribe, and let me know in the comments: what's the workflow in YOUR domain that has this same combinatorial explosion problem?"

---

## Production Notes

- **Diagrams needed:** Skill dependency graph, chain assembly visualization, branch condition flow
- **Screen recording:** Walk through msdyn_businessskill table with PA-specific columns, show chain assembly
- **B-roll ideas:** Doctor filling out PA forms, pharmacist on hold, patient waiting, prescription imagery
- **Thumbnail concept:** "43 PAs Per Week" or "14 Days Without Treatment" with healthcare imagery
