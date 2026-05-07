# Checklist Deployment GCE - XYZ Corp API

**Project**: xyz-corp-api  
**Deployment Target**: Google Compute Engine  
**Date Started**: _____________  
**Date Completed**: _____________

---

## FASE 1: PERSIAPAN DAN SETUP AWAL

### 1.1 Google Cloud Platform Setup
- [ ] Buat akun Google Cloud Platform (GCP)
- [ ] Akses https://console.cloud.google.com
- [ ] Buat project baru: `xyz-corp-deployment`
- [ ] Aktivkan billing untuk project
- [ ] Catat Project ID: ___________________

### 1.2 Local Environment Setup
- [ ] Install Google Cloud SDK
  - [ ] Windows: Download dari https://cloud.google.com/sdk/docs/install
  - [ ] Linux/Mac: `curl https://sdk.cloud.google.com | bash`
- [ ] Jalankan `gcloud init`
- [ ] Login dengan: `gcloud auth login`
- [ ] Verify login: `gcloud auth list`
- [ ] Set project: `gcloud config set project xyz-corp-deployment`

### 1.3 SSH Key Setup
- [ ] Generate SSH key (jika belum ada)
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/gce-key -C "gce@localhost"
  ```
- [ ] SSH key disimpan di: ___________________

---

## FASE 2: MEMBUAT VIRTUAL MACHINE

### 2.1 Pilih Region dan Zone
- [ ] Region dipilih: ___________________
  - Rekomendasi untuk Asia:
    - [ ] asia-southeast1 (Jakarta)
    - [ ] asia-southeast2 (Sydney)
    - [ ] asia-east1 (Taiwan)
- [ ] Zone dipilih: ___________________

### 2.2 VM Instance Creation
**Metode A: GCP Console**
- [ ] Buka Compute Engine → VM Instances
- [ ] Klik CREATE INSTANCE
- [ ] Konfigurasi:
  - Name: `xyz-corp-api-server`
  - Region: [pilihan Anda]
  - Zone: [pilihan Anda]
  - Machine Type: 
    - [ ] e2-micro (gratis tier)
    - [ ] e2-small (untuk production)
  - Boot Disk:
    - [ ] Ubuntu 20.04 LTS
    - [ ] Ubuntu 22.04 LTS (recommended)
    - [ ] Size: 20GB
  - Firewall:
    - [ ] Allow HTTP traffic
    - [ ] Allow HTTPS traffic
- [ ] Klik CREATE
- [ ] Tunggu 1-2 menit hingga selesai

**Metode B: gcloud CLI**
- [ ] Execute command dari Quick Reference
- [ ] Verifikasi: `gcloud compute instances list`

### 2.3 Dapatkan VM Details
- [ ] External IP Address: ___________________
- [ ] Internal IP Address: ___________________
- [ ] VM status: Running ✓
- [ ] SSH connection tested: ✓

---

## FASE 3: KONFIGURASI UBUNTU SERVER

### 3.1 SSH Koneksi
- [ ] Koneksi SSH berhasil
- [ ] Command untuk SSH:
  ```bash
  gcloud compute ssh xyz-corp-api-server --zone=[ZONE]
  ```
- [ ] SSH working directory verified

### 3.2 System Updates
- [ ] `sudo apt update` ✓
- [ ] `sudo apt upgrade -y` ✓
- [ ] System packages updated

### 3.3 Install Required Software
- [ ] Node.js LTS (v18.x) installed
  - [ ] Verify: `node --version` (v18.x.x)
  - [ ] npm installed: `npm --version` (9.x.x)
- [ ] Git installed
  - [ ] Verify: `git --version`
- [ ] Nginx installed
  - [ ] Verify: `nginx -v`
- [ ] PM2 installed globally
  - [ ] Verify: `pm2 --version`
- [ ] Monitoring tools installed (htop, curl, wget)

---

## FASE 4: DEPLOYMENT APLIKASI

### 4.1 Application Directory Setup
- [ ] Directory `/var/www/xyz-corp-api` dibuat
- [ ] Owner/permissions configured
- [ ] Verify: `ls -la /var/www/`

### 4.2 Upload Application Files
**Pilih metode:**

**A. Via Git Clone**
- [ ] Repository URL: ___________________
- [ ] `git clone [repo-url] /var/www/xyz-corp-api`
- [ ] Verify files exist

**B. Via SCP/Upload**
- [ ] Copy files dari lokal ke VM
- [ ] Command executed successfully
- [ ] Verify: `ls -la /var/www/xyz-corp-api/`

### 4.3 Install Dependencies
- [ ] `cd /var/www/xyz-corp-api`
- [ ] `npm install` executed
- [ ] `node_modules/` folder created
- [ ] No errors during installation

### 4.4 Environment Configuration
- [ ] `.env` file dibuat
  ```bash
  sudo nano /var/www/xyz-corp-api/.env
  ```
- [ ] .env content:
  ```
  PORT=3000
  NODE_ENV=production
  API_VERSION=1.0.0
  API_NAME=XYZ Corp REST API
  CORS_ORIGIN=*
  ```
- [ ] .env file saved

### 4.5 Application Testing
- [ ] Manual test: `node /var/www/xyz-corp-api/src/app.js`
- [ ] Test curl:
  - [ ] `curl http://localhost:3000/` ✓
  - [ ] `curl http://localhost:3000/api/projects` ✓
  - [ ] `curl http://localhost:3000/api/employees` ✓
