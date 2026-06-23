#!/usr/bin/env bash
set -e

THEME="conky_tron"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/conky/$THEME"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "Installing $THEME..."
mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$AUTOSTART_DIR"

cp "$SCRIPT_DIR/conky.conf"    "$CONFIG_DIR/"
cp "$SCRIPT_DIR/tron_grid.lua" "$CONFIG_DIR/"

cat > "$BIN_DIR/start-$THEME.sh" << LAUNCHER
#!/usr/bin/env bash
sleep 10
pkill -f "conky.*$THEME" 2>/dev/null || true
sleep 1
conky -c "\$HOME/.config/conky/$THEME/conky.conf" &
LAUNCHER
chmod +x "$BIN_DIR/start-$THEME.sh"

cat > "$AUTOSTART_DIR/$THEME.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=Conky TRON Grid
Exec=$BIN_DIR/start-$THEME.sh
StartupNotify=false
Terminal=false
Hidden=false
DESKTOP

echo "Installed to: $CONFIG_DIR"
echo "Start now: pkill -x conky 2>/dev/null; sleep 1; conky -c $CONFIG_DIR/conky.conf &"
echo "Autostart: $AUTOSTART_DIR/$THEME.desktop"
