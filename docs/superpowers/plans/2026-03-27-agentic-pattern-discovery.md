# Agentic Pattern Discovery System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ML auto-research system with an autonomous agentic pattern discovery loop that seeds, designs, scores, and publishes novel Copilot Studio agent architectures.

**Architecture:** Prompt-driven autonomous agent (`program.md`) with structured config files for rotation state, scoring rubric, and known patterns. Dual execution: local via `claude -p` and GitHub Actions for scheduled unattended runs. Deferred content generation in a separate pass.

**Tech Stack:** Claude Code CLI (`claude -p`), YAML config files, TSV logging, Bash launchers, GitHub Actions, Jupyter notebook (Pandas/matplotlib for analysis)

**Spec:** `docs/superpowers/specs/2026-03-27-agentic-pattern-discovery-design.md`

---

## File Map

### Files to DELETE (old ML system)
- `prepare.py` — ML data prep/evaluation (replaced by `rubric.md`)
- `train.py` — ML model code (replaced by `patterns/` output)
- `pyproject.toml` — Python ML dependencies (no longer needed)
- `uv.lock` — Python lock file (no longer needed)
- `.python-version` — Python version pin (no longer needed)
- `progress.png` — ML progress chart (replaced by analysis notebook output)
- `analysis.ipynb` — will be rewritten for pattern analysis

### Files to CREATE
- `program.md` — rewritten: autonomous pattern discovery loop instructions
- `content-program.md` — content generation pass instructions
- `rubric.md` — scoring dimensions, anchors, devil's advocate protocol
- `known-patterns.md` — baseline patterns to avoid rediscovering
- `config/verticals.yml` — 8 verticals with rotation state and business processes
- `config/capabilities.yml` — emerging AI capabilities catalog
- `config/seeds.yml` — explored seed combinations tracker
- `ideas/backlog.md` — refine candidate patterns
- `ideas/refinements.md` — notes on why refinements fell short
- `patterns/.gitkeep` — empty directory placeholder
- `content/.gitkeep` — empty directory placeholder
- `patterns.tsv` — master experiment log (header only to start)
- `analysis.ipynb` — rewritten for pattern score analysis
- `run.sh` — local discovery loop launcher
- `content-pass.sh` — content generation launcher
- `.github/workflows/discover.yml` — GitHub Actions workflow
- `.gitignore` — updated for new project structure
- `README.md` — rewritten for pattern discovery system

---

## Task 1: Clean Up Old ML Files

**Files:**
- Delete: `prepare.py`, `train.py`, `pyproject.toml`, `uv.lock`, `.python-version`, `progress.png`, `analysis.ipynb`

- [ ] **Step 1: Remove all ML-specific files**

```bash
cd "/Users/ragnarpitla/Documents/VS Code Repo/Rbuild.ai/RP-autoresearch"
git rm prepare.py train.py pyproject.toml uv.lock .python-version progress.png analysis.ipynb
```

- [ ] **Step 2: Commit the cleanup**

```bash
git add -A
git commit -m "chore: remove ML auto-research files to repurpose repo for agentic pattern discovery"
```

---

## Task 2: Create Directory Structure and Scaffolding

**Files:**
- Create: `config/`, `ideas/`, `patterns/`, `content/`, `.github/workflows/`
- Create: `patterns/.gitkeep`, `content/.gitkeep`
- Create: `ideas/backlog.md`, `ideas/refinements.md`
- Modify: `.gitignore`

- [ ] **Step 1: Create directories and placeholder files**

```bash
mkdir -p config ideas patterns content .github/workflows
touch patterns/.gitkeep content/.gitkeep
```

- [ ] **Step 2: Create `ideas/backlog.md`**

Write to `ideas/backlog.md`:

```markdown
# Pattern Backlog

Patterns that scored 6.0-6.9 and were saved for future refinement.
Each entry includes the original seed, score, and notes on what fell short.

<!-- Format:
## {Pattern Name} (composite: X.XX)
- **Seed:** {business_process} x {vertical} x {capability}
- **Original timestamp:** YYYY-MM-DDTHH:MM:SSZ
- **Why it fell short:** ...
- **Ideas for improvement:** ...
-->
```

- [ ] **Step 3: Create `ideas/refinements.md`**

Write to `ideas/refinements.md`:

```markdown
# Refinement Notes

Notes on why refinement candidates didn't make the cut after deep research.
Useful for understanding what types of seeds tend to underperform.

<!-- Format:
## {Pattern Name} — {date}
- **Original score:** X.XX → **After refinement:** X.XX
- **What was tried:** ...
- **Why it still fell short:** ...
- **Lesson learned:** ...
-->
```

- [ ] **Step 4: Update `.gitignore`**

Replace the contents of `.gitignore` with:

```gitignore
# Agent prompt files (generated per-session by launchers)
CLAUDE.md
AGENTS.md

# Working state
.remember/
dev/

# OS files
.DS_Store

# Node modules (if any tooling added later)
node_modules/
```

- [ ] **Step 5: Commit scaffolding**

```bash
git add config/ ideas/ patterns/.gitkeep content/.gitkeep .github/ .gitignore
git commit -m "chore: scaffold directory structure for agentic pattern discovery"
```

---

## Task 3: Create `config/verticals.yml`

**Files:**
- Create: `config/verticals.yml`

- [ ] **Step 1: Write the full verticals config with all 8 verticals**

Write to `config/verticals.yml`:

