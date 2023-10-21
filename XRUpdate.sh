#!/bin/bash

# Navigate to home directory
cd ~ || exit

# Backup the current config and download the new one
cp config.yml config.yml.bak
curl -o config.yml https://raw.githubusercontent.com/XrayR-project/XrayR/master/release/config/config.yml.example

# Extract NodeID
NODE_ID=$(sed -n 's/^[[:space:]]*NodeID:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p' config.yml.bak)
echo "NodeID is: $NODE_ID"

# Update the configuration
sed -i.bak -e '/^PanelType:/r'<(grep '^PanelType:' config.yml.bak) \
           -e '/^ApiHost:/r'<(grep '^ApiHost:' config.yml.bak) \
           -e '/^ApiKey:/r'<(grep '^ApiKey:' config.yml.bak) \
           -e '/^NodeID:/r'<(grep '^NodeID:' config.yml.bak) \
           -e '/^NodeType:/r'<(grep '^NodeType:' config.yml.bak) \
           -e '/^CertMode:/r'<(grep '^CertMode:' config.yml.bak) \
           -e '/^CertDomain:/r'<(grep '^CertDomain:' config.yml.bak) \
           -e '/^Provider:/r'<(grep '^Provider:' config.yml.bak) \
           -e '/^Email:/r'<(grep '^Email:' config.yml.bak) \
           -e '/^DNSEnv:/r'<(sed -n '/^DNSEnv:/,/^$/p' config.yml.bak) config.yml

# Generate the update log
echo -e "旧值\t--> 新值" > XrayrConfigUpdate.log
for key in PanelType ApiHost ApiKey NodeID NodeType CertMode CertDomain Provider Email DNSEnv; do
    OLD_VALUE=$(grep "^$key:" config.yml.bak)
    NEW_VALUE=$(grep "^$key:" config.yml)
    if [ "$OLD_VALUE" != "$NEW_VALUE" ]; then
        echo -e "$OLD_VALUE\t--> $NEW_VALUE" >> XrayrConfigUpdate.log
    fi
done

# Check for new values
echo -e "\n---\n新增值" >> XrayrConfigUpdate.log
grep -vf <(grep -o '^[^#]*' config.yml.bak) <(grep -o '^[^#]*' config.yml) >> XrayrConfigUpdate.log

# Delay based on NodeID
sleep $((NODE_ID * 2))

# Insert data into database
DB_PASSWORD="aF3iOAURaf"
LOG_CONTENT=$(<XrayrConfigUpdate.log)
mysql -h dbs-connect-cn-0.ip.parts -u vedbs_2150 -p$DB_PASSWORD vedbs_2150 --default-character-set=utf8mb4 -e "INSERT INTO FREED00R_XRUpdate (NodeID, log) VALUES ('$NODE_ID', '$LOG_CONTENT')"
