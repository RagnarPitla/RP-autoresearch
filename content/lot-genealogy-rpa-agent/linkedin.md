# Lot Genealogy RPA Agent — LinkedIn Post

**A defective batch just came off the line.**

Your quality engineer will spend the next 5 days logging into 6 different systems — including a 15-year-old MES with only a Windows desktop UI — to trace what went wrong.

Meanwhile, the line keeps running.

---

This is the dirty secret of manufacturing quality management in 2026: most factories are running 4-7 systems that contain the data you need for root cause analysis, and at least half of them have no API.

The ERP has lot transactions. The MES has batch parameters. The SCADA historian has process trends. The LIMS has lab results. The quality management system has inspection records. And somewhere, there's a paper logbook that hasn't been digitized.

When a non-conformance hits — a defective batch, an out-of-spec measurement, a customer complaint — the quality engineer becomes a human data aggregator. Log into D365. Search by lot number. Export. Log into Wonderware InBatch. Navigate the UI. Search by lot number. Screenshot. Log into OSIsoft PI. Pull up the batch trends. Export. Log into LabWare. Query the sample results. Export. Open Excel. Stitch everything together. Begin analysis.

2-5 days. 30-40% of the quality engineer's time. And by the time root cause analysis actually begins, the production line has been running for days — potentially producing more defective product.

A single product recall costs $10M-$100M+. And the ISO/IATF audit? They want "demonstrated traceability." Good luck demonstrating it when your traceability requires a human to manually navigate six different UIs.

## The Pattern: Lot Genealogy RPA Agent

I built an agent that has TWO data acquisition paths — and this is what makes it architecturally different from anything I've seen:

1. **Modern path:** MCP servers for systems with APIs (D365 F&O, modern LIMS, cloud-based systems)
2. **Legacy path:** Power Automate desktop flows (RPA) for systems with only desktop UIs (old MES, SCADA historians, proprietary thick-client software)

Think of the RPA desktop flows as **tentacles** that extend the agent's reach into systems that no API can touch. The agent coordinates both paths in parallel — MCP calls for modern systems (fast, 1-5 seconds) and RPA flows for legacy systems (slower, 30-120 seconds) — and assembles the complete lot genealogy from all sources.

The key design insight: the agent doesn't have hardcoded routing for which systems to query. Instead, it reads the product's BOM and routing from D365 to discover which systems were involved in manufacturing this specific product. Different products → different manufacturing processes → different systems → different data acquisition paths.

## Why This Matters for Quality Engineers

The agent compresses that 2-5 day manual data gathering into a parallel operation that takes minutes. But more importantly, it doesn't just gather data — it performs root cause analysis.

The Root Cause Analyzer child agent examines the assembled genealogy against historical non-conformance patterns: specification comparisons, trend analysis, 5-Why analysis, pattern matching against known failure modes. And the CAPA Generator produces containment scope (which lots to quarantine based on the genealogy tree), corrective actions, and preventive actions — all linked to specific evidence.

Every system query is logged. Every RPA extraction is tracked with status, duration, and record count. Every data gap is flagged — not silently skipped.

## The Architecture (Simplified)

- **System Registry in Dataverse** (`cr023_mfg_system_registry`) — Each manufacturing system is registered with its access method: MCP, RPA, Virtual Table, or Manual. Product-system mapping tells the agent which systems to query for each product.
- **Dual acquisition in parallel** — MCP calls start first (fast). RPA desktop flows also start (slower but running simultaneously). The agent doesn't wait for one before starting the other.
- **Process-aware routing** — The product's BOM tells the agent which raw material systems to check. The routing tells it which equipment was used (and therefore which MES/SCADA to query). The quality plan tells it which LIMS to check. This is manufacturing-process-driven routing.
- **Genealogy assembly** — All results merge into a complete lot genealogy tree: raw materials → processing steps with parameters → quality checks → finished lot → downstream distribution.
- **Root cause analysis** — 5-Why chains, fishbone categorization, historical pattern matching, specification comparison.

## The Insight

Everyone talking about "AI for manufacturing" is focused on the modern stack — cloud MES, IoT sensors, data lakes. That's important. But it ignores the reality: **40-60% of the manufacturing IT landscape is legacy systems with no API.**

You can build the most sophisticated AI analytics platform in the world, and it's useless if the critical process data is locked behind a Wonderware InBatch desktop client that only runs on Windows 10.

RPA desktop flows solve this. They're not glamorous. They're slow compared to APIs. But they give the agent **perception** into systems that would otherwise be invisible. And in quality investigations, having incomplete data is worse than having slow data — because you can't identify the root cause if you can't see what happened at every processing step.

I call this primitive **RPA-Extended Agent Perception** — an agent system that uses UI-based automation as a data acquisition mechanism for systems that lack APIs. The agent's field of view includes both API-connected systems and UI-only legacy systems.

It's an ugly but essential primitive. Because manufacturing quality doesn't wait for IT modernization.

## The Question

Every manufacturer I talk to has this problem: critical data locked in legacy systems. But many are reluctant to use RPA because it feels "fragile" or "hacky."

**If you run quality operations in manufacturing: would you trust an RPA-based agent to extract data from your legacy MES? What would it take to build that trust?**

I genuinely want to understand the adoption barrier here.

---

*Views expressed are my own and do not represent Microsoft's official position.*

---

**Series Note:** This is part of my **"Agentic Pattern Discovery"** series — novel multi-agent architectures for regulated industries. Other patterns: [SOX Continuous Controls](#sox-continuous-controls) (finance), [Clinical Trial Compliance Sentinel](#clinical-trial-compliance-sentinel) (healthcare), [Formulary-Adaptive Prior Auth](#formulary-adaptive-prior-auth) (healthcare), [KYC Jurisdiction Mesh](#kyc-jurisdiction-mesh) (banking). The manufacturing pattern stands alone in this catalog — it's the only one that extends the agent's perception through UI automation. But the quality investigation framework (genealogy assembly + root cause analysis + CAPA generation) shares DNA with the compliance patterns: **agents that gather evidence from distributed systems and produce auditable, evidence-based conclusions**.
