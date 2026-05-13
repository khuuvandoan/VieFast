#!/bin/bash

# =========================
# VieWarp Auto Installer
# =========================

BRAND="VieWarp"
VERSION="v1.0.1"

echo "======================================"
echo "  Install $BRAND - $VERSION"
echo "======================================"

# 1. Update system
echo "[1/7] Update system..."
apt update -y && apt install -y wget unzip curl

# 2. Create directories
echo "[2/7] Create directories..."
mkdir -p /usr/local/viewarp
mkdir -p /etc/viewarp

# 3. Download release
echo "[3/7] Download XrayR release..."
cd /usr/local/viewarp || exit 1

wget -O viewarp.zip "https://github.com/khuuvandoan/VieFast/releases/latest/download/XrayR-linux-64.zip"

if [ ! -f viewarp.zip ]; then
    echo "[ERROR] Download failed!"
    exit 1
fi

# 4. Unzip
echo "[4/7] Extracting..."
unzip -o viewarp.zip

# 5. Detect binary automatically
echo "[5/7] Detect binary..."

BIN=$(find /usr/local/viewarp -type f \( -name "XrayR*" -o -name "xrayr*" \) | head -n 1)

if [ -z "$BIN" ]; then
    echo "[ERROR] Binary not found after unzip!"
    ls -lah /usr/local/viewarp
    exit 1
fi

echo "[INFO] Found binary: $BIN"

chmod +x "$BIN"

# Create global command
ln -sf "$BIN" /usr/bin/xrayr

# 6. Create systemd service
echo "[6/7] Create systemd service..."

cat <<EOF > /etc/systemd/system/viewarp.service
[Unit]
Description=$BRAND Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/viewarp/
ExecStart=/usr/bin/xrayr -config /etc/viewarp/config.yml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable viewarp

# 7. Create CLI menu
echo "[7/7] Create CLI tool..."

cat <<'EOF' > /usr/bin/viewarp
#!/bin/bash

echo "=========================="
echo "   VieWarp Manager"
echo "=========================="
echo "1) Start"
echo "2) Stop"
echo "3) Restart"
echo "4) Status"
echo "5) Logs"
echo "=========================="
read -p "Choose: " c

case $c in
1) systemctl start viewarp ;;
2) systemctl stop viewarp ;;
3) systemctl restart viewarp ;;
4) systemctl status viewarp ;;
5) journalctl -u viewarp -f ;;
*) echo "Invalid option" ;;
esac
EOF

chmod +x /usr/bin/viewarp

echo ""
echo "======================================"
echo " INSTALL COMPLETED SUCCESSFULLY"
echo " Run: viewarp"
echo " Run: systemctl start viewarp"
echo " Check: xrayr version"
echo "======================================"
