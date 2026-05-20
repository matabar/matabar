#!/bin/bash
# Script to install project git hooks

HOOKS_DIR=$(git rev-parse --show-toplevel)/.git/hooks
PRE_COMMIT_HOOK=$HOOKS_DIR/pre-commit

cat <<'EOF' > "$PRE_COMMIT_HOOK"
#!/bin/bash

branch="$(git rev-parse --abbrev-ref HEAD)"

if [ "$branch" = "main" ]; then
  echo "ERROR: Direct commits to the main branch are forbidden by AGENTS.md."
  echo "Please create a feature branch and merge your changes from there."
  exit 1
fi
EOF

chmod +x "$PRE_COMMIT_HOOK"
echo "Git hooks installed successfully."
