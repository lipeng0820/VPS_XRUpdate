#!/bin/bash

# 定义变量
CONFIG_PATH=~/config.yml
CONFIG_BAK_PATH=~/config.yml.bak
CONFIG_OLD_PATH=~/config.yml.old
CONFIG_EXAMPLE_URL="https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example"
LOG_FILE=~/XrayrConfigUpdate.log
DB_HOST="dbs-connect-cn-0.ip.parts"
DB_USER="vedbs_2150"
DB_PASSWORD="aF3iOAURaf"
DB_NAME="vedbs_2150"
TABLE_NAME="FREED00R_XRUpdate"

# 备份旧的配置文件
cp $CONFIG_PATH $CONFIG_BAK_PATH

# 下载新的配置文件范例
wget -O ~/config.yml.example $CONFIG_EXAMPLE_URL

# 检查配置文件是否已经是最新版
OLD_CONFIG_KEYS=$(grep -v '^ *#' $CONFIG_PATH | awk -F: '{print $1}' | sort | uniq)
NEW_CONFIG_KEYS=$(grep -v '^ *#' ~/config.yml.example | awk -F: '{print $1}' | sort | uniq)

if diff <(echo "$OLD_CONFIG_KEYS") <(echo "$NEW_CONFIG_KEYS") &> /dev/null; then
    echo "当前已为最新版配置文件"
    exit 0
fi

# 重命名旧的配置文件
mv $CONFIG_PATH $CONFIG_OLD_PATH

# 提取旧配置文件中的特定字段
NODE_ID=$(grep -Po '^ *NodeID: *\K\d+' $CONFIG_OLD_PATH)
PANEL_TYPE=$(grep -Po '^ *PanelType: *\K.+' $CONFIG_OLD_PATH)
API_HOST=$(grep -Po '^ *ApiHost: *\K.+' $CONFIG_OLD_PATH)
API_KEY=$(grep -Po '^ *ApiKey: *\K.+' $CONFIG_OLD_PATH)
NODE_TYPE=$(grep -Po '^ *NodeType: *\K.+' $CONFIG_OLD_PATH)
CERT_MODE=$(grep -Po '^ *CertMode: *\K.+' $CONFIG_OLD_PATH)
CERT_DOMAIN=$(grep -Po '^ *CertDomain: *\K.+' $CONFIG_OLD_PATH)
PROVIDER=$(grep -Po '^ *Provider: *\K.+' $CONFIG_OLD_PATH)
EMAIL=$(grep -Po '^ *Email: *\K.+' $CONFIG_OLD_PATH)
CF_EMAIL=$(grep -Po '^ *CLOUDFLARE_EMAIL: *\K.+' $CONFIG_OLD_PATH)
CF_API_KEY=$(grep -Po '^ *CLOUDFLARE_API_KEY: *\K.+' $CONFIG_OLD_PATH)

# 修改新配置文件
sed -i "s/^ *PanelType: .*/ PanelType: $PANEL_TYPE/" ~/config.yml.example
sed -i "s/^ *ApiHost: .*/ ApiHost: $API_HOST/" ~/config.yml.example
sed -i "s/^ *ApiKey: .*/ ApiKey: $API_KEY/" ~/config.yml.example
sed -i "s/^ *NodeID: .*/ NodeID: $NODE_ID/" ~/config.yml.example
sed -i "s/^ *NodeType: .*/ NodeType: $NODE_TYPE/" ~/config.yml.example
sed -i "s/^ *CertMode: .*/ CertMode: $CERT_MODE/" ~/config.yml.example
sed -i "s/^ *CertDomain: .*/ CertDomain: $CERT_DOMAIN/" ~/config.yml.example
sed -i "s/^ *Provider: .*/ Provider: $PROVIDER/" ~/config.yml.example
sed -i "s/^ *Email: .*/ Email: $EMAIL/" ~/config.yml.example
sed -i "/^ *DNSEnv: *$/,/^$/s/^ *CLOUDFLARE_EMAIL: .*/  CLOUDFLARE_EMAIL: $CF_EMAIL/" ~/config.yml.example
sed -i "/^ *DNSEnv: *$/,/^$/s/^ *CLOUDFLARE_API_KEY: .*/  CLOUDFLARE_API_KEY: $CF_API_KEY/" ~/config.yml.example

# 重命名新配置文件
mv ~/config.yml.example $CONFIG_PATH

# 记录日志
echo -e "旧值\t新值" > $LOG_FILE
echo -e "PanelType: $PANEL_TYPE\tPanelType: $PANEL_TYPE" >> $LOG_FILE
echo -e "ApiHost: $API_HOST\tApiHost: $API_HOST" >> $LOG_FILE
echo -e "ApiKey: $API_KEY\tApiKey: $API_KEY" >> $LOG_FILE
echo -e "NodeID: $NODE_ID\tNodeID: $NODE_ID" >> $LOG_FILE
echo -e "NodeType: $NODE_TYPE\tNodeType: $NODE_TYPE" >> $LOG_FILE
echo -e "CertMode: $CERT_MODE\tCertMode: $CERT_MODE" >> $LOG_FILE
echo -e "CertDomain: $CERT_DOMAIN\tCertDomain: $CERT_DOMAIN" >> $LOG_FILE
echo -e "Provider: $PROVIDER\tProvider: $PROVIDER" >> $LOG_FILE
echo -e "Email: $EMAIL\tEmail: $EMAIL" >> $LOG_FILE
echo -e "CLOUDFLARE_EMAIL: $CF_EMAIL\tCLOUDFLARE_EMAIL: $CF_EMAIL" >> $LOG_FILE
echo -e "CLOUDFLARE_API_KEY: $CF_API_KEY\tCLOUDFLARE_API_KEY: $CF_API_KEY" >> $LOG_FILE

# 延迟写入数据库
DELAY=$((NODE_ID * 2))
echo "等待$DELAY秒..."
sleep $DELAY

# 将日志和NodeID写入数据库
LOG_CONTENT=$(cat $LOG_FILE | sed "s/'/''/g")
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME --default-character-set=utf8mb4 -e "INSERT INTO $TABLE_NAME (NodeID, log, update_time) VALUES ('$NODE_ID', '$LOG_CONTENT', NOW()) ON DUPLICATE KEY UPDATE log='$LOG_CONTENT', update_time=NOW();"

echo "配置文件已更新并记录到日志文件。NodeID和日志内容已写入数据库。"
