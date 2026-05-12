#!/bin/bash

# Thông tin thương hiệu
BRAND="VieWarp"
VERSION="v1.0.0 Alpha"

echo "------------------------------------------"
echo "  Cài đặt $BRAND - Phiên bản $VERSION"
echo "------------------------------------------"

# 1. Tạo file Service trực tiếp (Không cần file XrayR.service riêng trên GitHub)
echo "[*] Đang cấu hình hệ thống..."
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

# 2. Giả lập logic cài đặt (Bạn hãy thay thế bằng link file binary của bạn)
mkdir -p /usr/local/viewarp
mkdir -p /etc/viewarp

# 3. Tích hợp Menu điều khiển (Gộp XrayR.sh vào đây)
cat <<EOF > /usr/bin/viewarp
#!/bin/bash
echo "--- Menu Quản Lý $BRAND ---"
echo "1. Khởi động"
echo "2. Dừng"
echo "3. Xem Log"
# Thêm các chức năng khác từ xraypro.sh của bạn vào đây
EOF

chmod +x /usr/bin/viewarp

echo "[+] Cài đặt hoàn tất! Gõ 'viewarp' để mở menu điều khiển."
