#!/bin/bash

BRAND="VieWarp"
VERSION="v1.0.1"
INSTALL_DIR="/usr/local/viewarp"
CONFIG_DIR="/etc/viewarp"

echo "===================================="
echo "  CÀI ĐẶT $BRAND - PHIÊN BẢN CHUẨN"
echo "===================================="

# 1. Cài đặt các gói phụ thuộc
echo "[1/6] Đang cài đặt các công cụ cần thiết..."
apt update -y && apt install -y wget unzip curl

# 2. Tạo thư mục hệ thống
echo "[2/6] Đang tạo cấu trúc thư mục..."
mkdir -p $INSTALL_DIR
mkdir -p $CONFIG_DIR

cd $INSTALL_DIR || exit 1

# 3. Tải mã nguồn từ GitHub Release
echo "[3/6] Đang tải mã nguồn..."
wget -O viewarp.zip "https://github.com/khuuvandoan/VieFast/releases/latest/download/XrayR-linux-64.zip"

if [ ! -f viewarp.zip ]; then
    echo "[LỖI] Tải file thất bại. Vui lòng kiểm tra lại đường dẫn!"
    exit 1
fi

# 4. Giải nén
echo "[4/6] Đang giải nén dữ liệu..."
unzip -o viewarp.zip

# 5. Xử lý Binary (TỰ ĐỘNG FIX LỖI TÊN CHỮ HOA/CHỮ THƯỜNG)
echo "[5/6] Đang cấu hình lõi hệ thống..."

# Quét tìm file chạy (bất kể tên là XrayR hay xrayr)
BIN_TEMP=$(find $INSTALL_DIR -maxdepth 2 -type f \( -name "XrayR" -o -name "xrayr*" \) | head -n 1)

if [ -z "$BIN_TEMP" ]; then
    echo "[LỖI] Không tìm thấy file thực thi sau khi giải nén!"
    ls -lah $INSTALL_DIR
    exit 1
fi

# Đổi tên chuẩn hóa thành "xrayr" để tránh mọi lỗi của Linux
mv "$BIN_TEMP" $INSTALL_DIR/xrayr 2>/dev/null
chmod +x $INSTALL_DIR/xrayr

# Tạo lối tắt hệ thống
ln -sf $INSTALL_DIR/xrayr /usr/bin/xrayr

# Tạo file cấu hình rỗng (chống lỗi Service bị crash nếu chưa có config)
if [ ! -f $CONFIG_DIR/config.yml ]; then
    touch $CONFIG_DIR/config.yml
fi

# 6. Tạo Systemd Service
echo "[6/6] Đang thiết lập Service chạy ngầm..."

cat <<EOF > /etc/systemd/system/viewarp.service
[Unit]
Description=$BRAND Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/xrayr -config $CONFIG_DIR/config.yml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable viewarp

# Tạo Menu quản lý (Lệnh: viewarp)
cat <<'EOF' > /usr/bin/viewarp
#!/bin/bash
clear
echo "=========================="
echo "    VieWarp Manager"
echo "=========================="
echo "1) Khởi động (Start)"
echo "2) Dừng (Stop)"
echo "3) Khởi động lại (Restart)"
echo "4) Trạng thái (Status)"
echo "5) Xem Logs"
echo "=========================="
read -p "Chọn chức năng (1-5): " c

case $c in
1) systemctl start viewarp && echo "Đã khởi động!" ;;
2) systemctl stop viewarp && echo "Đã dừng!" ;;
3) systemctl restart viewarp && echo "Đã khởi động lại!" ;;
4) systemctl status viewarp ;;
5) journalctl -u viewarp -f ;;
*) echo "Lựa chọn không hợp lệ" ;;
esac
EOF

chmod +x /usr/bin/viewarp

echo ""
echo "===================================="
echo " 🎉 CÀI ĐẶT CORE VIEWARP HOÀN TẤT!"
echo " - Menu Quản lý: viewarp"
echo " - Lệnh gốc: xrayr"
echo "===================================="
