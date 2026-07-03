#!/bin/bash
CONFIG_FILE="/etc/xray/config.json"

# 初始化 Xauthority
touch /root/.Xauthority

update_and_restart() {
    echo "正在获取新节点并更新配置..."
    # 模拟获取新节点 (这里你需要根据你的逻辑替换为你真实的API请求)
    # 假设你获取到了一个新的IP
    NEW_IP="1.2.3.4" 
    
    # 使用 jq 动态替换 JSON 中的地址字段
    if [ -f "$CONFIG_FILE" ]; then
        jq --arg ip "$NEW_IP" '.outbounds[0].settings.vnext[0].address = $ip' /etc/xray/config.json.template > $CONFIG_FILE
        
        # 重启 Xray
        pkill xray
        sleep 2
        /usr/local/bin/xray run -c $CONFIG_FILE > /dev/null 2>&1 &
        echo "Xray 已使用新节点 $NEW_IP 重启"
    fi
}

# 初始执行一次
update_and_restart

while true; do
    # 增加冷却时间，避免 1 分钟内无限重启
    sleep 300 
    
    # 检测 8080 是否响应 (使用 --socks5 代理通过本地 xray 测试)
    if ! curl -s --socks5 127.0.0.1:8080 http://www.google.com --connect-timeout 10 > /dev/null; then
        echo "连接失败，触发切换..."
        update_and_restart
    fi
done
