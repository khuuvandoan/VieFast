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

# 5. Xử lý Binary (FIX LỖI TÊN + FIX LỖI MENU)
echo "[5/6] Đang cấu hình lõi hệ thống..."

BIN_TEMP=$(find $INSTALL_DIR -maxdepth 2 -type f \( -name "XrayR" -o -name "xrayr*" \) | head -n 1)

if [ -z "$BIN_TEMP" ]; then
    echo "[LỖI] Không tìm thấy file thực thi sau khi giải nén!"
    ls -lah $INSTALL_DIR
    exit 1
fi

mv "$BIN_TEMP" $INSTALL_DIR/xrayr 2>/dev/null
chmod +x $INSTALL_DIR/xrayr

# Tạo lối tắt trực tiếp cho lệnh xrayr
ln -sf $INSTALL_DIR/xrayr /usr/bin/xrayr

if [ ! -f $CONFIG_DIR/config.yml ]; then
    touch $CONFIG_DIR/config.yml
fi

# 6. Tạo Systemd Service (ĐÃ FIX -config THÀNH -c)
echo "[6/6] Đang thiết lập Service chạy ngầm..."

cat <<EOF > /etc/systemd/system/viewarp.service
[Unit]
Description=$BRAND Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/xrayr -c $CONFIG_DIR/config.yml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable viewarp

# TẠO MENU QUẢN LÝ (HỖ TRỢ CẢ GIAO DIỆN & LỆNH GÕ NHANH NHƯ XRAYR GỐC)
cat <<'EOF' > /usr/bin/viewarp
#!/bin/bash

# Kiểm tra nếu người dùng truyền tham số (vd: viewarp start, viewarp log)
if [ $# -gt 0 ]; then
    case $1 in
        start) systemctl start viewarp && echo "Đã khởi động VieWarp!" ;;
        stop) systemctl stop viewarp && echo "Đã dừng VieWarp!" ;;
        restart) systemctl restart viewarp && echo "Đã khởi động lại VieWarp!" ;;
        status) systemctl status viewarp ;;
        log) journalctl -u viewarp -f ;;
        *) /usr/local/viewarp/xrayr "$@" ;; # Chuyển các lệnh khác (như -v) cho nhân XrayR xử lý
    esac
    exit 0
fi

# Nếu không truyền tham số thì hiện Menu giao diện
clear
echo "=========================="
echo "    VieWarp Manager"
echo "=========================="
echo "1) Khởi động (start)"
echo "2) Dừng (stop)"
echo "3) Khởi động lại (restart)"
echo "4) Trạng thái (status)"
echo "5) Xem Logs (log)"
echo "6) Xem phiên bản Core (-v)"
echo "=========================="
read -p "Chọn chức năng (1-6): " c

case $c in
1) systemctl start viewarp && echo "Đã khởi động!" ;;
2) systemctl stop viewarp && echo "Đã dừng!" ;;
3) systemctl restart viewarp && echo "Đã khởi động lại!" ;;
4) systemctl status viewarp ;;
5) journalctl -u viewarp -f ;;
6) /usr/local/viewarp/xrayr -v ;;
*) echo "Lựa chọn không hợp lệ" ;;
esac
EOF

chmod +x /usr/bin/viewarp

echo ""
echo "===================================="
echo " 🎉 CÀI ĐẶT CORE VIEWARP HOÀN TẤT!"
echo " - Mở Menu: viewarp"
echo " - Xem log nhanh: viewarp log"
echo " - Kiểm tra version: viewarp -v"
echo "===================================="
