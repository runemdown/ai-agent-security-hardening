#!/bin/bash
# =============================================================================
# Script 1: Tighten AI Agent Directory Permissions
# Part of: ai-agent-security-hardening
# https://github.com/pleniv01/ai-agent-security-hardening
#
# Tightens file permissions on AI agent config directories to prevent
# other processes or users from reading sensitive config and session files.
#
# DRY RUN by default. Pass --apply to make changes.
# =============================================================================

set -euo pipefail

APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true

# Known AI agent config directories
AGENT_DIRS=(
  "$HOME/.openclaw"
  "$HOME/.config/openclaw"
  "$HOME/.claude"
  "$HOME/.config/claude"
  "$HOME/.cursor"
  "$HOME/.config/cursor"
  "$HOME/.continue"
  "$HOME/.config/continue"
  "$HOME/.codeium"
  "$HOME/.aider"
  "$HOME/.config/aider"
  "$HOME/.local/share/claude"
  "$HOME/Library/Application Support/Claude"
  "$HOME/Library/Application Support/Cursor"
  "$HOME/Library/Application Support/OpenClaw"
)

# Credential-like filename patterns to tighten
# Note: we skip extensions/ and node_modules/ to avoid false positives
CRED_PATTERNS=("*.json" "*.key" "*.pem" "*.token" "soul.md" "device.json" "gateway*" "credentials*" "secrets*" "auth*.json" "*token*.json" "*apikey*")

# Directories to skip when scanning for credential files
SKIP_DIRS=("extensions" "node_modules" "dist" ".cache" "typeshed-fallback")

echo "============================================"
echo " AI Agent Permission Hardening Script"
echo " Platform: macOS"
if $APPLY; then
  echo " MODE: APPLYING CHANGES"
else
  echo " MODE: DRY RUN (pass --apply to make changes)"
fi
echo "============================================"
echo ""

FOUND_ANY=false

for dir in "${AGENT_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    FOUND_ANY=true
    echo "📁 Found: $dir"

    CURRENT_PERMS=$(stat -f "%A" "$dir")
    echo "   Current permissions: $CURRENT_PERMS"

    if [ "$CURRENT_PERMS" != "700" ]; then
      echo "   ⚠️  Will change to 700 (owner-only)"
      if $APPLY; then
        chmod 700 "$dir"
        echo "   ✅ Directory permissions set to 700"
      fi
    else
      echo "   ✅ Directory permissions already 700"
    fi

    # Build find exclusions for noisy subdirectories
    EXCLUDES=()
    for skip in "${SKIP_DIRS[@]}"; do
      EXCLUDES+=(-not -path "*/${skip}/*")
    done

    echo "   Scanning for credential files (skipping extensions/node_modules)..."
    for pattern in "${CRED_PATTERNS[@]}"; do
      while IFS= read -r -d '' file; do
        FILE_PERMS=$(stat -f "%A" "$file")
        echo "   🔑 $file (perms: $FILE_PERMS)"
        if [ "$FILE_PERMS" != "600" ]; then
          echo "      ⚠️  Will change to 600 (owner-read/write only)"
          if $APPLY; then
            chmod 600 "$file"
            echo "      ✅ Set to 600"
          fi
        else
          echo "      ✅ Already 600"
        fi
      done < <(find "$dir" "${EXCLUDES[@]}" -name "$pattern" -type f -print0 2>/dev/null)
    done
    echo ""
  fi
done

if ! $FOUND_ANY; then
  echo "ℹ️  No known AI agent directories found on this system."
  echo "   This is fine if you haven't installed any AI agents."
  echo "   To add custom paths, edit the AGENT_DIRS array in this script."
fi

echo ""
if ! $APPLY; then
  echo "============================================"
  echo " DRY RUN COMPLETE — no changes were made."
  echo " To apply: bash $0 --apply"
  echo "============================================"
else
  echo "============================================"
  echo " CHANGES APPLIED."
  echo "============================================"
fi
