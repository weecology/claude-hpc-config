#!/usr/bin/env bash
# install.sh — copy Weecology lab agents and skills to ~/.claude/
# Run once per HiPerGator account. Re-run to update.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.claude/agents ~/.claude/skills/ledger-format

cp "$REPO_DIR"/agents/launch.md  ~/.claude/agents/
cp "$REPO_DIR"/agents/log.md     ~/.claude/agents/
cp "$REPO_DIR"/agents/ledger.md  ~/.claude/agents/
cp "$REPO_DIR"/agents/analytics.md ~/.claude/agents/
cp "$REPO_DIR"/skills/ledger-format/SKILL.md ~/.claude/skills/ledger-format/

echo "Installed agents and skills to ~/.claude/"
echo
echo "Next steps:"
echo "  1. Copy CLAUDE.md and GETTING_STARTED.md into each project repo root."
echo "  2. Fork agents/analytics.md into .claude/agents/ inside each project"
echo "     and edit it for that project's metrics."
echo "  3. Create experiments/ledger.jsonl in each project repo:"
echo "     touch experiments/ledger.jsonl && git add experiments/ledger.jsonl"
