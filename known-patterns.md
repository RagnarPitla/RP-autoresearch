# Known Patterns — Do Not Rediscover

These patterns already exist. The agent MUST compare every generated pattern
against this list. If a generated pattern is within 1-2 architectural decisions
of any pattern below, cap its novelty score at 4.

The agent must explicitly state which known pattern is closest and articulate
the architectural delta in the "Why This Is Novel" section of every pattern card.

---

## Niyam (Policy-Driven Agents)

**Creator:** Ragnar Pitla
**Key trait:** Policies ARE the agent's knowledge — stored as structured Dataverse rows, not prompt instructions.

Architecture:
- Dataverse policy tables store business rules, compliance requirements, procedures
- D365 F&O ERP MCP provides real-time ERP data access
- Power Automate enforces policies and executes workflows
- Parent agent reads policies from Dataverse, enforces business rules, logs compliance
- Table prefix convention: `cr023_` + domain abbreviation

What makes it Niyam: The agent's behavior is governed by structured data in Dataverse tables, not hardcoded prompt instructions. Change the policies, change the agent's behavior — no code changes needed.

---

## Niyam Worker (Single Reusable Worker Agent)

**Creator:** Ragnar Pitla
**Key trait:** Only two agents regardless of domain complexity.

Architecture:
- Parent Orchestrator discovers skills/policies/processes from Dataverse
- Single generic Worker Agent handles ALL task execution
- Parent decides what to do; Worker does it
- Skills, policies, and processes are Dataverse rows the Parent reads at runtime

What makes it Niyam Worker: The radical simplification — instead of N child agents for N domains, one Worker handles everything. The intelligence is in the Parent's orchestration and Dataverse's skill catalog.

---

## Niyam Worker V2 (Microsoft Business Skills + Niyam Governance)

**Creator:** Ragnar Pitla
**Key trait:** Microsoft-native skill discovery + policy enforcement.

Architecture:
- Uses Microsoft's first-party `msdyn_businessskill` table as the skill layer
- Combines open SKILL.md format with Niyam's policy/process governance
- Worker Agent uses `msdyn_businessskill` for capability discovery
- Parent Orchestrator adds Niyam policy enforcement on top

What makes it V2: Leverages Microsoft's own skill infrastructure instead of custom tables, while preserving Niyam's governance layer. Best of both worlds — Microsoft-native + policy-driven.

---

## Neom (Validation-Only Agents)

**Creator:** Ragnar Pitla
**Key trait:** Zero write operations, pure assessment.

Architecture:
- Agents ONLY validate — never create, never modify
- Read-only access to D365 F&O via MCP
- Read-only access to Dataverse policies/rules
- Output is always an assessment, score, or recommendation — never an action
- Used for: quote review, compliance checking, audit, risk assessment

What makes it Neom: The architectural constraint IS the pattern. By forbidding write operations, you get agents that are safe to deploy in regulated environments where autonomous actions are not yet trusted.

---

## APA V5 (Skills + Policies + Processes in Dataverse)

**Creator:** Ragnar Pitla
**Key trait:** Triple-table governance structure.

Architecture:
- Three Dataverse table families:
  - Skills — what agents can do (capabilities, tools, actions)
  - Policies — rules agents must follow (business rules, compliance, constraints)
  - Processes — workflows agents execute (step-by-step procedures)
- Parent agent reads all three at runtime to determine behavior
- Each table family has its own schema, versioning, and lifecycle

What makes it APA V5: The explicit separation of concerns — skills, policies, and processes are independently managed. You can add a new skill without changing policies, or tighten a policy without modifying processes.

---

## Standard Multi-Agent Orchestration

**Key trait:** This is Copilot Studio's built-in pattern — not novel on its own.

Architecture:
- Parent agent with description-based routing to child agents
- Each child agent handles a specific domain or checkpoint
- Non-sequential access — users can invoke any child directly
- Routing is based on child agent descriptions matching user intent

What makes it standard: This is the default Copilot Studio multi-agent pattern. Every agent built in Copilot Studio with child agents uses this. It is the baseline, not an innovation.
