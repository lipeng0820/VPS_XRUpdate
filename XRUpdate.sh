#!/bin/bash

# 检查yq是否已安装
if ! command -v yq &> /dev/null
then
    # 如果yq未安装，则下载并安装yq
    wget https://github.com/mikefarah/yq/releases/download/v4.13.5/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
fi

# 下载最新的config.yml.example文件
wget -O ~/config.yml.example https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example

# 备份旧的config.yml文件
mv ~/config.yml ~/config.yml.bak

# 提取用户配置文件（config.yml.bak）中的参数
panelType=$(yq e '.Nodes[0].PanelType' ~/config.yml.bak)
apiHost=$(yq e '.Nodes[0].ApiConfig.ApiHost' ~/config.yml.bak)
apiKey=$(yq e '.Nodes[0].ApiConfig.ApiKey' ~/config.yml.bak)
nodeID=$(yq e '.Nodes[0].ApiConfig.NodeID' ~/config.yml.bak)
nodeType=$(yq e '.Nodes[0].ApiConfig.NodeType' ~/config.yml.bak)
certMode=$(yq e '.Nodes[0].ControllerConfig.CertConfig.CertMode' ~/config.yml.bak)
certDomain=$(yq e '.Nodes[0].ControllerConfig.CertConfig.CertDomain' ~/config.yml.bak)
provider=$(yq e '.Nodes[0].ControllerConfig.CertConfig.Provider' ~/config.yml.bak)
email=$(yq e '.Nodes[0].ControllerConfig.CertConfig.Email' ~/config.yml.bak)

# 提取DNSEnv为一个临时文件
yq e '.Nodes[0].ControllerConfig.CertConfig.DNSEnv' ~/config.yml.bak > ~/temp_dns_env.yml

# 更新config.yml.example文件的其他参数
yq eval -i ".Nodes[0].PanelType = \"$panelType\"" ~/config.yml.example
yq eval -i ".Nodes[0].ApiConfig.ApiHost = \"$apiHost\"" ~/config.yml.example
yq eval -i ".Nodes[0].ApiConfig.ApiKey = \"$apiKey\"" ~/config.yml.example
yq eval -i ".Nodes[0].ApiConfig.NodeID = $nodeID" ~/config.yml.example
yq eval -i ".Nodes[0].ApiConfig.NodeType = \"$nodeType\"" ~/config.yml.example
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.CertMode = \"$certMode\"" ~/config.yml.example
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.CertDomain = \"$certDomain\"" ~/config.yml.example
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.Provider = \"$provider\"" ~/config.yml.example
yq eval -i ".Nodes[0].ControllerConfig.CertConfig.Email = \"$email\"" ~/config.yml.example

# 更新config.yml.example文件的DNSEnv部分
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' ~/config.yml.example ~/temp_dns_env.yml > ~/temp_updated.yml

# 移动临时更新文件以替换config.yml.example
mv ~/temp_updated.yml ~/config.yml.example

# 重命名config.yml.example为config.yml
mv ~/config.yml.example ~/config.yml

# 记录变化到XrayrConfigUpdate.log文件
cat <<EOL > ~/XrayrConfigUpdate.log
旧值 ---> 新值
ApiHost: "$apiHost" ---> ApiHost: "$(yq e '.Nodes[0].ApiConfig.ApiHost' ~/config.yml)"
EOL

# 清理临时文件
rm ~/temp_dns_env.yml
