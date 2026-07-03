#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"

update_node_logic() {
    echo "正在从 VPNGate 获取可用 Socks5 节点..."
    
    # 获取数据，这里提取 IP (第2列) 和 Port (第3列)
    # 假设你获取的是标准 VPNGate CSV
    NODE_DATA=$(curl -s "https://www.vpngate.net/api/iphone/" | grep -v "#" | head -n 50 | sort -t, -k4 -n | head -n 1 | awk -F, '{print $2":"$3}')
    
    NEW_IP=$(echo $NODE_DATA | cut -d: -f1)
    NEW_PORT=$(echo $NODE_DATA | cut -d: -f2)

    if [ -z "$NEW_IP" ] || [ -z "$NEW_PORT" ]; then
        return
    fi

    echo "注入节点: IP=$NEW_IP, Port=$NEW_PORT"
    
    # 使用 jq 动态写入 Socks5 节点信息
    jq --arg ip "$NEW_IP" --arg port "$NEW_PORT" \
      '.outbounds[0].settings.servers[0].address = $ip | .outbounds[0].settings.servers[0].port = ($port|tonumber)' \
      "$TEMPLATE" > "$CONFIG_FILE"
}

# 监控循环
while true; do
    # 测试连接 (注意：测试地址需要通过 socks5 协议)
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        update_node_logic
        pkill xray
        sleep 2
        /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
    fi
    sleep 60
done
