# Wazuh, Caddy, and Fail2ban Integration

[English](README.md) | [Indonesia](README.id.md)
This project contains configuration files and scripts to integrate Caddy web server access logs with Wazuh for threat detection, and to automatically ban malicious IP addresses using Fail2ban via Wazuh Active Response.

## Files Overview and Usage

### 1. Wazuh Decoders and Rules
Caddy produces JSON formatted access logs, which Wazuh's built-in JSON decoder can parse automatically. Therefore, no complex custom decoder is required.

*   **`wazuh/decoders/caddy_decoder.xml`**
    *   **Purpose:** A dummy decoder. Caddy's JSON access logs are automatically parsed by Wazuh's built-in JSON decoder, so this file simply ensures compatibility if specific routing or ignore rules are ever needed.
    *   **Installation:** Copy this file to your Wazuh Manager's decoder directory.
        ```bash
        sudo cp wazuh/decoders/caddy_decoder.xml /var/ossec/etc/decoders/
        ```
    *   **Permissions:** Ensure it has the correct ownership.
        ```bash
        sudo chown wazuh:wazuh /var/ossec/etc/decoders/caddy_decoder.xml
        ```

*   **`wazuh/rules/caddy_rules.xml`**
    *   **Purpose:** Contains Wazuh rules to detect malicious behavior from Caddy JSON access logs. It includes rules for:
        *   WordPress scanning detection (Level 12 - Triggers Active Response)
        *   Client error thresholds (4xx errors)
        *   Unauthorized/Forbidden access attempts (Brute Force)
        *   Server errors (5xx errors)
    *   **Installation:** Copy this file to your Wazuh Manager's rules directory.
        ```bash
        sudo cp wazuh/rules/caddy_rules.xml /var/ossec/etc/rules/
        ```
    *   **Permissions:** Ensure it has the correct ownership.
        ```bash
        sudo chown wazuh:wazuh /var/ossec/etc/rules/caddy_rules.xml
        ```
    *   **Action:** Restart the Wazuh Manager after adding decoders and rules.
        ```bash
        sudo systemctl restart wazuh-manager
        ```

### 2. Fail2ban Configuration
We need a Fail2ban jail that Wazuh can interact with to execute the actual IP bans.

*   **`fail2ban/wazuh-jail.local`**
    *   **Purpose:** Defines a Fail2ban jail named `wazuh-jail`. It is configured to listen to manual ban/unban commands from the Wazuh Active Response script rather than parsing log files itself (`logpath = /dev/null`). The `bantime` is set very high because Wazuh will manage the timeout and send an explicit unban command.
    *   **Installation:** Copy this file to your Fail2ban configuration directory.
        ```bash
        sudo cp fail2ban/wazuh-jail.local /etc/fail2ban/jail.d/
        ```
    *   **Action:** Restart Fail2ban to load the new jail.
        ```bash
        sudo systemctl restart fail2ban
        ```

### 3. Wazuh Active Response
This setup allows Wazuh to trigger Fail2ban when a specific rule is matched (e.g., WordPress scanning).

*   **`wazuh/active-response/wazuh-fail2ban.sh`**
    *   **Purpose:** The Active Response script that Wazuh executes. It receives JSON input from Wazuh containing the offender's IP address and the command (`add` or `delete`), and translates it into a `fail2ban-client` command for the `wazuh-jail`.
    *   **Installation:** Copy this script to the Wazuh Active Response bin directory on the machine where Fail2ban is installed (either the Manager or the Agent).
        ```bash
        sudo cp wazuh/active-response/wazuh-fail2ban.sh /var/ossec/active-response/bin/wazuh-fail2ban
        ```
    *   **Permissions:** This is critical. The script must have the correct permissions and ownership to be executed by Wazuh.
        ```bash
        sudo chown root:wazuh /var/ossec/active-response/bin/wazuh-fail2ban
        sudo chmod 750 /var/ossec/active-response/bin/wazuh-fail2ban
        ```

*   **`wazuh/config/wazuh-fail2ban-config.xml`**
    *   **Purpose:** Contains the XML configuration snippets needed to define the Active Response command and trigger in Wazuh.
    *   **Installation:** You need to merge these XML blocks into your `ossec.conf` file (usually located at `/var/ossec/etc/ossec.conf`).
        *   If Fail2ban is running on the Wazuh Manager, edit the Manager's `ossec.conf`.
        *   If Fail2ban is running on a Wazuh Agent, edit the Agent's `ossec.conf` or use the Manager's shared `agent.conf`.
    *   **Configuration Details:** 
        *   Add the `<command>` block to define the executable (`wazuh-fail2ban`) and timeout settings.
        *   Add the `<active-response>` block to define when the command should run (e.g., on specific rule IDs or severity levels), where it should run (`local` or `server`), and the timeout duration (after which Wazuh sends the `delete` command to unban the IP).
    *   **Action:** Restart the Wazuh Manager (and Agent if configured there) after modifying `ossec.conf`.
