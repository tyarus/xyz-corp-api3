# Troubleshooting & Best Practices - GCE Deployment

## TROUBLESHOOTING GUIDE

### 1. SSH Connection Issues

#### Problem: "Permission denied (publickey)"

**Causes:**
- SSH key not properly configured
- Firewall blocking SSH (port 22)
- User permissions issue

**Solutions:**
```bash
# Verify SSH key permissions
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa

# Test SSH verbosely
ssh -vvv [external-ip]

# Reset SSH key in GCP
gcloud compute instances os-login ssh-keys add \
  --key-file=~/.ssh/id_rsa.pub

# Or allow SSH through GCP console SSH button
# This doesn't require local SSH setup
```

#### Problem: "Connection timeout"

**Solutions:**
```bash
# Check if firewall rule exists
gcloud compute firewall-rules list | grep ssh

# Create SSH firewall rule if needed
gcloud compute firewall-rules create allow-ssh \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0

# Check if VM is running
gcloud compute instances list --filter="name:xyz-corp-api-server"

# Verify external IP assigned
gcloud compute instances describe xyz-corp-api-server \
  --zone=asia-southeast1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

---

### 2. Application Not Running

#### Problem: PM2 shows "stopped" status

```bash
# Check PM2 status
pm2 list

# View logs
pm2 logs xyz-corp-api
pm2 logs xyz-corp-api --err

# Try restarting
pm2 restart xyz-corp-api

# Or start if not running
cd /var/www/xyz-corp-api
pm2 start src/app.js --name xyz-corp-api

# Save PM2 state
pm2 save
pm2 startup
```

#### Problem: "npm ERR! code EACCES"

**Solutions:**
```bash
# Fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH

# Or use sudo (not recommended)
sudo npm install -g pm2

# Clear npm cache
npm cache clean --force
npm install
```

#### Problem: "Cannot find module" errors

```bash
# Verify in correct directory
cd /var/www/xyz-corp-api

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check if dependencies exist
npm list

# Install missing specific package
npm install [package-name]
```

#### Problem: Port 3000 already in use

```bash
# Find process using port 3000
sudo lsof -i :3000
netstat -tlnp | grep 3000

# Kill the process
sudo kill -9 [PID]

# Or change port in .env
PORT=3001

# Restart PM2
pm2 restart xyz-corp-api
```

---

### 3. Nginx Issues

#### Problem: "502 Bad Gateway"

**Causes:**
- Node.js application not running
- Port 3000 not listening
- Timeout configuration

**Solutions:**
```bash
# Check if Node.js listening on 3000
sudo netstat -tlnp | grep 3000
sudo ss -tlnp | grep 3000

# Check PM2 status
pm2 status

# View PM2 logs
pm2 logs xyz-corp-api --err

# Check Nginx error log
sudo tail -f /var/log/nginx/error.log

# Verify PM2 process
ps aux | grep node

# Try restarting application
pm2 restart xyz-corp-api

# Wait a few seconds and test
sleep 5
curl http://localhost:3000/
```

#### Problem: "Connection refused"

```bash
# Check Nginx status
sudo systemctl status nginx

# Check if Nginx listening on 80
sudo netstat -tlnp | grep :80
sudo ss -tlnp | grep :80

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check firewall rules
sudo ufw status
sudo iptables -L
```

#### Problem: "413 Request Entity Too Large"

```bash
# Edit Nginx config
sudo nano /etc/nginx/sites-available/xyz-corp-api

# Add or modify in server block:
client_max_body_size 10m;

# Test and restart
sudo nginx -t
sudo systemctl restart nginx
```

#### Problem: SSL Certificate issues (HTTPS)

```bash
# Check certificate validity
sudo certbot certificates

# Test certificate
openssl s_client -connect yourdomain.com:443

# Renew certificate manually
sudo certbot renew --force-renewal

# Check auto-renewal
sudo systemctl status certbot.timer

# View Nginx SSL config
sudo nginx -T | grep -i ssl
```

---

### 4. Performance Issues

#### Problem: High CPU Usage

```bash
# Real-time monitoring
htop

# Check which process using CPU
top -o %CPU

# Check PM2
pm2 monit

# If Node process using high CPU:
# 1. Check for infinite loops in code
# 2. Check database queries
# 3. Try increasing memory
pm2 restart xyz-corp-api --update-env

# Set memory limit
pm2 start src/app.js --name xyz-corp-api --max-memory-restart 512M
```

#### Problem: High Memory Usage

```bash
# Check memory details
free -h
vmstat 1 5

