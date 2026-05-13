#!/bin/bash

BRAND="VieWarp"
INSTALL_DIR="/usr/local/viewarp"
CONFIG_DIR="/etc/viewarp"

echo "===================================="
echo "  INSTALL $BRAND AUTO FIX VERSION"
echo "===================================="

# 1. Install dependencies
echo "[1/6] Installing dependencies..."
apt update -y && apt install -y wget unzip curl

# 2. Create folders
echo "[2/6] Creating folders..."
mkdir -p $INSTALL_DIR
mkdir -p $CONFIG_DIR

cd $INSTALL_DIR || exit 1

# 3. Download XrayR
echo "[3/6] Downloading XrayR..."
wget -O viewarp.zip "https://github.com/khuuvandoan/VieFast/releases/latest/download/XrayR-linux-64.zip"

if [ ! -f viewarp.zip ]; then
    echo "[ERROR] Download failed"
    exit 1
fi

# 4. Extract
echo "[4/6] Extracting..."
unzip -o viewarp.zip

# 5. FIX: detect REAL binary (IMPORTANT FIX)
echo "[5/6] Detecting binary..."

BIN=$(find $INSTALL_DIR -type f \( -name "XrayR" -o -name "XrayR*" \) | head -n 1)

if [ -z "$BIN" ]; then
    echo "[ERROR] No XrayR binary found!"
    ls -lah $INSTALL_DIR
    exit 1
fi

echo "[OK] Found binary: $BIN"

chmod +x "$BIN"

# IMPORTANT FIX: create system command
ln -sf "$BIN" /usr/bin/xrayr

# 6. systemd service FIXED
echo "[6/6] Creating service..."

cat <<EOF > /etc/systemd/system/viewarp.service
[Unit]
Description=$BRAND Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$BIN -config $CONFIG_DIR/config.yml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable viewarp

# CLI menu
cat <<'EOF' > /usr/bin/viewarp
#!/bin/bash
echo "==== VieWarp Manager ===="
echo "1) Start"
echo "2) Stop"
echo "3) Restart"
echo "4) Status"
echo "5) Logs"
read -p "Choose: " c

case $c in
1) systemctl start viewarp ;;
2) systemctl stop viewarp ;;
3) systemctl restart viewarp ;;
4) systemctl status viewarp ;;
5) journalctl -u viewarp -f ;;
*) echo "Invalid" ;;
esac
EOF

chmod +x /usr/bin/viewarp

echo ""
echo "===================================="
echo " INSTALL DONE"
echo " Run: systemctl start viewarp"
echo " Run: xrayr"
echo " Run: viewarp"
echo "===================================="
