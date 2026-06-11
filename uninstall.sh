#!/bin/bash
# OpenDevAgent uninstaller — removes the system-wide launchers. The repo itself stays.
set -euo pipefail
rm -f "$HOME/.local/bin/mai" "$HOME/.local/bin/era"
echo "✅ removed ~/.local/bin/mai and ~/.local/bin/era"
echo "   (delete this repo folder to remove everything)"
