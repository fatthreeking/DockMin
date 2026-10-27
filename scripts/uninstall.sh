#!/bin/bash

# Locate repository root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "==> Uninstalling DockMin..."

# 1. Stop service and running processes
echo "==> Stopping service and process..."
launchctl unload "$HOME/Library/LaunchAgents/com.github.fatthreeking.DockMin.plist" 2>/dev/null || true

pkill -9 -f "DockMin" 2>/dev/null || true
killall -9 DockMin 2>/dev/null || true

# 2. Remove application bundle and launch agent configuration
echo "==> Removing app and configuration..."
rm -f "$HOME/Library/LaunchAgents/com.github.fatthreeking.DockMin.plist"
rm -f /tmp/dockmin.log /tmp/dockmin.err 2>/dev/null || true

# Remove application bundle from /Applications and ~/Applications
rm -rf "/Applications/DockMin.app" 2>/dev/null || true
rm -rf "$HOME/Applications/DockMin.app" 2>/dev/null || true
rm -rf "$REPO_ROOT/DockMin.app" 2>/dev/null || true
rm -f "$REPO_ROOT/DockMin" 2>/dev/null || true

# 3. Reset macOS Accessibility (TCC) permissions
echo "==> Resetting Accessibility permissions..."
tccutil reset Accessibility com.github.fatthreeking.DockMin 2>/dev/null || true

echo "==> Done."
