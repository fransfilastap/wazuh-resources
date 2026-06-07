# Wazuh Resources and Config Examples

[English](README.md) | [Indonesia](README.id.md)

Selamat datang di repositori Sumber Daya Wazuh (Wazuh Resources). Repositori ini berfungsi sebagai kumpulan contoh konfigurasi, skrip, dan sumber daya untuk memperluas dan mengkustomisasi penerapan [Wazuh](https://wazuh.com/) Anda.

## Contoh yang Tersedia

### 1. Integrasi Server Web Caddy & Fail2ban

Contoh ini mendemonstrasikan cara mengintegrasikan log akses server web Caddy dengan Wazuh untuk deteksi ancaman, dan cara secara otomatis memblokir alamat IP berbahaya menggunakan Fail2ban melalui Wazuh Active Response.

#### Ringkasan File dan Penggunaan

**Decoder dan Rules Wazuh**

Caddy menghasilkan log akses berformat JSON, yang dapat diurai secara otomatis oleh decoder JSON bawaan Wazuh. Oleh karena itu, decoder kustom yang rumit tidak diperlukan.

*   **`wazuh/decoders/caddy_decoder.xml`**
    *   **Tujuan:** Decoder dummy untuk memastikan kompatibilitas jika aturan perutean atau abaikan spesifik diperlukan untuk Caddy.
    *   **Instalasi:** 
        ```bash
        sudo cp wazuh/decoders/caddy_decoder.xml /var/ossec/etc/decoders/
        sudo chown wazuh:wazuh /var/ossec/etc/decoders/caddy_decoder.xml
        ```

*   **`wazuh/rules/caddy_rules.xml`**
    *   **Tujuan:** Berisi aturan untuk mendeteksi perilaku berbahaya dari log akses JSON Caddy (misalnya, pemindaian WordPress, kesalahan klien, Brute Force).
    *   **Instalasi:** 
        ```bash
        sudo cp wazuh/rules/caddy_rules.xml /var/ossec/etc/rules/
        sudo chown wazuh:wazuh /var/ossec/etc/rules/caddy_rules.xml
        ```

**Konfigurasi Fail2ban**

*   **`fail2ban/jail.d/wazuh-jail.local`**
    *   **Tujuan:** Mendefinisikan *jail* Fail2ban bernama `wazuh-jail` yang mendengarkan perintah pemblokiran/pembukaan blokir manual dari skrip Wazuh Active Response.
    *   **Instalasi:** 
        ```bash
        sudo cp fail2ban/jail.d/wazuh-jail.local /etc/fail2ban/jail.d/
        ```

*   **`fail2ban/filter.d/wazuh-jail.conf`**
    *   **Tujuan:** Filter regex dummy untuk mencegah error saat Fail2ban dijalankan, karena *jail* ini dipicu secara manual.
    *   **Instalasi:** 
        ```bash
        sudo cp fail2ban/filter.d/wazuh-jail.conf /etc/fail2ban/filter.d/
        sudo systemctl restart fail2ban
        ```

**Wazuh Active Response**

*   **`wazuh/active-response/wazuh-fail2ban.sh`**
    *   **Tujuan:** Skrip Active Response yang mengeksekusi perintah `fail2ban-client` berdasarkan peringatan Wazuh.
    *   **Instalasi:** 
        ```bash
        sudo cp wazuh/active-response/wazuh-fail2ban.sh /var/ossec/active-response/bin/wazuh-fail2ban
        sudo chown root:wazuh /var/ossec/active-response/bin/wazuh-fail2ban
        sudo chmod 750 /var/ossec/active-response/bin/wazuh-fail2ban
        ```

*   **`wazuh/config/wazuh-fail2ban-config.xml`**
    *   **Tujuan:** Berisi potongan konfigurasi XML yang diperlukan untuk mendefinisikan perintah Active Response dan pemicunya di `ossec.conf`.
    *   **Instalasi:** Gabungkan blok XML ini ke dalam file `/var/ossec/etc/ossec.conf` Anda di Manager atau Agent tempat Fail2ban berjalan.

*Setelah membuat perubahan pada konfigurasi Wazuh, ingatlah untuk memulai ulang (restart) Wazuh Manager/Agent:*
```bash
sudo systemctl restart wazuh-manager
```

---
*Lebih banyak sumber daya dan contoh akan ditambahkan di masa mendatang.*
