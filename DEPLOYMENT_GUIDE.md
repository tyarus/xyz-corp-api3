# XYZ Corp REST API - Ubuntu Server Deployment Guide

Panduan lengkap untuk deploy XYZ Corp REST API di Ubuntu Server VM dengan Nginx, Node.js, dan PM2.

## 📋 Daftar Isi

- [Prerequisites](#prerequisites)
- [FASE 2: Konfigurasi VM & Web Server](#fase-2-konfigurasi-vm--web-server)
- [FASE 3: Konfigurasi Firewall & Security](#fase-3-konfigurasi-firewall--security)
- [FASE 4: Deploy Aplikasi](#fase-4-deploy-aplikasi)
- [FASE 5: Monitoring](#fase-5-monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Ubuntu Server 20.04 LTS atau lebih baru
- Internet connection
- SSH access ke server
- Akun dengan sudo privileges

## FASE 2: Konfigurasi VM & Web Server

### Step 1: Update Sistem

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git ufw htop vim
```

**Penjelasan:**
- `apt update`: Refresh package list
- `apt upgrade`: Update semua packages
- `curl, wget, git`: Tools untuk networking dan version control
- `ufw`: Firewall management
- `htop`: System monitoring tool
- `vim`: Text editor

### Step 2: Install Node.js LTS

```bash
# Download Node.js setup script
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verifikasi instalasi
node --version
npm --version
```

**Output yang diharapkan:**
```
v18.x.x atau lebih baru
9.x.x atau lebih baru
```

### Step 3: Install dan Setup Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start Nginx
sudo systemctl start nginx

# Enable pada boot
sudo systemctl enable nginx

# Verifikasi
sudo systemctl status nginx
```

### Step 4: Konfigurasi Nginx sebagai Reverse Proxy

Buat file konfigurasi Nginx:

```bash
sudo nano /etc/nginx/sites-available/xyz-corp-api
```

Isi dengan konfigurasi berikut:

```nginx
# XYZ Corp API - Nginx Reverse Proxy Configuration
# Purpose: Proxy requests dari port 80 (publik) ke port 3000 (internal)

upstream xyz_corp_api {
    server localhost:3000;
    # Bisa ditambah server lain jika ada load balancing
}

# HTTP to HTTPS redirect (optional untuk production)
server {
    listen 80;
    server_name _;

    # Health check endpoint untuk Nginx
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Proxy semua request ke Node.js backend
    location / {
        proxy_pass http://xyz_corp_api;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
}
```

Aktivasi konfigurasi:

```bash
# Symlink ke sites-enabled
sudo ln -s /etc/nginx/sites-available/xyz-corp-api \
  /etc/nginx/sites-enabled/xyz-corp-api

# Disable default site
sudo rm /etc/nginx/sites-enabled/default

# Test konfigurasi
sudo nginx -t

# Expected output: "syntax is ok" dan "test is successful"

# Reload Nginx
sudo systemctl reload nginx
```

Verifikasi Nginx berjalan:

```bash
sudo systemctl status nginx
sudo netstat -tlnp | grep -E ':(80|3000)'
```

### Step 5: Setup Application User (Best Practice)

Jangan jalankan app sebagai root. Buat user khusus:

```bash
# Buat user 'appuser'
sudo useradd -m -s /bin/bash appuser

# Berikan direktori home
sudo mkdir -p /home/appuser/applications
sudo chown -R appuser:appuser /home/appuser/applications

# Test login
sudo su - appuser
exit
```

### Step 6: Install dan Setup PM2

PM2 adalah process manager untuk Node.js yang akan menjaga aplikasi tetap berjalan.

```bash
# Install PM2 globally
sudo npm install -g pm2

# Setup PM2 startup script
sudo pm2 startup systemd -u appuser --hp /home/appuser

# Verifikasi
pm2 status
```

**Catatan:** Jika install sebagai appuser, ganti username dengan appuser.

## FASE 3: Konfigurasi Firewall & Security

### Step 1: Setup UFW Firewall

```bash
# Reset firewall ke default
sudo ufw reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (CRITICAL - jangan skip!)
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS (jika sudah ada SSL certificate)
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Verifikasi rules
sudo ufw status numbered

# Expected output:
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere
```

### Step 2: Verify Security

```bash
# Check open ports
sudo ss -tlnp

# Expected output should show:
# :22  (SSH)
# :80  (HTTP via Nginx)
# :3000 (hanya localhost, tidak publik)

# Verify port 3000 tidak bisa diakses dari luar
telnet localhost 3000  # Berhasil dari local
# telnet [public-ip] 3000  # Tidak bisa dari luar
```

### Step 3: Dokumentasi Security

Lihat file `SECURITY.md` di project directory untuk detail security configuration.

## FASE 4: Deploy Aplikasi

### Step 1: Clone Repository dari GitHub

```bash
# Login sebagai appuser
sudo su - appuser

# Clone repository
cd ~/applications
git clone https://github.com/YOUR-USERNAME/xyz-corp-api.git xyz-corp-prod
cd xyz-corp-prod

# Verifikasi struktur
ls -la
```

### Step 2: Install Dependencies

```bash
cd ~/applications/xyz-corp-prod
npm install

# Verifikasi
npm list --depth=0
```

### Step 3: Jalankan dengan PM2

```bash
# Start aplikasi
pm2 start src/app.js --name "xyz-corp-api"

# Buat startup script
pm2 startup
pm2 save

# Verifikasi status
pm2 status
pm2 logs xyz-corp-api
```

### Step 4: Test API

```bash
# Health check
curl -s http://localhost/

# List projects
curl -s http://localhost/api/projects

# Stats
curl -s http://localhost/api/stats

# Create project
curl -s -X POST http://localhost/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Project",
    "team": "Engineering",
    "country": "Indonesia",
    "deadline": "2026-12-31",
    "progress": 0
  }'
```

### Step 5: Setup Auto-restart on Reboot

```bash
# Pastikan PM2 startup sudah running
pm2 startup

# Save PM2 process list
pm2 save

# Test: reboot server dan check jika app sudah berjalan
sudo reboot
```

Setelah reboot:
```bash
pm2 status  # Should show xyz-corp-api running
```

## FASE 5: Monitoring

### Step 1: Buat Monitoring Script

Lihat file `monitor.sh` di project directory.

### Step 2: Setup Cron Job untuk Monitoring

```bash
# Edit crontab
crontab -e

# Tambahkan baris ini (monitoring setiap 5 menit):
*/5 * * * * ~/applications/xyz-corp-prod/monitor.sh >> ~/xyz-corp-monitoring.log 2>&1

# Verifikasi
crontab -l
```

### Step 3: View Monitoring Logs

```bash
# Real-time monitoring
tail -f ~/xyz-corp-monitoring.log

# Check latest entries
head -20 ~/xyz-corp-monitoring.log
```

## Troubleshooting

### App tidak berjalan setelah deploy

```bash
# Check PM2 logs
pm2 logs xyz-corp-api

# Check error details
pm2 show xyz-corp-api

# Restart app
pm2 restart xyz-corp-api

# Stop dan start lagi
pm2 stop xyz-corp-api
pm2 start src/app.js --name "xyz-corp-api"
```

### Nginx error 502 Bad Gateway

```bash
# Check jika Node.js process masih berjalan
pm2 status

# Check jika port 3000 open
netstat -tlnp | grep 3000

# Restart Nginx
sudo systemctl restart nginx
```

### Port 80 sudah digunakan

```bash
# Cari process yang pakai port 80
sudo lsof -i :80

# Stop process yang conflict
sudo systemctl stop <service-name>
```

### Firewall memblokir akses

```bash
# Check UFW status
sudo ufw status numbered

# Verifikasi port 80 allow
sudo ufw status | grep 80

# Jika belum, tambahkan
sudo ufw allow 80/tcp
```

### PM2 tidak auto-start setelah reboot

```bash
# Rerun startup
pm2 startup systemd -u $USER --hp $HOME

# Save process list
pm2 save

# Check installed startup script
sudo systemctl status pm2-$USER

# Check if enabled
sudo systemctl is-enabled pm2-$USER
```

## Commands Quick Reference

```bash
# Server info
uname -a
node -v && npm -v
nginx -v

# Systemd services
sudo systemctl status nginx
sudo systemctl status pm2-appuser

# PM2 process management
pm2 list
pm2 status
pm2 logs
pm2 restart xyz-corp-api
pm2 stop xyz-corp-api
pm2 delete xyz-corp-api

# Network
sudo ss -tlnp
sudo ufw status numbered
netstat -an | grep LISTEN

# Monitoring
htop
vmstat 1 3
free -m
df -h
```

---

**Last Updated**: 2026-05-07  
**Support**: XYZ Corp Engineering Team
