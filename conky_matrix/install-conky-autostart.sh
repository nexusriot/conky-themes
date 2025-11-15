#!/usr/bin/env bash
set -e

mkdir -p ~/.config/conky/conky_matrix
cp conky.conf matrix.lua ~/.config/conky/conky_matrix/

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/start-conky.sh" <<'EOF'
#!/usr/bin/env bash
# Wait a bit for DE/WM and compositor to start
sleep 10
conky -q -c "$HOME/.config/conky/conky_matrix/conky.conf" &
EOF

chmod +x "$HOME/.local/bin/start-conky.sh"
mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/conky.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=$HOME/.local/bin/start-conky.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Conky
Comment=Start Conky on login
EOF

echo "✅ Conky autostart installed!"
echo "  Script:  $HOME/.local/bin/start-conky.sh"
echo "  Desktop: $HOME/.config/autostart/conky.desktop"
echo
echo "Conky will auto-launch 10 seconds after login."
