
{
  "Goal": "Review README.md and ensure the lead-generation utility fully implements the documented plan, solves the problem, and captures everything outlined in README.md.",
  "Context": {
    "WorkspaceStructure": [
      "scripts/",
      "scripts/lib/",
      "bin/elvis-run",
      "tests/run-tests.sh",
      "docs/runbook.md",
      "docs/man/elvis.1",
      "README.md"
    ],
    "Constraints": [
      "Do NOT propose or modify the directory structure.",
      "Only update, edit, and add new files as required.",
      "Strictly follow README.md for pseudocode and problem-solving logic."
    ]
  },
  "Source": {
    "PrimaryReference": "README.md",
    "ConfigFiles": [".env", ".env.example", "project.conf", "*.ini", "*.conf"],
    "DataFiles": ["data/seeds/seeds.csv"]
  },
  "Expectations": {
    "Compliance": "Full alignment with README.md logic and workflows.",
    "Code": "POSIX-compliant shell scripts, modular and reusable.",
    "Testing": [
      "Enhanced unit tests covering all logic paths.",
      "Mock tests for isolated scenarios.",
      "Smoke tests for end-to-end workflows.",
      "Real tests using URLs from seeds.csv.",
      "Interactive prompts for manual contact enrichment."
    ],
    "Documentation": [
      "Update docs/runbook.md with final instructions.",
      "Update docs/man/elvis.1 using roff syntax."
    ],
    "Optimisation": [
      "Remove duplication, unused code, unnecessary complexity.",
      "Check for conflicts and overlaps.",
      "Create additional *.ini files for configs if needed."
    ],
    "ConfigManagement": [
      "All constants, arguments, and variables must be loaded from config files.",
      "No hardcoding in *.sh or *.awk scripts.",
      "Auto-update .env.example and project.conf with missing keys."
    ]
  },
  "Instructions": {
    "Iteration": [
      "Generate a to-do list based on README.md.",
      "Implement tasks one by one.",
      "After each task, verify compliance with README.md.",
      "Report progress: completed tasks, remaining tasks, optimisations applied.",
      "Repeat until all tasks are complete and optimised."
    ],
    "Simulation": [
      "Use real URLs from seeds.csv for live fetch tests.",
      "Simulate network delays, retries, and backoff logic.",
      "Prompt user to add missing contact details before continuing."
    ]
  }
}
