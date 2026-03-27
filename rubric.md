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
