#!/bin/bash
# Descreption: Install shadowsocks.

echo "Install pip..."
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py

echo "Install shadowsocks..."
pip install shadowsocks

echo "Config shadowsocks account..."
cat > /etc/shadowsocks.json <<EOF
{
  "server": "0.0.0.0",
  "port_password": {
    "8388": "shadowsocks"
  },
  "timeout": 600,
  "method": "aes-256-cfb"
}
EOF

echo "Config boost script..."
cat > /etc/systemd/system/shadowsocks.service <<EOF
[Unit]
Description=Shadowsocks

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/ssserver -c /etc/shadowsocks.json

[Install]
WantedBy=multi-user.target
EOF

echo "Set start when boot server..."
systemctl enable shadowsocks

echo "Start shadowsocks service..."
systemctl start shadowsocks

echo "Done."
echo ""
echo "********** Default connection information **********"
echo ""
echo "        IP: Your public IP"
echo "      Port: 8388"
echo "   Pasword: shadowsocks"
echo "Encryption: aes-256-cfb"
echo ""
echo "****************************************************"
echo ""
echo "If you want to change port or passord, please update file /etc/shadowsocks.json , then restart shadowsocks services."
echo "  start service: systemctl start shadowsocks"
echo "   stop service: systemctl stop shadowsocks"
echo "restart service: systemctl restart shadowsocks"
echo ""
