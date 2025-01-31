#!/bin/bash
colorized_echo() {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    colorized_echo red "Error: Skrip ini harus dijalankan sebagai root."
    exit 1
fi

# Check supported operating system
supported_os=false

if [ -f /etc/os-release ]; then
    os_name=$(grep -E '^ID=' /etc/os-release | cut -d= -f2)
    os_version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    if [ "$os_name" == "debian" ] && [ "$os_version" == "11" ]; then
        supported_os=true
    elif [ "$os_name" == "ubuntu" ] && [ "$os_version" == "20.04" ]; then
        supported_os=true
    fi
fi
apt install sudo curl -y
if [ "$supported_os" != true ]; then
    colorized_echo red "Error: Skrip ini hanya support di Debian 11 dan Ubuntu 20.04. Mohon gunakan OS yang di support."
    exit 1
fi

# Fungsi untuk menambahkan repo Debian 11
addDebian11Repo() {
    echo "#mirror_kambing-sysadmind deb11
deb http://kartolo.sby.datautama.net.id/debian bullseye main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian bullseye-updates main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security bullseye-security main contrib non-free" | sudo tee /etc/apt/sources.list > /dev/null
}

# Fungsi untuk menambahkan repo Ubuntu 20.04
addUbuntu2004Repo() {
    echo "#mirror buaya klas 20.04
deb https://buaya.klas.or.id/ubuntu/ focal main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-updates main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-security main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-backports main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-proposed main restricted universe multiverse" | sudo tee /etc/apt/sources.list > /dev/null
}

# Mendapatkan informasi kode negara dan OS
COUNTRY_CODE=$(curl -s https://ipinfo.io/country)
OS=$(lsb_release -si)

# Pemeriksaan IP Indonesia
if [[ "$COUNTRY_CODE" == "ID" ]]; then
    colorized_echo green "IP Indonesia terdeteksi, menggunakan repositories lokal Indonesia"

    # Menanyakan kepada pengguna apakah ingin menggunakan repo lokal atau repo default
    read -p "Apakah Anda ingin menggunakan repo lokal Indonesia? (y/n): " use_local_repo

    if [[ "$use_local_repo" == "y" || "$use_local_repo" == "Y" ]]; then
        # Pemeriksaan OS untuk menambahkan repo yang sesuai
        case "$OS" in
            Debian)
                VERSION=$(lsb_release -sr)
                if [ "$VERSION" == "11" ]; then
                    addDebian11Repo
                else
                    colorized_echo red "Versi Debian ini tidak didukung."
                fi
                ;;
            Ubuntu)
                VERSION=$(lsb_release -sr)
                if [ "$VERSION" == "20.04" ]; then
                    addUbuntu2004Repo
                else
                    colorized_echo red "Versi Ubuntu ini tidak didukung."
                fi
                ;;
            *)
                colorized_echo red "Sistem Operasi ini tidak didukung."
                ;;
        esac
    else
        colorized_echo yellow "Menggunakan repo bawaan VM."
        # Tidak melakukan apa-apa, sehingga repo bawaan VM tetap digunakan
    fi
else
    colorized_echo yellow "IP di luar Indonesia."
    # Lanjutkan dengan repo bawaan OS
fi
mkdir -p /etc/data

#domain
read -rp "Masukkan Domain: " domain
echo "$domain" > /etc/data/domain
domain=$(cat /etc/data/domain)

#email
read -rp "Masukkan Email anda: " email

#username
while true; do
    read -rp "Masukkan UsernamePanel (hanya huruf dan angka): " userpanel

    # Memeriksa apakah userpanel hanya mengandung huruf dan angka
    if [[ ! "$userpanel" =~ ^[A-Za-z0-9]+$ ]]; then
        echo "UsernamePanel hanya boleh berisi huruf dan angka. Silakan masukkan kembali."
    elif [[ "$userpanel" =~ [Aa][Dd][Mm][Ii][Nn] ]]; then
        echo "UsernamePanel tidak boleh mengandung kata 'admin'. Silakan masukkan kembali."
    else
        echo "$userpanel" > /etc/data/userpanel
        break
    fi
