#!/usr/bin/env bash
# install.sh — DEPRECATED
#
# This script previously installed cc-config skills via curl.
# Skills are now distributed as a Claude Code plugin.
#
# Install via the Claude Code plugin system instead:
#
#   /plugin marketplace add MichaelvanLaar/claude-code-config-skills
#   /plugin install cc-config@cc-config-skills

echo ""
echo "This install script is no longer used."
echo ""
echo "Install the cc-config skills via the Claude Code plugin system:"
echo ""
echo "  1. In Claude Code, run:"
echo "       /plugin marketplace add MichaelvanLaar/claude-code-config-skills"
echo ""
echo "  2. Then install the plugin:"
echo "       /plugin install cc-config@cc-config-skills"
echo ""
echo "  3. To enable auto-updates, go to /plugin → Marketplaces tab"
echo "     and turn on auto-update for MichaelvanLaar/claude-code-config-skills."
echo ""

exit 1
