# Panduan Migrasi dari VirtualBox ke Google Compute Engine

## Daftar Isi
1. [Persiapan](#persiapan)
2. [Setup GCP dan Membuat VM](#setup-gcp-dan-membuat-vm)
3. [Konfigurasi Virtual Machine](#konfigurasi-virtual-machine)
4. [Setup Web Server (Nginx)](#setup-web-server-nginx)
5. [Deploy Aplikasi](#deploy-aplikasi)
6. [Konfigurasi Firewall & Security](#konfigurasi-firewall--security)
7. [Monitoring CPU dan Memory](#monitoring-cpu-dan-memory)
8. [Troubleshooting](#troubleshooting)

---

## Persiapan

### Persyaratan:
- ✅ Akun Google Cloud Platform (GCP) dengan billing aktif
- ✅ Terminal/Command Line (PowerShell, CMD, atau Bash)
- ✅ SSH key (akan dibuat oleh GCP)
- ✅ Aplikasi Node.js siap di-deploy

### Biaya Estimasi:
- **VM Kecil (e2-micro)**: ~Rp 100-200rb/bulan (gratis 12 bulan first-time)
- **Storage**: ~Rp 0-50rb/bulan
- **Network Traffic**: Gratis untuk 1 GB pertama

---

## Setup GCP dan Membuat VM

### Langkah 1: Akses Google Cloud Console
1. Buka https://console.cloud.google.com
2. Login dengan akun Google Anda
3. Pilih atau buat project baru: `xyz-corp-deployment`
4. Aktifkan billing untuk project

### Langkah 2: Setup Project
```bash
# Set project ID di cloud shell atau CLI lokal
gcloud config set project xyz-corp-deployment
gcloud auth login
```

### Langkah 3: Membuat Virtual Machine
Pilih salah satu metode:

#### Metode A: Menggunakan Google Cloud Console (GUI)
1. Buka menu **Compute Engine** → **VM Instances**
2. Klik **CREATE INSTANCE**
3. Konfigurasi:
   ```
   Name: xyz-corp-api-server
   Region: asia-southeast1 (Jakarta) atau asia-southeast2 (Sydney)
   Zone: Pilih zone tersedia (contoh: a)
   Machine type: e2-micro (gratis tier) atau e2-small untuk performa lebih baik
   Boot disk:
   - Debian/Ubuntu recommended
   - Image: Ubuntu 20.04 LTS atau 22.04 LTS
   - Size: 20 GB (cukup untuk aplikasi + monitoring)
   Firewall: Centang "Allow HTTP" dan "Allow HTTPS"
   ```
4. Klik **Create** dan tunggu 1-2 menit

#### Metode B: Menggunakan gcloud CLI
```bash
# Install gcloud SDK jika belum
# Untuk Windows: https://cloud.google.com/sdk/docs/install

# Create VM dengan command
gcloud compute instances create xyz-corp-api-server \
  --zone=asia-southeast1-a \
  --machine-type=e2-small \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --metadata enable-oslogin=true \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

### Langkah 4: Dapatkan IP Eksternal VM
```bash
# Dari GCP Console: Lihat di kolom "EXTERNAL IP"
# Atau gunakan command:
gcloud compute instances list

# Output akan menampilkan IP VM Anda, contoh: 34.101.xx.xx
```

---

## Konfigurasi Virtual Machine

### Langkah 1: Koneksi SSH ke VM

#### Dari GCP Console:
1. Di halaman VM Instances, klik tombol **SSH** pada VM Anda

#### Dari Terminal Lokal:
```powershell
# PowerShell (Windows)
gcloud compute ssh xyz-corp-api-server --zone=asia-southeast1-a

# Atau jika sudah setup SSH key:
ssh -i [path_to_key] [username]@[external-ip]
```

### Langkah 2: Update Sistem & Install Dependencies

```bash
# Update package manager
sudo apt update
sudo apt upgrade -y

# Install Node.js (versi LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verifikasi instalasi
node --version    # v18.x.x
npm --version     # 9.x.x

# Install Git untuk cloning repository
sudo apt install -y git

# Install Nginx sebagai reverse proxy
sudo apt install -y nginx

# Install PM2 untuk process management
sudo npm install -g pm2

# Install monitoring tools
sudo apt install -y htop curl wget
```

### Langkah 3: Setup direktori aplikasi

```bash
# Buat direktori aplikasi
sudo mkdir -p /var/www/xyz-corp-api
sudo chown -R $USER:$USER /var/www/xyz-corp-api

# Navigate ke direktori
cd /var/www/xyz-corp-api
```

---

## Setup Web Server (Nginx)

### Langkah 1: Configure Nginx sebagai Reverse Proxy

Buat file konfigurasi Nginx:

```bash
sudo nano /etc/nginx/sites-available/xyz-corp-api
```

Paste konfigurasi berikut:

```nginx
upstream nodejs {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name _;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    location / {
        proxy_pass http://nodejs;
        proxy_http_version 1.1;
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
    
    # Serve static files directly
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1d;
        add_header Cache-Control "public, immutable";
    }
}
```

### Langkah 2: Enable konfigurasi Nginx

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/xyz-corp-api /etc/nginx/sites-enabled/

# Test konfigurasi
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx  # Auto-start on reboot
```

---

## Deploy Aplikasi

### Langkah 1: Clone atau Upload Aplikasi

#### Opsi A: Clone dari Repository (jika menggunakan Git)
```bash
cd /var/www/xyz-corp-api
git clone https://github.com/username/xyz-corp-api.git .
# atau
git clone https://github.com/username/xyz-corp-api.git ./temp
mv ./temp/* .
rm -rf ./temp
```

#### Opsi B: Upload secara Manual
```bash
# Di terminal lokal Anda, gunakan SCP
# Windows PowerShell:
scp -r "D:\semester 6\komputasi awann\new\xyz-corp-api\*" `
    username@[external-ip]:/var/www/xyz-corp-api/

# Atau dari GCP Cloud Shell:
gsutil -m cp -r local_path gs://xyz-corp-api-bucket/
```

### Langkah 2: Install Dependencies dan Setup Environment

```bash
# Navigate ke aplikasi directory
cd /var/www/xyz-corp-api

# Install npm dependencies
npm install

# Buat file .env
sudo nano .env
```

Isi file `.env` dengan:
```env
PORT=3000
NODE_ENV=production
API_VERSION=1.0.0
API_NAME=XYZ Corp REST API
CORS_ORIGIN=*
```

### Langkah 3: Setup PM2 untuk Auto-restart Application

```bash
# Start aplikasi dengan PM2
pm2 start src/app.js --name xyz-corp-api

# Setup PM2 startup on reboot
pm2 startup
# Copy dan jalankan command yang diberikan oleh PM2

# Save PM2 configuration
pm2 save

# Verifikasi PM2 processes
pm2 list
pm2 logs xyz-corp-api
```

### Langkah 4: Test Aplikasi

```bash
# Test dari VM
curl http://localhost:3000/
curl http://localhost:3000/api/projects
curl http://localhost:3000/api/employees

# Test dari browser lokal (ganti IP dengan external IP Anda)
# http://[external-ip]/
# http://[external-ip]/api/projects
```

---

## Konfigurasi Firewall & Security

### Langkah 1: Setup Firewall di GCP Console

1. Buka **VPC Network** → **Firewall rules**
2. Klik **CREATE FIREWALL RULE**
3. Konfigurasi untuk HTTP:
   ```
   Name: allow-http
   Direction: Ingress
   Priority: 1000
   Match - Source IPv4 ranges: 0.0.0.0/0
   Match - Protocols and ports:
     - tcp: 80
     - tcp: 443
   ```
4. Klik Create

Atau gunakan gcloud CLI:

```bash
# Allow HTTP
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# Allow HTTPS
gcloud compute firewall-rules create allow-https \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=https-server

# Allow SSH (opsional, untuk akses manual)
gcloud compute firewall-rules create allow-ssh \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0
```

### Langkah 2: Setup SSL/TLS Certificate (Opsional tapi Disarankan)

Gunakan Let's Encrypt dengan Certbot:

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain certificate (ganti dengan domain Anda jika ada)
sudo certbot certonly --nginx -d yourdomain.com

# Atau use standalone jika belum punya domain:
sudo certbot certonly --standalone --preferred-challenges http -d yourdomain.com

# Auto-renew setup
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

Update Nginx config untuk HTTPS:
```bash
sudo nano /etc/nginx/sites-available/xyz-corp-api
```

Tambahkan:
```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # ... rest of configuration
}

# Redirect HTTP ke HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
```

```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

## Monitoring CPU dan Memory

### Metode 1: Menggunakan GCP Cloud Monitoring (Rekomendasi)

#### Setup Monitoring Agent:
```bash
# Install Google Cloud Monitoring Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Start agent
sudo service google-cloud-ops-agent start
sudo systemctl enable google-cloud-ops-agent

# Verifikasi
sudo service google-cloud-ops-agent status
```

#### Akses Dashboard di GCP:
1. Buka **Monitoring** → **Dashboards**
2. Klik **Create Dashboard**
3. Tambahkan widgets untuk:
   - CPU utilization
   - Memory usage
   - Network traffic
   - Disk I/O

### Metode 2: Custom Monitoring Script

Buat script monitoring lokal:

```bash
# Buat file monitoring script
cat > /var/www/xyz-corp-api/monitor.sh << 'EOF'
#!/bin/bash

# Log file
LOG_FILE="/var/log/app-monitor.log"

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
  MEM=$(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')
  
  echo "[$TIMESTAMP] CPU: $CPU | Memory: $MEM" >> $LOG_FILE
  
  sleep 60  # Collect data setiap 60 detik
done
EOF

chmod +x /var/www/xyz-corp-api/monitor.sh

# Run dengan PM2
pm2 start /var/www/xyz-corp-api/monitor.sh --name monitor-app
pm2 save
```

### Metode 3: Real-time Monitoring di VM

```bash
# Install monitoring tools
sudo apt install -y htop sysstat

# Real-time monitoring
htop

# Atau gunakan tools ini:
top         # CPU and memory monitoring
free -h     # Memory usage
df -h       # Disk space
iostat      # I/O statistics
vmstat      # Virtual memory statistics
```

### Metode 4: Setup Alert di GCP

1. **Monitoring** → **Alerting Policies** → **Create Policy**
2. Konfigurasi:
   ```
   Condition:
   - Resource: Compute Engine Instance
   - Metric: cpu.utilization
   - Condition: Above 80% untuk 2 menit
   
   Notification:
   - Email Anda
   - atau Slack/PagerDuty
   ```

---

## Performance Tuning

### 1. Node.js Optimization

```bash
# Update .env dengan production settings
sudo nano /var/www/xyz-corp-api/.env
```

Tambahkan:
```env
NODE_ENV=production
NODE_OPTIONS=--max-old-space-size=512
```

### 2. Nginx Optimization

```bash
sudo nano /etc/nginx/nginx.conf
```

Dalam http block, tambahkan:
```nginx
# Worker processes
worker_processes auto;
worker_connections 2048;

# Buffer sizes
client_body_buffer_size 128k;
client_max_body_size 10m;

# Timeouts
keepalive_timeout 65;
```

### 3. System Optimization

```bash
# Increase file descriptors
sudo nano /etc/security/limits.conf
# Tambahkan di akhir:
* soft nofile 65535
* hard nofile 65535
```

---

## Troubleshooting

### Aplikasi tidak berjalan

```bash
# Check PM2 logs
pm2 logs xyz-corp-api

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Test aplikasi langsung
curl http://localhost:3000/

# Restart aplikasi
pm2 restart xyz-corp-api
```

### Koneksi refused/Timeout

```bash
# Check jika port 3000 listening
netstat -tlnp | grep 3000

# Check jika Nginx running
sudo systemctl status nginx

# Check firewall rules
sudo ufw status
sudo iptables -L
```

### Memory leak

```bash
# Monitor memory real-time
watch -n 1 'free -h'

# Check process memory
ps aux --sort=-%mem | head

# Restart aplikasi dengan PM2
pm2 restart xyz-corp-api --update-env
```

### SSH Connection Issues

```bash
# Dari lokal, test SSH
ssh -vvv username@[external-ip]

# Reset SSH key di GCP
gcloud compute instances os-login ssh-keys add \
  --key-file=~/.ssh/id_rsa.pub
```

---

## Checklist Deployment

- [ ] GCP project dibuat dan billing aktif
- [ ] VM instance dibuat dengan spesifikasi sesuai
- [ ] SSH key configured dan koneksi berhasil
- [ ] Node.js, npm, Nginx, PM2 terinstall
- [ ] Aplikasi di-upload ke /var/www/xyz-corp-api
- [ ] Dependencies di-install (npm install)
- [ ] .env file dikonfigurasi
- [ ] Aplikasi running di PM2
- [ ] Nginx reverse proxy configured
- [ ] Firewall rules allow HTTP/HTTPS
- [ ] Monitoring agent terinstall
- [ ] SSL/TLS certificate (opsional)
- [ ] Test akses dari browser (IP eksternal)
- [ ] Cek monitoring metrics di GCP console

---

## Referensi & Resource

- **GCP Docs**: https://cloud.google.com/docs/compute
- **Nginx Proxy**: https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- **PM2 Docs**: https://pm2.keymetrics.io/
- **Node.js Best Practices**: https://nodejs.org/en/docs/guides/nodejs-docker-webapp/

---

## Support & Next Steps

Jika menghadapi masalah:
1. Check logs di `/var/log/nginx/` dan PM2
2. Verifikasi firewall rules di GCP
3. Test koneksi: `curl http://[external-ip]/`
4. Check resource usage: `htop`

Untuk production grade:
- Setup Load Balancer
- Enable auto-scaling
- Setup CI/CD pipeline
- Implement backup strategy
- Configure CDN untuk static assets