- [ ] Stop dengan Ctrl+C
- [ ] Application working correctly ✓

---

## FASE 5: PM2 PROCESS MANAGER SETUP

### 5.1 Start Application dengan PM2
- [ ] `pm2 start /var/www/xyz-corp-api/src/app.js --name xyz-corp-api`
- [ ] `pm2 list` shows app running
- [ ] Status: online ✓

### 5.2 PM2 Startup Configuration
- [ ] `pm2 startup` executed
- [ ] Jalankan command yang diberikan oleh PM2
- [ ] `pm2 save` executed

### 5.3 PM2 Monitoring
- [ ] `pm2 logs xyz-corp-api` - logs visible
- [ ] `pm2 monit` - monitoring active
- [ ] CPU and Memory tracked

---

## FASE 6: NGINX REVERSE PROXY SETUP

### 6.1 Nginx Configuration
- [ ] Config file exist: `/etc/nginx/sites-available/xyz-corp-api`
- [ ] Content verified:
  - [ ] Upstream nodejs on port 3000
  - [ ] Security headers configured
  - [ ] Gzip compression enabled
  - [ ] Static files caching enabled

### 6.2 Enable Nginx Config
- [ ] Symlink created: `/etc/nginx/sites-enabled/xyz-corp-api`
- [ ] `sudo nginx -t` passes validation
- [ ] `sudo systemctl restart nginx` executed

### 6.3 Nginx Status
- [ ] Nginx service running: `sudo systemctl status nginx`
- [ ] Enable on startup: `sudo systemctl enable nginx`
- [ ] Test: `curl http://localhost/` works

---

## FASE 7: FIREWALL & SECURITY

### 7.1 GCP Firewall Rules (Execute dari lokal)
- [ ] Allow HTTP (port 80):
  ```bash
  gcloud compute firewall-rules create allow-http \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0
  ```

- [ ] Allow HTTPS (port 443):
  ```bash
  gcloud compute firewall-rules create allow-https \
    --allow=tcp:443 \
    --source-ranges=0.0.0.0/0
  ```

- [ ] Verify rules: `gcloud compute firewall-rules list`

### 7.2 Test External Access
- [ ] Get External IP: `gcloud compute instances list`
- [ ] External IP: ___________________
- [ ] Test dari browser: `http://[external-ip]/`
- [ ] Test API: `http://[external-ip]/api/projects`
- [ ] Access successful ✓

### 7.3 Security Configuration (Opsional)
- [ ] SSH key based authentication only
- [ ] Disable password authentication (if needed)
- [ ] UFW/iptables configured (if needed)

---

## FASE 8: SSL/TLS CERTIFICATE (OPTIONAL)

### 8.1 Domain Setup (jika ada domain)
- [ ] Domain purchased: ___________________
- [ ] Domain A record pointing to: [external-ip]
- [ ] DNS verified: `nslookup yourdomain.com`

### 8.2 Certbot Installation
- [ ] `sudo apt install -y certbot python3-certbot-nginx`
- [ ] Certbot installed ✓

### 8.3 Certificate Generation
- [ ] `sudo certbot certonly --nginx -d yourdomain.com`
- [ ] Certificate generated in: `/etc/letsencrypt/live/yourdomain.com/`
- [ ] Certificate expiry date: ___________________

### 8.4 Nginx HTTPS Configuration
- [ ] Nginx config updated with SSL paths
- [ ] `sudo nginx -t` passes
- [ ] `sudo systemctl restart nginx`
- [ ] HTTPS access working: `https://yourdomain.com`

### 8.5 Auto-renewal Setup
- [ ] `sudo systemctl enable certbot.timer`
- [ ] `sudo systemctl start certbot.timer`
- [ ] Test renewal: `sudo certbot renew --dry-run`

---

## FASE 9: MONITORING SETUP

### 9.1 Google Cloud Monitoring Agent (Recommended)
- [ ] `curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh`
- [ ] `sudo bash add-google-cloud-ops-agent-repo.sh --also-install`
- [ ] Agent service started: `sudo service google-cloud-ops-agent start`
- [ ] Verify: `sudo service google-cloud-ops-agent status`

### 9.2 GCP Monitoring Dashboard
- [ ] Akses: https://console.cloud.google.com/monitoring
- [ ] Create dashboard: `xyz-corp-api-dashboard`
- [ ] Widgets added:
  - [ ] CPU Utilization
  - [ ] Memory Usage
  - [ ] Network Traffic
  - [ ] Disk I/O

