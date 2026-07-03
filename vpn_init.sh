#!/bin/bash
echo "正在尝试获取节点..."
while true; do
    # 使用更保险的抓取方式
    curl -s "http://www.vpngate.net/api/iphone/" | grep -v "*" | awk -F, 'NR>3 {if ($15 != "") print $15}' | head -n 1 > /tmp/vpn_b64
    
    if [ -s /tmp/vpn_b64 ]; then
        base64 -d /tmp/vpn_b64 > /client.ovpn 2>/dev/null
        if [ -s /client.ovpn ]; then
            echo "节点获取成功，拨号中..."
            openvpn --config /client.ovpn --daemon
            sleep 15
            # 确认 tun0 是否存在
            if ip addr show tun0 > /dev/null 2>&1; then
                echo "VPN 拨号成功。"
                break
            fi
        fi
    fi
    echo "拨号失败，重试中..."
    sleep 10
done
