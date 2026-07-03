#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"

# 测试该节点是否为有效的 Socks5 代理
test_socks5_node() {
    local ip=$1
    local port=$2
    # 使用 curl 通过该节点进行 SOCKS5 握手，超时 5 秒
    # 如果返回状态码 0，说明代理正常可用
    curl -s --socks5 "${ip}:${port}" --connect-timeout 5 http://www.google.com > /dev/null 2>&1
    return $?
}

update_node_logic() {
    echo "正在扫描并验证 VPNGate 节点..."
    
    # 循环尝试前 20 个节点，直到找到一个支持 Socks5 的
    for i in {1..20}; do
        # 提取 IP 和 端口 (这里假定端口列在 CSV 中，需根据实际情况调整)
        # 注意：VPNGate 原生无 Socks5 端口，此处的逻辑需配合你使用的代理池 API
        NODE_DATA=$(curl -s "https://www.vpngate.net/api/iphone/" | grep -v "#" | head -n 50 | sed -n "${i}p" | awk -F, '{print $2":"1080}')
        
        NEW_IP=$(echo $NODE_DATA | cut -d: -f1)
        NEW_PORT=$(echo $NODE_DATA | cut -d: -f2)

        if test_socks5_node "$NEW_IP" "$NEW_PORT"; then
            echo "找到有效 Socks5 节点: $NEW_IP:$NEW_PORT，正在应用..."
            jq --arg ip "$NEW_IP" --arg port "$NEW_PORT" \
              '.outbounds[0].settings.servers[0].address = $ip | .outbounds[0].settings.servers[0].port = ($port|tonumber)' \
              "$TEMPLATE" > "$CONFIG_FILE"
            return 0
        fi
    done
    return 1
}

# 主循环
while true; do
    # 检查 Xray 连通性
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        echo "当前节点不可用，正在更换..."
        update_node_logic
        pkill xray
        sleep 2
        /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
    fi
    sleep 60
done