### 9.3 Alerts Configuration
- [ ] Create alert policy for high CPU (> 80%)
- [ ] Create alert policy for high memory (> 85%)
- [ ] Notification channel configured:
  - [ ] Email: ___________________
  - [ ] Atau Slack/PagerDuty (optional)

### 9.4 Local Monitoring
- [ ] Monitoring script uploaded: `gce-monitor.sh`
- [ ] Script permissions: `chmod +x gce-monitor.sh`
- [ ] Run manually: `./gce-monitor.sh` (test)
- [ ] PM2 monitoring: `pm2 start ./gce-monitor.sh --name monitor-app`

### 9.5 Monitoring Verification
- [ ] CPU usage tracked
- [ ] Memory usage tracked
- [ ] Disk usage tracked
- [ ] Log files created and updated

---

## FASE 10: TESTING & VALIDATION

### 10.1 Functionality Testing
- [ ] **Homepage**: `curl http://[external-ip]/` ✓
- [ ] **API Projects**: `curl http://[external-ip]/api/projects` ✓
- [ ] **API Employees**: `curl http://[external-ip]/api/employees` ✓
- [ ] **Static Files**: Assets loading (CSS, JS, images)
- [ ] **Error Handling**: Test with invalid routes

### 10.2 Performance Testing
- [ ] Load time acceptable (< 2 seconds)
- [ ] No memory leaks (monitor `pm2 monit`)
- [ ] CPU usage normal (< 50% idle)
- [ ] Database queries efficient (if applicable)

### 10.3 Security Testing
- [ ] HTTPS working (if domain setup)
- [ ] Security headers present (X-Frame-Options, etc.)
- [ ] CORS properly configured
- [ ] No sensitive data in logs

### 10.4 Availability Testing
- [ ] VM restart test: `sudo reboot`
- [ ] Application auto-starts with PM2 ✓
- [ ] Nginx auto-starts ✓
- [ ] Services running after reboot ✓

### 10.5 Monitoring Validation
- [ ] Alert emails received (test)
- [ ] Metrics visible in GCP dashboard
- [ ] Logs accessible: `pm2 logs`

---

## FASE 11: DOCUMENTATION & HANDOVER

### 11.1 Documentation Completed
- [ ] GCE_DEPLOYMENT_GUIDE.md reviewed
- [ ] QUICK_REFERENCE_GCE.md created
- [ ] Monitoring guide documented
- [ ] Troubleshooting steps documented

### 11.2 Credentials & Access
- [ ] GCP Project ID: ___________________
- [ ] SSH key location: ___________________
- [ ] VM External IP: ___________________
- [ ] Domain name (if any): ___________________
- [ ] Admin email: ___________________

### 11.3 Backup Strategy
- [ ] Application code backed up
- [ ] Database backup procedure documented (if applicable)
- [ ] VM snapshot created (GCP)
- [ ] Backup location: ___________________

### 11.4 Maintenance Plan
- [ ] Regular update schedule documented
- [ ] Monitoring schedule established
- [ ] Support contact: ___________________
- [ ] Escalation procedure: ___________________

---

## FASE 12: POST-DEPLOYMENT

### 12.1 Performance Baseline
- [ ] Baseline CPU usage: __________%
- [ ] Baseline Memory usage: __________%
- [ ] Baseline Response time: __________ms
- [ ] Baseline Disk usage: __________%

### 12.2 Ongoing Monitoring
- [ ] Daily checks scheduled
- [ ] Weekly performance reports generated
- [ ] Monthly updates planned
- [ ] Quarterly reviews scheduled

### 12.3 Troubleshooting Readiness
- [ ] Common issues documented
- [ ] Rollback procedures documented
- [ ] Support escalation process defined
- [ ] Team trained on procedures

---

## NOTES & ISSUES

### Issues Encountered:
```
1. ___________________________________________
   Resolution: ____________________________

2. ___________________________________________
   Resolution: ____________________________

3. ___________________________________________
   Resolution: ____________________________
```

### Lessons Learned:
```
- ___________________________________________
- ___________________________________________
- ___________________________________________
```

### Future Improvements:
```
- [ ] Implement CI/CD pipeline
- [ ] Setup load balancer
- [ ] Enable auto-scaling
- [ ] Implement CDN for static assets
- [ ] Setup database replication
- [ ] Implement backup automation
```

---

## SIGN-OFF

**Deployed by**: _______________________  
**Date**: _______________________  
**Reviewed by**: _______________________  
**Date**: _______________________  
**Approved for production**: ☐ Yes  ☐ No  

**Comments**:
```
____________________________________________________________
____________________________________________________________
____________________________________________________________
```

---

**Last Updated**: [Current Date]  
**Next Review Date**: [3 months from now]
