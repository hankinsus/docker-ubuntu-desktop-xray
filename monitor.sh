#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"
# 你的订阅地址 (替换为你自己的订阅源链接)
SUB_URL="https://api.v1.mk/sub?target=v2ray&url=https://raw.githubusercontent.com/freefq/free/master/v2"

update_node() {
    echo "正在拉取并注入新节点..."
    TEMP_SUB=$(mktemp)
    
    # 1. 获取转换后的 JSON 数据
    if curl -s -L "$SUB_URL" > "$TEMP_SUB"; then
        # 2. 从下载的 JSON 中提取第一个 outbound
        # 使用 jq 直接提取转换后的 outbound 配置
        NEW_OUTBOUND=$(jq '.outbounds[0]' "$TEMP_SUB")
        
        if [[ -n "$NEW_OUTBOUND" ]]; then
            # 3. 将新节点注入模板的 outbounds 数组中
            jq --argjson out "$NEW_OUTBOUND" '.outbounds = [$out]' "$TEMPLATE" > "$CONFIG_FILE"
            echo "节点已更新。"
            rm "$TEMP_SUB"
            return 0
        fi
    fi
    rm "$TEMP_SUB"
    return 1
}

# 监控循环
while true; do
    # 测试连接 (经由 8080 端口)
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        echo "节点失效，正在热切换..."
        if update_node; then
            pkill xray
            sleep 2
            /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
        fi
    fi
    sleep 300
done