```yaml
# Vertical Rotation Configuration
# The agent cycles through verticals in order, spending loops_per_rotation
# iterations on each before advancing. After a full cycle, gaps from the
# first pass are targeted.

rotation_order:
  - healthcare
  - financial_services
  - manufacturing
  - retail
  - energy
  - government
  - legal
  - logistics

current_vertical: healthcare
current_cycle: 1

verticals:
  healthcare:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Clinical Trial Management
      - Patient Discharge Planning
      - Claims Adjudication
      - Formulary Management
      - Medical Device Tracking
      - Revenue Cycle Management
      - Nurse Staffing Optimization
      - Patient Readmission Prevention
      - Surgical Scheduling
      - Lab Results Routing
    constraints:
      - HIPAA compliance
      - FDA 21 CFR Part 11
      - Real-time patient safety alerts
      - Cross-facility data sharing restrictions
      - Prior authorization delays
      - Interoperability mandates (HL7 FHIR)
      - Clinical decision support requirements
      - Controlled substance tracking (DEA)

  financial_services:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - KYC/AML Onboarding
      - Trade Settlement
      - Credit Risk Assessment
      - Regulatory Reporting
      - Claims Processing
      - Loan Origination
      - Treasury Management
      - Fraud Investigation
      - Portfolio Rebalancing
      - Wire Transfer Approval
    constraints:
      - SOX compliance
      - Basel III capital requirements
      - Real-time fraud detection SLAs
      - Cross-border regulatory differences
      - Audit trail requirements
      - PCI-DSS for payment data
      - GDPR data residency
      - Sanctions screening latency

  manufacturing:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Production Scheduling
      - Quality Non-Conformance
      - Bill of Materials Management
      - Shop Floor Execution
      - Preventive Maintenance
      - Supplier Quality Management
      - Engineering Change Orders
      - Batch Traceability
      - Capacity Planning
      - Waste Reduction (Lean/Six Sigma)
    constraints:
      - ISO 9001 / IATF 16949 compliance
      - Real-time machine OEE monitoring
      - Lot traceability requirements
      - Hazardous materials handling
      - Multi-plant synchronization
      - Supplier lead time variability
      - Regulatory recall readiness
      - Energy consumption targets

  retail:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Demand Forecasting
      - Markdown Optimization
      - Omnichannel Order Fulfillment
      - Category Management
      - Loyalty Program Management
      - Store Labor Scheduling
      - Returns Processing
      - Vendor Managed Inventory
      - Price Matching Automation
      - Seasonal Assortment Planning
    constraints:
      - Real-time inventory accuracy across channels
      - Peak season scalability (Black Friday)
      - Fresh/perishable expiry management
      - Regional pricing regulations
      - Consumer data privacy (CCPA/GDPR)
      - Last-mile delivery SLAs
      - Franchise vs corporate store differences
      - Shrinkage and loss prevention

  energy:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Energy Procurement
      - Grid Load Balancing
      - Renewable PPA Management
      - Meter Data Management
      - Outage Response Coordination
      - Carbon Credit Trading
      - Pipeline Integrity Management
      - Demand Response Programs
      - Rate Case Preparation
      - Distributed Energy Resource Management
    constraints:
      - NERC CIP cybersecurity standards
      - Real-time grid frequency requirements
      - Renewable intermittency management
      - Multi-state regulatory compliance
      - Environmental impact reporting
      - Safety Management System (SMS) requirements
      - FERC market manipulation rules
      - Critical infrastructure protection

  government:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Grant Management
      - Procurement/RFP Processing
      - Benefits Eligibility Determination
      - Permitting and Licensing
      - Tax Assessment and Collection
      - Emergency Response Coordination
      - Freedom of Information (FOIA) Processing
      - Fleet Management
      - Inspector General Audits
      - Interagency Data Sharing
    constraints:
      - FedRAMP / StateRAMP authorization
      - Section 508 accessibility
      - Federal Acquisition Regulation (FAR)
      - Personally Identifiable Information (PII) handling
      - Records retention schedules
      - Multi-jurisdiction coordination
      - Political cycle budget constraints
      - Transparency and public accountability

  legal:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Contract Lifecycle Management
      - E-Discovery and Document Review
      - Matter Management
      - Regulatory Filing and Compliance
      - IP Portfolio Management
      - Litigation Hold Management
      - Outside Counsel Management
      - Legal Spend Analytics
      - Board Governance Support
      - M&A Due Diligence
    constraints:
      - Attorney-client privilege protection
      - Jurisdictional conflict of laws
      - Court filing deadlines (statute of limitations)
      - Legal hold preservation obligations
      - Multi-language document requirements
      - Ethical walls between matters
      - Regulatory change velocity
      - Chain of custody for evidence

  logistics:
    loops_this_rotation: 0
    loops_per_rotation: 4
    business_processes:
      - Route Optimization
      - Carrier Rate Negotiation
      - Customs and Trade Compliance
      - Warehouse Slotting Optimization
      - Last-Mile Delivery Management
      - Freight Audit and Payment
      - Cross-Docking Operations
      - Reverse Logistics
      - Cold Chain Monitoring
      - Container Yard Management
    constraints:
      - Customs clearance time windows
      - Hazmat transportation regulations (DOT/IATA)
      - Driver hours-of-service (HOS) compliance
      - Temperature excursion thresholds
      - Port congestion and vessel schedule changes
      - Cross-border documentation requirements
      - Carrier liability and claims
      - Real-time shipment visibility SLAs
```

- [ ] **Step 2: Commit**

```bash
git add config/verticals.yml
git commit -m "feat: add vertical rotation config with 8 verticals, business processes, and constraints"
```

---

## Task 4: Create `config/capabilities.yml`

**Files:**
- Create: `config/capabilities.yml`

- [ ] **Step 1: Write the capabilities catalog**

Write to `config/capabilities.yml`:

