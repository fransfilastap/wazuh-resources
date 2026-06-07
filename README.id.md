# Integrasi Wazuh, Caddy, dan Fail2ban

[English](README.md) | [Indonesia](README.id.md)

Proyek ini berisi file konfigurasi dan skrip untuk mengintegrasikan log akses server web Caddy dengan Wazuh untuk deteksi ancaman, dan secara otomatis memblokir alamat IP berbahaya menggunakan Fail2ban melalui Wazuh Active Response.

## Ringkasan File dan Penggunaan

### 1. Decoder dan Rules Wazuh
Caddy menghasilkan log akses berformat JSON, yang dapat diurai secara otomatis oleh decoder JSON bawaan Wazuh. Oleh karena itu, decoder kustom yang rumit tidak diperlukan.

*   **`wazuh/decoders/caddy_decoder.xml`**
    *   **Tujuan:** Decoder dummy. Log akses JSON Caddy secara otomatis diurai oleh decoder JSON bawaan Wazuh, jadi file ini hanya memastikan kompatibilitas jika aturan perutean atau abaikan (ignore rules) spesifik diperlukan suatu saat nanti.
    *   **Instalasi:** Salin file ini ke direktori decoder Wazuh Manager Anda.
        ```bash
        sudo cp wazuh/decoders/caddy_decoder.xml /var/ossec/etc/decoders/
        ```
    *   **Izin (Permissions):** Pastikan kepemilikannya benar.
        ```bash
        sudo chown wazuh:wazuh /var/ossec/etc/decoders/caddy_decoder.xml
        ```

*   **`wazuh/rules/caddy_rules.xml`**
    *   **Tujuan:** Berisi aturan (rules) Wazuh untuk mendeteksi perilaku berbahaya dari log akses JSON Caddy. Ini termasuk aturan untuk:
        *   Deteksi pemindaian (scanning) WordPress (Level 12 - Memicu Active Response)
        *   Ambang batas kesalahan klien (client error) (kesalahan 4xx)
        *   Upaya akses tidak sah/terlarang (Brute Force)
        *   Kesalahan server (kesalahan 5xx)
    *   **Instalasi:** Salin file ini ke direktori rules Wazuh Manager Anda.
        ```bash
        sudo cp wazuh/rules/caddy_rules.xml /var/ossec/etc/rules/
        ```
    *   **Izin (Permissions):** Pastikan kepemilikannya benar.
        ```bash
        sudo chown wazuh:wazuh /var/ossec/etc/rules/caddy_rules.xml
        ```
    *   **Tindakan:** Mulai ulang (restart) Wazuh Manager setelah menambahkan decoder dan rules.
        ```bash
        sudo systemctl restart wazuh-manager
        ```

### 2. Konfigurasi Fail2ban
Kita membutuhkan *jail* Fail2ban yang dapat berinteraksi dengan Wazuh untuk mengeksekusi pemblokiran IP yang sebenarnya.

*   **`fail2ban/wazuh-jail.local`**
    *   **Tujuan:** Mendefinisikan *jail* Fail2ban bernama `wazuh-jail`. Ini dikonfigurasi untuk mendengarkan perintah pemblokiran/pembukaan blokir (ban/unban) manual dari skrip Wazuh Active Response daripada mengurai file log itu sendiri (`logpath = /dev/null`). `bantime` diatur sangat tinggi karena Wazuh akan mengelola batas waktu dan mengirimkan perintah pembukaan blokir secara eksplisit.
    *   **Instalasi:** Salin file ini ke direktori konfigurasi Fail2ban Anda.
        ```bash
        sudo cp fail2ban/wazuh-jail.local /etc/fail2ban/jail.d/
        ```
    *   **Tindakan:** Mulai ulang (restart) Fail2ban untuk memuat *jail* baru.
        ```bash
        sudo systemctl restart fail2ban
        ```

### 3. Wazuh Active Response
Pengaturan ini memungkinkan Wazuh untuk memicu Fail2ban ketika aturan tertentu cocok (misalnya, pemindaian WordPress).

*   **`wazuh/active-response/wazuh-fail2ban.sh`**
    *   **Tujuan:** Skrip Active Response yang dieksekusi oleh Wazuh. Skrip ini menerima input JSON dari Wazuh yang berisi alamat IP pelanggar dan perintah (`add` atau `delete`), lalu menerjemahkannya menjadi perintah `fail2ban-client` untuk `wazuh-jail`.
    *   **Instalasi:** Salin skrip ini ke direktori bin Active Response Wazuh pada mesin di mana Fail2ban diinstal (baik itu Manager atau Agent).
        ```bash
        sudo cp wazuh/active-response/wazuh-fail2ban.sh /var/ossec/active-response/bin/wazuh-fail2ban
        ```
    *   **Izin (Permissions):** Ini sangat penting. Skrip harus memiliki izin dan kepemilikan yang benar agar dapat dieksekusi oleh Wazuh.
        ```bash
        sudo chown root:wazuh /var/ossec/active-response/bin/wazuh-fail2ban
        sudo chmod 750 /var/ossec/active-response/bin/wazuh-fail2ban
        ```

*   **`wazuh/config/wazuh-fail2ban-config.xml`**
    *   **Tujuan:** Berisi potongan konfigurasi XML yang diperlukan untuk mendefinisikan perintah Active Response dan pemicunya di Wazuh.
    *   **Instalasi:** Anda perlu menggabungkan blok XML ini ke dalam file `ossec.conf` Anda (biasanya terletak di `/var/ossec/etc/ossec.conf`).
        *   Jika Fail2ban berjalan di Wazuh Manager, edit `ossec.conf` milik Manager.
        *   Jika Fail2ban berjalan di Wazuh Agent, edit `ossec.conf` milik Agent atau gunakan shared `agent.conf` milik Manager.
    *   **Detail Konfigurasi:** 
        *   Tambahkan blok `<command>` untuk mendefinisikan pengaturan *executable* (`wazuh-fail2ban`) dan batas waktu (*timeout*).
        *   Tambahkan blok `<active-response>` untuk mendefinisikan kapan perintah harus dijalankan (misalnya, pada ID aturan atau tingkat keparahan tertentu), di mana itu harus dijalankan (`local` atau `server`), dan durasi batas waktu (setelah itu Wazuh mengirimkan perintah `delete` untuk membuka blokir IP).
    *   **Tindakan:** Mulai ulang (restart) Wazuh Manager (dan Agent jika dikonfigurasi di sana) setelah memodifikasi `ossec.conf`.
