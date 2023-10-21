#!/bin/bash

# 进入家目录
cd ~ || {
  echo "切换到家目录失败"
  exit 1
}

# 备份config.yml文件，并删除原文件
if [ -f "config.yml" ]; then
  cp config.yml config.yml.bak
  rm -f config.yml
else
  echo "config.yml 文件不存在，请检查"
  exit 1
fi

# 下载最新版的XrayR配置文件范例
curl -o config.yml https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example

# 读取备份文件中的值
PanelType=$(awk -F': ' '/^[[:blank:]]*PanelType:/{print $2}' config.yml.bak | tr -d ' ')
ApiHost=$(awk -F': ' '/^[[:blank:]]*ApiHost:/{print $2}' config.yml.bak | tr -d ' ')
ApiKey=$(awk -F': ' '/^[[:blank:]]*ApiKey:/{print $2}' config.yml.bak | tr -d ' ')
NodeID=$(awk -F': ' '/^[[:blank:]]*NodeID:/{print $2}' config.yml.bak | tr -d ' ')
NodeType=$(awk -F': ' '/^[[:blank:]]*NodeType:/{print $2}' config.yml.bak | tr -d ' ')
CertMode=$(awk -F': ' '/^[[:blank:]]*CertMode:/{print $2}' config.yml.bak | tr -d ' ')
CertDomain=$(awk -F': ' '/^[[:blank:]]*CertDomain:/{print $2}' config.yml.bak | tr -d ' ')
Provider=$(awk -F': ' '/^[[:blank:]]*Provider:/{print $2}' config.yml.bak | tr -d ' ')
Email=$(awk -F': ' '/^[[:blank:]]*Email:/{print $2}' config.yml.bak | tr -d ' ')

DNSEnv=$(awk '/^DNSEnv:/{flag=1;next}/^[^[:blank:]]/{flag=0}flag' config.yml.bak)

# 调试输出
echo "NodeID: $NodeID"

# 如果NodeID为空，则退出脚本
if [ -z "$NodeID" ]; then
  echo "NodeID 为空，请检查 config.yml.bak 文件"
  exit 1
fi

# 修改新配置文件
sed -i "s/^PanelType: .*/PanelType: $PanelType/" config.yml
sed -i "s/^ApiHost: .*/ApiHost: $ApiHost/" config.yml
sed -i "s/^ApiKey: .*/ApiKey: $ApiKey/" config.yml
sed -i "s/^NodeID: .*/NodeID: $NodeID/" config.yml
sed -i "s/^NodeType: .*/NodeType: $NodeType/" config.yml
sed -i "s/^CertMode: .*/CertMode: $CertMode/" config.yml
sed -i "s/^CertDomain: .*/CertDomain: $CertDomain/" config.yml
sed -i "s/^Provider: .*/Provider: $Provider/" config.yml
sed -i "s/^Email: .*/Email: $Email/" config.yml

sed -i "/^DNSEnv:/,/^        -/ {
  /- CLOUDFLARE_EMAIL:/c$DNSEnv
}" config.yml

# 生成更新日志
echo "旧值    --> 新值" > XrayrConfigUpdate.log
echo "PanelType: $PanelType" >> XrayrConfigUpdate.log
echo "ApiHost: $ApiHost" >> XrayrConfigUpdate.log
echo "ApiKey: $ApiKey" >> XrayrConfigUpdate.log
echo "NodeID: $NodeID" >> XrayrConfigUpdate.log
echo "NodeType: $NodeType" >> XrayrConfigUpdate.log
echo "CertMode: $CertMode" >> XrayrConfigUpdate.log
echo "CertDomain: $CertDomain" >> XrayrConfigUpdate.log
echo "Provider: $Provider" >> XrayrConfigUpdate.log
echo "Email: $Email" >> XrayrConfigUpdate.log
echo "DNSEnv: $DNSEnv" >> XrayrConfigUpdate.log

# 等待 NodeID * 2 秒
sleep $((NodeID * 2))

# 将数据写入数据库
DB_PASSWORD="aF3iOAURaf"
LOG_CONTENT=$(cat XrayrConfigUpdate.log | sed ':a;N;$!ba;s/\n/\\n/g')
mysql -h dbs-connect-cn-0.ip.parts -u vedbs_2150 -p"$DB_PASSWORD" vedbs_2150 --default-character-set=utf8mb4 -e "INSERT INTO FREED00R_XRUpdate (NodeID, log) VALUES ('$NodeID', '$LOG_CONTENT')"