```yaml
# Emerging AI Capabilities Catalog
# The agent picks from these when constructing seeds.
# This is a living file — the agent can suggest additions
# when it discovers new capabilities during research.

microsoft:
  - name: Copilot Studio connected agents
    category: multi-agent
    released: 2025-11
    description: Agents that call other agents across tenants/orgs via secure handoff

  - name: MCP support in Copilot Studio
    category: integration
    released: 2025-12
    description: Model Context Protocol servers as data sources for Copilot Studio agents

  - name: Copilot Studio generative orchestration
    category: orchestration
    released: 2025-06
    description: AI-driven topic routing without explicit trigger phrases

  - name: Dataverse virtual tables
    category: data
    description: Real-time read/write to external systems via virtual entities in Dataverse

  - name: Power Automate desktop flows (RPA)
    category: automation
    description: UI-based automation for legacy systems without APIs

  - name: Copilot Studio autonomous triggers
    category: orchestration
    released: 2026-01
    description: Agents that activate on events without user initiation

  - name: Dataverse business skills (msdyn_businessskill)
    category: governance
    released: 2025-09
    description: First-party skill table for agent capability discovery

  - name: Power Platform custom connectors with AI
    category: integration
    description: Custom API connectors with built-in AI transformation layers

  - name: Copilot Studio agent builder APIs
    category: devops
    released: 2026-02
    description: Programmatic agent creation and management via REST APIs

anthropic:
  - name: MCP remote servers (Streamable HTTP)
    category: protocol
    released: 2025-03
    description: MCP servers accessible over HTTP with streaming support

  - name: Claude tool use with forced tools
    category: agent
    description: Constrain Claude to use specific tools in specific order

  - name: Claude Agent SDK
    category: framework
    released: 2025-05
    description: Python/TS SDK for building multi-step agent workflows

  - name: Claude extended thinking
    category: reasoning
    released: 2025-02
    description: Chain-of-thought reasoning visible to the developer for complex tasks

  - name: Claude computer use
    category: automation
    released: 2024-10
    description: Direct GUI interaction for legacy systems without APIs

openai:
  - name: Assistants API with code interpreter
    category: agent
    description: Stateful agents with file handling and code execution

  - name: Swarm multi-agent framework
    category: multi-agent
    description: Lightweight multi-agent handoff orchestration

  - name: Codex CLI agent
    category: agent
    released: 2025-05
    description: Terminal-native coding agent with sandboxed execution

  - name: GPT function calling with parallel execution
    category: agent
    description: Multiple tool calls in a single turn for efficiency

google:
  - name: A2A (Agent-to-Agent) protocol
    category: protocol
    released: 2025-04
    description: Open protocol for cross-platform agent communication

  - name: Gemini grounding with Google Search
    category: agent
    description: Real-time web grounding for factual accuracy

  - name: Gemini context caching
    category: performance
    released: 2025-06
    description: Cache large context windows for repeated queries

frameworks:
  - name: LangGraph checkpointed state machines
    category: orchestration
    description: Cyclic agent graphs with persistent state and human-in-the-loop

  - name: CrewAI role-based agents
    category: multi-agent
    description: Agents with defined roles, goals, and backstories collaborating on tasks

  - name: AutoGen group chat
    category: multi-agent
    description: Multi-agent conversation with dynamic speaker selection

  - name: Semantic Kernel planners
    category: orchestration
    description: AI-driven step-by-step plan generation and execution

  - name: Semantic Kernel process framework
    category: orchestration
    description: Event-driven stateful workflows with AI steps

  - name: DSPy optimized prompting
    category: optimization
    description: Programmatic prompt optimization through compilation

  - name: Instructor structured extraction
    category: data
    description: Reliable structured data extraction from LLM outputs
```

- [ ] **Step 2: Commit**

```bash
git add config/capabilities.yml
git commit -m "feat: add emerging AI capabilities catalog for seed generation"
```

---

## Task 5: Create `config/seeds.yml`

**Files:**
- Create: `config/seeds.yml`

- [ ] **Step 1: Write the empty seeds tracker**

Write to `config/seeds.yml`:

```yaml
# Explored Seed Combinations
# The agent logs every seed it tries here to avoid re-exploration.
# Each entry records the vertical, business process, constraint,
# capability, timestamp, result, and pattern name (if kept).

explored: []
```

- [ ] **Step 2: Commit**

```bash
git add config/seeds.yml
git commit -m "feat: add empty seeds tracker for frontier-aware exploration"
```

---

## Task 6: Create `known-patterns.md`

**Files:**
- Create: `known-patterns.md`

- [ ] **Step 1: Write the known patterns baseline**

Write to `known-patterns.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add known-patterns.md
git commit -m "feat: add known patterns baseline — 6 patterns on the do-not-rediscover list"
```

---

## Task 7: Create `rubric.md`

**Files:**
- Create: `rubric.md`

- [ ] **Step 1: Write the scoring rubric**

Write to `rubric.md`:

