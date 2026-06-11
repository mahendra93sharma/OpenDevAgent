#!/bin/bash
# OpenDevAgent installer — sets up `mai` and `era` system-wide (user level).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

echo "OpenDevAgent installer"
echo "--------------------"

# 1. macOS only (sandbox-exec + caffeinate are macOS tools)
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ macOS required: the write-jail uses /usr/bin/sandbox-exec and keep-awake uses /usr/bin/caffeinate." >&2
  exit 1
fi
for tool in sandbox-exec caffeinate; do
  command -v "$tool" >/dev/null || { echo "❌ missing $tool (expected at /usr/bin)" >&2; exit 1; }
done
echo "✅ macOS sandbox + caffeinate found"

# 2. Claude Code CLI
if ! command -v claude >/dev/null; then
  echo "❌ Claude Code CLI not found. Install it first:" >&2
  echo "     npm install -g @anthropic-ai/claude-code" >&2
  echo "   then authenticate with:  claude   (interactive login)" >&2
  exit 1
fi
echo "✅ Claude Code CLI found ($(claude --version 2>/dev/null | head -1))"

# 3. Symlink launchers
mkdir -p "$BIN_DIR"
chmod +x "$REPO_DIR/bin/mai" "$REPO_DIR/bin/era"
ln -sf "$REPO_DIR/bin/mai" "$BIN_DIR/mai"
ln -sf "$REPO_DIR/bin/era" "$BIN_DIR/era"
echo "✅ installed: $BIN_DIR/mai, $BIN_DIR/era (symlinks into this repo)"

# 4. Claude Code permission rules — so running mai/era from inside a Claude Code
#    session never triggers an approval prompt. Merged into user-level settings,
#    existing settings preserved. (Plain Terminal runs never prompt anyway.)
SETTINGS="$HOME/.claude/settings.json"
if command -v python3 >/dev/null && python3 - "$SETTINGS" <<'PY'
import json, os, sys
p = sys.argv[1]
os.makedirs(os.path.dirname(p), exist_ok=True)
data = {}
if os.path.exists(p):
    with open(p) as f:
        data = json.load(f)
perms = data.setdefault("permissions", {})
allow = perms.setdefault("allow", [])
for rule in ("Bash(mai *)", "Bash(era *)"):
    if rule not in allow:
        allow.append(rule)
with open(p, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
then
  echo "✅ Claude Code permissions: mai/era run without approval prompts ($SETTINGS)"
else
  echo "⚠️  could not update $SETTINGS — to skip approval prompts inside Claude Code,"
  echo "    add \"Bash(mai *)\" and \"Bash(era *)\" to permissions.allow manually."
fi

# 5. PATH check
case ":$PATH:" in
  *":$BIN_DIR:"*) echo "✅ $BIN_DIR already on PATH" ;;
  *)
    SHELL_RC="$HOME/.zshrc"
    [[ "${SHELL:-}" == */bash ]] && SHELL_RC="$HOME/.bashrc"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
    echo "✅ added $BIN_DIR to PATH in $SHELL_RC — open a new terminal (or: source $SHELL_RC)"
    ;;
esac

echo ""
echo "Done. Try it:"
echo "  era ./my-task \"rough idea of what you want done\""
echo "  mai ./my-task"
echo ""
echo "Docs: $REPO_DIR/GUIDE.md"
