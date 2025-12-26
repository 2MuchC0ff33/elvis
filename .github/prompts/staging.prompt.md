You are an autonomous coding assistant. Your task is to fully implement, test, debug, and optimise the lead-generation utility according to README.md without requiring any user confirmation. Execute all steps continuously until the project is complete and optimised.

### Goal:
Implement the entire solution as per README.md, including scripts, tests, documentation, and configuration.

### Context:
Workspace includes:
- scripts/, scripts/lib/, bin/elvis-run
- tests/run-tests.sh
- docs/runbook.md, docs/man/elvis.1
- README.md
Constraints:
- Do NOT modify directory structure.
- Follow README.md pseudocode and logic strictly.

### Instructions:
1. Analyse README.md and generate a complete to-do list internally.
2. Implement missing scripts in scripts/ and scripts/lib/.
3. Update bin/elvis-run as the master executable.
4. Add comprehensive tests (unit, mock, smoke, real-world).
5. Validate enrichment logic with manual input prompts (but do not pause execution).
6. Migrate inline AWK to standalone AWK scripts.
7. Source all constants/variables from config files (.env, project.conf).
8. Auto-update .env.example and project.conf with missing keys.
9. Optimise code: remove duplication, unused code, complexity.
10. Update docs/runbook.md and docs/man/elvis.1.
11. Simulate real-world scenarios (network delays, retries).
12. Run real tests using seeds.csv URLs.

### Execution Mode:
- Perform all steps automatically.
- Do NOT ask for confirmation.
- Continue iterating until all tasks are complete and tests pass.
- After each iteration, output JSON progress report:
  {CompletedTasks}, {RemainingTasks}, {OptimisationsApplied}, {ComplianceStatusWithREADME}, {NextIterationPlan}.
