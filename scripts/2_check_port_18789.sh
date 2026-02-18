#!/bin/bash
# =============================================================================
# Script 2: Check Port 18789 (OpenClaw Default Port)
# Part of: ai-agent-security-hardening
# https://github.com/pleniv01/ai-agent-security-hardening
#
# Checks whether anything is listening on or connecting to port 18789,
# the default port used by OpenClaw. Prints the exact firewall commands
# needed to block it — but does NOT modify your firewall.
#
# READ-ONLY — this script never modifies anything.
# =============================================================================

echo "============================================"
echo " Port 18789 Audit Script"
echo " (OpenClaw default port)"
echo " READ-ONLY — no changes will be made"
echo "============================================"
echo ""

PORT=18789

echo "🔍 Checking for processes listening on port $PORT..."
LISTENERS=$(lsof -iTCP:$PORT -sTCP:LISTEN 2>/dev/null || true)

if [ -z "$LISTENERS" ]; then
  echo "✅ Nothing is currently listening on port $PORT."
else
  echo "⚠️  ACTIVE LISTENER FOUND on port $PORT:"
  echo ""
  echo "$LISTENERS"
  echo ""
  echo "   Something on your machine is actively serving on this port."
  echo "   Identify the process above and consider stopping it if unexpected."
fi

echo ""
echo "🔍 Checking for active connections on port $PORT..."
CONNECTIONS=$(lsof -iTCP:$PORT 2>/dev/null || true)
if [ -z "$CONNECTIONS" ]; then
  echo "✅ No active connections on port $PORT."
else
  echo "⚠️  Active connections found:"
  echo "$CONNECTIONS"
fi

echo ""
echo "🔍 Checking macOS Application Firewall status..."
FIREWALL_STATE=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "unknown")
case "$FIREWALL_STATE" in
  0) echo "⚠️  macOS Application Firewall is DISABLED." ;;
  1) echo "✅ macOS Application Firewall is ON (allow signed apps)." ;;
  2) echo "✅ macOS Application Firewall is ON (block all)." ;;
  *) echo "ℹ️  Could not read firewall state (try running with sudo for full output)." ;;
esac

echo ""
echo "============================================"
echo " HOW TO BLOCK PORT 18789 (if needed)"
echo "============================================"
echo ""
echo "macOS's built-in Application Firewall blocks apps, not ports."
echo "To block a specific port, use the packet filter (pf):"
echo ""
echo "  Step 1 — Create a rule file:"
echo '    echo "block drop in quick proto tcp from any to any port 18789" | sudo tee /etc/pf.anchors/block_openclaw'
echo ""
echo "  Step 2 — Load the rule:"
echo "    sudo pfctl -f /etc/pf.conf -e"
echo "    sudo pfctl -a block_openclaw -f /etc/pf.anchors/block_openclaw"
echo ""
echo "  Step 3 — Verify it's active:"
echo "    sudo pfctl -s rules"
echo ""
echo "⚠️  NOTE: pf rules reset on reboot unless added to /etc/pf.conf."
echo "   For a persistent block, add to /etc/pf.conf:"
echo '     anchor "block_openclaw"'
echo '     load anchor "block_openclaw" from "/etc/pf.anchors/block_openclaw"'
echo ""
echo "This script has NOT modified your firewall."
echo "============================================"