# Monitor PM2 memory
pm2 monit

# Check which process
ps aux --sort=-%mem | head

# If memory constantly increasing (leak):
# 1. Review code for memory leaks
# 2. Check if logs rotating properly
# 3. Restart PM2 periodically

# Setup periodic restart
pm2 start src/app.js --cron-restart="0 3 * * *"  # Daily at 3 AM

# Or monitor and restart if exceeds limit
pm2 start src/app.js --max-memory-restart 512M
```

#### Problem: Slow Response Times

```bash
# Check network latency
ping 8.8.8.8

# Monitor Nginx access time
sudo tail -f /var/log/nginx/access.log | grep "response_time"

# Test application response
time curl http://localhost:3000/api/projects

# Check database (if applicable)
# Review query performance

# Enable compression in .env and restart
GZIP_LEVEL=6
```

#### Problem: High Disk Usage

```bash
# Check disk space
df -h

# Find large files
du -sh /*
du -sh /var/www/xyz-corp-api/*

# Check log files
ls -lh /var/log/nginx/
ls -lh /var/log/xyz-corp-api/

# Rotate logs if needed
sudo logrotate -f /etc/logrotate.conf

# Clean old logs
sudo find /var/log -type f -name "*.log" -mtime +30 -delete

# Clean npm cache
npm cache clean --force

# Check disk usage by directory
ncdu /var/www/xyz-corp-api
```

---

### 5. Monitoring & Logging Issues

#### Problem: No monitoring data in GCP

```bash
# Check if ops-agent running
sudo service google-cloud-ops-agent status

# View logs
sudo google-cloud-ops-agent diag

# Restart ops-agent
sudo service google-cloud-ops-agent restart

# Check if metrics flowing
gcloud monitoring metrics-descriptors list | grep compute
```

#### Problem: Logs not appearing

```bash
# Check PM2 logs path
pm2 logs

# Verify log file exists
ls -la ~/.pm2/logs/

# Check log rotation
logrotate -d /etc/logrotate.conf

# Check permissions
sudo tail -f /var/log/nginx/error.log
```

---

### 6. Networking Issues

#### Problem: External IP not accessible

```bash
# Verify external IP assigned
gcloud compute instances describe xyz-corp-api-server --zone=asia-southeast1-a

# Check firewall rules
gcloud compute firewall-rules list

# Verify HTTP/HTTPS rules exist
gcloud compute firewall-rules describe allow-http
gcloud compute firewall-rules describe allow-https

# Test from VM
curl http://localhost/

# Test external access
curl http://[external-ip]/
```

#### Problem: DNS not resolving

```bash
# Check DNS
nslookup yourdomain.com
dig yourdomain.com

# Verify A record points to external IP
nslookup -type=A yourdomain.com

# If using CloudFlare, verify:
cloudflare.com → DNS settings
```

---

### 7. Security Issues

#### Problem: "Blocked by CORS"

```bash
# Check CORS setting in app.js
nano /var/www/xyz-corp-api/src/app.js

# Update .env
CORS_ORIGIN=http://yourdomain.com

# Or allow all (not recommended for production)
CORS_ORIGIN=*

# Restart application
pm2 restart xyz-corp-api
```

#### Problem: Headers not being set

```bash
# Check if headers in Nginx config
sudo grep -n "add_header" /etc/nginx/sites-available/xyz-corp-api

# Verify headers with curl
curl -I http://localhost/

# If headers missing, add to Nginx config
sudo nano /etc/nginx/sites-available/xyz-corp-api

# Restart Nginx
sudo systemctl restart nginx

# Verify with curl
curl -I http://[external-ip]/
```

---

### 8. SSL/TLS Issues

#### Problem: "SSL_ERROR_RX_RECORD_TOO_LONG"

```bash
# Usually means HTTP being served as HTTPS
# Verify Nginx HTTP/HTTPS config

sudo nano /etc/nginx/sites-available/xyz-corp-api

# Ensure:
# - listen 80 for HTTP
# - listen 443 ssl for HTTPS
# - Proper redirect from HTTP to HTTPS

sudo nginx -t
sudo systemctl restart nginx
```

#### Problem: Certificate renewal failed

```bash
# Check renewal log
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Verify domain accessibility
curl -I http://yourdomain.com/.well-known/acme-challenge/test

# Manual renewal
sudo certbot renew --force-renewal

# Check if timer active
sudo systemctl status certbot.timer
```

---

## BEST PRACTICES

### 1. Code & Deployment

```javascript
// Always use .env for configuration
require('dotenv').config();

// Log application startup
console.log(`Server running on port ${process.env.PORT}`);

// Implement health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

// Implement graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
```

### 2. PM2 Configuration

```bash
# Create ecosystem.config.js for complex apps
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'xyz-corp-api',
    script: './src/app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
EOF

# Start with ecosystem config
pm2 start ecosystem.config.js
pm2 save
```

### 3. Nginx Optimization

```nginx
# In /etc/nginx/nginx.conf
http {
    # Increase worker processes
    worker_processes auto;
    
    # Connection limits
    worker_connections 2048;
    
    # Buffer optimization
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    
    # Caching
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
    
    # Timeout
    keepalive_timeout 65;
    send_timeout 60;
    client_body_timeout 60;
    client_header_timeout 60;
}
```

### 4. Monitoring & Alerting

```bash
# Setup multiple alert levels
# - Warning: CPU > 70%, Memory > 75%
# - Critical: CPU > 85%, Memory > 90%

# Implement custom metrics
curl -X POST https://monitoring.googleapis.com/v3/projects/xyz-corp-deployment/timeSeries \
  --data-binary @metrics.json

# Regular health checks
0 */6 * * * /usr/local/bin/health-check.sh

