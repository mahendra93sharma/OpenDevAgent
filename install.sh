#!/bin/bash
# MyDevAgent installer — sets up `mai` and `era` system-wide (user level).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

echo "MyDevAgent installer"
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

# 4. PATH check
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
