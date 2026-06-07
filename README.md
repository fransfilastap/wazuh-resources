# Wazuh Resources and Config Examples

[English](README.md) | [Indonesia](README.id.md)

Welcome to the Wazuh Resources repository. This repository serves as a collection of configuration examples, scripts, and resources for extending and customizing your [Wazuh](https://wazuh.com/) deployments.

## Available Examples

### 1. Caddy Web Server & Fail2ban Integration

This example demonstrates how to integrate Caddy web server access logs with Wazuh for threat detection, and how to automatically ban malicious IP addresses using Fail2ban via Wazuh Active Response.

#### Files Overview and Usage

**Wazuh Decoders and Rules**

Caddy produces JSON formatted access logs, which Wazuh's built-in JSON decoder can parse automatically. Therefore, no complex custom decoder is required.

*   **`wazuh/decoders/caddy_decoder.xml`**
    *   **Purpose:** A dummy decoder to ensure compatibility if specific routing or ignore rules are needed for Caddy.
    *   **Installation:** 
        ```bash
        sudo cp wazuh/decoders/caddy_decoder.xml /var/ossec/etc/decoders/
        sudo chown wazuh:wazuh /var/ossec/etc/decoders/caddy_decoder.xml
        ```

*   **`wazuh/rules/caddy_rules.xml`**
    *   **Purpose:** Contains rules to detect malicious behavior from Caddy JSON access logs (e.g., WordPress scanning, client errors, Brute Force).
    *   **Installation:** 
        ```bash
        sudo cp wazuh/rules/caddy_rules.xml /var/ossec/etc/rules/
        sudo chown wazuh:wazuh /var/ossec/etc/rules/caddy_rules.xml
        ```

**Fail2ban Configuration**

*   **`fail2ban/wazuh-jail.local`**
    *   **Purpose:** Defines a Fail2ban jail named `wazuh-jail` that listens to manual ban/unban commands from the Wazuh Active Response script.
    *   **Installation:** 
        ```bash
        sudo cp fail2ban/wazuh-jail.local /etc/fail2ban/jail.d/
        sudo systemctl restart fail2ban
        ```

**Wazuh Active Response**

*   **`wazuh/active-response/wazuh-fail2ban.sh`**
    *   **Purpose:** The Active Response script that executes `fail2ban-client` commands based on Wazuh alerts.
    *   **Installation:** 
        ```bash
        sudo cp wazuh/active-response/wazuh-fail2ban.sh /var/ossec/active-response/bin/wazuh-fail2ban
        sudo chown root:wazuh /var/ossec/active-response/bin/wazuh-fail2ban
        sudo chmod 750 /var/ossec/active-response/bin/wazuh-fail2ban
        ```

*   **`wazuh/config/wazuh-fail2ban-config.xml`**
    *   **Purpose:** Contains the XML configuration snippets needed to define the Active Response command and trigger in `ossec.conf`.
    *   **Installation:** Merge these XML blocks into your `/var/ossec/etc/ossec.conf` file on the Manager or Agent where Fail2ban runs.

*After making changes to Wazuh configurations, remember to restart the Wazuh Manager/Agent:*
```bash
sudo systemctl restart wazuh-manager
```

---
*More resources and examples will be added in the future.*
