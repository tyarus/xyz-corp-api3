#!/bin/bash

# XYZ Corp API - System Monitoring Script
# Shows CPU, Memory, Disk usage and application status
# Usage: ./monitor.sh or set in cron for automated monitoring

set -e

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Get CPU usage
read cpu user system idle other < <(awk '/cpu / {printf "%d %d %d %d %d\n", ($2+$3+$4+$5+$6)/100, $2/100, $4/100, $5/100, ($6+$7+$8+$9+$10)/100}' /proc/stat)
CPU_USAGE=$((100 - idle))

# Get Memory usage
MEM_INFO=$(free -h | grep Mem)
MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
MEM_PERCENT=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100)}')

# Get Disk usage for root partition
DISK_INFO=$(df -h / | tail -1)
DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
DISK_PERCENT=$(echo $DISK_INFO | awk '{print $5}')

# Check Nginx status
NGINX_STATUS=$(sudo systemctl is-active nginx 2>/dev/null || echo "unknown")
if [ "$NGINX_STATUS" = "active" ]; then
    NGINX_ICON="✅"
else
    NGINX_ICON="❌"
fi

# Get PM2 processes info
PM2_PROCESSES=$(pm2 list --no-header 2>/dev/null | grep -v "empty list" || echo "")

# Create monitoring report
{
echo "╔════════════════════════════════════════════════════════╗"
echo "║    XYZ CORP API - MONITORING REPORT                    ║"
echo "╠════════════════════════════════════════════════════════╣"
echo "║ Timestamp         : $TIMESTAMP"
echo "║ CPU Usage         : ${CPU_USAGE}%"
echo "║ Memory            : ${MEM_USED} / ${MEM_TOTAL} (${MEM_PERCENT}%)"
echo "║ Disk Usage (/)    : ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT})"
echo "╠════════════════════════════════════════════════════════╣"
echo "║ PROCESS STATUS:                                        ║"

if [ -z "$PM2_PROCESSES" ]; then
    echo "║ No PM2 processes running"
else
    pm2 list --no-header 2>/dev/null | grep -v "empty list" | head -5 | while IFS= read -r line; do
        # Format: name │ namespace │ version │ mode │ pid │ uptime │ ↺ │ status │ cpu │ mem
        NAME=$(echo "$line" | awk -F'│' '{print $1}' | xargs)
        STATUS=$(echo "$line" | awk -F'│' '{print $8}' | xargs)
        CPU=$(echo "$line" | awk -F'│' '{print $9}' | xargs)
        MEM=$(echo "$line" | awk -F'│' '{print $10}' | xargs)
        
        if [ "$STATUS" = "online" ]; then
            STATUS_ICON="✅"
        else
            STATUS_ICON="❌"
        fi
        
        printf "║ %-10s %s CPU: %-5s MEM: %-10s  ║\n" "${NAME:0:10}" "$STATUS_ICON" "$CPU" "$MEM"
    done
fi

echo "║                                                        ║"
echo "║ NGINX STATUS      : $NGINX_ICON Nginx"
echo "╠════════════════════════════════════════════════════════╣"
echo "║ TOP 5 PROCESSES BY CPU:                                ║"

ps aux --sort=-%cpu | head -6 | tail -5 | while IFS= read -r line; do
    USER=$(echo "$line" | awk '{print $1}')
    PID=$(echo "$line" | awk '{print $2}')
    CPU_P=$(echo "$line" | awk '{print $3}')
    MEM_P=$(echo "$line" | awk '{print $4}')
    CMD=$(echo "$line" | awk '{print $11}' | xargs)
    
    printf "║ %-8s %-6s CPU:%-5s MEM:%-5s %-13s ║\n" "${USER:0:8}" "$PID" "$CPU_P" "$MEM_P" "${CMD:0:13}"
done

echo "╚════════════════════════════════════════════════════════╝"

} | tee -a ~/xyz-corp-monitoring.log

# Keep only last 1000 lines of log
tail -1000 ~/xyz-corp-monitoring.log > ~/xyz-corp-monitoring.log.tmp
mv ~/xyz-corp-monitoring.log.tmp ~/xyz-corp-monitoring.log
