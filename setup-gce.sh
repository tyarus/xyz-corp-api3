#!/bin/bash
# ============================================
# GCE Ubuntu Server Setup Script
# Automated setup untuk xyz-corp-api
# ============================================

set -e  # Exit on error

echo "========================================="
echo "XYZ Corp API - GCE Setup Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_header() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# ============================================
# 1. System Update
# ============================================
print_header "Step 1: Updating System Packages"
sudo apt update
sudo apt upgrade -y
print_status "System updated"

# ============================================
# 2. Install Node.js
# ============================================
print_header "Step 2: Installing Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
print_status "Node.js installed: $(node --version)"
print_status "NPM installed: $(npm --version)"

# ============================================
# 3. Install Git
# ============================================
print_header "Step 3: Installing Git"
sudo apt install -y git
print_status "Git installed: $(git --version)"

# ============================================
# 4. Install Nginx
# ============================================
print_header "Step 4: Installing Nginx"
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
print_status "Nginx installed and started"

# ============================================
# 5. Install PM2
# ============================================
print_header "Step 5: Installing PM2"
sudo npm install -g pm2
pm2 completion install 2>/dev/null || true
print_status "PM2 installed: $(pm2 --version)"

# ============================================
# 6. Install Monitoring Tools
# ============================================
print_header "Step 6: Installing Monitoring Tools"
sudo apt install -y htop sysstat curl wget
print_status "Monitoring tools installed"

# ============================================
# 7. Setup Application Directory
# ============================================
print_header "Step 7: Setting Up Application Directory"
APP_DIR="/var/www/xyz-corp-api"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR
print_status "Application directory created: $APP_DIR"

# ============================================
# 8. Create Nginx Configuration
# ============================================
print_header "Step 8: Configuring Nginx Reverse Proxy"
cat | sudo tee /etc/nginx/sites-available/xyz-corp-api > /dev/null << 'EOF'
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
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/xyz-corp-api /etc/nginx/sites-enabled/

# Test configuration
if sudo nginx -t 2>&1 | grep -q "successful"; then
    print_status "Nginx configuration valid"
else
    print_error "Nginx configuration invalid"
    exit 1
fi

sudo systemctl restart nginx
print_status "Nginx configured and restarted"

# ============================================
# 9. Install Google Cloud Ops Agent
# ============================================
print_header "Step 9: Installing Google Cloud Ops Agent (Optional)"
read -p "Install Google Cloud Monitoring Agent? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
    sudo service google-cloud-ops-agent start
    print_status "Google Cloud Ops Agent installed"
else
    print_warning "Skipped Google Cloud Ops Agent installation"
fi

# ============================================
# 10. Setup Firewall Rules
# ============================================
print_header "Step 10: Firewall Configuration"
print_warning "Firewall rules should be configured in GCP Console"
echo "Run these commands from your local machine:"
echo ""
echo "gcloud compute firewall-rules create allow-http \\"
echo "  --allow=tcp:80 \\"
echo "  --source-ranges=0.0.0.0/0 \\"
echo "  --target-tags=http-server"
echo ""
echo "gcloud compute firewall-rules create allow-https \\"
echo "  --allow=tcp:443 \\"
echo "  --source-ranges=0.0.0.0/0 \\"
echo "  --target-tags=https-server"
echo ""

# ============================================
# Summary
# ============================================
print_header "Setup Complete!"
echo -e "${GREEN}All dependencies installed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Upload your application to: $APP_DIR"
echo "2. Run: cd $APP_DIR && npm install"
echo "3. Create .env file with configuration"
echo "4. Run: pm2 start src/app.js --name xyz-corp-api"
echo "5. Access your application at: http://[external-ip]"
echo ""
echo "Useful commands:"
echo "  pm2 list              - Show running processes"
echo "  pm2 logs              - Show PM2 logs"
echo "  sudo systemctl status nginx  - Check Nginx status"
echo "  pm2 start src/app.js --name xyz-corp-api"
echo "  pm2 save"
echo "  pm2 startup"
echo ""