done

read -rp "Masukkan Password Panel: " passpanel
echo "$passpanel" > /etc/data/passpanel

# Function to validate port input
while true; do
  read -rp "Masukkan Default Port untuk Marzban Dashboard GUI (selain 443 dan 80): " port

  if [[ "$port" -eq 443 || "$port" -eq 80 ]]; then
    echo "Port $port tidak valid. Silakan isi dengan port selain 443 atau 80."
  else
    echo "Port yang Anda masukkan adalah: $port"
    break
  fi
done

#Preparation
clear
cd;
apt-get update;

#Remove unused Module
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

#install bbr
echo 'fs.file-max = 500000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 4000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p;

#install toolkit
apt-get install libio-socket-inet6-perl libsocket6-perl libcrypt-ssleay-perl libnet-libidn-perl perl libio-socket-ssl-perl libwww-perl libpcre3 libpcre3-dev zlib1g-dev dbus iftop zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr dnsutils sudo at htop iptables bsdmainutils cron lsof lnav -y

#Set Timezone GMT+7
timedatectl set-timezone Asia/Jakarta;

#Install Marzban
sudo bash -c "$(curl -sL https://github.com/Hermananza/Marzban-scripts/raw/master/marzban.sh)" @ install

#Install Subs
wget -N -P /var/lib/marzban/templates/subscription/  https://raw.githubusercontent.com/Hermananza/MarLing/main/index.html

#install env
wget -O /opt/marzban/.env "https://raw.githubusercontent.com/Hermananza/MarLing/main/env"

#install core Xray & Assets folder
mkdir -p /var/lib/marzban/assets
mkdir -p /var/lib/marzban/core
wget -O /var/lib/marzban/core/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v1.8.16/Xray-linux-64.zip"  
cd /var/lib/marzban/core && unzip xray.zip && chmod +x xray
cd

#profile
echo -e 'profile' >> /root/.profile
wget -O /usr/bin/profile "https://raw.githubusercontent.com/Hermananza/MarLing/main/profile";
chmod +x /usr/bin/profile
apt install neofetch -y
wget -O /usr/bin/cekservice "https://raw.githubusercontent.com/Hermananza/MarLing/main/cekservice.sh"
chmod +x /usr/bin/cekservice

#install compose
wget -O /opt/marzban/docker-compose.yml "https://raw.githubusercontent.com/Hermananza/MarLing/main/docker-compose.yml"

#Install VNSTAT
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://github.com/Hermananza/MarLing/raw/main/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install 
cd
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz 
rm -rf /root/vnstat-2.6

#Install backup
git clone https://github.com/Hermananza/backup.git

#Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest -y

