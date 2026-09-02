#!/usr/bin/env bash

set -euo pipefail

# --- Variables ---

BF_DIR="$HOME/.local/share/bonfire"
NOCTALIA_DIR="$HOME/.config/noctalia"
NOCTALIA_TEMPLATE_DIR="$NOCTALIA_DIR/templates"
MATUGEN_DIR="$HOME/.config/matugen"
MATUGEN_TEMPLATE_DIR="$MATUGEN_DIR/templates"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT="$UNIT_DIR/bonfire.service"

die() { echo "error: $*" >&2; exit 1; }

usage() {
	cat <<'EOF'
usage: uninstall.sh [--backend noctalia|matugen]

  --backend  only remove the template of that backend. Without it, a bonfire
             template is removed from whichever of the two it is found in.
EOF
}

# --- Arguments ---

BACKEND=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		(--backend) BACKEND="${2:-}"; shift 2 ;;
		(--backend=*) BACKEND="${1#*=}"; shift ;;
		(-h|--help) usage; exit 0 ;;
		(*) usage >&2; die "unknown argument: $1" ;;
	esac
done

case "$BACKEND" in
	(""|noctalia|matugen) ;;
	(*) die "unknown backend '$BACKEND' -- expected noctalia or matugen" ;;
esac

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

# --- Templates ---

# An uninstall shouldn't have to be told which backend was used, so unless you
# name one we clear the template out of both.
REMOVED_NOCTALIA=false
REMOVED_MATUGEN=false

if [[ "$BACKEND" != "matugen" && -e "$NOCTALIA_TEMPLATE_DIR/bonfire.css" ]]; then
	rm -f "$NOCTALIA_TEMPLATE_DIR/bonfire.css"
	echo "removed $NOCTALIA_TEMPLATE_DIR/bonfire.css"
	REMOVED_NOCTALIA=true
fi

if [[ "$BACKEND" != "noctalia" && -e "$MATUGEN_TEMPLATE_DIR/bonfire.css" ]]; then
	rm -f "$MATUGEN_TEMPLATE_DIR/bonfire.css"
	echo "removed $MATUGEN_TEMPLATE_DIR/bonfire.css"
	REMOVED_MATUGEN=true
fi

# --- Static files ---

if [[ -d "$BF_DIR" ]]; then
	rm -rf "$BF_DIR"
	echo "removed $BF_DIR"
fi

# --- Leftovers we don't touch ---

echo
echo "bonfire uninstalled"

if $REMOVED_NOCTALIA; then
	echo "One thing left for you: delete this block from your noctalia/config.toml,"
	echo "otherwise noctalia keeps rendering a template into a directory that is gone."
	echo "
[theme.templates.user.bonfire]
input_path = \"$NOCTALIA_TEMPLATE_DIR/bonfire.css\"
output_path = \"$BF_DIR/colors.css\"
"
fi

if $REMOVED_MATUGEN; then
	echo "One thing left for you: delete this block from your matugen/config.toml,"
	echo "otherwise matugen keeps rendering a template into a directory that is gone."
	echo "
[templates.bonfire]
input_path = \"$MATUGEN_TEMPLATE_DIR/bonfire.css\"
output_path = \"$BF_DIR/colors.css\"
"
fi
