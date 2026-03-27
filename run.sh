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