#install nginx
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log
wget -O /opt/marzban/nginx.conf "https://raw.githubusercontent.com/Hermananza/MarLing/main/nginx.conf"
wget -O /opt/marzban/default.conf "https://raw.githubusercontent.com/Hermananza/MarLing/main/vps.conf"
wget -O /opt/marzban/xray.conf "https://raw.githubusercontent.com/Hermananza/MarLing/main/xray.conf"
mkdir -p /var/www/html
echo "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EDtunnel-rev - VLESS Proxy</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            background: linear-gradient(135deg, #1d1f21 0%, #34495e 100%);
            color: #ecf0f1;
            overflow-x: hidden;
        }

        .sidebar {
            width: 300px;
            background: rgba(44, 62, 80, 0.9);
            color: #ecf0f1;
            padding: 30px 20px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            box-shadow: 5px 0 15px rgba(0, 0, 0, 0.2);
            position: relative;
            z-index: 1;
        }

        .sidebar h2 {
            font-size: 24px;
            margin-bottom: 25px;
            padding-bottom: 10px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
        }

        .sidebar a {
            font-size: 20px;
            margin-bottom: 20px;
            color: #ecf0f1;
            text-decoration: none;
            display: flex;
            align-items: center;
            transition: all 0.3s ease;
        }

        .sidebar a i {
            margin-right: 15px;
            font-size: 24px;
            transition: transform 0.3s;
        }

        .sidebar a:hover {
            color: #1abc9c;
        }

        .sidebar a:hover i {
            transform: rotate(360deg);
        }

        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 50px;
            background: linear-gradient(to right, #2c3e50, #34495e);
            position: relative;
        }

        .main-content:before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle at center, rgba(255, 255, 255, 0.1), transparent);
            pointer-events: none;
            animation: pulse 5s infinite;
        }

        @keyframes pulse {
            0% {
                transform: scale(0.9);
            }
            50% {
                transform: scale(1.1);
            }
            100% {
                transform: scale(0.9);
            }
        }

        h1 {
            font-size: 42px;
            color: #ecf0f1;
            text-shadow: 0 5px 10px rgba(0, 0, 0, 0.3);
            margin-bottom: 30px;
            position: relative;
            z-index: 2;
        }

        .content {
            max-width: 800px;
            width: 100%;
            padding: 30px;
            background-color: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            position: relative;
            z-index: 2;
        }

        .content h2 {
            font-size: 30px;
            margin-bottom: 20px;
            color: #1abc9c;
        }

        .content p {
            font-size: 18px;
            line-height: 1.7;
            margin-bottom: 20px;
        }

        input[type="text"] {
            padding: 15px;
            font-size: 16px;
            width: 100%;
            max-width: 450px;
            margin-bottom: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
            box-shadow: inset 0 5px 10px rgba(0, 0, 0, 0.2);
            transition: all 0.3s ease;
        }

        input[type="text"]:focus {
            outline: none;
            border-color: #1abc9c;
            background: rgba(255, 255, 255, 0.2);
        }

        button {
            padding: 15px 30px;
            font-size: 18px;
            color: #fff;
            background-color: #1abc9c;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            box-shadow: 0 5px 15px rgba(26, 188, 156, 0.5);
            transition: all 0.3s ease, transform 0.2s ease;
            position: relative;
            z-index: 2;
        }

        button:active {
            transform: translateY(3px);
            box-shadow: 0 3px 10px rgba(26, 188, 156, 0.3);
        }

        button:hover {
            background-color: #16a085;
        }

        button:hover::after {
            content: '';
            position: absolute;
            top: -15px;
            left: -15px;
            right: -15px;
            bottom: -15px;
            border-radius: 20px;
            border: 2px solid rgba(26, 188, 156, 0.6);
            opacity: 0;
            animation: hover-effect 0.4s forwards;
        }

        @keyframes hover-effect {
            0% {
                opacity: 0;
                transform: scale(0.8);
            }
            100% {
                opacity: 1;
                transform: scale(1.2);
            }
        }

        .special-thanks {
            margin-top: 50px;
            position: relative;
            z-index: 2;
        }

        .special-thanks p {
            margin-bottom: 15px;
        }

        .special-thanks a {
            color: #1abc9c;
            text-decoration: none;
            font-weight: bold;
            position: relative;
            z-index: 2;
            transition: color 0.3s ease;
        }

        .special-thanks a:hover {
            color: #16a085;
            text-shadow: 0 5px 15px rgba(26, 188, 156, 0.5);
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 100%;
                height: auto;
                padding: 15px 20px;
                box-shadow: none;
            }

            .main-content {
                padding: 30px 20px;
            }

            h1 {
                font-size: 32px;
            }

            .content {
                padding: 20px;
            }

            .content h2 {
                font-size: 24px;
            }

            input[type="text"] {
                font-size: 14px;
                padding: 12px;
            }

            button {
                padding: 12px 25px;
                font-size: 16px;
            }
        }
    </style>
