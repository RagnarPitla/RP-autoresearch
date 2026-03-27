# Agentic Pattern Discovery System — Design Spec

> Autonomous agent that discovers novel agentic AI patterns by looping forever — seeding, designing, scoring, publishing keepers, and discarding the rest.

**Author:** Ragnar Pitla
**Date:** 2026-03-27
**Repo:** `RP-autoresearch/` (repurposed from Karpathy's auto-research)

---

## 1. Overview

An autonomous Claude Code agent that runs in a continuous loop, discovering novel Copilot Studio agent architectures. Each loop iteration picks a seed (business process x industry vertical x emerging AI capability), designs a full agent architecture around it, scores it against a 7-dimension rubric, and either publishes it as a complete build guide or discards it.

Inspired by Karpathy's auto-research system (same repo) where an agent modifies `train.py`, trains for 5 minutes, and keeps/discards based on `val_bpb`. Here, the "training run" is pattern design, and the "loss metric" is a composite pattern score.

### Design Decisions

- **Prompt-driven with lightweight scaffolding.** `program.md` is the agent's brain. Structured config files (`config/`) provide rotation state and reference data the agent reads and updates. No orchestration script — the agent drives everything.
- **Session-based git commits.** No per-pattern commits. The agent accumulates keep patterns during a session and commits in batches (every 5 keeps, on vertical rotation, or at session end).
- **Adaptive research depth.** Light scan for all seeds (~2-3 min). Deep research only for patterns scoring 6.0-6.9 (~10-15 min). Maximizes throughput while enriching promising candidates.
- **Anchored scoring with devil's advocate.** Concrete examples for each score level prevent drift. Mandatory adversarial arguments before finalizing scores.
- **Deferred content generation.** The main loop produces pattern cards only. LinkedIn/YouTube drafts are generated in a separate content pass.
- **Dual execution.** Local via `claude -p` for interactive runs. GitHub Actions for unattended scheduled/overnight runs.

---

## 2. Repository Structure

```
RP-autoresearch/
├── program.md                    # Agent brain — autonomous loop instructions
├── content-program.md            # Content generation pass instructions
├── rubric.md                     # Scoring dimensions, anchors, devil's advocate protocol
├── known-patterns.md             # Baseline patterns to NOT rediscover
├── config/
│   ├── verticals.yml             # 8 verticals with rotation state + business processes
│   ├── capabilities.yml          # Emerging AI capabilities catalog
│   └── seeds.yml                 # Explored seed combos tracker
├── ideas/
│   ├── backlog.md                # "Refine" patterns — retry later
│   └── refinements.md            # Notes on why refinement candidates fell short
├── patterns/                     # Output — one folder per keep pattern
│   └── {pattern-name}/
│       ├── pattern.md            # Full pattern card
│       ├── sources.md            # Every URL that contributed
│       └── .score                # Machine-readable scores
├── content/                      # Deferred content generation output
│   └── {pattern-name}/
│       ├── linkedin.md           # LinkedIn post draft (800-1200 words)
│       └── youtube.md            # YouTube script outline (8-12 min)
├── patterns.tsv                  # Master experiment log
├── analysis.ipynb                # Visualization notebook
├── run.sh                        # Local launcher
├── content-pass.sh               # Content generation launcher
├── .github/
│   └── workflows/
│       └── discover.yml          # GitHub Actions workflow
├── .gitignore
└── README.md
```

### Parallels to Karpathy's System

| Karpathy Original | Pattern Discovery Equivalent |
|-------------------|------------------------------|
| `program.md` | `program.md` (agent instructions) |
| `prepare.py` (immutable reference) | `rubric.md` + `config/` + `known-patterns.md` |
| `train.py` (agent modifies) | `patterns/{name}/` (agent creates) |
| `results.tsv` | `patterns.tsv` |
| `val_bpb` (lower is better) | `composite` score (higher is better, >= 7.0 to keep) |
| `git reset` on discard | No reset — discards are just rows in TSV |
| 5-minute time budget | ~15-20 minutes per loop iteration |

---

## 3. The Loop — `program.md` Core Logic

```
SEED --> RESEARCH (light) --> DESIGN --> SCORE --> [DECIDE] --> PUBLISH or DISCARD --> LOOP
                                                     |
                                                 if 6.0-6.9
                                                     |
                                          RESEARCH (deep) --> REDESIGN --> RE-SCORE --> [DECIDE]
```

### Phase 1: SEED

1. Read `patterns.tsv` to understand what's been explored
2. Read `config/verticals.yml` to find current vertical in rotation
3. Read `config/capabilities.yml` to pick an emerging capability
4. Read `config/seeds.yml` to avoid repeating combinations
5. Read `ideas/backlog.md` to check if any "refine" candidates target the current vertical
6. Construct seed: `{business_process} x {vertical} x {capability}`
7. Log the seed to `config/seeds.yml`

### Phase 2: RESEARCH (Light) — ~2-3 minutes

- Quick web searches: does this problem space exist? Are there real pain points?
- Check Microsoft Learn for relevant D365/Copilot Studio/Dataverse capabilities
- Check if anyone has already built something similar
- If seed is clearly nonsensical or already solved: skip to DISCARD, pick new seed

### Phase 3: DESIGN

Design the full Copilot Studio agent architecture:
- Parent agent instructions (paste-ready for Copilot Studio)
- Child agent descriptions and routing logic
- Dataverse schema (tables, columns, types, choice values, relationships)
- MCP server configuration
- Power Automate flow designs
- Testing scenarios (5-10 test cases)

### Phase 4: SCORE

1. Switch to critical reviewer mode
2. Score each of the 7 dimensions (1-10) using anchored rubric from `rubric.md`
3. Run devil's advocate step: write 3 reasons this pattern should be discarded
4. Calculate composite score (simple average of 7 dimensions)
5. Run known-pattern gravity check: if within 1-2 architectural decisions of a known pattern, cap novelty at 4
6. Log everything to `patterns.tsv`

### Phase 5: DECIDE

| Composite Score | Action |
|----------------|--------|
| >= 7.0 | **KEEP** — write pattern card to `patterns/{name}/`, mark as keep |
| 6.0 - 6.9 | **REFINE** — deep research pass, redesign, re-score. If now >= 7.0: keep. If still < 7.0: save to `ideas/backlog.md` |
| < 6.0 | **DISCARD** — one line in `patterns.tsv`, move on |

### Phase 6: ADVANCE

- Update `config/verticals.yml` rotation state (increment loop count)
- Update `config/seeds.yml` with explored combination
- If loop count for current vertical reached `loops_per_rotation`: rotate to next vertical
- If accumulated 5 keep patterns (or rotating vertical, or session ending): git commit batch
- Loop back to Phase 1

---

## 4. Scoring Rubric — 7 Dimensions

### Dimension Definitions and Anchors

#### Novelty (1-10)
How far beyond known patterns does this go?
- **3 (weak):** Known pattern applied to a new vertical
- **5 (moderate):** Interesting combination of existing ideas, but not architecturally new
- **7 (solid):** New architectural idea not seen in any existing framework
- **9 (exceptional):** Genuinely new primitive — could become a named pattern others reference

#### Feasibility (1-10)
Can you actually build this today with available tools?
- **3:** Requires capabilities that don't exist yet
- **5:** Buildable but requires significant custom development or workarounds
- **7:** Buildable with current Copilot Studio + Dataverse + MCP, some custom work
- **9:** Buildable in a day with existing tools, no hacks

#### Business Value (1-10)
Does a real business care about this?
- **3:** Solves a theoretical problem nobody has
- **5:** Plausible value but hard to quantify, unclear buyer
- **7:** Clear pain point, quantifiable ROI for a specific role
- **9:** CFO/COO would fund this tomorrow — obvious money or risk on the table

#### Simplicity (1-10)
Could you explain it in 2 minutes?
- **3:** Requires a whiteboard session and 30 minutes to explain the architecture
- **5:** Explainable but requires walking through several moving parts
- **7:** Fits on one slide, non-technical stakeholder gets it
- **9:** One sentence: "It does X when Y happens"

#### Vertical Depth (1-10)
Is this generic or deeply industry-specific?
- **3:** Could apply to any industry (generic CRUD agent)
- **5:** Has some industry flavor but the core pattern is universal
- **7:** Leverages specific industry regulations, processes, or data structures
- **9:** Impossible outside this vertical — the pattern IS the domain expertise

#### Content Value (1-10)
Would people share this on LinkedIn/YouTube?
- **3:** "Cool I guess" — no engagement hook
- **5:** Interesting to practitioners but not share-worthy
- **7:** Clear "I didn't know you could do that" moment, shareable insight
- **9:** Viral potential — challenges an assumption, reveals a non-obvious truth

#### Buildability (1-10)
Can the pattern card produce a working agent?
- **3:** Vague architecture, missing implementation details
- **5:** High-level design but significant gaps in implementation guidance
- **7:** Complete enough that a skilled Copilot Studio builder could ship it in a week
- **9:** Paste-ready — someone could copy the instructions and have a working agent in hours

### Composite Score

Simple average of all 7 dimensions. No weighting — all dimensions matter equally.

### Devil's Advocate Protocol

Before finalizing scores, the agent MUST write:
1. "The strongest reason to discard this pattern is..."
2. "This is really just [existing pattern] with..."
3. "The person who would object to this pattern is [role] because..."

If any of these arguments is convincing, adjust scores downward before calculating the composite.

### Known-Pattern Gravity Check

After scoring, compare against every pattern in `known-patterns.md`. If the generated pattern is within 1-2 architectural decisions of Niyam, Niyam Worker, Niyam Worker V2, Neom, APA V5, or standard multi-agent routing — cap novelty at 4. The agent must explicitly state which known pattern is closest and articulate the architectural delta.

---

## 5. Seed Generation — Structured Rotation with Frontier Awareness

### Vertical Rotation Schedule

8 verticals, cycled in order. Each gets 3-5 loops (configurable as `loops_per_rotation`) before rotating:

1. Healthcare
2. Financial Services
3. Manufacturing
4. Retail
5. Energy
6. Government
7. Legal
8. Logistics

After a full cycle, start again — but target gaps from the first pass.

### Seed Components

| Component | Source | Examples |
|-----------|--------|---------|
| Business Process | D365 F&O process hierarchy + vertical-specific | Record to Report, Source to Pay, Claims Adjudication, Clinical Trial Management |
| Constraint/Problem | Industry-specific pain points, regulations, failure modes | FDA compliance, real-time fraud detection, cold chain breaks, tariff reclassification |
| Emerging Capability | `config/capabilities.yml` | MCP remote servers, A2A protocol, Copilot Studio connected agents, Claude tool use, Gemini grounding, Semantic Kernel planners, AutoGen group chat |

### Seed Formula

`{business_process} x {constraint} x {capability}`

The agent asks: "What novel agent architecture solves {constraint} in {business_process} by leveraging {capability} in a way nobody has built before?"

### `config/seeds.yml` Structure

```yaml
# Tracks every seed combination explored
explored:
  - vertical: healthcare
    business_process: Clinical Trial Management
    constraint: FDA 21 CFR Part 11
    capability: MCP remote servers (Streamable HTTP)
    timestamp: 2026-03-28T02:15:00Z
    result: keep
    pattern_name: regulatory-ghost-agent
  - vertical: healthcare
    business_process: Patient Discharge Planning
    constraint: Cross-facility data sharing restrictions
    capability: A2A protocol
    timestamp: 2026-03-28T02:35:00Z
    result: discard
    pattern_name: null
```

### Frontier Awareness

Before picking a seed, the agent:
1. Reads `patterns.tsv` — what scored well? What failed?
2. Reads `config/seeds.yml` — what combinations have been tried?
3. Avoids already-explored combinations
4. Biases toward capabilities not yet paired with the current vertical
5. Checks `ideas/backlog.md` — if a "refine" pattern targets the current vertical, retry it with a new capability

### `config/verticals.yml` Structure

```yaml
healthcare:
  current_cycle: 1
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
  constraints:
    - HIPAA compliance
    - FDA 21 CFR Part 11
    - Real-time patient safety alerts
    - Cross-facility data sharing restrictions
    - Prior authorization delays
  explored: []

financial_services:
  current_cycle: 1
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
  constraints:
    - SOX compliance
    - Basel III capital requirements
    - Real-time fraud detection SLAs
    - Cross-border regulatory differences
    - Audit trail requirements
  explored: []

# ... (manufacturing, retail, energy, government, legal, logistics)
```

---

## 6. Research Sources & Strategy

### Light Scan (~2-3 min) — Every Seed

| Source | Purpose |
|--------|---------|
| Microsoft Learn | Copilot Studio docs, Dataverse capabilities, MCP updates, D365 F&O process docs, Power Platform what's new |
| Web search | Has anyone built this? Blog posts, case studies, conference talks |
| Known-pattern check | Compare against `known-patterns.md` — is this just a known pattern with a new coat of paint? |

### Deep Research (~10-15 min) — Only for 6.0-6.9 Patterns

| Source | Purpose |
|--------|---------|
| Microsoft Learn (deep) | Specific Dataverse table structures, connector capabilities, Power Automate trigger types, D365 F&O data entities for the vertical |
| Anthropic | MCP protocol spec updates, Claude tool use patterns, agent SDK patterns |
| OpenAI | Assistants API architecture, Codex agent patterns, swarm multi-agent research |
| Google | Gemini grounding, A2A protocol spec, agent-to-agent communication patterns |
| Frameworks | LangGraph state machines, CrewAI role patterns, AutoGen group chat, Semantic Kernel planners |
| ArXiv | Recent papers on agent architectures, multi-agent coordination, tool use |
| Industry sources | Vertical-specific regulatory bodies, analyst reports, trade publications |

### Source Tracking

- Keep patterns: full URL list in `patterns/{name}/sources.md`
- Discard patterns: comma-separated URLs in `patterns.tsv` sources column

---

## 7. Output Formats

### `patterns.tsv` — Master Log

Tab-separated, one row per experiment:

```
timestamp	pattern_name	novelty	feasibility	business_value	simplicity	vertical_depth	content_value	buildability	composite	status	vertical	one_liner	sources
```

Column definitions:
- `timestamp`: ISO 8601 (e.g., `2026-03-28T02:15:00Z`)
- `pattern_name`: kebab-case identifier (e.g., `regulatory-ghost-agent`)
- `novelty` through `buildability`: integer scores 1-10
- `composite`: average of 7 dimensions, 2 decimal places
- `status`: `keep`, `refine`, or `discard`
- `vertical`: which vertical this targets
- `one_liner`: < 140 chars describing the pattern
- `sources`: comma-separated URLs

### `patterns/{name}/pattern.md` — Full Pattern Card

```markdown
# {Pattern Name}
> {one-liner description}

## The Problem
What pain point this solves, in what vertical, for what role.

## The Architecture
- Parent agent: purpose, routing strategy
- Child agents: names, descriptions, routing logic
- How this differs from known patterns

## Dataverse Schema
All tables, columns, data types, choice values, relationships.
Complete enough to create the tables.

## MCP Configuration
Which MCP servers, what tools exposed, connection configuration.

## Power Automate Flows
Flow names, triggers, actions, what they enforce or automate.

## Agent Instructions (Paste-Ready)
The actual system instructions for the parent and each child agent.
Copy-paste into Copilot Studio.

## Testing Scenarios
5-10 test cases:
| # | User Utterance | Expected Behavior | Verify |
|---|---------------|-------------------|--------|

## Why This Is Novel
Explicit comparison to the closest known pattern.
What is architecturally different. Why this couldn't be built
with Niyam/Neom/APA V5 as-is.
```

### `patterns/{name}/.score` — Machine-Readable Scores

```
novelty=8 feasibility=7 business_value=9 simplicity=6 vertical_depth=9 content_value=8 buildability=7 composite=7.71
```

### `content/{name}/linkedin.md` — LinkedIn Post Draft

- Hook (first 2 lines that make people stop scrolling)
- Pattern explained in plain English (no jargon)
- Why it matters for the vertical
- "I built this" practitioner energy — not a commentator
- Call to action
- 800-1200 words in Ragnar's voice

### `content/{name}/youtube.md` — YouTube Script Outline

- Viral hook (first 15 seconds — pattern interrupt, bold claim, or "what if")
- Problem setup (the pain, make viewer feel it)
- Pattern reveal (architecture, visual walkthrough)
- Live demo scenario (walk through step by step)
- "Why this matters" close
- 8-12 minute target length

### `patterns/{name}/sources.md` — Source Attribution

Every URL consulted during research, grouped by source type.

---

## 8. Known Patterns Baseline — `known-patterns.md`

The "do not rediscover" list. Agent reads it every loop and compares.

### Niyam (Policy-Driven Agents)
Dataverse policy tables + D365 F&O ERP MCP + Power Automate enforcement. Parent agent reads policies, enforces business rules, logs compliance. Key trait: policies ARE the agent's knowledge — stored as structured Dataverse rows, not prompt instructions.

### Niyam Worker (Single Reusable Worker)
Parent orchestrator + one generic Worker Agent that handles all tasks. Parent discovers skills/policies from Dataverse, delegates everything to the Worker. Key trait: only two agents regardless of domain complexity.

### Niyam Worker V2 (Microsoft Business Skills + Niyam Governance)
Uses Microsoft's first-party `msdyn_businessskill` table as the skill layer. Combines open SKILL.md format with Niyam's policy/process governance. Key trait: Microsoft-native skill discovery + policy enforcement.

### Neom (Validation-Only Agents)
Agents that ONLY validate — never create, never modify. Read-only pattern for audit, compliance checking, quote review. Key trait: zero write operations, pure assessment.

### APA V5 (Skills + Policies + Processes in Dataverse)
Three Dataverse table families: Skills (what agents can do), Policies (rules they follow), Processes (workflows they execute). Key trait: triple-table governance structure.

### Standard Multi-Agent Orchestration
Parent agent with description-based routing to child agents. Each child handles a domain. Non-sequential access. Key trait: this is Copilot Studio's built-in pattern — not novel on its own.

---

## 9. Execution Model

### Local Execution

**`run.sh`** — Discovery loop:
```bash
claude -p "$(cat program.md)" --allowedTools "WebSearch,WebFetch,Read,Write,Edit,Glob,Grep,Bash"
```

**`content-pass.sh`** — Content generation for keep patterns:
```bash
claude -p "$(cat content-program.md)" --allowedTools "Read,Write,Edit,Glob,Grep"
```

### GitHub Actions

**`discover.yml`** workflow:
- **Triggers:** Cron schedule (every hour) + manual `workflow_dispatch`
- **Runner:** `ubuntu-latest`
- **Steps:**
  1. Checkout repo
  2. Install Claude Code CLI
  3. Set `ANTHROPIC_API_KEY` from repository secret
  4. Run `run.sh` with `MAX_SESSION_MINUTES=50` (10 min buffer in 60 min window)
  5. Run `content-pass.sh` for new keep patterns
  6. Git commit all accumulated state
  7. Push to repo
- **Concurrency:** `group: discover, cancel-in-progress: false`

### Time Management

The `program.md` instructs the agent to check elapsed time before starting a new seed. If `MAX_SESSION_MINUTES` is set and the session is near the limit, the agent finishes the current pattern, commits all accumulated state, and exits gracefully.

Default `MAX_SESSION_MINUTES` (if not set): unlimited (loop forever).

### State Continuity Across Sessions

A fresh agent instance picks up where the last one left off by reading:
- `patterns.tsv` — full history of all experiments
- `config/verticals.yml` — current position in vertical rotation
- `config/seeds.yml` — all explored combinations
- `config/capabilities.yml` — available capabilities catalog
- `ideas/backlog.md` — refine candidates to retry
- `patterns/` folder — existing keep patterns

No session state is needed. Everything is in the repo.

### Git Strategy

- **During a session:** Patterns accumulate uncommitted
- **Commit triggers:**
  - Every 5 keep patterns
  - On vertical rotation
  - At session end (launcher commits pending state)
  - Manual checkpoint
- **Commit message format:** `discover: N patterns (X keep, Y refine, Z discard) -- {vertical} vertical`
- **Discard patterns:** Never committed as folders. Only exist as rows in `patterns.tsv`
- **GitHub Actions:** Each workflow run ends with commit-and-push

### API Key Requirements

- `ANTHROPIC_API_KEY` — required as GitHub Actions repository secret
- Claude Code's built-in web search tools work with the API key for research steps in CI

---

## 10. `config/capabilities.yml` — Living Catalog

```yaml
microsoft:
  - name: Copilot Studio connected agents
    category: multi-agent
    released: 2025-11
  - name: MCP support in Copilot Studio
    category: integration
    released: 2025-12
  - name: Copilot Studio generative orchestration
    category: orchestration
    released: 2025-06
  - name: Dataverse virtual tables
    category: data
  - name: Power Automate desktop flows (RPA)
    category: automation

anthropic:
  - name: MCP remote servers (Streamable HTTP)
    category: protocol
    released: 2025-03
  - name: Claude tool use with forced tools
    category: agent
  - name: Claude Agent SDK
    category: framework
    released: 2025-05

openai:
  - name: Assistants API with code interpreter
    category: agent
  - name: Swarm multi-agent framework
    category: multi-agent
  - name: Codex CLI agent
    category: agent
    released: 2025-05

google:
  - name: A2A (Agent-to-Agent) protocol
    category: protocol
    released: 2025-04
  - name: Gemini grounding with Google Search
    category: agent

frameworks:
  - name: LangGraph checkpointed state machines
    category: orchestration
  - name: CrewAI role-based agents
    category: multi-agent
  - name: AutoGen group chat
    category: multi-agent
  - name: Semantic Kernel planners
    category: orchestration
  - name: Semantic Kernel process framework
    category: orchestration
```

The agent can suggest additions when it discovers new capabilities during research. Manual updates welcome.

---

## 11. Content Pass — `content-program.md`

Separate agent invocation that:
1. Reads all folders in `patterns/` that do NOT have a corresponding `content/{name}/` folder
2. For each, reads the pattern card and generates:
   - `content/{name}/linkedin.md` — 800-1200 word LinkedIn post in Ragnar's voice
   - `content/{name}/youtube.md` — 8-12 minute YouTube script outline
3. Cross-references other keep patterns for series/theme opportunities
4. Commits all generated content

Voice guidelines for content generation:
- Confident practitioner — "I built this"
- Framework-driven — structure ideas clearly
- Direct but not arrogant
- Never a vendor pitch
- Real implementation experience, not speculation
- Disclaimer: "Views expressed are my own and do not represent Microsoft's official position"

---

## 12. Analysis Notebook — `analysis.ipynb`

Adapted from Karpathy's original. Provides:
- Load `patterns.tsv` into Pandas
- Count experiments by status (keep/refine/discard)
- Count patterns by vertical — coverage heatmap
- Score distribution histograms per dimension
- Composite score over time — are patterns getting better?
- Top patterns leaderboard
- Vertical x capability exploration matrix — where are the gaps?
- Word cloud of pattern names/descriptions for theme spotting
