#!/bin/bash

# 安装 yq 工具
if ! command -v yq &> /dev/null
then
    echo "yq could not be found, installing now..."
    wget -O /usr/bin/yq https://github.com/mikefarah/yq/releases/download/v4.13.5/yq_linux_amd64
    chmod +x /usr/bin/yq
fi

# 检查 config.yml 是否存在
if [[ ! -f ~/config.yml ]]; then
    echo "Error: config.yml file not found!"
    exit 1
fi

# 下载新的 config.yml.example
wget -O ~/config.yml.example https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example

# 备份当前的 config.yml
mv ~/config.yml ~/config.yml.bak

# 提取所需的参数值并将它们复制到 config.yml.example
for param in PanelType ApiHost ApiKey NodeID NodeType CertMode CertDomain Provider Email; do
    value=$(yq e ".Nodes[0].${param}" ~/config.yml.bak)
    yq eval -i ".Nodes[0].${param} = ${value}" ~/config.yml.example
done

# 替换 DNSEnv 下的两个参数
dnsEnv=$(yq e ".Nodes[0].ControllerConfig.CertConfig.DNSEnv" ~/config.yml.bak)
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.DNSEnv = ${dnsEnv}" ~/config.yml.example

# 删除 ALICLOUD_ACCESS_KEY 和 ALICLOUD_SECRET_KEY
yq eval -i "del(.Nodes[0].ControllerConfig.CertConfig.DNSEnv.ALICLOUD_ACCESS_KEY)" ~/config.yml.example
yq eval -i "del(.Nodes[0].ControllerConfig.CertConfig.DNSEnv.ALICLOUD_SECRET_KEY)" ~/config.yml.example

# 将 CLOUDFLARE_EMAIL 和 CLOUDFLARE_API_KEY 添加到 DNSEnv 下，并按照指定的格式缩进
cloudflareEmail=$(yq e ".Nodes[0].ControllerConfig.CertConfig.DNSEnv.CLOUDFLARE_EMAIL" ~/config.yml.bak)
cloudflareApiKey=$(yq e ".Nodes[0].ControllerConfig.CertConfig.DNSEnv.CLOUDFLARE_API_KEY" ~/config.yml.bak)
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.DNSEnv.CLOUDFLARE_EMAIL = \"${cloudflareEmail}\"" ~/config.yml.example
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.DNSEnv.CLOUDFLARE_API_KEY = \"${cloudflareApiKey}\"" ~/config.yml.example

# 将更新后的 config.yml.example 重命名为 config.yml
mv ~/config.yml.example ~/config.yml

# 创建一个日志文件以记录所做的更改
echo "旧值 ---> 新值" > ~/XrayrConfigUpdate.log
for param in PanelType ApiHost ApiKey NodeID NodeType CertMode CertDomain Provider Email; do
    oldValue=$(yq e ".Nodes[0].${param}" ~/config.yml.bak)
    newValue=$(yq e ".Nodes[0].${param}" ~/config.yml)
    echo "${param}: ${oldValue} ---> ${param}: ${newValue}" >> ~/XrayrConfigUpdate.log
done
