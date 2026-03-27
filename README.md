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
