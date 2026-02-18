AI Agent Security Hardening

Practical shell scripts for macOS to protect against AI agent identity theft — a new threat class where infostealers exfiltrate an AI agent's complete identity (config files, private keys, gateway tokens, memory logs) and use it as an autonomous proxy with the victim's permissions.

Background

In February 2025, a Vidar infostealer swept a victim's .openclaw directory and exfiltrated the agent's complete identity: soul.md (personality and behavioral instructions), device.json (cryptographic private key), gateway tokens, and memory files. Hudson Rock confirmed the infection. No custom module was needed — a routine file grab captured everything.

Unlike credential theft, rotating a password doesn't help. Steal an agent's identity and the attacker obtains a persistent, autonomous proxy of the victim. IAM systems don't know this identity class exists.

SecurityScorecard found over 135,000 internet-exposed OpenClaw instances across 82 countries, with 78% running unpatched versions. CoSAI cataloged nearly 40 MCP threats. This is an emerging and active threat surface.

What These Scripts Do

Three focused, single-purpose scripts for macOS (Sequoia). Read before you run.

Script
What it does
Changes anything?
3_inventory_agents.shAudits installed AI agents, config directories, credential files, MCP connectionsNo — read-only2_check_port_18789.shChecks for OpenClaw's default port, prints firewall commandsNo — read-only1_tighten_agent_permissions.shTightens directory and file permissionsOnly with --apply

Recommended Order

Run them in this order:

bash# Make executable

chmod +x 1_tighten_agent_permissions.sh 2_check_port_18789.sh 3_inventory_agents.sh

# Step 1: See what's on your system (read-only)

bash 3_inventory_agents.sh

# Step 2: Check port 18789 (read-only)

bash 2_check_port_18789.sh

# Step 3: Preview permission changes (dry run, read-only)

bash 1_tighten_agent_permissions.sh

# Step 4: Apply permission changes

bash 1_tighten_agent_permissions.sh --apply

What Gets Protected

Script 1 tightens permissions on config directories for:

Claude (~/.claude, ~/Library/Application Support/Claude)
Cursor (~/.cursor, ~/Library/Application Support/Cursor)
OpenClaw (~/.openclaw, ~/Library/Application Support/OpenClaw)
Continue, Codeium, Aider, and others

Directories are set to 700 (owner-only). Config files, session files, and credential-like files are set to 600 (owner read/write only). Extension and node_modules directories are skipped to avoid noise.

What to Do Beyond These Scripts

Enable macOS Firewall: System Settings → Network → Firewall
Move plaintext tokens to Keychain: Any API keys or gateway tokens sitting in JSON files should live in macOS Keychain instead
Audit MCP connections: Script 3 will list them. Remove any you don't recognise
Keep agents updated: Claude Desktop, Cursor, and any other agents should be on current versions
Be selective about extensions: The article noted 12% of one AI agent marketplace was confirmed malware

Platform

macOS (tested on Sequoia 15.x, Apple Silicon). These scripts use macOS-specific tools (stat -f, defaults, lsof, pfctl) and will not work on Linux or Windows without modification.

Known Limitations

Pattern matching for "credential files" uses filename heuristics — it may flag false positives (library files with "credentials" or "secrets" in their names). Always review dry-run output before applying.

pf firewall rules set by script 2's suggested commands reset on reboot unless added to /etc/pf.conf.

These scripts address file-level hardening. They do not replace endpoint security software, network monitoring, or keeping software updated.

License

MIT License — see LICENSE.

Use freely. No warranty. Review before running. These scripts make no network requests and do not collect or transmit any data.
Contributing

Pull requests welcome, especially:

Linux / Windows equivalents
Additional agent directories to scan
Improved credential detection that reduces false positives
Automated tests

References

Hudson Rock — AI Agent Identity Theft
SecurityScorecard — OpenClaw Exposure Report
CoSAI MCP Threat Catalog
Anthropic MCP Documentation
