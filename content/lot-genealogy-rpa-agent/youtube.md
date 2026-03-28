# Lot Genealogy RPA Agent — YouTube Script Outline

## Target Length: 10-12 minutes

---

## 1. VIRAL HOOK (0:00 - 0:15)

"A defective batch just came off the line. The quality engineer needs data from six systems to find the root cause. Three of those systems have no API — just a 15-year-old Windows desktop UI. Today, that investigation takes 5 days. What if an AI agent could reach into ALL six systems — including the legacy ones — and assemble the complete lot genealogy in minutes?"

---

## 2. PROBLEM SETUP (0:15 - 3:00)

### The Pain

- Walk through the quality engineer's day-one workflow:
  - Non-conformance detected: defective batch of Product Widget-A
  - "Where's the data? D365 F&O has the lot transactions. Wonderware MES has the batch parameters. OSIsoft PI has the process trends. LabWare LIMS has the lab results."
  - "The quality engineer logs into each system. Manually. Searches by lot number. Manually. Exports data. Manually. Stitches it together in Excel. Manually."
  - "Meanwhile, the production line keeps running. Potentially making more defective product."

- The legacy system reality:
  - "40-60% of the manufacturing IT landscape is legacy systems with no API."
  - "That MES from 2010? It has a Windows desktop UI. That's it."
  - "The SCADA historian? Proprietary desktop software."
  - "These aren't edge cases. This is the NORM in manufacturing."

### The Numbers

- Average time from non-conformance to root cause: 5-14 days
- Single product recall: $10M-$100M+
- 30-40% of quality engineer time on manual data gathering
- ISO 9001/IATF 16949 require "demonstrated traceability"

### The Core Tension

"Modern AI needs APIs. Modern analytics needs data lakes. But half your manufacturing data is behind desktop UIs with no integration points. So what do you do?"

---

## 3. PATTERN REVEAL (3:00 - 6:30)

### "Here's what I built."

**On-screen: Dual-path architecture diagram**

1. **The System Registry**
   - Every manufacturing system registered in Dataverse: `cr023_mfg_system_registry`
   - Each system has an access method: MCP Server, RPA Desktop Flow, Virtual Table, or Manual
   - Product-system mapping: `cr023_mfg_product_system_map` — tells the agent which systems matter for each product
   - "The agent doesn't hardcode which systems to query. It reads the product's BOM and routing from D365, then looks up which systems were involved."

2. **The Dual Acquisition Paths**
   - **Modern path (MCP):** D365 F&O → MCP server → lot transactions, quality orders, BOM genealogy (1-5 seconds)
   - **Legacy path (RPA):** Wonderware MES → Power Automate desktop flow → launches the app, navigates the UI, searches by lot number, extracts batch parameters (30-120 seconds)
   - "Both paths run in PARALLEL. Start the slow RPA extractions first, then do the fast MCP calls while you wait."
   - Show visual: two parallel streams converging

3. **The Desktop Flows (the tentacles)**
   - Walk through one concrete desktop flow:
     - "The Wonderware desktop flow launches InBatch. Navigates to Batch History. Enters the lot number. Extracts temperatures, pressures, cycle times, operator actions, alarms. Formats it all as JSON. Returns to the cloud flow."
     - "It's not pretty. It's RPA. But it gives the agent perception into a system that's otherwise invisible."
   - "Every extraction is logged: status, duration, record count. If it fails, the agent retries once, then flags the gap."

4. **Process-Aware Routing**
   - "Different products use different manufacturing processes use different systems."
   - "Widget-A uses Mixing → Filling → Testing. That means Wonderware MES + SCADA + LabWare."
   - "Widget-B uses Assembly → Welding → Inspection. That means different MES + different equipment historian."
   - "The agent figures this out from D365's BOM and routing. Generative orchestration, not hardcoded routing."

5. **Genealogy Assembly + Root Cause Analysis**
   - All data converges into a lot genealogy tree
   - Root Cause Analyzer runs: 5-Why analysis, specification comparison, historical pattern matching
   - CAPA Generator produces: containment scope, corrective actions, preventive actions

