#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Chỉ người dùng root mới có thể thực thi lệnh${PLAIN}"
    exit 1
fi
if [[ -f "/etc/os-release" ]]; then
    OS_RELEASE=$(awk -F= '$1=="ID" {print $2}' /etc/os-release | tr -d '"')
    OS_VERSION=$(awk -F= '$1=="VERSION_ID" {print $2}' /etc/os-release | tr -d '"')
    IFS='.' read -r -a OS_VERSION <<< "$OS_VERSION"
    OS_VERSION=${OS_VERSION[0]}
fi
if [[ ! $OS_RELEASE || ! $OS_VERSION ]]; then
    if [[ -f "/usr/lib/os-release" ]]; then
        OS_RELEASE=$(awk -F= '$1=="ID" {print $2}' /usr/lib/os-release | tr -d '"')
        OS_VERSION=$(awk -F= '$1=="VERSION_ID" {print $2}' /usr/lib/os-release | tr -d '"')
        IFS='.' read -r -a OS_VERSION <<< "$OS_VERSION"
        OS_VERSION=${OS_VERSION[0]}
    fi
fi
ARCH=$(arch)
if [[ $ARCH == "i386" || $ARCH == "i686" ]]; then
    ARCH="386"
elif [[ $ARCH == "x86_64" || $ARCH == "x64" ]]; then
    ARCH="amd64"
elif [[ $ARCH == "aarch64" || $ARCH == "arm64-v8a" ]]; then
    ARCH="arm64"
else
    ARCH="amd64"
    echo -e "${YELLOW}Không phát hiện được cấu trúc thiết bị sử dụng cấu trúc mặc định ${GREEN}${ARCH}${PLAIN}"
fi
echo -e "${PLAIN}Kiến trúc: ${GREEN}${ARCH}${PLAIN}"
SUPPORTED_OS=0
if [[ x"${OS_RELEASE}" == x"centos" && ${OS_VERSION} -eq 7 ]]; then
    SUPPORTED_OS=1
    yum update -y
    yum install -y epel-release
    yum install -y wget curl unzip tar crontabs socat
fi
if [[ x"${OS_RELEASE}" == x"centos" && ${OS_VERSION} -eq 8 ]]; then
    SUPPORTED_OS=1
    dnf update -y
    dnf install -y epel-release
    dnf install -y wget curl unzip tar crontabs socat
fi
if [[ x"${OS_RELEASE}" == x"ubuntu" && ${OS_VERSION} -ge 16 ]]; then
    SUPPORTED_OS=1
    apt update -y
    apt install -y wget curl unzip tar cron socat
fi
if [[ x"${OS_RELEASE}" == x"debian" && ${OS_VERSION} -ge 8 ]]; then
    SUPPORTED_OS=1
    apt update -y
    apt install -y wget curl unzip tar cron socat
fi
if [[ ${SUPPORTED_OS} -eq 0 ]]; then
    echo -e "${RED}Hệ điều hành không được VieFast hỗ trợ. VieFast chỉ hỗ trợ các hệ điều hành sau:${PLAIN}"
    echo -e "${GREEN}CentOS 7${PLAIN}"
    echo -e "${GREEN}CentOS 8${PLAIN}"
    echo -e "${GREEN}Ubuntu 16 trở lên${PLAIN}"
    echo -e "${GREEN}Debian 8 trở lên${PLAIN}"
    exit 0
fi
if [[ ! -z ${1} ]]; then
    VIEFAST_VERSION=${1}