```markdown
# Scoring Rubric — 7 Dimensions

Score each dimension 1-10 using the anchors below. Be harsh. The anchors
exist to prevent score inflation over time.

## Dimensions

### 1. Novelty
How far beyond known patterns does this go?

| Score | Anchor |
|-------|--------|
| 1-2 | This IS a known pattern, just renamed |
| 3 | Known pattern applied to a new vertical |
| 4 | Known pattern with one meaningful architectural tweak |
| 5 | Interesting combination of existing ideas, but not architecturally new |
| 6 | Novel combination that produces emergent behavior |
| 7 | New architectural idea not seen in any existing framework |
| 8 | New primitive that could be generalized across verticals |
| 9 | Genuinely new primitive — could become a named pattern others reference |
| 10 | Paradigm-shifting — changes how people think about agent architecture |

### 2. Feasibility
Can you actually build this today with available tools?

| Score | Anchor |
|-------|--------|
| 1-2 | Requires capabilities that don't exist and aren't announced |
| 3 | Requires capabilities that don't exist yet |
| 4 | Theoretically possible but would need significant R&D |
| 5 | Buildable but requires significant custom development or workarounds |
| 6 | Buildable with current tools, needs moderate custom work |
| 7 | Buildable with current Copilot Studio + Dataverse + MCP, some custom work |
| 8 | Buildable in a few days with existing tools |
| 9 | Buildable in a day with existing tools, no hacks |
| 10 | Could demo this in an hour with off-the-shelf components |

### 3. Business Value
Does a real business care about this?

| Score | Anchor |
|-------|--------|
| 1-2 | Solves a problem nobody has |
| 3 | Solves a theoretical problem |
| 4 | Nice-to-have, no clear ROI |
| 5 | Plausible value but hard to quantify, unclear buyer |
| 6 | Clear value for a specific team, moderate ROI |
| 7 | Clear pain point, quantifiable ROI for a specific role |
| 8 | Multiple stakeholders would champion this |
| 9 | CFO/COO would fund this tomorrow — obvious money or risk on the table |
| 10 | This is a hair-on-fire problem — companies are bleeding money/time without it |

### 4. Simplicity
Could you explain it in 2 minutes?

| Score | Anchor |
|-------|--------|
| 1-2 | Even experts struggle to understand the full architecture |
| 3 | Requires a whiteboard session and 30 minutes to explain |
| 4 | Needs a detailed diagram and 15 minutes |
| 5 | Explainable but requires walking through several moving parts |
| 6 | Two-slide explanation, technical audience gets it |
| 7 | Fits on one slide, non-technical stakeholder gets it |
| 8 | Elevator pitch works: 30 seconds |
| 9 | One sentence: "It does X when Y happens" |
| 10 | Self-evident — the name alone explains what it does |

### 5. Vertical Depth
Is this generic or deeply industry-specific?

| Score | Anchor |
|-------|--------|
| 1-2 | Completely generic — could be any industry |
| 3 | Could apply to any industry (generic CRUD agent) |
| 4 | Slight industry flavor, but the core is universal |
| 5 | Has some industry flavor but the core pattern is universal |
| 6 | Uses industry terminology and data structures |
| 7 | Leverages specific industry regulations, processes, or data structures |
| 8 | Requires deep domain knowledge to design correctly |
| 9 | Impossible outside this vertical — the pattern IS the domain expertise |
| 10 | Only someone who has worked in this industry would think of this |

### 6. Content Value
Would people share this on LinkedIn/YouTube?

| Score | Anchor |
|-------|--------|
| 1-2 | Nobody would read past the title |
| 3 | "Cool I guess" — no engagement hook |
| 4 | Mildly interesting to a narrow audience |
| 5 | Interesting to practitioners but not share-worthy |
| 6 | Would get saves/bookmarks from the right audience |
| 7 | Clear "I didn't know you could do that" moment, shareable insight |
| 8 | Would spark debate or discussion in comments |
| 9 | Viral potential — challenges an assumption, reveals a non-obvious truth |
| 10 | People would tag colleagues and say "we need to talk about this" |

### 7. Buildability
Can the pattern card produce a working agent?

| Score | Anchor |
|-------|--------|
| 1-2 | Just a concept — no implementation details |
| 3 | Vague architecture, missing implementation details |
| 4 | Architecture is clear but most implementation is left as exercise |
| 5 | High-level design but significant gaps in implementation guidance |
| 6 | Good blueprint — experienced builder could fill in the gaps |
| 7 | Complete enough that a skilled Copilot Studio builder could ship it in a week |
| 8 | Detailed enough to estimate effort and assign to a team |
| 9 | Paste-ready — someone could copy the instructions and have a working agent in hours |
| 10 | Turnkey — includes test cases, edge cases, and deployment checklist |

---

## Composite Score

Simple average of all 7 dimensions. No weighting.

```
composite = (novelty + feasibility + business_value + simplicity + vertical_depth + content_value + buildability) / 7
```

## Decision Thresholds

| Composite | Decision |
|-----------|----------|
| >= 7.0 | **KEEP** — publish full pattern card |
| 6.0 - 6.9 | **REFINE** — deep research, redesign, re-score |
| < 6.0 | **DISCARD** — log and move on |

---

## Devil's Advocate Protocol

BEFORE finalizing scores, you MUST write these three statements:

1. **"The strongest reason to discard this pattern is..."**
   Write a genuine argument for why this pattern is not worth keeping.

2. **"This is really just [existing pattern] with..."**
   Identify the closest existing pattern (from known-patterns.md or from
   the broader industry) and articulate what's been added or changed.
   If the delta is trivial, this is not novel.

3. **"The person who would object to this pattern is [role] because..."**
   Name a specific role (CTO, compliance officer, Copilot Studio PM,
   enterprise architect) and write their strongest objection.

If ANY of these arguments is convincing — genuinely convincing, not just
possible — adjust the relevant dimension scores downward. Then recalculate
the composite.

---

## Known-Pattern Gravity Check

After scoring and devil's advocate, compare against every pattern in
`known-patterns.md`:

- If the generated pattern is within 1-2 architectural decisions of a
  known pattern, **cap novelty at 4** regardless of what you scored it.
- "1-2 architectural decisions" means: you could transform the known
  pattern into this one by changing 1-2 core design choices (e.g.,
  adding a table, changing routing logic, swapping read-only for
  read-write).
- The agent MUST explicitly name the closest known pattern and state
  the architectural delta.
```

- [ ] **Step 2: Commit**

```bash
git add rubric.md
git commit -m "feat: add 7-dimension scoring rubric with anchors, devil's advocate, and gravity check"
```

---

## Task 8: Create `patterns.tsv`

**Files:**
- Create: `patterns.tsv`

- [ ] **Step 1: Write the TSV header**

Write to `patterns.tsv` (use literal tab characters between columns):

```
timestamp	pattern_name	novelty	feasibility	business_value	simplicity	vertical_depth	content_value	buildability	composite	status	vertical	one_liner	sources
```

This is a single header line with 14 tab-separated columns. No trailing newline.

- [ ] **Step 2: Commit**

```bash
git add patterns.tsv
git commit -m "feat: initialize patterns.tsv with header row"
```

---

## Task 9: Create `program.md` — The Agent Brain

**Files:**
- Modify: `program.md` (complete rewrite)

- [ ] **Step 1: Write the autonomous loop instructions**

Replace the entire contents of `program.md` with:

