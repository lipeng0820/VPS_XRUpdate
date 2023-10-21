#!/bin/bash

# 设置工作目录为用户的主目录
cd ~

# 备份当前的 XrayR 配置文件
if [ -f "config.yml" ]; then
    cp config.yml config.yml.bak
    rm -f config.yml
else
    echo "错误：找不到 config.yml 文件。"
    exit 1
fi

# 下载最新的 XrayR 配置文件范例
curl -O https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example
mv config.yml.example config.yml

# 更新配置文件和生成更新日志
> XrayrConfigUpdate.log  # 清空更新日志文件
for key in PanelType ApiHost ApiKey NodeID NodeType CertMode CertDomain Provider Email; do
    old_value=$(grep "^$key:" config.yml.bak | awk '{print $2}')
    new_value=$(grep "^$key:" config.yml | awk '{print $2}')
    if [ "$old_value" != "$new_value" ]; then
        sed -i "s/^$key: $new_value/$key: $old_value/" config.yml
        echo "$key: $new_value --> $key: $old_value" >> XrayrConfigUpdate.log
    fi
done

# 特殊处理 DNSEnv
old_keys=$(grep -A 2 "^DNSEnv:" config.yml.bak | grep -v "DNSEnv:" | awk '{print $1}' | sed 's/://')
for key in $old_keys; do
    old_value=$(grep -A 2 "^DNSEnv:" config.yml.bak | grep "^$key:" | awk '{print $2}')
    sed -i "/^DNSEnv:/,/^$/s/$key:.*$/$key: $old_value/" config.yml
done

# 获取 NodeID
NODE_ID=$(grep "^NodeID:" config.yml | awk '{print $2}')

# 等待 NodeID * 2 秒
sleep $((NODE_ID * 2))

# 写入数据库
DB_PASSWORD="your_database_password"
LOG_CONTENT=$(sed ':a;N;$!ba;s/\n/\\n/g' XrayrConfigUpdate.log)  # 将换行符替换为 \n
mysql -h your_database_host -u your_database_user -p$DB_PASSWORD your_database_name --default-character-set=utf8mb4 -e "INSERT INTO FREED00R_XRUpdate (NodeID, log) VALUES ('$NODE_ID', '$LOG_CONTENT')"
