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
extract_value() {
  grep -Po "^ *$1: *\K.*" $CONFIG_OLD_PATH | sed -e 's/ *#.*//' -e 's/"//g'
}

NODE_ID=$(extract_value 'NodeID')
PANEL_TYPE=$(extract_value 'PanelType')
API_HOST=$(extract_value 'ApiHost')
API_KEY=$(extract_value 'ApiKey')
NODE_TYPE=$(extract_value 'NodeType')
CERT_MODE=$(extract_value 'CertMode')
CERT_DOMAIN=$(extract_value 'CertDomain')
PROVIDER=$(extract_value 'Provider')
EMAIL=$(extract_value 'Email')
CF_EMAIL=$(extract_value 'CLOUDFLARE_EMAIL')
CF_API_KEY=$(extract_value 'CLOUDFLARE_API_KEY')

# 修改新配置文件
update_config() {
  sed -i "s|^ *$1: .*|$1: $2|" ~/config.yml.example
}

update_config 'PanelType' "$PANEL_TYPE"
update_config 'ApiHost' "$API_HOST"
update_config 'ApiKey' "$API_KEY"
update_config 'NodeID' "$NODE_ID"
update_config 'NodeType' "$NODE_TYPE"
update_config 'CertMode' "$CERT_MODE"
update_config 'CertDomain' "$CERT_DOMAIN"
update_config 'Provider' "$PROVIDER"
update_config 'Email' "$EMAIL"
sed -i "/^ *DNSEnv: *$/,/^$/s|^ *CLOUDFLARE_EMAIL: .*|  CLOUDFLARE_EMAIL: $CF_EMAIL|" ~/config.yml.example
sed -i "/^ *DNSEnv: *$/,/^$/s|^ *CLOUDFLARE_API_KEY: .*|  CLOUDFLARE_API_KEY: $CF_API_KEY|" ~/config.yml.example

# 重命名新配置文件
mv ~/config.yml.example $CONFIG_PATH

# 记录日志
echo -e "旧值 --> 新值" > $LOG_FILE
echo -e "PanelType: $PANEL_TYPE --> PanelType: $PANEL_TYPE" >> $LOG_FILE
echo -e "ApiHost: $API_HOST --> ApiHost: $API_HOST" >> $LOG_FILE
echo -e "ApiKey: $API_KEY --> ApiKey: $API_KEY" >> $LOG_FILE
echo -e "NodeID: $NODE_ID --> NodeID: $NODE_ID" >> $LOG_FILE
echo -e "NodeType: $NODE_TYPE --> NodeType: $NODE_TYPE" >> $LOG_FILE
echo -e "CertMode: $CERT_MODE --> CertMode: $CERT_MODE" >> $LOG_FILE
echo -e "CertDomain: $CERT_DOMAIN --> CertDomain: $CERT_DOMAIN" >> $LOG_FILE
echo -e "Provider: $PROVIDER --> Provider: $PROVIDER" >> $LOG_FILE
echo -e "Email: $EMAIL --> Email: $EMAIL" >> $LOG_FILE
echo -e "CLOUDFLARE_EMAIL: $CF_EMAIL --> CLOUDFLARE_EMAIL: $CF_EMAIL" >> $LOG_FILE
echo -e "CLOUDFLARE_API_KEY: $CF_API_KEY --> CLOUDFLARE_API_KEY: $CF_API_KEY" >> $LOG_FILE

# 延迟写入数据库
DELAY=$((NODE_ID * 2))
echo "等待$DELAY秒..."
sleep $DELAY

# 将日志和NodeID写入数据库
LOG_CONTENT=$(cat $LOG_FILE | sed "s/'/''/g")
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME --default-character-set=utf8mb4 -e "INSERT INTO $TABLE_NAME (NodeID, log, update_time) VALUES ('$NODE_ID', '$LOG_CONTENT', NOW()) ON DUPLICATE KEY UPDATE log='$LOG_CONTENT', update_time=NOW();"

echo "配置文件已更新并记录到日志文件。NodeID和日志内容已写入数据库。"