else
    VIEFAST_VERSION=$(curl -Ls "https://api.github.com/repos/khuuvandoan/VieFast/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
fi
GITHUB_API=($(curl -Ls "https://api.github.com/repos/khuuvandoan/VieFast/releases" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/'))
EXIST=false
for ITEM in ${GITHUB_API[@]}; do
    if [[ ${ITEM} == "https://github.com/khuuvandoan/VieFast/releases/download/${VIEFAST_VERSION}/linux-${ARCH}.zip" ]]; then
        EXIST=true
    fi
done
if [[ ${EXIST} == false ]]; then
    echo -e "${RED}Không tìm thấy thấy ${GREEN}VieFast${RED} phiên bản ${GREEN}${VIEFAST_VERSION}${RED} cho kiến trúc ${GREEN}${ARCH}${RED} tham khảo phiên bản tại ${GREEN}https://github.com/khuuvandoan/VieFast/releases${PLAIN}"
else
    if [[ -e "/usr/local/VieFast" ]]; then
        rm -rf "/usr/local/VieFast"
    fi
    if [[ -e "/etc/VieFast" ]]; then
        rm -rf "/etc/VieFast"
    fi
    if [[ -f "/etc/systemd/system/VieFast.service" ]]; then
        rm -f "/etc/systemd/system/VieFast.service"
    fi
    if [[ -f "/usr/bin/VieFast" ]]; then
        rm -f "/usr/bin/VieFast"
    fi
    if [[ -f "/usr/bin/viefast" ]]; then
        rm -f "/usr/bin/viefast"
        unlink "/usr/bin/viefast"
    fi
    mkdir "/usr/local/VieFast"
    cd "/usr/local/VieFast"
    wget -q -N --no-check-certificate -O "/usr/local/VieFast/linux-${ARCH}.zip" "https://github.com/khuuvandoan/VieFast/releases/download/${VIEFAST_VERSION}/linux-${ARCH}.zip"
    unzip "linux-${ARCH}.zip"
    rm -f "/usr/local/VieFast/linux-${ARCH}.zip"
    cp -R "/usr/local/VieFast" "/etc/VieFast"
    rm -f "/etc/VieFast/VieFast"
    rm -f "/etc/VieFast/VieFast.sh"
    rm -f "/etc/VieFast/VieFast.service"
    mkdir "/etc/VieFast/certificate"
    cp -R "/usr/local/VieFast/VieFast.sh" "/usr/bin/VieFast"
    chmod +x "/usr/bin/VieFast"
    ln -s "/usr/bin/VieFast" "/usr/bin/viefast"
    chmod +x "/usr/bin/viefast"
    cp -R "/usr/local/VieFast/VieFast.service" "/etc/systemd/system/VieFast.service"
    systemctl reset-failed
    systemctl daemon-reload
    systemctl enable VieFast
    systemctl start VieFast
    if [[ -f "/etc/systemd/system/VieFast.service" ]]; then
        echo -e "${GREEN}Cài đặt VieFast thành công${PLAIN}"
    else
        echo -e "${RED}Cài đặt VieFast thất bại${PLAIN}"
    fi
    while true; do
        echo -en "${YELLOW}Để trống ấn Enter để thoát tập lệnh, nếu cần thêm máy chủ nhập số lượng máy chủ ấn Enter để thêm máy chủ: ${PLAIN}"
        read INPUT_KEY
        if [[ -z ${INPUT_KEY} ]]; then
            break
            exit 0
        else
            if [ -z "${INPUT_KEY##*[!0-9]*}" ]; then
                echo -e "${RED}Số lượng máy chủ không hợp lệ${PLAIN}"
            else
                for ((INDEX=1; INDEX<=$INPUT_KEY; INDEX++)); do
                    if [[ ${INDEX} != 1 ]]; then
                        echo -e "----------------------------------------"
                    fi
                    echo -e "${RED}Địa chỉ giao tiếp máy chủ số ${INDEX}${PLAIN}"
                    echo -en "${PLAIN}Vui lòng nhập: ${GREEN}"
                    read API_HOST
                    echo -en "${PLAIN}"
                    echo -e "${RED}Mã giao tiếp máy chủ số ${INDEX}${PLAIN}"
                    echo -en "${PLAIN}Vui lòng nhập: ${GREEN}"
                    read API_KEY
                    echo -en "${PLAIN}"
                    echo -e "${RED}Kiểu máy chủ số ${INDEX}${PLAIN}"
                    echo -e "${PLAIN}Mặc định: ${YELLOW}V2ray${PLAIN}"
                    echo -e "${PLAIN}Nhập ${RED}[${GREEN}1${RED}]${PLAIN} Shadowsocks"
                    echo -e "${PLAIN}Nhập ${RED}[${GREEN}2${RED}]${PLAIN} V2ray"
                    echo -e "${PLAIN}Nhập ${RED}[${GREEN}3${RED}]${PLAIN} Trojan"
                    echo -en "${PLAIN}Vui lòng nhập: ${GREEN}"
                    read API_TYPE
                    echo -en "${PLAIN}"
                    if [[ ${API_TYPE} == 1 ]]; then
                        API_TYPE="Shadowsocks"
                    elif [[ ${API_TYPE} == 2 ]]; then
                        API_TYPE="V2ray"
                    elif [[ ${API_TYPE} == 3 ]]; then
                        API_TYPE="Trojan"
                    else
                        API_TYPE="V2ray"
                    fi
                    echo -e "${RED}Số thứ tự máy chủ số ${INDEX}${PLAIN}"
                    echo -en "${PLAIN}Vui lòng nhập: ${GREEN}"
                    read API_ID
                    echo -en "${PLAIN}"
                    TLS_DOMAIN=$(curl -Ls "${API_HOST}/api/v1/guest/tls/domain/${API_KEY}")
                    if [[ -z "${TLS_DOMAIN}" ]]; then
                        echo -e "${RED}Cài đặt máy chủ số ${INDEX} thất bại${PLAIN}"
                    else
                        curl -Lsk \
                            -o "/etc/VieFast/certificate/${TLS_DOMAIN}.key" \
                            -X GET "${API_HOST}/api/v1/guest/tls/privatekey/${API_KEY}"
                        curl -Lsk \
                            -o "/etc/VieFast/certificate/${TLS_DOMAIN}.crt" \
                            -X GET "${API_HOST}/api/v1/guest/tls/certificate/${API_KEY}"
                        curl -Lsk \
                            -o "/etc/VieFast/config.yml" \
                            -H "Content-Type: application/x-www-form-urlencoded" \
                            -d "type=${API_TYPE}" \
                            -d "id=${API_ID}" \
                            -d "config=$([[ -f "/etc/VieFast/config.yml" ]] && cat "/etc/VieFast/config.yml" | base64)" \
                            -d "config_example=$([[ -f "/usr/local/VieFast/config.yml.example" ]] && cat "/usr/local/VieFast/config.yml.example" | base64)" \
                            -X POST "${API_HOST}/api/v1/guest/resource/config/${API_KEY}"
                        echo -e "${GREEN}Cài đặt máy chủ số ${INDEX} thành công${PLAIN}"
                    fi
                done
                break
            fi
        fi
    done
    systemctl restart VieFast
    systemctl restart VieFast
    sleep 2
    TEMP=$(systemctl status VieFast | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${TEMP}" == x"running" ]]; then
        echo -e "${GREEN}VieFast khởi động thành công${PLAIN}"
    else
        echo -e "${RED}VieFast khởi động thất bại${PLAIN}"
    fi
fi
