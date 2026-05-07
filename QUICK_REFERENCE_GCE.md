# Quick Reference - GCE Deployment Commands

## 1. SETUP AWAL DI LOKAL

```powershell
# Windows PowerShell - Install GCloud SDK
# Download: https://cloud.google.com/sdk/docs/install

# Setelah install, initialize gcloud
gcloud init
gcloud auth login

# Set project
gcloud config set project xyz-corp-deployment
```

## 2. MEMBUAT VM

```bash
# Create VM dengan gcloud CLI
gcloud compute instances create xyz-corp-api-server \
  --zone=asia-southeast1-a \
  --machine-type=e2-small \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB

# List VM instances
gcloud compute instances list

# Get VM details
gcloud compute instances describe xyz-corp-api-server --zone=asia-southeast1-a
```

## 3. KONEKSI SSH

```bash
# SSH ke VM
gcloud compute ssh xyz-corp-api-server --zone=asia-southeast1-a

# Copy file dari lokal ke VM
gcloud compute scp [LOCAL_FILE] [INSTANCE_NAME]:~/[REMOTE_PATH] \
  --zone=asia-southeast1-a --recurse

# Copy file dari VM ke lokal
gcloud compute scp [INSTANCE_NAME]:~/[REMOTE_FILE] [LOCAL_PATH] \
  --zone=asia-southeast1-a --recurse
```

## 4. SETUP OTOMATIS DI VM (Jalankan ini setelah SSH)

```bash
# Download dan run setup script
curl -O https://[your-repo-url]/setup-gce.sh
chmod +x setup-gce.sh
./setup-gce.sh

# ATAU install manual:
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git nginx htop
sudo npm install -g pm2
```

## 5. DEPLOY APLIKASI

```bash
# Di VM, setelah SSH
cd /var/www/xyz-corp-api

# Clone dari Git (jika ada)
# git clone https://github.com/username/repo.git .

# ATAU copy file manually dari lokal:
# gcloud compute scp -r "D:\path\to\project\*" xyz-corp-api-server:~/app --zone=asia-southeast1-a

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
PORT=3000
NODE_ENV=production
API_VERSION=1.0.0
API_NAME=XYZ Corp REST API
CORS_ORIGIN=*
EOF

# Start dengan PM2
pm2 start src/app.js --name xyz-corp-api
pm2 startup
pm2 save

# Verify aplikasi
curl http://localhost:3000/
```

## 6. KONFIGURASI NGINX

```bash
# Nginx config sudah di /etc/nginx/sites-available/xyz-corp-api
# Jika perlu edit:
sudo nano /etc/nginx/sites-available/xyz-corp-api

# Test config
sudo nginx -t

# Restart
sudo systemctl restart nginx
```

## 7. FIREWALL RULES (Dari lokal)

```bash
# Allow HTTP
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0

# Allow HTTPS
gcloud compute firewall-rules create allow-https \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0

# List rules
gcloud compute firewall-rules list
```

## 8. AKSES APLIKASI

```
Buka di browser: http://[EXTERNAL_IP]/
Contoh: http://34.101.xx.xx/
```

## 9. MONITORING

```bash
# Real-time CPU & Memory (di VM)
htop

# Monitor PM2
pm2 monit

# Check logs
pm2 logs xyz-corp-api
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Check memory
free -h

# Check disk
df -h

# Check running processes
ps aux | grep node
```

## 10. RESTART & MAINTENANCE

```bash
# Restart aplikasi
pm2 restart xyz-corp-api

# Restart Nginx
sudo systemctl restart nginx

# Reboot VM
sudo reboot

# Stop VM (dari lokal)
gcloud compute instances stop xyz-corp-api-server --zone=asia-southeast1-a

# Start VM (dari lokal)
gcloud compute instances start xyz-corp-api-server --zone=asia-southeast1-a

# Delete VM (HATI-HATI!)
gcloud compute instances delete xyz-corp-api-server --zone=asia-southeast1-a
```

## 11. TROUBLESHOOTING

```bash
# Check PM2 status
pm2 status

# Tail PM2 logs
pm2 logs

# Check if port 3000 is listening
netstat -tlnp | grep 3000
sudo ss -tlnp | grep 3000

# Check Nginx status
sudo systemctl status nginx

# Test Nginx config
sudo nginx -t

# Check system resources
top
vmstat 1 5

# Check network connectivity
curl http://localhost:3000/
curl http://localhost:3000/api/projects
```

## 12. SSL/TLS (HTTPS)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate (ganti yourdomain.com)
sudo certbot certonly --nginx -d yourdomain.com

# Or standalone
sudo certbot certonly --standalone -d yourdomain.com

# Auto-renew
sudo systemctl enable certbot.timer

# Manual renewal
sudo certbot renew --dry-run
```

## 13. TIPS & BEST PRACTICES

```bash
# Backup database atau files
tar -czf backup_$(date +%Y%m%d).tar.gz /var/www/xyz-corp-api

# Monitor disk usage
du -sh /var/www/xyz-corp-api

# Clear npm cache
npm cache clean --force

# Update packages
npm update

# Check outdated packages
npm outdated

# View PM2 info
pm2 info xyz-corp-api
```

## Variables

Ganti nilai-nilai ini:
- `asia-southeast1-a` → Zone pilihan Anda
- `e2-small` → Tipe mesin (e2-micro untuk free tier)
- `xyz-corp-api-server` → Nama VM Anda
- `[EXTERNAL_IP]` → IP dari `gcloud compute instances list`
- `yourdomain.com` → Domain Anda (jika ada)
- `D:\path\to\project` → Path lokal ke project

## Useful Links

- GCP Console: https://console.cloud.google.com
- GCloud CLI: https://cloud.google.com/cli
- VM Instances: https://console.cloud.google.com/compute/instances
- Monitoring: https://console.cloud.google.com/monitoring
