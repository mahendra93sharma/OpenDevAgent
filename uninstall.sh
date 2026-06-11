#!/bin/bash
# OpenDevAgent uninstaller — removes the system-wide launchers. The repo itself stays.
set -euo pipefail
rm -f "$HOME/.local/bin/mai" "$HOME/.local/bin/era"
echo "✅ removed ~/.local/bin/mai and ~/.local/bin/era"

# remove the Claude Code permission rules added by install.sh (best-effort)
SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$SETTINGS" ]] && command -v python3 >/dev/null; then
  python3 - "$SETTINGS" <<'PY' && echo "✅ removed mai/era permission rules from $SETTINGS"
import json, sys
p = sys.argv[1]
with open(p) as f:
    data = json.load(f)
allow = data.get("permissions", {}).get("allow", [])
data.setdefault("permissions", {})["allow"] = [
    r for r in allow if r not in ("Bash(mai *)", "Bash(era *)")
]
with open(p, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
fi
echo "   (delete this repo folder to remove everything)"
