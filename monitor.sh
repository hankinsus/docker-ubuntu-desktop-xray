#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"
TEMPLATE="/etc/xray/config.json.template"
# 使用订阅转换接口，将任何格式统一转换为 Xray 支持的 JSON
SUB_URL="https://api.v1.mk/sub?target=v2ray&url=https://raw.githubusercontent.com/freefq/free/master/v2"

update_node_logic() {
    echo "正在从订阅转换接口获取节点配置..."
    
    # 1. 获取订阅内容 (直接下载转换后的 JSON)
    TEMP_JSON=$(mktemp)
    if ! curl -s -L "$SUB_URL" > "$TEMP_JSON"; then
        echo "订阅下载失败"
        return 1
    fi

    # 2. 校验 JSON 是否合法，并提取第一个 outbound
    if jq empty "$TEMP_JSON" >/dev/null 2>&1; then
        # 注入转换后的配置到模板中
        jq '.outbounds[0]' "$TEMP_JSON" > "$CONFIG_FILE"
        echo "配置更新成功"
        rm "$TEMP_JSON"
        return 0
    else
        echo "JSON 格式错误，跳过更新"
        rm "$TEMP_JSON"
        return 1
    fi
}

# 主循环
while true; do
    # 测试连通性
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 5 > /dev/null; then
        echo "连接失败，执行热切换..."
        if update_node_logic; then
            pkill xray
            sleep 2
            /usr/local/bin/xray run -c "$CONFIG_FILE" > /dev/null 2>&1 &
        fi
    fi
    sleep 300
done
