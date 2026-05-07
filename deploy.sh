#!/bin/bash

# XYZ Corp API - Complete Deployment Automation Script
# Run this script on Ubuntu Server to automate the entire deployment process
# Usage: bash deploy.sh

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║    XYZ CORP API - AUTOMATED DEPLOYMENT SCRIPT          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# PHASE 1: SYSTEM UPDATE
# ============================================
echo "[PHASE 1] Updating system..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget git ufw htop build-essential

# ============================================
# PHASE 2: INSTALL NODE.JS
# ============================================
echo "[PHASE 2] Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "Node.js version:"
node --version
echo "npm version:"
npm --version

# ============================================
# PHASE 3: INSTALL NGINX
# ============================================
echo "[PHASE 3] Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx

# ============================================
# PHASE 4: CREATE APPLICATION USER
# ============================================
echo "[PHASE 4] Creating application user..."
if id -u xyz-corp-user >/dev/null 2>&1; then
    echo "User xyz-corp-user already exists"
else
    sudo useradd -m -s /bin/bash xyz-corp-user
    echo "User xyz-corp-user created"
fi

# ============================================
# PHASE 5: CLONE AND SETUP APPLICATION
# ============================================
echo "[PHASE 5] Cloning and setting up application..."
cd $HOME

if [ -d "xyz-corp-api" ]; then
    cd xyz-corp-api
    git pull
else
    # IMPORTANT: User must replace USERNAME with their actual GitHub username
    git clone https://github.com/USERNAME/xyz-corp-api.git
    cd xyz-corp-api
fi

npm install --production
cp .env.example .env

echo "Application setup complete at: $HOME/xyz-corp-api"

# ============================================
# PHASE 6: SETUP NGINX CONFIGURATION
# ============================================
echo "[PHASE 6] Configuring Nginx..."
sudo tee /etc/nginx/sites-available/xyz-corp-api > /dev/null <<EOF
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
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location ~ /\. {
        deny all;
    }
    
    location ~ ~$ {
        deny all;
    }
}
EOF

# Enable configuration
sudo ln -sf /etc/nginx/sites-available/xyz-corp-api /etc/nginx/sites-enabled/xyz-corp-api

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# ============================================
# PHASE 7: INSTALL PM2
# ============================================
echo "[PHASE 7] Installing PM2..."
sudo npm install -g pm2

# ============================================
# PHASE 8: START APPLICATION
# ============================================
echo "[PHASE 8] Starting application with PM2..."
cd ~/xyz-corp-api
pm2 start src/app.js --name "xyz-corp-api"
pm2 startup
pm2 save

echo "PM2 Status:"
pm2 status

# ============================================
# PHASE 9: SETUP FIREWALL
# ============================================
echo "[PHASE 9] Configuring UFW Firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall (will prompt for confirmation)
sudo ufw enable

echo "Firewall Status:"
sudo ufw status verbose

# ============================================
# PHASE 10: SETUP MONITORING
# ============================================
echo "[PHASE 10] Setting up monitoring..."
cp ~/xyz-corp-api/monitor.sh ~/monitor.sh
chmod +x ~/monitor.sh

# Add cron job for monitoring (every 5 minutes)
(crontab -l 2>/dev/null | grep -v "monitor.sh"; echo "*/5 * * * * $HOME/monitor.sh >> $HOME/xyz-corp-monitoring.log 2>&1") | crontab -

echo "Monitoring setup complete"

# ============================================
# VERIFICATION
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║         DEPLOYMENT VERIFICATION                        ║"
echo "╠════════════════════════════════════════════════════════╣"
echo ""

echo "Testing API endpoints..."
sleep 2

echo "1. Health Check:"
curl -s http://localhost/ | head -c 100
echo "..."
echo ""

echo "2. Projects List:"
curl -s http://localhost/api/projects | head -c 100
echo "..."
echo ""

echo "3. Employees List:"
curl -s http://localhost/api/employees | head -c 100
echo "..."
echo ""

echo "4. Statistics:"
curl -s http://localhost/api/stats | head -c 100
echo "..."
echo ""

echo "╠════════════════════════════════════════════════════════╣"
echo "║          DEPLOYMENT COMPLETED SUCCESSFULLY!            ║"
echo "╠════════════════════════════════════════════════════════╣"
echo "║ ✅ Node.js installed"
echo "║ ✅ Nginx configured"
echo "║ ✅ Application deployed"
echo "║ ✅ PM2 process manager active"
echo "║ ✅ Firewall configured"
echo "║ ✅ Monitoring setup"
echo "║"
echo "║ API URL: http://$(hostname -I | awk '{print $1}'):80"
echo "║ Health Check: http://$(hostname -I | awk '{print $1}')/health"
echo "║"
echo "║ Next Steps:"
echo "║ - Configure SSL/HTTPS with Let's Encrypt"
echo "║ - Setup database backup"
echo "║ - Configure domain name"
echo "║"
echo "╚════════════════════════════════════════════════════════╝"
