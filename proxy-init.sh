# !/bin/bash

if [ -n "$1" ]; then
    PROXY_SERVER=$1
else
    echo "Please input PROXY_SERVER_IP:"
    read PROXY_SERVER
fi

# shadowsocks client
echo "Updating" && sudo apt-get update >/dev/null 2>&1
echo "Installing python3 python3-pip privoxy" && sudo apt-get install -y python3 python3-pip privoxy >/dev/null
echo "Installing shadowsocks" && sudo pip3 install shadowsocks >/dev/null
# bugfix
sudo sed -i 's/EVP_CIPHER_CTX_cleanup/EVP_CIPHER_CTX_reset/g' /usr/local/lib/python3.8/dist-packages/shadowsocks/crypto/openssl.py
# socks5
cat << EOF > shadowsocks.jsn.tmp
{
    "server":"$PROXY_SERVER",
    "server_port":8388,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"12qwaszx",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
sudo mv ./shadowsocks.jsn.tmp /etc/shadowsocks.json
# service
cat << EOF > shadowsocks.svc.tmp
[Unit]
Description=shadowsocks
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/sslocal -c /etc/shadowsocks.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv shadowsocks.svc.tmp /etc/systemd/system/shadowsocks.service
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks.service >/dev/null
sudo systemctl restart shadowsocks.service
sudo systemctl status shadowsocks.service

# http
# port 8118
sudo cp /etc/privoxy/config /etc/privoxy/config.origin
sudo sed -i '/^#/d' /etc/privoxy/config

# docker0_ip=$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
docker0_ip="172.17.0.1"
sudo echo "listen-address $docker0_ip:8118">> /etc/privoxy/config
sudo echo "forward-socks5 / 127.0.0.1:1080 .">> /etc/privoxy/config
sudo systemctl enable privoxy >/dev/null
sudo systemctl restart privoxy
sudo systemctl status privoxy

echo "proxy for terminal"
sudo echo "export http_proxy=http://127.0.0.1:8118">> /etc/profile
sudo echo "export https_proxy=http://127.0.0.1:8118">> /etc/profile
sudo echo "export no_proxy=localhost,127.0.0.1">> /etc/profile
# no sudo
source /etc/profile
echo "proxy for terminal has been setted"
# test connnection
echo "Proxy IP: " && curl ip.sb
