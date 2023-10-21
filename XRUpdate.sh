#!/bin/bash

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

# 定位到 home 目录
cd ~

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

# 删除所有注释，提取需要的字段，并保存到 XRconf.tmp 文件
sed '/^ *#/d; /^ *$/d' config.yml | awk '
function trim(value) {
  sub(/ *#.*$/, "", value);
  return value;
}
/PanelType:/ {match($0, /PanelType: *(.*)/, arr); print "PanelType: " trim(arr[1])}
/ApiHost:/ {match($0, /ApiHost: *(.*)/, arr); print "ApiHost: " trim(arr[1])}
/ApiKey:/ {match($0, /ApiKey: *(.*)/, arr); print "ApiKey: " trim(arr[1])}
/NodeID:/ {match($0, /NodeID: *(.*)/, arr); print "NodeID: " trim(arr[1])}
/NodeType:/ {match($0, /NodeType: *(.*)/, arr); print "NodeType: " trim(arr[1])}
/CertMode:/ {match($0, /CertMode: *(.*)/, arr); print "CertMode: " trim(arr[1])}
/CertDomain:/ {match($0, /CertDomain: *(.*)/, arr); print "CertDomain: " trim(arr[1])}
/Provider:/ {match($0, /Provider: *(.*)/, arr); print "Provider: " trim(arr[1])}
/Email:/ {match($0, /Email: *(.*)/, arr); print "Email: " trim(arr[1])}
/CLOUDFLARE_EMAIL:/ {match($0, /CLOUDFLARE_EMAIL: *(.*)/, arr); print "CLOUDFLARE_EMAIL: " trim(arr[1])}
/CLOUDFLARE_API_KEY:/ {match($0, /CLOUDFLARE_API_KEY: *(.*)/, arr); print "CLOUDFLARE_API_KEY: " trim(arr[1])}
' > XRconf.tmp

log_and_print "提取完成，结果已保存到 XRconf.tmp 文件中"

# 读取XRconf.tmp文件并存储到关联数组中
declare -A config
while IFS=": " read -r key value; do
  config["$key"]="$value"
done < XRconf.tmp

# 替换config.yml.example文件中的值
if ! while IFS= read -r line; do
  if [[ "$line" =~ ^([[:space:]]*)([^#[:space:]]+):(.*)$ ]]; then
    indent="${BASH_REMATCH[1]}"
    key="${BASH_REMATCH[2]}"
    rest="${BASH_REMATCH[3]}"
    if [[ -n "${config[$key]}" ]]; then
      # 如果键存在于XRconf.tmp中，则替换值
      echo "${indent}${key}: ${config[$key]}"
    elif [[ "$key" == "ALICLOUD_ACCESS_KEY" && -n "${config["CLOUDFLARE_EMAIL"]}" ]]; then
      # 特殊处理CLOUDFLARE_EMAIL
      echo "${indent}CLOUDFLARE_EMAIL: ${config["CLOUDFLARE_EMAIL"]}"
    elif [[ "$key" == "ALICLOUD_SECRET_KEY" && -n "${config["CLOUDFLARE_API_KEY"]}" ]]; then
      # 特殊处理CLOUDFLARE_API_KEY
      echo "${indent}CLOUDFLARE_API_KEY: ${config["CLOUDFLARE_API_KEY"]}"
    else
      # 如果键不存在于XRconf.tmp中，则保持原样
      echo "$line"
    fi
  else
    # 如果行不包含键值对，则保持原样
    echo "$line"
  fi
done < config.yml.example > config.yml.example.tmp; then
  log_and_print "错误: 无法读取或写入文件。"
  exit 1
fi

# 将临时文件重命名为最终文件
if ! mv config.yml.example.tmp config.yml.example; then
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

# 删除临时文件
rm -f XRconf.tmp
log_and_print "脚本执行成功!临时文件 XRconf.tmp 已删除"

# 在脚本的最后，读取NodeID和日志文件内容，然后调用 log_to_db 函数
node_id="${config["NodeID"]}"
log_content=$(<"$log_file")
log_to_db "$node_id" "$log_content"
