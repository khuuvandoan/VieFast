#!/bin/bash

BRAND="viewarp"
VERSION="v1.0.4"
INSTALL_DIR="/usr/local/viewarp"
CONFIG_DIR="/etc/viewarp"

echo "===================================="
echo "  CÀI ĐẶT $BRAND - PHIÊN BẢN $VERSION"
echo "===================================="

# 1. Cài đặt các gói phụ thuộc
apt update -y && apt install -y wget unzip curl iptables-persistent netfilter-persistent

# 2. Tạo thư mục hệ thống
mkdir -p $INSTALL_DIR
mkdir -p $CONFIG_DIR

cd $INSTALL_DIR || exit 1

# 3. Tải mã nguồn từ chính Release v1.0.4 của bạn
echo "[3/6] Đang tải mã nguồn từ GitHub VieFast..."
wget -O viewarp.zip "https://github.com/khuuvandoan/VieFast/releases/download/v1.0.4/XrayR-linux-64.zip"

if [ ! -f viewarp.zip ]; then
    echo "[LỖI] Không tìm thấy file zip. Vui lòng kiểm tra lại link Release!"
    exit 1
fi

# 4. Giải nén
unzip -o viewarp.zip

# 5. Chuẩn hóa file thực thi (Fix lỗi 203/EXEC)
# Tìm bất kỳ file nào có thuộc tính thực thi trong thư mục
BIN_FOUND=$(find . -maxdepth 1 -type f -executable -not -name "*.sh" -not -name "*.zip" | head -n 1)

if [ -z "$BIN_FOUND" ]; then
    # Nếu không tìm thấy bằng quyền, tìm theo tên phổ biến
    BIN_FOUND=$(find . -maxdepth 1 -type f \( -name "XrayR" -o -name "xrayr" \) | head -n 1)
fi

if [ -n "$BIN_FOUND" ]; then
    mv "$BIN_FOUND" "$INSTALL_DIR/xrayr"
    chmod +x "$INSTALL_DIR/xrayr"
    ln -sf "$INSTALL_DIR/xrayr" /usr/bin/xrayr
else
    echo "[LỖI] Không tìm thấy file chạy sau khi giải nén!"
    exit 1
fi

# 6. Thiết lập Service (Dùng cờ -c cho bản Mtoly)
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
StartLimitIntervalSec=0
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable viewarp
systemctl restart viewarp

# 7. Tạo Menu quản lý (Giao diện dọc chuyên nghiệp)
cat <<'EOF' > /usr/bin/viewarp
#!/bin/bash
case $1 in
    start) systemctl start viewarp ;;
    stop) systemctl stop viewarp ;;
    restart) systemctl restart viewarp ;;
    status) systemctl status viewarp ;;
    log) journalctl -u viewarp -f ;;
    *)
        clear
        echo -e "====================================="
        echo -e "          MENU QUẢN LÝ NODE          "
        echo -e "====================================="
        echo -e "  1. Start (Khởi động)"
        echo -e "  2. Stop (Dừng chạy)"
        echo -e "  3. Restart (Khởi động lại)"
        echo -e "  4. Check log (Xem nhật ký)"
        echo -e "  5. Delete (Xóa trắng Node)"
        echo -e "  6. Version (Xem phiên bản)"
        echo -e "  0. Thoát"
        echo -e "====================================="
        echo -e -n "Chọn chức năng (0-6): "
        read c
        case $c in
            1) systemctl start viewarp; echo "Đã Start Node." ;;
            2) systemctl stop viewarp; echo "Đã Stop Node." ;;
            3) systemctl restart viewarp; echo "Đã Restart Node." ;;
            4) journalctl -u viewarp -f ;;
            5) 
                echo -n "Bạn có chắc chắn muốn xóa toàn bộ Node không? (y/n): "
                read confirm
                if [ "$confirm" == "y" ]; then
                    systemctl stop viewarp
                    systemctl disable viewarp
                    rm -rf /usr/local/viewarp
                    rm -f /etc/systemd/system/viewarp.service
                    systemctl daemon-reload
                    echo "Đã xóa hoàn toàn Node và Service."
                else
                    echo "Đã hủy thao tác xóa."
                fi
                ;;
            6) /usr/local/viewarp/xrayr -version ;;
            0) exit 0 ;;
            *) echo "Lựa chọn không hợp lệ!" ;;
        esac
        ;;
esac
EOF
chmod +x /usr/bin/viewarp

echo "🎉 CÀI ĐẶT CORE HOÀN TẤT! Dùng lệnh: viewarp"