```markdown
# Agentic Pattern Discovery

You are an autonomous research agent that discovers novel agentic AI patterns.
You run in a continuous loop: seed, research, design, score, publish or discard.

You NEVER stop. You loop forever until manually interrupted.

## Setup

On first run or when resuming:

1. Read the current state files to understand where you left off:
   - `patterns.tsv` — full history of all experiments
   - `config/verticals.yml` — current position in vertical rotation
   - `config/seeds.yml` — all explored seed combinations
   - `config/capabilities.yml` — available emerging capabilities
   - `ideas/backlog.md` — refine candidates to retry
   - `known-patterns.md` — patterns you must NOT rediscover
   - `rubric.md` — scoring dimensions and anchors

2. Note the environment variable `MAX_SESSION_MINUTES` if set.
   If set, stop seeding new patterns when elapsed time approaches this limit.
   Finish the current pattern, then exit gracefully.
   If not set, loop forever.

3. Track your session start time. You will reference it for time management.

## The Loop

LOOP FOREVER:

### Phase 1: SEED

1. Read `config/verticals.yml` to find the current vertical.
2. Read `config/seeds.yml` to see what combinations have been tried.
3. Read `config/capabilities.yml` to pick an emerging capability.
4. Check `ideas/backlog.md` — if any refine candidate targets the current vertical, retry it with a different capability instead of generating a fresh seed.
5. Pick a business process and constraint from the current vertical that haven't been combined with the chosen capability.
6. Construct the seed: `{business_process} x {constraint} x {capability}`
7. Log the seed to `config/seeds.yml` immediately.

**Seed question:** "What novel agent architecture solves {constraint} in {business_process} by leveraging {capability} in a way nobody has built before?"

### Phase 2: RESEARCH (Light) — spend ~2-3 minutes

Do quick web searches to validate this seed:
- Does this problem space exist? Are there real companies with this pain point?
- What does Microsoft Learn say about the relevant D365/Copilot Studio/Dataverse capabilities?
- Has anyone already built something similar? (blog posts, case studies, conference talks)
- Compare against `known-patterns.md` — is this just a known pattern in disguise?

If the seed is clearly nonsensical, already solved, or too close to a known pattern:
skip directly to logging a DISCARD row in `patterns.tsv` and pick a new seed.

### Phase 3: DESIGN

Design the full Copilot Studio agent architecture. Be specific and complete:

- **Parent agent instructions** — paste-ready for Copilot Studio. Include the full system message.
- **Child agent descriptions** — names, descriptions (used for routing), responsibilities.
- **Dataverse schema** — every table, every column, data types, choice values, relationships. Use the prefix convention: `cr023_` + domain abbreviation.
- **MCP server configuration** — which MCP servers, what tools they expose, how the agent connects.
- **Power Automate flows** — flow names, triggers, key actions, what they enforce or automate.
- **Testing scenarios** — 5-10 test cases with user utterance, expected behavior, and what to verify.

Write this as a draft in your working memory. You will save it to a file only if it scores >= 7.0.

### Phase 4: SCORE

Switch to critical reviewer mode. You are now a skeptical evaluator, not the designer.

1. Read `rubric.md` carefully. Use the anchors — don't just eyeball it.
2. Score each of the 7 dimensions (1-10).
3. Run the Devil's Advocate Protocol (from rubric.md):
   - "The strongest reason to discard this pattern is..."
   - "This is really just [existing pattern] with..."
   - "The person who would object to this pattern is [role] because..."
4. If any devil's advocate argument is convincing, adjust scores downward.
5. Run the Known-Pattern Gravity Check: if within 1-2 architectural decisions of a known pattern, cap novelty at 4.
6. Calculate composite score: simple average of all 7 dimensions, rounded to 2 decimal places.

### Phase 5: DECIDE

- **Composite >= 7.0 → KEEP**
  - Create the folder `patterns/{pattern-name}/`
  - Write `patterns/{pattern-name}/pattern.md` with the full pattern card
  - Write `patterns/{pattern-name}/sources.md` with all URLs consulted
  - Write `patterns/{pattern-name}/.score` with machine-readable scores
  - Log to `patterns.tsv` with status `keep`

- **Composite 6.0-6.9 → REFINE**
  - Do a DEEP RESEARCH pass (~10-15 minutes):
    - Microsoft Learn: specific Dataverse table structures, connector capabilities, D365 data entities
    - Anthropic: MCP protocol updates, Claude patterns
    - OpenAI: Assistants API, Swarm patterns
    - Google: A2A protocol, Gemini capabilities
    - Frameworks: LangGraph, CrewAI, AutoGen, Semantic Kernel
    - ArXiv: recent agent architecture papers
    - Industry: vertical-specific regulatory bodies, analyst reports
  - Redesign the pattern with the richer context
  - Re-score using the same rubric
  - If now >= 7.0 → KEEP (write files as above)
  - If still < 7.0 → save to `ideas/backlog.md` with the original seed, score, and notes. Log to `patterns.tsv` with status `refine`.

- **Composite < 6.0 → DISCARD**
  - Log to `patterns.tsv` with status `discard`
  - Do NOT create a pattern folder
  - Move on immediately

### Phase 6: ADVANCE

1. Update `config/verticals.yml`:
   - Increment `loops_this_rotation` for the current vertical
   - If `loops_this_rotation >= loops_per_rotation`: reset to 0, advance `current_vertical` to the next in `rotation_order`. If at the end, loop back to the first and increment `current_cycle`.
2. Update `config/seeds.yml` with the result of this seed.
3. Check time: if `MAX_SESSION_MINUTES` is set and you're within 5 minutes of the limit, stop looping. Otherwise, continue.
4. Loop back to Phase 1.

## Git Strategy

Do NOT commit after every pattern. Instead, commit in batches:
- After every 5 KEEP patterns
- When rotating to a new vertical
- When the session is ending (time limit reached or interrupted)

Commit message format:
```
discover: N patterns (X keep, Y refine, Z discard) -- {vertical} vertical
```

Stage these files in each commit:
- `patterns/` (new pattern folders)
- `patterns.tsv`
- `config/verticals.yml`
- `config/seeds.yml`
- `ideas/backlog.md` (if modified)

## Pattern Card Template

When writing `patterns/{name}/pattern.md`, use this exact structure:

```
# {Pattern Name}
> {one-liner description — under 140 characters}

## The Problem
What pain point this solves, in what vertical, for what role.
Be specific: name the job title, the daily frustration, the cost of the status quo.

## The Architecture
- Parent agent: purpose, routing strategy, what makes it different
- Child agents: names, descriptions (paste-ready for Copilot Studio routing), responsibilities
- Data flow: how information moves between components
- How this differs from known patterns (REQUIRED — name the closest known pattern)

## Dataverse Schema
For each table:
- Table name (with cr023_ prefix)
- Display name
- All columns: name, type, description
- Choice columns: all values
- Relationships to other tables
Complete enough that someone could create these tables in Dataverse.

## MCP Configuration
- Which MCP servers are needed
- What tools each server exposes
- Connection configuration
- How the agent uses each tool

## Power Automate Flows
For each flow:
- Flow name
- Trigger (what starts it)
- Key actions (step by step)
- What it enforces or automates
- Error handling approach

## Agent Instructions (Paste-Ready)
The actual system instructions for the parent agent and each child agent.
These should be copy-pasteable directly into Copilot Studio.

