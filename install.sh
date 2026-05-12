#!/bin/bash

# Thông tin thương hiệu
BRAND="VieWarp"
VERSION="v1.0.1" # Cập nhật theo bản release mới nhất trên GitHub của bạn

echo "------------------------------------------"
echo "  Cài đặt $BRAND - Phiên bản $VERSION"
echo "------------------------------------------"

# 1. Cài đặt các công cụ cần thiết (nếu chưa có)
echo "[*] Đang kiểm tra công cụ hỗ trợ..."
apt update && apt install -y wget unzip

# 2. Tạo thư mục hệ thống
mkdir -p /usr/local/viewarp
mkdir -p /etc/viewarp

# 3. Tải và cài đặt file từ Release GitHub của bạn
echo "[*] Đang tải bộ cài từ GitHub..."
# Sử dụng link trực tiếp từ repo VieFast mà bạn đã tạo
wget -O /usr/local/viewarp/viewarp.zip https://github.com/khuuvandoan/VieFast/releases/latest/download/XrayR-linux-64.zip
unzip -o /usr/local/viewarp/viewarp.zip -d /usr/local/viewarp/
chmod +x /usr/local/viewarp/xrayr

# 4. Tạo file Service trực tiếp
echo "[*] Đang cấu hình service hệ thống..."
cat <<EOF > /etc/systemd/system/viewarp.service
[Unit]
Description=$BRAND Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/viewarp/
ExecStart=/usr/local/viewarp/xrayr -config /etc/viewarp/config.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# 5. Tích hợp Menu điều khiển (Lệnh gọi nhanh: viewarp)
cat <<EOF > /usr/bin/viewarp
#!/bin/bash
echo "--- Menu Quản Lý $BRAND ---"
echo "1. Start: systemctl start viewarp"
echo "2. Stop:  systemctl stop viewarp"
echo "3. Logs:  journalctl -u viewarp -f"
# Bạn có thể copy nội dung từ file XrayR.sh cũ vào đây để hoàn thiện menu
EOF

chmod +x /usr/bin/viewarp

echo "[+] Cài đặt hoàn tất! Gõ 'viewarp' để quản lý."
