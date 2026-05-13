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

# Sử dụng link trực tiếp từ repo VieFast của bạn
wget -O viewarp.zip "https://github.com/khuuvandoan/VieFast/releases/latest/download/XrayR-linux-64.zip"

if [ ! -f viewarp.zip ]; then
    echo "[ERROR] Download failed!"
    exit 1
fi

# 4. Unzip
echo "[4/7] Extracting..."
unzip -o viewarp.zip

# 5. Cố định tên Binary để tránh lỗi tìm kiếm
echo "[5/7] Configuring binary..."

# Ép tên file binary về đúng chuẩn xrayr để dễ quản lý
if [ -f "XrayR" ]; then
    mv XrayR xrayr
fi

chmod +x xrayr

# Tạo link hệ thống để gõ 'xrayr' ở bất cứ đâu
ln -sf /usr/local/viewarp/xrayr /usr/bin/xrayr

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

# 7. Create CLI menu (Fix lỗi Menu rỗng)
echo "[7/7] Create CLI tool..."

cat <<'EOF' > /usr/bin/viewarp
#!/bin/bash
clear
echo "=========================="
echo "    VieWarp Manager"
echo "=========================="
echo "1) Start"
echo "2) Stop"
echo "3) Restart"
echo "4) Status"
echo "5) Logs"
echo "=========================="
read -p "Choose: " c

case $c in
1) systemctl start viewarp && echo "Started!" ;;
2) systemctl stop viewarp && echo "Stopped!" ;;
3) systemctl restart viewarp && echo "Restarted!" ;;
4) systemctl status viewarp ;;
5) journalctl -u viewarp -f ;;
*) echo "Invalid option" ;;
esac
EOF

chmod +x /usr/bin/viewarp

# Tạo file config mẫu nếu chưa có để tránh lỗi Service không khởi động được
if [ ! -f /etc/viewarp/config.yml ]; then
    echo "[INFO] Creating template config.yml..."
    touch /etc/viewarp/config.yml
fi

echo ""
echo "======================================"
echo " INSTALL COMPLETED SUCCESSFULLY"
echo "--------------------------------------"
echo " Chạy menu: viewarp"
echo " Chạy lệnh gốc: xrayr"
echo " Kiểm tra version: xrayr -v"
echo "======================================"