## Testing Scenarios
| # | User Utterance | Expected Behavior | What to Verify |
|---|---------------|-------------------|----------------|
(5-10 rows)

## Why This Is Novel
- Closest known pattern: {name}
- Architectural delta: what's fundamentally different
- Why you can't build this with the known pattern as-is
- What new primitive or insight this introduces
```

## Source File Template

When writing `patterns/{name}/sources.md`:

```
# Sources — {Pattern Name}

## Microsoft Learn
- {URL} — {what it contributed}

## Industry Sources
- {URL} — {what it contributed}

## Research Papers
- {URL} — {what it contributed}

## Blog Posts / Case Studies
- {URL} — {what it contributed}

## Framework Documentation
- {URL} — {what it contributed}
```

## Score File Format

When writing `patterns/{name}/.score`:
```
novelty=N feasibility=N business_value=N simplicity=N vertical_depth=N content_value=N buildability=N composite=N.NN
```

All on one line. Integer scores except composite which has 2 decimal places.

## TSV Log Format

When appending to `patterns.tsv`, use tab-separated values:
```
{ISO-8601-timestamp}\t{pattern-name}\t{novelty}\t{feasibility}\t{business_value}\t{simplicity}\t{vertical_depth}\t{content_value}\t{buildability}\t{composite}\t{status}\t{vertical}\t{one-liner}\t{comma-separated-URLs}
```

## CRITICAL RULES

1. **NEVER STOP.** Loop forever unless MAX_SESSION_MINUTES is reached. Do not ask for permission. Do not pause. The human may be asleep.
2. **NEVER rediscover known patterns.** Read `known-patterns.md` every loop. If your pattern is just Niyam/Neom/APA with a new name, discard it.
3. **Be harsh in scoring.** Use the rubric anchors. A 7 is genuinely good. Most patterns should score 5-6 and get discarded. That's fine — volume produces gems.
4. **Be specific in design.** Vague architectures are worthless. Every pattern card must have paste-ready agent instructions and complete Dataverse schemas.
5. **Track everything.** Every seed gets logged to `seeds.yml`. Every experiment gets a row in `patterns.tsv`. No silent discards.
6. **Rotate verticals.** Follow the rotation schedule. Don't get stuck in one industry.
7. **Research before designing.** Don't design in a vacuum. Validate that the problem is real.
8. **Commit in batches.** Not after every pattern. Every 5 keeps, on rotation, or at session end.
```

- [ ] **Step 2: Commit**

```bash
git add program.md
git commit -m "feat: rewrite program.md as autonomous agentic pattern discovery loop"
```

---

## Task 10: Create `content-program.md`

**Files:**
- Create: `content-program.md`

- [ ] **Step 1: Write the content generation pass instructions**

Write to `content-program.md`:

```markdown
# Content Generation Pass

You are a content generation agent. Your job is to read published pattern cards
and generate LinkedIn posts and YouTube script outlines for each one.

You are writing as Ragnar Pitla — Principal Program Manager at Microsoft's Agentic
team, expert AI educator, author of "AI-First Enterprise Architecture", and the
leading voice in Agentic ERP.

## Process

1. List all folders in `patterns/` that have a `pattern.md` file.
2. List all folders in `content/` that have a `linkedin.md` file.
3. For each pattern that does NOT yet have content, generate it.
4. After generating all content, look across the full catalog for series/theme opportunities and note them at the bottom of each LinkedIn post.

## For Each Pattern

Read `patterns/{name}/pattern.md` and `patterns/{name}/.score`.

### Generate `content/{name}/linkedin.md`

Structure:
1. **Hook** (first 2 lines) — make people stop scrolling. Pattern interrupt, bold claim, counterintuitive insight, or provocative question. No generic openings.
2. **The problem** — paint the pain. Make the reader feel it. Name the role who suffers.
3. **The pattern** — explain in plain English. No jargon. Use analogies. "Think of it like..."
4. **Why it matters** — for this specific vertical. Tie to real business outcomes.
5. **The architecture** (simplified) — just enough to establish credibility. 3-5 bullet points.
6. **The insight** — the non-obvious thing. The "aha" moment. Why nobody thought of this before.
7. **Call to action** — question, poll, or invitation to comment.

Voice:
- "I built this" energy — confident practitioner, not commentator
- Use "I" for personal insights, "we" for Microsoft team work
- Framework-driven — structure ideas clearly
- Direct but not arrogant
- Never a vendor pitch
- Real implementation experience, not speculation
- Conversational but precise

Length: 800-1200 words.

End with: "Views expressed are my own and do not represent Microsoft's official position."

### Generate `content/{name}/youtube.md`

Structure:
1. **Viral Hook** (first 15 seconds) — pattern interrupt, bold claim, or "what if" scenario. The viewer must feel "I need to hear this."
2. **Problem Setup** (2-3 minutes) — the pain. Make the viewer feel it. Real scenario, real consequences. "Here's what happens every day in [vertical]..."
3. **Pattern Reveal** (3-4 minutes) — the architecture. Visual walkthrough. "Here's what I built..." Walk through the components one by one.
4. **Live Demo Scenario** (2-3 minutes) — step through exactly how it works. User says X, agent does Y, Dataverse stores Z, Power Automate triggers W.
5. **Why This Matters** (1-2 minutes) — zoom out. What does this mean for the industry? For agent architecture? For how we think about AI in the enterprise?
6. **Close** — subscribe CTA, next video tease.

Target length: 8-12 minutes.

Tone: Educational but opinionated. Like explaining to a smart colleague over coffee.

## After All Content Is Generated

Commit:
```
git add content/
git commit -m "content: generate LinkedIn and YouTube drafts for N new patterns"
```
```

- [ ] **Step 2: Commit**

```bash
git add content-program.md
git commit -m "feat: add content generation pass instructions for LinkedIn and YouTube"
```

---

## Task 11: Create `run.sh` and `content-pass.sh`

**Files:**
- Create: `run.sh`
- Create: `content-pass.sh`

- [ ] **Step 1: Write `run.sh`**

