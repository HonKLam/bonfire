#!/usr/bin/env bash

set -euo pipefail

# --- Variables ---

BF_DIR="$HOME/.local/share/bonfire"
NOCTALIA_DIR="$HOME/.config/noctalia"
TEMPLATE_DIR="$NOCTALIA_DIR/templates"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT="$UNIT_DIR/bonfire.service"

die() { echo "error: $*" >&2; exit 1; }

# --- Preflight ---

# Don't run as root or sudo

if [[ $EUID -eq 0 ]]; then
	die "please don't run this with sudo"
fi

# --- systemd user service ---

# Stop before deleting anything
if command -v systemctl >/dev/null 2>&1; then
	systemctl --user disable --now bonfire.service 2>/dev/null || true
fi

if [[ -e "$UNIT" ]]; then
	rm -f "$UNIT"
	echo "removed $UNIT"
	command -v systemctl >/dev/null 2>&1 && systemctl --user daemon-reload || true
fi

# --- Static files ---

if [[ -d "$BF_DIR" ]]; then
	rm -rf "$BF_DIR"
	echo "removed $BF_DIR"
fi

# --- Noctalia template ---

if [[ -e "$TEMPLATE_DIR/bonfire.css" ]]; then
	rm -f "$TEMPLATE_DIR/bonfire.css"
	echo "removed $TEMPLATE_DIR/bonfire.css"
fi

# --- Leftovers we refuse to touch ---

# Same reasoning as install.sh: the config is yours, so removing the block is
# your call, not this script's.
echo
echo "bonfire uninstalled"
echo "One thing left for you: delete this block from your noctalia/config.toml,"
echo "otherwise noctalia keeps rendering a template into a directory that is gone."
echo "
[theme.templates.user.bonfire]
input_path = \"$TEMPLATE_DIR/bonfire.css\"
output_path = \"$BF_DIR/colors.css\"
"
