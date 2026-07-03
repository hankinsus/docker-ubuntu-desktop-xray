#!/bin/bash
echo "正在从 VPNGate 获取最新住宅 IP 节点..."
# 获取 CSV 并解码第一个 OpenVPN 节点
curl -s "http://www.vpngate.net/api/iphone/" | grep -v "*" | awk -F, 'NR>3 {if ($15 != "") print $15}' | head -n 1 | base64 -d > /client.ovpn

if [ -s /client.ovpn ]; then
    echo "拨号中..."
    openvpn --config /client.ovpn --daemon
    sleep 15
else
    echo "获取节点失败，请检查网络。"
fi