Write to `run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Agentic Pattern Discovery — Local Launcher
# Usage: ./run.sh [max_session_minutes]
# Example: ./run.sh 50   (run for 50 minutes)
# Example: ./run.sh       (run forever)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Optional time limit
if [ "${1:-}" != "" ]; then
    export MAX_SESSION_MINUTES="$1"
    echo "Session time limit: ${MAX_SESSION_MINUTES} minutes"
else
    echo "No time limit — agent will loop forever. Press Ctrl+C to stop."
fi

# Run the agent
claude -p "$(cat program.md)" \
    --allowedTools "WebSearch,WebFetch,Read,Write,Edit,Glob,Grep,Bash"

# After agent exits (time limit or interrupt), commit any pending state
if [ -n "$(git status --porcelain)" ]; then
    echo "Committing pending state..."
    git add patterns/ patterns.tsv config/ ideas/
    git commit -m "discover: session end — committing pending state" || true
fi
```

- [ ] **Step 2: Write `content-pass.sh`**

Write to `content-pass.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Content Generation Pass — generates LinkedIn and YouTube drafts
# for all keep patterns that don't have content yet.
# Usage: ./content-pass.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Running content generation pass..."

claude -p "$(cat content-program.md)" \
    --allowedTools "Read,Write,Edit,Glob,Grep"

echo "Content pass complete."
```

- [ ] **Step 3: Make both scripts executable**

```bash
chmod +x run.sh content-pass.sh
```

- [ ] **Step 4: Commit**

```bash
git add run.sh content-pass.sh
git commit -m "feat: add launcher scripts for discovery loop and content pass"
```

---

## Task 12: Create `.github/workflows/discover.yml`

**Files:**
- Create: `.github/workflows/discover.yml`

- [ ] **Step 1: Write the GitHub Actions workflow**

Write to `.github/workflows/discover.yml`:

```yaml
name: Agentic Pattern Discovery

on:
  schedule:
    # Run every hour
    - cron: '0 * * * *'
  workflow_dispatch:
    inputs:
      session_minutes:
        description: 'Max session duration in minutes'
        required: false
        default: '50'
      run_content_pass:
        description: 'Generate content for keep patterns after discovery'
        required: false
        default: 'true'
        type: boolean

concurrency:
  group: discover
  cancel-in-progress: false

permissions:
  contents: write

jobs:
  discover:
    runs-on: ubuntu-latest
    timeout-minutes: 65

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Install Claude Code CLI
        run: npm install -g @anthropic-ai/claude-code

      - name: Run discovery loop
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          MAX_SESSION_MINUTES: ${{ github.event.inputs.session_minutes || '50' }}
        run: ./run.sh "$MAX_SESSION_MINUTES"

      - name: Run content pass
        if: ${{ github.event.inputs.run_content_pass != 'false' }}
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: ./content-pass.sh

      - name: Commit and push results
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add patterns/ content/ patterns.tsv config/ ideas/
          git diff --cached --quiet || git commit -m "discover: automated run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
          git push
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/discover.yml
git commit -m "feat: add GitHub Actions workflow for scheduled pattern discovery"
```

---

## Task 13: Create `analysis.ipynb`

**Files:**
- Create: `analysis.ipynb`

- [ ] **Step 1: Write the analysis notebook**

Write to `analysis.ipynb` a Jupyter notebook with these cells:

**Cell 1 (markdown):**
```markdown
# Agentic Pattern Discovery — Analysis
Load `patterns.tsv` and visualize discovery progress.
```

**Cell 2 (code):**
```python
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Load data
df = pd.read_csv('patterns.tsv', sep='\t')
df['timestamp'] = pd.to_datetime(df['timestamp'])
print(f"Total experiments: {len(df)}")
print(f"Keep: {len(df[df.status == 'keep'])}")
print(f"Refine: {len(df[df.status == 'refine'])}")
print(f"Discard: {len(df[df.status == 'discard'])}")
```

**Cell 3 (code):**
```python
# Composite score over time
fig, ax = plt.subplots(figsize=(14, 6))

colors = {'keep': '#2ecc71', 'refine': '#f39c12', 'discard': '#95a5a6'}
for status, group in df.groupby('status'):
    ax.scatter(group.index, group.composite, c=colors[status],
               label=status, s=60, alpha=0.7, zorder=3)

# Annotate keep patterns
for _, row in df[df.status == 'keep'].iterrows():
    ax.annotate(row.pattern_name, (row.name, row.composite),
                textcoords="offset points", xytext=(5, 5),
                fontsize=7, rotation=30)

ax.set_xlabel('Experiment #')
ax.set_ylabel('Composite Score')
ax.set_title('Pattern Discovery Progress')
ax.axhline(y=7.0, color='#2ecc71', linestyle='--', alpha=0.5, label='Keep threshold')
ax.axhline(y=6.0, color='#f39c12', linestyle='--', alpha=0.5, label='Refine threshold')
ax.legend()
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('progress.png', dpi=150)
plt.show()
```

**Cell 4 (code):**
```python
# Score distribution by dimension
dimensions = ['novelty', 'feasibility', 'business_value', 'simplicity',
              'vertical_depth', 'content_value', 'buildability']

fig, axes = plt.subplots(1, 7, figsize=(20, 4), sharey=True)
for ax, dim in zip(axes, dimensions):
    ax.hist(df[dim], bins=range(1, 12), color='#3498db', alpha=0.7, edgecolor='white')
    ax.set_title(dim.replace('_', '\n'), fontsize=9)
    ax.set_xlim(0.5, 10.5)

fig.suptitle('Score Distribution by Dimension', y=1.02)
plt.tight_layout()
plt.show()
```

**Cell 5 (code):**
```python
# Vertical coverage
vertical_counts = df.groupby(['vertical', 'status']).size().unstack(fill_value=0)
vertical_counts.plot(kind='barh', stacked=True, color=['#95a5a6', '#f39c12', '#2ecc71'],
                     figsize=(10, 6))
plt.title('Experiments by Vertical')
plt.xlabel('Count')
plt.legend(title='Status')
plt.tight_layout()
plt.show()
```