# Log rotation
/var/log/xyz-corp-api/*.log {
  daily
  rotate 30
  compress
  delaycompress
  notifempty
  create 0640 nobody nobody
}
```

### 5. Security Best Practices

```bash
# Firewall - restrict SSH to known IPs
gcloud compute firewall-rules create allow-ssh-restricted \
  --allow=tcp:22 \
  --source-ranges=YOUR_IP/32

# Update regularly
sudo apt update && sudo apt upgrade -y

# Install fail2ban for brute-force protection
sudo apt install -y fail2ban

# Monitor failed login attempts
sudo tail -f /var/log/auth.log | grep "Failed password"

# Keep Node.js and npm updated
npm update -g
node --version  # should be LTS
```

### 6. Backup & Recovery

```bash
# Daily backup to Cloud Storage
0 2 * * * /usr/local/bin/backup.sh

# Create VM snapshots
gcloud compute disks snapshot xyz-corp-api-disk \
  --snapshot-names=backup-$(date +%Y%m%d)

# Keep minimum 7-day backup history
gcloud compute snapshots list --sort-by=~creationTimestamp --limit=7
```

### 7. Documentation

- [ ] Keep deployment guide updated
- [ ] Document any custom configurations
- [ ] Log all changes in change log
- [ ] Maintain runbook for common issues
- [ ] Record escalation procedures

### 8. Testing Before Production

```bash
# Load testing
ab -n 1000 -c 10 http://localhost/

# Benchmark tools
apache-bench
wrk
hey

# Staging environment should mirror production
# Test all deployment steps in staging first
```

---

## QUICK FIXES

```bash
# Application won't start
pm2 restart xyz-corp-api
pm2 logs xyz-corp-api --err

# Can't access externally
gcloud compute firewall-rules list
curl http://localhost/  # Test internally first

# Memory/CPU high
pm2 monit
sudo systemctl restart google-cloud-ops-agent

# SSH not working
gcloud compute ssh xyz-corp-api-server --zone=asia-southeast1-a

# Reboot entire VM
gcloud compute instances stop xyz-corp-api-server --zone=asia-southeast1-a
gcloud compute instances start xyz-corp-api-server --zone=asia-southeast1-a

# Clear everything and start fresh
# ⚠️ ONLY IF NOTHING WORKS
pm2 kill
sudo systemctl restart nginx
ps aux | grep node  # check for orphaned processes
```

---

## SUPPORT CONTACTS & RESOURCES

- **GCP Support**: https://cloud.google.com/support
- **GCP Docs**: https://cloud.google.com/docs
- **Node.js Docs**: https://nodejs.org/docs
- **Nginx Docs**: https://nginx.org/en/docs
- **PM2 Docs**: https://pm2.keymetrics.io
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/google-cloud-platform

---

## Emergency Contacts

**OPS Team**: ___________________  
**Database Admin**: ___________________  
**Security Team**: ___________________  
**Cloud Provider Support**: https://cloud.google.com/support

---

**Last Updated**: May 8, 2026  
**Next Review**: May 8, 2027
