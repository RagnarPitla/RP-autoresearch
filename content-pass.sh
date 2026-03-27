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