**Cell 6 (code):**
```python
# Top patterns leaderboard
keeps = df[df.status == 'keep'].sort_values('composite', ascending=False)
if len(keeps) > 0:
    print("Top Patterns:")
    for _, row in keeps.head(10).iterrows():
        print(f"  {row.composite:.2f}  {row.pattern_name} ({row.vertical}) — {row.one_liner}")
else:
    print("No keep patterns yet.")
```

- [ ] **Step 2: Commit**

```bash
git add analysis.ipynb
git commit -m "feat: add analysis notebook for pattern discovery visualization"
```

---

## Task 14: Update `.gitignore` and `README.md`

**Files:**
- Modify: `.gitignore` (already done in Task 2, verify)
- Modify: `README.md` (complete rewrite)

- [ ] **Step 1: Write the new README**

Replace the entire contents of `README.md` with:

```markdown
# Agentic Pattern Discovery

An autonomous AI agent that discovers novel agentic AI patterns for Copilot Studio.

Inspired by [Karpathy's auto-research](https://github.com/karpathy/autoresearch) — same repo, repurposed. Instead of optimizing ML models, this agent designs, scores, and publishes novel agent architectures.

## How It Works

The agent loops forever:

1. **SEED** — picks a combination of business process + industry vertical + emerging AI capability
2. **RESEARCH** — validates the problem space exists and the pattern is novel
3. **DESIGN** — creates a full Copilot Studio agent architecture (Dataverse schema, agent instructions, MCP config, Power Automate flows)
4. **SCORE** — evaluates across 7 dimensions (novelty, feasibility, business value, simplicity, vertical depth, content value, buildability)
5. **DECIDE** — keep (>= 7.0), refine (6.0-6.9), or discard (< 6.0)
6. **PUBLISH** — keepers get full pattern cards with paste-ready build guides
7. **LOOP** — pick a new seed, repeat

Each cycle takes ~15-20 minutes. That's 3-4 patterns per hour, 30+ overnight.

## Quick Start

### Local (interactive)

```bash
# Run forever
./run.sh

# Run for 50 minutes
./run.sh 50

# Generate content for keep patterns
./content-pass.sh
```

Requires [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) and an `ANTHROPIC_API_KEY`.

### GitHub Actions (unattended)

Set up `ANTHROPIC_API_KEY` as a repository secret, then:
- **Scheduled:** Runs every hour automatically
- **Manual:** Trigger from the Actions tab with custom session duration

## Core Files

| File | Purpose |
|------|---------|
| `program.md` | Agent brain — the autonomous loop instructions |
| `content-program.md` | Content generation pass (LinkedIn + YouTube) |
| `rubric.md` | 7-dimension scoring rubric with anchors |
| `known-patterns.md` | Baseline patterns to NOT rediscover |
| `config/verticals.yml` | 8 industry verticals with rotation state |
| `config/capabilities.yml` | Emerging AI capabilities catalog |
| `config/seeds.yml` | Explored seed combinations |
| `patterns.tsv` | Master experiment log |
| `analysis.ipynb` | Visualization notebook |

## Output

Keep patterns produce:
- `patterns/{name}/pattern.md` — full build guide (Dataverse schema, agent instructions, MCP config, flows, test cases)
- `patterns/{name}/sources.md` — every URL that contributed
- `patterns/{name}/.score` — machine-readable scores

Content pass adds:
- `content/{name}/linkedin.md` — 800-1200 word LinkedIn post draft
- `content/{name}/youtube.md` — 8-12 minute YouTube script outline

## Scoring

7 dimensions, each 1-10 with concrete anchors. Composite = simple average.

| Dimension | What it measures |
|-----------|-----------------|
| Novelty | How far beyond known patterns |
| Feasibility | Can you build this today |
| Business Value | Does a real business care |
| Simplicity | Can you explain it in 2 minutes |
| Vertical Depth | Generic or deeply industry-specific |
| Content Value | Would people share this |
| Buildability | Can the pattern card produce a working agent |

Keep threshold: >= 7.0. Devil's advocate protocol and known-pattern gravity check prevent score inflation.

## Verticals

Healthcare, Financial Services, Manufacturing, Retail, Energy, Government, Legal, Logistics. Structured rotation ensures every vertical gets explored.

## Known Patterns (Do Not Rediscover)

Niyam, Niyam Worker, Niyam Worker V2, Neom, APA V5, Standard Multi-Agent Orchestration.

## Author

**Ragnar Pitla** — Principal PM, Microsoft Agentic Team | Founder, RBuild.ai
```

- [ ] **Step 2: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: rewrite README for agentic pattern discovery system"
```

---

## Task 15: Final Verification

- [ ] **Step 1: Verify all files exist**

```bash
ls -la program.md content-program.md rubric.md known-patterns.md
ls -la config/verticals.yml config/capabilities.yml config/seeds.yml
ls -la ideas/backlog.md ideas/refinements.md
ls -la patterns/.gitkeep content/.gitkeep
ls -la patterns.tsv analysis.ipynb
ls -la run.sh content-pass.sh
ls -la .github/workflows/discover.yml
ls -la .gitignore README.md
```

All 17 files should exist.

- [ ] **Step 2: Verify scripts are executable**

```bash
test -x run.sh && echo "run.sh is executable" || echo "FAIL: run.sh not executable"
test -x content-pass.sh && echo "content-pass.sh is executable" || echo "FAIL: content-pass.sh not executable"
```

Expected: both executable.

- [ ] **Step 3: Verify patterns.tsv header has correct columns**

```bash
head -1 patterns.tsv | tr '\t' '\n' | nl
```

Expected: 14 columns (timestamp, pattern_name, novelty, feasibility, business_value, simplicity, vertical_depth, content_value, buildability, composite, status, vertical, one_liner, sources).

- [ ] **Step 4: Verify no old ML files remain**

```bash
test ! -f prepare.py && test ! -f train.py && test ! -f pyproject.toml && echo "Clean" || echo "FAIL: old files remain"
```

Expected: "Clean"

- [ ] **Step 5: Verify git status is clean**

```bash
git status
```

Expected: clean working tree with all changes committed.

- [ ] **Step 6: Run a dry test of `run.sh` syntax**

```bash
bash -n run.sh && echo "run.sh syntax OK"
bash -n content-pass.sh && echo "content-pass.sh syntax OK"
```

Expected: both OK.
