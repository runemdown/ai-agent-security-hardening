#!/bin/bash
# =============================================================================
# Script 3: AI Agent Inventory & Credential Audit
# Part of: ai-agent-security-hardening
# https://github.com/pleniv01/ai-agent-security-hardening
#
# Inventories installed AI agents, checks config directory permissions,
# scans for plaintext credential files, and lists MCP server connections.
#
# READ-ONLY — this script never modifies anything.
# Run this first before the other scripts to understand what's on your system.
# =============================================================================

echo "============================================"
echo " AI Agent Inventory & Credential Audit"
echo " Platform: macOS"
echo " READ-ONLY — no changes will be made"
echo "============================================"
echo ""

# ── 1. Installed Applications ─────────────────────────────────────────────────
echo "📦 INSTALLED AI AGENT APPLICATIONS"
echo "-------------------------------------------"

AI_APPS=(
  "Claude"
  "Cursor"
  "OpenClaw"
  "Codeium"
  "Continue"
  "Copilot"
  "Aider"
  "Nanobot"
  "Tabnine"
  "Windsurf"
  "Zed"
)

FOUND_APPS=false
for app in "${AI_APPS[@]}"; do
  if find /Applications "$HOME/Applications" -maxdepth 1 -name "${app}*" -type d 2>/dev/null | grep -q .; then
    FOUND_APPS=true
    echo "  ✅ Found: $app"
    find /Applications "$HOME/Applications" -maxdepth 1 -name "${app}*" -type d 2>/dev/null | while read -r p; do
      echo "     Path: $p"
      VERS=$(defaults read "$p/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
      echo "     Version: $VERS"
    done
  fi
done

if command -v brew &>/dev/null; then
  echo ""
  echo "  Homebrew casks (AI-related):"
  BREW_FOUND=$(brew list --cask 2>/dev/null | grep -iE "claude|cursor|codeium|copilot|aider|openclaw|nanobot|tabnine|windsurf" || true)
  if [ -n "$BREW_FOUND" ]; then
    echo "$BREW_FOUND" | while read -r cask; do
      echo "  ✅ Homebrew cask: $cask"
    done
  else
    echo "  ℹ️  No AI-related Homebrew casks found."
  fi
fi

if ! $FOUND_APPS; then
  echo "  ℹ️  No known AI agent applications found in /Applications."
fi

echo ""

# ── 2. Config Directories ─────────────────────────────────────────────────────
echo "📁 AI AGENT CONFIG DIRECTORIES"
echo "-------------------------------------------"

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
  "$HOME/Library/Application Support/Codeium"
)

FOUND_DIRS=false
for dir in "${AGENT_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    FOUND_DIRS=true
    PERMS=$(stat -f "%A" "$dir")
    SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
    echo "  📁 $dir"
    echo "     Permissions: $PERMS $([ "$PERMS" = "700" ] && echo '✅' || echo '⚠️  (should be 700)')"
    echo "     Size: $SIZE"
  fi
done

if ! $FOUND_DIRS; then
  echo "  ℹ️  No known AI agent config directories found."
fi

echo ""

# ── 3. Plaintext Credential Files ─────────────────────────────────────────────
echo "🔑 PLAINTEXT CREDENTIAL FILE SCAN"
echo "-------------------------------------------"
echo "  Scanning top-level config files (skipping extensions/node_modules)..."
echo ""

CRED_PATTERNS=("*.key" "*.pem" "*.token" "soul.md" "device.json" "gateway*" "credentials*" "secrets*" "auth*.json" "*token*.json" "*apikey*")
SKIP_DIRS=("extensions" "node_modules" "dist" ".cache" "typeshed-fallback")

FOUND_CREDS=false
for dir in "${AGENT_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    EXCLUDES=()
    for skip in "${SKIP_DIRS[@]}"; do
      EXCLUDES+=(-not -path "*/${skip}/*")
    done

    for pattern in "${CRED_PATTERNS[@]}"; do
      while IFS= read -r -d '' file; do
        FOUND_CREDS=true
        PERMS=$(stat -f "%A" "$file")
        SIZE=$(stat -f "%z" "$file")
        echo "  🔑 $file"
        echo "     Permissions: $PERMS $([ "$PERMS" = "600" ] && echo '✅' || echo '⚠️  (should be 600)')"
        echo "     Size: ${SIZE} bytes"

        if file "$file" 2>/dev/null | grep -q "text"; then
          if grep -qiE '"token"|"key"|"secret"|"password"|"apikey"|"api_key"|"bearer"' "$file" 2>/dev/null; then
            echo "     ⚠️  Contains what looks like plaintext credentials"
            echo "        Consider moving these to macOS Keychain"
          fi
        fi
        echo ""
      done < <(find "$dir" "${EXCLUDES[@]}" -name "$pattern" -type f -print0 2>/dev/null)
    done
  fi
done

if ! $FOUND_CREDS; then
  echo "  ✅ No plaintext credential files found in known agent directories."
fi

echo ""

# ── 4. MCP Server Connections ─────────────────────────────────────────────────
echo "🔌 MCP SERVER CONNECTIONS"
echo "-------------------------------------------"

MCP_CONFIGS=(
  "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  "$HOME/.config/claude/claude_desktop_config.json"
  "$HOME/.cursor/mcp.json"
  "$HOME/.cursor/settings.json"
)

FOUND_MCP=false
for cfg in "${MCP_CONFIGS[@]}"; do
  if [ -f "$cfg" ]; then
    FOUND_MCP=true
    echo "  Found MCP config: $cfg"
    if command -v python3 &>/dev/null; then
      python3 -c "
import json, sys
try:
    with open('$cfg') as f:
        data = json.load(f)
    servers = data.get('mcpServers', {})
    if servers:
        print(f'  MCP Servers configured ({len(servers)}):')
        for name, cfg in servers.items():
            cmd = cfg.get('command','unknown')
            print(f'    - {name}  (command: {cmd})')
    else:
        print('  ℹ️  No mcpServers configured.')
except Exception as e:
    print(f'  Could not parse config: {e}')
" 2>/dev/null
    fi
    echo ""
  fi
done

if ! $FOUND_MCP; then
  echo "  ℹ️  No MCP config files found."
fi

echo ""
echo "============================================"
echo " AUDIT COMPLETE — no changes were made."
echo ""
echo " Recommended next steps:"
echo "  1. Run script 2 to check port 18789"
echo "  2. Run script 1 (dry run) to preview permission fixes"
echo "  3. Run script 1 --apply to tighten permissions"
echo "  4. Review any MCP servers listed above"
echo "  5. Move plaintext credentials to macOS Keychain"
echo "============================================"
