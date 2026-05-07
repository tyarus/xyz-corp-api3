# XYZ Corp API - Deployment Commands Reference

Referensi lengkap perintah-perintah yang dibutuhkan untuk deployment manual ke Ubuntu Server.

## 📋 Persiapan Lokal (Local Development Machine)

### Inisialisasi Project

```bash
# Buat folder project
mkdir xyz-corp-api && cd xyz-corp-api

# Inisialisasi npm
npm init -y

# Install dependencies
npm install express cors dotenv morgan
npm install --save-dev nodemon

# Buat struktur folder
mkdir -p src/routes src/middleware

# Buat file-file utama
touch src/app.js src/middleware/logger.js src/routes/projects.js src/routes/employees.js
touch .env .env.example package.json README.md
```

### Testing Lokal

```bash
# Jalankan server
npm start

# Di terminal lain, test endpoints
curl http://localhost:3000/
curl http://localhost:3000/api/projects
curl http://localhost:3000/api/employees
curl http://localhost:3000/api/stats

# Test POST endpoint
curl -X POST http://localhost:3000/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Project","team":"Team A","country":"Indonesia","deadline":"2026-12-31","progress":0}'
```

### Push ke GitHub

```bash
# Inisialisasi git
git init
git add .
git commit -m "feat: initial XYZ Corp REST API"
git branch -M main
git remote add origin https://github.com/USERNAME/xyz-corp-api.git
git push -u origin main
```

---

## 🖥️ Deployment ke Ubuntu Server (Manual)

### Step 1: Connect ke Ubuntu Server

```bash
# Connect via SSH
ssh -i /path/to/key.pem ubuntu@<server-ip>

# Atau dengan password
ssh ubuntu@<server-ip>
```

### Step 2: Update Sistem

```bash
# Update package manager
sudo apt update
sudo apt upgrade -y

# Install tools tambahan
sudo apt install -y curl wget git ufw htop build-essential
```

### Step 3: Install Node.js LTS

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verifikasi
node --version
npm --version
```

### Step 4: Buat Non-Root User

```bash
# Create user
sudo useradd -m -s /bin/bash xyz-corp-user

# Add to sudo group (optional)
sudo usermod -aG sudo xyz-corp-user

# Switch ke user baru
su - xyz-corp-user
```

### Step 5: Clone dan Setup Aplikasi

```bash
# Clone repository (ganti USERNAME)
git clone https://github.com/USERNAME/xyz-corp-api.git
cd xyz-corp-api

# Install dependencies
npm install --production

# Copy environment file
cp .env.example .env

# Edit .env jika perlu
nano .env
```

### Step 6: Install dan Setup Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start dan enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verifikasi
sudo systemctl status nginx
```

### Step 7: Konfigurasi Nginx Reverse Proxy

```bash
# Create Nginx config file
sudo nano /etc/nginx/sites-available/xyz-corp-api
```

Paste configuration berikut:

```nginx
upstream xyz_corp_app {
    server localhost:3000;
}

server {
    listen 80;
    server_name _;
    
    access_log /var/log/nginx/xyz-corp-api-access.log combined;
    error_log /var/log/nginx/xyz-corp-api-error.log;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
    
    location / {
        proxy_pass http://xyz_corp_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location ~ /\. {
        deny all;
    }
}
```

```bash
# Enable configuration
sudo ln -s /etc/nginx/sites-available/xyz-corp-api /etc/nginx/sites-enabled/

# Remove default
sudo rm /etc/nginx/sites-enabled/default 2>/dev/null || true

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 8: Install PM2 Process Manager

```bash
# Install PM2 globally
sudo npm install -g pm2

# Start aplikasi dengan PM2
cd ~/xyz-corp-api
pm2 start src/app.js --name "xyz-corp-api"

# Setup startup script
pm2 startup
pm2 save

# Verifikasi
pm2 status
pm2 logs xyz-corp-api
```

### Step 9: Setup Firewall (UFW)

```bash
# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS (future)
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Verify
sudo ufw status verbose

# Check open ports
sudo ss -tlnp
```

### Step 10: Test API

```bash
# Test dari server
curl http://localhost

# Test specific endpoints
curl http://localhost/api/projects
curl http://localhost/api/employees
curl http://localhost/api/stats

