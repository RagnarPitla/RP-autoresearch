# Formulary-Adaptive Prior Authorization Agent — LinkedIn Post

**89% of physicians say prior authorization increases burnout.**

The other 11% probably haven't done one this week.

---

Here's what nobody in the "AI for healthcare" conversation is saying: Prior authorization isn't a workflow problem. It's a combinatorial explosion problem.

50+ payers. Thousands of drugs. Varying formulary tiers. Step therapy prerequisites that change by payer, by drug class, by the patient's medication history. That's tens of thousands of unique PA pathways — and today, a human has to manually navigate the right one for each request.

43 PA requests per physician per week. 13-16 hours spent on paperwork, phone holds, and appeals. Patients waiting 2-14 days without treatment. 80% of physicians report patients paying out of pocket because the PA process is too slow.

Prior authorization was ranked the #1 barrier to healthcare access after cost in 2026. Not the drug. Not the condition. The paperwork.

## The Pattern: Formulary-Adaptive Prior Authorization

I built an agent pattern that dynamically discovers and chains PA workflow steps from Dataverse based on the specific drug, payer, and formulary context of each request.

Think of it like GPS navigation for prior authorization. GPS doesn't hardcode every possible route from every origin to every destination — that would be impossible to maintain. Instead, it discovers the road network in real-time and assembles the optimal route for THIS trip. That's what this agent does with PA workflows.

The key: every PA workflow step is stored as a **business skill** in Microsoft's `msdyn_businessskill` table, with structured dependency metadata that encodes which skills must run first, which branch conditions apply, and what output each skill produces. The workflow isn't hardcoded. It isn't LLM-reasoned. It's assembled from data at runtime — deterministic and auditable.

## Why This Changes the Game for PA Specialists

Today, when a new payer changes their formulary requirements, someone has to update hardcoded workflows or retrain staff. With this pattern, you add new skills to Dataverse with the right drug class, payer ID, and formulary tier tags. The next PA request for that combination automatically discovers and chains the new skills. Zero code changes. Zero retraining.

When a physician writes a script for Humira through BCBS:
1. Agent discovers: Formulary Check → Step Therapy Check → Clinical Criteria → PA Submission
2. Step therapy shows the patient hasn't tried methotrexate first
3. Agent branches to Alternative Recommendation — suggests methotrexate with clinical rationale
4. If the physician insists on Humira, the agent assembles the appeal pathway with all evidence compiled

The entire chain is transparent. Every step is logged. Every branch decision is traceable. Auditors can see exactly why the agent recommended what it recommended.

## The Architecture (Simplified)

What makes this architecturally novel:

- **Data-Driven Skill Chaining** — Each skill in `msdyn_businessskill` has prerequisite columns (`cr023_pa_prerequisites`) and branch conditions (`cr023_pa_branch_condition`). The parent agent resolves these into an execution chain at runtime. The workflow graph is in the data, not in code or prompts.
- **Conditional branching** — The output of one skill determines which skills run next. `step_therapy_met=false` triggers the Alternative Recommendation path. `criteria_met=true` triggers PA Submission. Dynamic, not static.
- **Worker Agent delegation** — A single Worker Agent executes each skill in sequence, passing context forward. It calls MCP servers for real-time formulary data, patient lab results, pharmacy claims, and ePA submission.
- **Payer-specific everything** — Skills are tagged by payer. Add a new payer? Create their skills in Dataverse. The agent discovers them on the next request.
- **Three MCP servers** — Pharmacy Benefits (formulary + claims), EHR Clinical Data (labs + diagnoses via FHIR), ePA Submission (NCPDP SCRIPT standard).

## The Insight

Everyone building AI for prior authorization is trying to make a smarter chatbot that understands PA requirements. That's the wrong abstraction.

The right abstraction is: **PA workflows are dependency graphs, and the graph should live in data, not in the agent's reasoning.**

When you store the dependency graph in structured skill metadata — prerequisites, branch conditions, output schemas — you get something more reliable than LLM planning (deterministic execution) and more flexible than hardcoded workflows (new payers, new drugs, new criteria just need new rows in Dataverse).

The agent doesn't reason about what to do next. It reads what to do next from structured metadata. That's the difference between "AI figures out the PA process" (scary in healthcare) and "AI executes a verified, auditable process" (what regulators want).

## The Question

Prior authorization is a $40B+ problem in US healthcare. This pattern compresses the PA cycle from days to minutes — but only if the skill library is comprehensive.

**What's the hardest part of making PA automation work at scale: building the skill library, getting payer buy-in for ePA, or convincing physicians to trust the recommendations?**

I'd love to hear from anyone in healthcare IT, PBM, or clinical informatics. What am I missing?

---

*Views expressed are my own and do not represent Microsoft's official position.*

---

**Series Note:** This is part of my **"Agentic Pattern Discovery"** series — novel multi-agent architectures for regulated industries. Related patterns: [Clinical Trial Compliance Sentinel](#clinical-trial-compliance-sentinel) (also healthcare), [SOX Continuous Controls](#sox-continuous-controls) (finance), [KYC Jurisdiction Mesh](#kyc-jurisdiction-mesh) (banking), [Lot Genealogy RPA Agent](#lot-genealogy-rpa-agent) (manufacturing). The healthcare patterns in this series share a theme: **data-driven orchestration in domains where LLM reasoning is too unreliable for clinical decisions**.