</head>
<body>

    <!-- Sidebar -->
    <div class="sidebar">
        <div>
            <h2>HC STORE</h2>
            <a href="https://" target="_blank"><i class="fas fa-info-circle"></i> Project Overview</a>
            <a href="https://t.me/hermananza" target="_blank"><i class="fab fa-telegram"></i> Order Akun Vpn</a>
        </div>
        <div>
            <a href="https://github.com" target="_blank"><i class="fab fa-github"></i> GitHub Repository</a>
        </div>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <h1>HC STORE Adalah penyedia akun vpn</h1>
        <div class="content">
            <h2>Selamat datang di hc store</h2>
            <p>Disini menyediakan akun vpn dengan protokol SSH, VMESS, VLESS DAN TROJAN. Utuk server baru ada singapura dan indonesia.</p>

            <div class="Harga Akun Vpn">
                <h2>Special Thanks</h2>
                <p>1. 10K = 30 HARI (2 HP)</p>
                <p>2. 20K = 70 HARI (2 HP)</p>
                <p>3. 25K = 90 HARI (2 HP)</p>
            </div>
        </div>
    </div>

</body>
</html>


    `;
}
" > /var/www/html/index.html

#install socat
apt install iptables -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion -y

#install cert
curl https://get.acme.sh | sh -s email=$email
/root/.acme.sh/acme.sh --server letsencrypt --register-account -m $email --issue -d $domain --standalone -k ec-256 --debug
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /var/lib/marzban/xray.crt --keypath /var/lib/marzban/xray.key --ecc
wget -O /var/lib/marzban/xray_config.json "https://raw.githubusercontent.com/Hermananza/MarLing/main/xray_config.json"

#install firewall
apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8081/tcp
sudo ufw allow 1080/tcp
sudo ufw allow 1080/udp
sudo ufw allow $port/tcp
yes | sudo ufw enable

#install database
wget -O /var/lib/marzban/db.sqlite3 "https://github.com/Hermananza/MarLing/raw/main/db.sqlite3"

#install WARP Proxy
wget -O /root/warp "https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh"
sudo chmod +x /root/warp
sudo bash /root/warp -y 

#finishing
apt autoremove -y
apt clean
cd /opt/marzban
sed -i "s/# SUDO_USERNAME = \"admin\"/SUDO_USERNAME = \"${userpanel}\"/" /opt/marzban/.env
sed -i "s/# SUDO_PASSWORD = \"admin\"/SUDO_PASSWORD = \"${passpanel}\"/" /opt/marzban/.env
sed -i "s/UVICORN_PORT = 7879/UVICORN_PORT = ${port}/" /opt/marzban/.env
docker compose down && docker compose up -d
marzban cli admin import-from-env -y
sed -i "s/SUDO_USERNAME = \"${userpanel}\"/# SUDO_USERNAME = \"admin\"/" /opt/marzban/.env
sed -i "s/SUDO_PASSWORD = \"${passpanel}\"/# SUDO_PASSWORD = \"admin\"/" /opt/marzban/.env
docker compose down && docker compose up -d
cd
profile
echo "Untuk data login dashboard Marzban: " | tee -a log-install.txt
echo "-=================================-" | tee -a log-install.txt
echo "URL HTTPS : https://${domain}:${port}/dashboard" | tee -a log-install.txt
echo "URL HTTP  : http://${domain}:${port}/dashboard" | tee -a log-install.txt
echo "username  : ${userpanel}" | tee -a log-install.txt
echo "password  : ${passpanel}" | tee -a log-install.txt
echo "-=================================-" | tee -a log-install.txt
echo "Jangan lupa join Channel & Grup Telegram saya juga di" | tee -a log-install.txt
echo "Telegram Channel: https://t.me/" | tee -a log-install.txt
echo "Telegram Group: https://t.me/" | tee -a log-install.txt
echo "-=================================-" | tee -a log-install.txt
colorized_echo green "Script telah berhasil di install"
rm /root/mar.sh
colorized_echo blue "Menghapus admin bawaan db.sqlite"
marzban cli admin delete -u admin -y
echo -e "[\e[1;31mWARNING\e[0m] Reboot sekali biar ga error lur [default y](y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
cat /dev/null > ~/.bash_history && history -c && reboot
fi
