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

## Cross-Facility Readmission Prevention Network (composite: 6.43)
- **Seed:** Patient Readmission Prevention x Cross-facility data sharing restrictions x Copilot Studio connected agents
- **Vertical:** Healthcare
- **Original timestamp:** 2026-03-27T00:10:00Z
- **Why it fell short:** Novelty (5) — using connected agents for cross-org data sharing is exactly what connected agents are designed for. The HIPAA privacy-preserving twist is a design constraint, not an architectural innovation. The pattern is "use the product feature as intended" not "invent a new architecture."
- **Ideas for improvement:** Could become novel if combined with a federated risk scoring primitive where no single agent has full patient data but the network collectively computes readmission risk through partial signal exchange. Would need to validate if A2A protocol supports the necessary stateful multi-turn coordination. Alternatively, try a different capability (e.g., autonomous triggers for discharge event detection + adaptive follow-up intensity, similar to the Sentinel adaptive scrutiny pattern).