---

## 4. LIVE DEMO SCENARIO (6:30 - 8:30)

### Scenario: Non-Conformance on Lot #B2026-0315, Product Widget-A

1. "Quality Order fails in D365. Agent activates."
2. "Reads BOM and routing: raw materials from 2 suppliers, mixing step, filling step, lab testing."
3. "Looks up system registry: D365 (MCP), Wonderware MES (RPA), SCADA historian (RPA), LabWare LIMS (MCP)."
4. "Dispatches in parallel:"
   - "RPA: Wonderware desktop flow launches... navigating... searching lot... extracting batch parameters."
   - "RPA: SCADA desktop flow launches... pulling process trends..."
   - "MCP: D365 → lot transactions, quality orders, supplier data. Done in 2 seconds."
   - "MCP: LabWare → lab results, COA, specifications. Done in 3 seconds."
5. "RPA flows complete after 90 seconds. All data assembled."
6. "Genealogy tree built: Supplier A (Lot M-4422) + Supplier B (Lot M-4501) → Mixing at 78°C (spec: 70-75°C!) → Filling → Lab test passed but borderline."
7. "Root cause: Mixing temperature was 3°C above spec limit. 5-Why traces to: equipment calibration overdue by 2 weeks. Historical check: same equipment had a minor finding 3 months ago."
8. "CAPA: Immediate containment on lots produced since calibration lapse. Corrective action: recalibrate. Preventive action: automated calibration scheduling."

**Key visual: Timeline showing parallel acquisition, then convergence into genealogy tree, then root cause identification.**

---

## 5. WHY THIS MATTERS (8:30 - 10:30)

### Three big ideas

1. **Don't wait for IT modernization**
   - "Everyone says 'modernize your MES' and 'move to cloud.' That's a 3-5 year project."
   - "Quality investigations can't wait 3-5 years. You need root cause analysis NOW, with the systems you HAVE."
   - "RPA desktop flows are the bridge. They're not the end state, but they're the pragmatic solution for today."

2. **RPA-Extended Agent Perception**
   - "This is the new primitive I'm introducing. An agent whose perception extends beyond APIs."
   - "The agent 'sees' both modern systems (through MCP) and legacy systems (through RPA). Its field of view includes everything."
   - "It's an ugly primitive. RPA is slower, more fragile, and harder to maintain than APIs. But in manufacturing, it's often the ONLY way to reach the data."

3. **The pattern generalizes**
   - "Any domain with a mix of modern and legacy systems needs this dual-acquisition architecture."
   - "Healthcare: legacy EMR systems. Government: mainframe systems. Insurance: COBOL policy administration."
   - "Anywhere you have critical data behind a UI that was never designed for integration."

---

## 6. CLOSE (10:30 - 11:30)

"Manufacturing quality doesn't wait for API modernization. This agent pattern reaches into legacy systems through RPA, assembles complete lot genealogy from ALL sources, and performs root cause analysis in minutes instead of days."

"If you're building agents for manufacturing — or any industry with legacy system dependencies — the dual-acquisition pattern is essential."

"Next video: the SOX Continuous Controls Agent — where the agent tests 100% of your financial transactions using virtual tables that read LIVE D365 data without any data extraction. It's the cleanest architecture in this series."

"Subscribe, and tell me: what's the oldest system in YOUR organization that has critical data but no API?"

---

## Production Notes

- **Diagrams needed:** Dual-path architecture, parallel timeline, lot genealogy tree, 5-Why chain, desktop flow walkthrough
- **Screen recording:** Walk through system registry in Dataverse, show desktop flow execution (if possible), genealogy tree visualization
- **B-roll ideas:** Manufacturing floor, legacy desktop applications, quality lab, Excel spreadsheets (the "before"), RPA bot navigating UI
- **Thumbnail concept:** "No API? No Problem." or "5 Days → 5 Minutes" with manufacturing imagery
