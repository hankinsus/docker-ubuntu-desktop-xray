#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"

# 抓取并解析 SS 节点 (解析 base64 编码)
fetch_ss_node() {
    # 示例来源：GitHub 公共节点仓库，可替换为其他你发现的 ss:// 订阅源
    URL="https://raw.githubusercontent.com/freefq/free/master/v2" 
    
    # 获取并处理：假设获取到 base64 编码的节点，解码并提取第一个节点
    # 注意：此逻辑需根据具体订阅源格式微调
    NODE_RAW=$(curl -s $URL | head -n 1 | base64 -d) 
    
    # 解析 ss:// 链接格式: ss://method:password@host:port
    # 这里通过 sed/awk 提取参数
    echo "$NODE_RAW" | sed -E 's/ss:\/\/(.*)@(.*):([0-9]+)/\1 \2 \3/'
}

update_node_logic() {
    echo "正在扫描免费 Shadowsocks 节点..."
    
    # 循环尝试以确保连通性
    IFS=' ' read -r AUTH HOST PORT <<< "$(fetch_ss_node)"
    METHOD=$(echo $AUTH | cut -d: -f1)
    PASSWORD=$(echo $AUTH | cut -d: -f2)

    # 写入配置
    jq --arg host "$HOST" --arg port "$PORT" --arg m "$METHOD" --arg p "$PASSWORD" \
      '.outbounds[0].protocol = "shadowsocks" |
       .outbounds[0].settings.servers[0] = {address: $host, port: ($port|tonumber), method: $m, password: $p}' \
      "$TEMPLATE" > "$CONFIG_FILE"
}

while true; do
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        update_node_logic
        pkill xray
        sleep 2
        /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
    fi
    sleep 300
done
