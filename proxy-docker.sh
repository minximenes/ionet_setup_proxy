# !/bin/bash

echo "proxy for docker pull"
# /etc/systemd/system/docker.service.d
sudo mkdir -p /etc/systemd/system/docker.service.d
cat << EOF > http-proxy.tmp
[Service]
Environment=HTTP_PROXY=http://127.0.0.1:8118
Environment=HTTPS_PROXY=http://127.0.0.1:8118
Environment=NO_PROXY=localhost,127.0.0.1
EOF
sudo mv http-proxy.tmp /etc/systemd/system/docker.service.d/http-proxy.conf
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "proxy for docker pull has been setted"
# test connnection
docker pull curlimages/curl

echo "proxy for container"
docker0_ip=$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

sudo sed -i "s/# listen-address 172.17.0.1/listen-address $docker0_ip/g" /etc/privoxy/config
sudo systemctl restart privoxy
sudo systemctl status privoxy

sudo mkdir -p ~/.docker/
sudo cat << EOF > ~/.docker/config.json
{
  "proxies":
  {
    "default":
    {
      "httpProxy": "http://$docker0_ip:8118",
      "httpsProxy": "http://$docker0_ip:8118",
      "noProxy": "localhost,127.0.0.1"
    }
  }
}
EOF

echo "proxy for container has been setted"
# test connnection
docker run --rm curlimages/curl curl ip.sb
docker rmi curlimages/curl >/dev/null
