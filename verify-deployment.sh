#!/bin/bash

# XYZ Corp API - Quick Deployment Verification Script
# Run this to verify all components are correctly installed

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║    XYZ CORP API - DEPLOYMENT VERIFICATION              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0

# Check Node.js
echo "[CHECK] Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "  ✅ Node.js $NODE_VERSION installed"
else
    echo "  ❌ Node.js not found"
    ((ERRORS++))
fi

# Check npm
echo "[CHECK] npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "  ✅ npm $NPM_VERSION installed"
else
    echo "  ❌ npm not found"
    ((ERRORS++))
fi

# Check Nginx
echo "[CHECK] Nginx..."
if sudo systemctl is-active nginx &> /dev/null; then
    echo "  ✅ Nginx is running"
else
    echo "  ⚠️  Nginx is not running (may not be deployed to Ubuntu yet)"
    ((WARNINGS++))
fi

# Check PM2
echo "[CHECK] PM2..."
if command -v pm2 &> /dev/null; then
    PM2_VERSION=$(pm2 --version)
    echo "  ✅ PM2 $PM2_VERSION installed"
    
    if pm2 list &> /dev/null | grep -q "xyz-corp-api"; then
        echo "  ✅ xyz-corp-api process found"
    else
        echo "  ⚠️  xyz-corp-api process not running"
        ((WARNINGS++))
    fi
else
    echo "  ⚠️  PM2 not installed globally (may not be deployed to Ubuntu yet)"
    ((WARNINGS++))
fi

# Check Application Files
echo "[CHECK] Application Files..."
FILES=("src/app.js" "src/routes/projects.js" "src/routes/employees.js" "src/middleware/logger.js" "package.json")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file missing"
        ((ERRORS++))
    fi
done

# Check node_modules
echo "[CHECK] Dependencies..."
if [ -d "node_modules" ]; then
    echo "  ✅ Dependencies installed"
else
    echo "  ❌ Dependencies not installed - run: npm install"
    ((ERRORS++))
fi

# Check Configuration Files
echo "[CHECK] Configuration Files..."
CONFIG_FILES=(".env" "SECURITY.md" "DEPLOYMENT_GUIDE.md" "COMMANDS_REFERENCE.md" "TEST_REPORT.md")
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ⚠️  $file missing"
        ((WARNINGS++))
    fi
done

# Try to connect to API
echo "[CHECK] API Connectivity..."
if curl -s http://localhost:3000/ &> /dev/null; then
    echo "  ✅ API is responding on http://localhost:3000"
else
    echo "  ⚠️  Cannot reach API on http://localhost:3000"
    echo "     Start the API with: npm start"
    ((WARNINGS++))
fi

# Port checks
echo "[CHECK] Port Status..."
if lsof -i :3000 &> /dev/null; then
    echo "  ✅ Port 3000 is in use (application running)"
else
    echo "  ⚠️  Port 3000 is not in use"
    ((WARNINGS++))
fi

if sudo lsof -i :80 &> /dev/null 2>&1; then
    echo "  ✅ Port 80 is in use (Nginx running)"
elif [ "$(uname)" = "Linux" ]; then
    echo "  ⚠️  Port 80 is not in use"
    ((WARNINGS++))
fi

echo ""
echo "╠════════════════════════════════════════════════════════╣"
echo "║ VERIFICATION SUMMARY                                   ║"
echo "╠════════════════════════════════════════════════════════╣"
echo "║ Errors    : $ERRORS"
echo "║ Warnings  : $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "║ ✅ All checks passed - System ready!"
    echo "╚════════════════════════════════════════════════════════╝"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "║ ⚠️  Some warnings detected - Review above"
    echo "╚════════════════════════════════════════════════════════╝"
    exit 0
else
    echo "║ ❌ Errors detected - Cannot proceed"
    echo "╚════════════════════════════════════════════════════════╝"
    exit 1
fi
