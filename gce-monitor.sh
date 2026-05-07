#!/bin/bash
# ============================================
# Monitoring Script untuk XYZ Corp API
# Mencatat CPU, Memory, dan Disk Usage
# ============================================

set -e

APP_NAME="xyz-corp-api"
LOG_DIR="/var/log/xyz-corp-api"
LOG_FILE="$LOG_DIR/monitor.log"
STATS_FILE="$LOG_DIR/stats-$(date +%Y%m%d).csv"

# Buat log directory jika belum ada
mkdir -p "$LOG_DIR"

# Headers untuk CSV
if [ ! -f "$STATS_FILE" ]; then
    echo "timestamp,cpu_usage,memory_usage,memory_percent,disk_usage,pm2_status,nginx_status" > "$STATS_FILE"
fi

# Function untuk collect data
collect_stats() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU usage (last minute average)
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # Memory usage
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_percent=$(echo "scale=2; $mem_used / $mem_total * 100" | bc)
    
    # Disk usage
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    
    # PM2 status
    local pm2_status=$(pm2 status | grep "xyz-corp-api" | awk '{print $13}')
    if [ -z "$pm2_status" ]; then
        pm2_status="unknown"
    fi
    
    # Nginx status
    local nginx_status=$(sudo systemctl is-active nginx)
    
    # Format untuk CSV
    echo "$timestamp,$cpu_usage,$mem_used,$mem_percent,$disk_usage,$pm2_status,$nginx_status" >> "$STATS_FILE"
    
    # Display output
    echo "[$timestamp]"
    echo "  CPU Usage: ${cpu_usage}%"
    echo "  Memory: ${mem_used}MB / ${mem_total}MB (${mem_percent}%)"
    echo "  Disk: $disk_usage"
    echo "  PM2 Status: $pm2_status"
    echo "  Nginx Status: $nginx_status"
    echo "  ---"
}

# Main loop
echo "Starting monitoring for $APP_NAME..."
echo "Log file: $LOG_FILE"
echo "Stats file: $STATS_FILE"
echo ""

while true; do
    collect_stats >> "$LOG_FILE" 2>&1
    
    # Alert jika CPU > 80%
    cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    if (( $(echo "$cpu > 80" | bc -l) )); then
        echo "[ALERT] High CPU usage: ${cpu}% at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    fi
    
    # Alert jika Memory > 85%
    mem_percent=$(free | grep Mem | awk '{printf "%.0f\n", $3/$2 * 100}')
    if [ $mem_percent -gt 85 ]; then
        echo "[ALERT] High memory usage: ${mem_percent}% at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    fi
    
    # Alert jika Disk > 90%
    disk_percent=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $disk_percent -gt 90 ]; then
        echo "[ALERT] High disk usage: ${disk_percent}% at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    fi
    
    sleep 60  # Collect data setiap 60 detik
done