# Test POST
curl -X POST http://localhost/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"New Project","team":"Team","country":"ID","deadline":"2026-12-31","progress":0}'
```

### Step 11: Setup Monitoring (Optional)

```bash
# Copy monitoring script
cp ~/xyz-corp-api/monitor.sh ~/monitor.sh
chmod +x ~/monitor.sh

# Run monitoring script
~/monitor.sh

# Setup cron job (every 5 minutes)
crontab -e

# Add this line to crontab:
# */5 * * * * ~/monitor.sh >> ~/xyz-corp-monitoring.log 2>&1

# View monitoring logs
tail -f ~/xyz-corp-monitoring.log
```

---

## 🔍 Verifikasi Deployment

### Check Services Status

```bash
# Check Node.js application
pm2 status
pm2 logs xyz-corp-api

# Check Nginx
sudo systemctl status nginx

# Check Firewall
sudo ufw status

# Check ports
sudo ss -tlnp

# Check processes
top
ps aux | grep node
```

### Check Logs

```bash
# Nginx access log
sudo tail -f /var/log/nginx/xyz-corp-api-access.log

# Nginx error log
sudo tail -f /var/log/nginx/xyz-corp-api-error.log

# System log
sudo journalctl -u nginx -f

# PM2 application log
pm2 logs xyz-corp-api
```

### Test Endpoints

```bash
# Health check
curl -I http://localhost

# Verify response headers
curl -v http://localhost

# Test API response
curl http://localhost/api/stats | jq .

# Load test (install apache2-utils)
sudo apt install -y apache2-utils
ab -n 100 -c 10 http://localhost/api/projects
```

---

## 🚨 Troubleshooting

### Application not starting

```bash
# Check if port 3000 is in use
sudo lsof -i :3000

# Kill existing process
kill -9 <PID>

# Restart PM2
pm2 restart xyz-corp-api

# Check PM2 logs
pm2 logs xyz-corp-api
```

### Nginx not working

```bash
# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx

# View error log
sudo tail -f /var/log/nginx/xyz-corp-api-error.log
```

### Can't connect to API

```bash
# Check if application is running
pm2 list

# Check if Nginx is running
sudo systemctl status nginx

# Check firewall
sudo ufw status

# Test locally
curl http://localhost/

# Test from external machine
curl http://<server-ip>/
```

### High memory/CPU usage

```bash
# Monitor resources
pm2 monit

# Check top processes
top -b -n 1 | head -20

# Restart with memory limit
pm2 restart xyz-corp-api --max-memory-restart 512M
```

---

## 🔐 Security Hardening

### Additional Security Steps

```bash
# Setup fail2ban (prevent brute force)
sudo apt install -y fail2ban
sudo systemctl enable fail2ban

# Configure SSH key-only authentication
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes
sudo systemctl restart sshd

# Setup UFW logging
sudo ufw logging on

# Enable auto updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### SSL/HTTPS Setup (Let's Encrypt)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot certonly --nginx -d your-domain.com

# Verify certificate
sudo certbot certificates

# Auto renewal should be setup automatically
sudo systemctl status certbot.timer
```

---

## 📊 Monitoring & Maintenance

### Regular Checks

```bash
# Check disk space
df -h

# Check memory
free -h

# Check CPU
top -bn1 | head -n 3

# Check application uptime
pm2 status

# Check Nginx uptime
sudo systemctl status nginx
```

### Backup Application

```bash
# Backup application
cd ~
tar -czf xyz-corp-api-backup-$(date +%Y%m%d).tar.gz xyz-corp-api/

# List backups
ls -lh xyz-corp-api-backup-*.tar.gz

# Restore from backup
tar -xzf xyz-corp-api-backup-20260507.tar.gz
```

### Update Dependencies

```bash
# Check for outdated packages
npm outdated

# Update packages
npm update

# Security audit
npm audit

# Fix vulnerabilities
npm audit fix
```

---

## 📝 Useful Commands Summary

```bash
# View all commands
man pm2
man nginx
man ufw

# Quick status check
pm2 status && sudo systemctl status nginx && sudo ufw status

# Restart all services
pm2 restart xyz-corp-api && sudo systemctl restart nginx

# View system info
hostnamectl
uname -a
lsb_release -a
```

---

**Last Updated:** 2026-05-07  
**Maintained By:** XYZ Corp DevOps Team
