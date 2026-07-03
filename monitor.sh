#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"

update_node_logic() {
    echo "正在从 VPNGate 获取可用节点..."
    
    # 获取数据并过滤：跳过头部，取前50条，按延迟(第5列)排序，取第一个
    # VPNGate CSV 格式: HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64
    NODE_IP=$(curl -s "https://www.vpngate.net/api/iphone/" | grep -v "#" | head -n 50 | sort -t, -k4 -n | head -n 1 | cut -d, -f2)
    
    if [ -z "$NODE_IP" ]; then
        echo "获取节点失败，跳过本次更新。"
        return
    fi

    echo "发现最佳节点 IP: $NODE_IP，正在写入配置..."
    
    # 动态写入配置 (注意：请确保你的 template 里的 port 和 uuid 是正确的)
    jq --arg ip "$NODE_IP" '.outbounds[0].settings.vnext[0].address = $ip' "$TEMPLATE" > "$CONFIG_FILE"
}

while true; do
    # 检测 8080 是否工作
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        echo "检测到节点连接失败，执行热切换..."
        update_node_logic
        pkill xray
        sleep 2
        /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
    fi
    sleep 300 # 每 5 分钟检测一次，避免频率过高
done
