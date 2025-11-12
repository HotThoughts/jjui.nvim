#!/usr/bin/env bash
# Development environment setup script for jjui.nvim

set -e

# ANSI color codes (referenced inline for zero-cost abstraction)
readonly B='\033[0;34m' G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' N='\033[0m'

echo "🚀 Setting up jjui.nvim development environment...
"

# Tool specs: cmd|name|brew_pkg
readonly TOOLS=(
  "pre-commit|pre-commit|pre-commit"
  "stylua|StyLua|stylua"
  "luacheck|Luacheck|luacheck"
)

missing=0
for spec in "${TOOLS[@]}"; do
  IFS='|' read -r cmd name brew_pkg <<< "$spec"
  echo -e "${B}[INFO]${N} Checking $name..."
  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${G}[✓]${N} $name is installed ($($cmd --version 2>&1 | head -1))"
  else
    echo -e "${Y}[!]${N} $name is not installed
  Install with: brew install $brew_pkg"
    ((missing++))
  fi
done

echo ""

# Install & test pre-commit hooks if available
if command -v pre-commit >/dev/null 2>&1; then
  echo -e "${B}[INFO]${N} Installing pre-commit hooks..."
  pre-commit install
  echo -e "${G}[✓]${N} Pre-commit hooks installed!
"
  echo -e "${B}[INFO]${N} Testing pre-commit setup..."
  if pre-commit run --all-files; then
    echo -e "${G}[✓]${N} All pre-commit checks passed!"
  else
    echo -e "${Y}[!]${N} Some pre-commit checks failed (this is normal for first run)
${B}[INFO]${N} You may need to commit the formatted files"
  fi
else
  echo -e "${R}[✗]${N} Cannot install pre-commit hooks - pre-commit is not installed"
fi

cat << 'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Next Steps:

  1. Install missing tools:
     brew install pre-commit stylua luacheck

  2. Make changes and commit:
     - The pre-commit hooks will run automatically
     - Or run: pre-commit run --all-files

  3. Common commands:
     - pre-commit run           (check staged files)
     - pre-commit run --all-files (check all files)
     - stylua .                 (format Lua files)
     - luacheck lua/            (lint Lua files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

if ((missing)); then
  echo -e "${Y}[!]${N} Some tools are missing. Install them for the best experience!"
  exit 1
fi

echo -e "${G}[✓]${N} Development environment setup complete! 🎉"
