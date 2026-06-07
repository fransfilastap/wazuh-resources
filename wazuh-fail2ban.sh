#!/usr/bin/env bash
# Wazuh Active Response to execute Fail2ban
# Target Path: /var/ossec/active-response/bin/wazuh-fail2ban
# Ownership: chown root:wazuh /var/ossec/active-response/bin/wazuh-fail2ban
# Permissions: chmod 750 /var/ossec/active-response/bin/wazuh-fail2ban

# Configuration
JAIL_NAME="wazuh-jail" # Change this to your target fail2ban jail
LOG_FILE="/var/ossec/logs/active-responses.log"

# Read input from STDIN (Wazuh 4.2+ format is JSON)
read -r INPUT_JSON

# We can parse JSON using jq if available, or grep as a fallback. 
# Here we use grep/sed to avoid jq dependency, extracting "command" and "srcip".
COMMAND=$(echo "$INPUT_JSON" | grep -o '"command":"[^"]*' | cut -d'"' -f4)

# Try to extract srcip from data.srcip first, then fallback to alert.srcip
SRCIP=$(echo "$INPUT_JSON" | grep -o '"srcip":"[^"]*' | head -n 1 | cut -d'"' -f4)

if [ -z "$SRCIP" ]; then
    echo "$(date '+%Y/%m/%d %H:%M:%S') wazuh-fail2ban: Cannot extract srcip from alert." >> "$LOG_FILE"
    exit 0
fi

# Execute Fail2ban client
if [ "$COMMAND" = "add" ]; then
    echo "$(date '+%Y/%m/%d %H:%M:%S') wazuh-fail2ban: Banning $SRCIP in jail $JAIL_NAME" >> "$LOG_FILE"
    fail2ban-client set "$JAIL_NAME" banip "$SRCIP" >> "$LOG_FILE" 2>&1
elif [ "$COMMAND" = "delete" ]; then
    echo "$(date '+%Y/%m/%d %H:%M:%S') wazuh-fail2ban: Unbanning $SRCIP in jail $JAIL_NAME" >> "$LOG_FILE"
    fail2ban-client set "$JAIL_NAME" unbanip "$SRCIP" >> "$LOG_FILE" 2>&1
else
    echo "$(date '+%Y/%m/%d %H:%M:%S') wazuh-fail2ban: Invalid command '$COMMAND'" >> "$LOG_FILE"
    exit 1
fi

exit 0
