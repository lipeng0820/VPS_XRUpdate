#!/bin/bash

#!/bin/bash

# 检查 yq 是否已安装
if ! command -v yq &> /dev/null
then
    log_and_print "yq 未安装，尝试安装..."

    # 尝试安装 yq
    if [ -f "/etc/debian_version" ]; then
        sudo apt-get update
        sudo apt-get install -y yq
    elif [ -f "/etc/redhat-release" ]; then
        sudo yum install -y yq
    else
        log_and_print "错误: 不支持的操作系统"
        exit 1
    fi

    # 检查 yq 是否安装成功
    if ! command -v yq &> /dev/null
    then
        log_and_print "错误: yq 安装失败"
        exit 1
    fi
    log_and_print "yq 安装成功"
fi

log_file="$HOME/XRUpdate.log"
db_user="vedbs_2150"
db_password="aF3iOAURaf"
db_host="dbs-connect-cn-0.ip.parts"
db_name="vedbs_2150"
db_table="FREED00R_XRUpdate"

# 定义一个函数，用于记录日志并打印消息
log_and_print() {
  echo "$1"
  echo "$1" >> "$log_file"
}

# 确保日志文件存在，并清空其内容
touch "$log_file"
> "$log_file"

log_to_db() {
  local node_id="$1"
  local log_content="$2"
  local wait_time=$((node_id * 2))

  log_and_print "等待 $wait_time 秒后将日志写入数据库..."
  sleep "$wait_time"

  local escaped_log_content=$(echo "$log_content" | sed "s/\'/\'\'/g")
  local insert_command="INSERT INTO $db_table (NodeID, log, update_time) VALUES ('$node_id', '$escaped_log_content', NOW()) ON DUPLICATE KEY UPDATE log=VALUES(log), update_time=VALUES(update_time);"
  
  if mysql -h "$db_host" -u "$db_user" -p"$db_password" "$db_name" --default-character-set=utf8mb4 -e "$insert_command"; then
    log_and_print "日志已成功写入数据库"
  else
    log_and_print "错误: 无法将日志写入数据库"
  fi
}

# 检查 config.yml 文件是否存在
if [ ! -f "config.yml" ]; then
  log_and_print "错误: config.yml 文件不存在!"
  exit 1
fi

# 检查 config.yml.example 文件是否存在
if [ ! -f "config.yml.example" ]; then
  log_and_print "config.yml.example 文件不存在，尝试从网络下载..."
  if ! wget https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example; then
    log_and_print "错误: 下载 config.yml.example 文件失败!"
    exit 1
  else
    log_and_print "config.yml.example 已下载至 home 目录下"
  fi
fi

# 使用 yq 提取 config.yml 中的相关字段，并存储到关联数组中
declare -A config
while IFS=": " read -r key value; do
  config["$key"]="$value"
done < <(yq eval '.PanelType, .ApiHost, .ApiKey, .NodeID, .NodeType, .CertMode, .CertDomain, .Provider, .Email, .CLOUDFLARE_EMAIL, .CLOUDFLARE_API_KEY' config.yml)

log_and_print "提取完成，结果已存储到关联数组中"

# 使用 yq 替换 config.yml.example 文件中的值，并保存到临时文件
if ! yq eval-all '
  . as $item ireduce ({}; . * $item)
' config.yml.example <(echo "${config[@]}" | yq eval '.PanelType, .ApiHost, .ApiKey, .NodeID, .NodeType, .CertMode, .CertDomain, .Provider, .Email, .CLOUDFLARE_EMAIL, .CLOUDFLARE_API_KEY') > config.yml.tmp; then
  log_and_print "错误: 无法替换 config.yml.example 文件中的值。"
  exit 1
fi

# 将临时文件重命名为 config.yml
if ! mv config.yml.tmp config.yml.example; then
  log_and_print "错误: 无法重命名文件。"
  exit 1
fi

log_and_print "更新完成，结果已保存到 config.yml.example 文件中"

# 备份原 config.yml 文件，如果 config.yml.bak 已存在，则覆盖
if ! cp -f config.yml config.yml.bak; then
  log_and_print "错误: 无法备份 config.yml 文件。"
  exit 1
fi
log_and_print "config.yml 文件已备份为 config.yml.bak"

# 移除原 config.yml 文件
if ! rm config.yml; then
  log_and_print "错误: 无法移除 config.yml 文件。"
  exit 1
fi
log_and_print "config.yml 文件已移除"

# 将 config.yml.example 重命名为 config.yml
if ! mv config.yml.example config.yml; then
  log_and_print "错误: 无法重命名 config.yml.example 为 config.yml。"
  exit 1
fi
log_and_print "config.yml.example 已重命名为 config.yml"

log_and_print "脚本执行成功!"

# 在脚本的最后，读取NodeID和日志文件内容，然后调用 log_to_db 函数
node_id="${config["NodeID"]}"
log_content=$(<"$log_file")
log_to_db "$node_id" "$log_content"
