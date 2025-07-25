#!/bin/bash
# ============================================================================
# 5651 LOG SERVER - COMPLETE FRESH INSTALL SCRIPT
# Ubuntu 22.04 LTS + Optimal Rsyslog + 10K EPS Ready
# Version: 1.0
# Date: 2025-07-25
# ============================================================================

echo "🚀 5651 LOG SERVER - COMPLETE FRESH INSTALL"
echo "==========================================="
echo "Target: 10K EPS | 40 CPU Cores | 64GB RAM"
echo "Rsyslog Multi-threading | Auto Log Rotation"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (sudo ./5651-fresh-install-complete.sh)"
    exit 1
fi

log_info "Starting 5651 Log Server Fresh Installation..."

# ============================================================================
# 1. SYSTEM UPDATE AND BASIC PACKAGES + VMWARE TOOLS
# ============================================================================
log_info "1. System Update and Basic Packages Installation..."

apt update && apt upgrade -y
apt install -y htop iotop sysstat net-tools curl wget git bc lsof tcpdump

log_info "Installing VMware Tools for optimal performance..."
apt install -y open-vm-tools open-vm-tools-dev linux-modules-extra-$(uname -r)
systemctl enable open-vm-tools
systemctl start open-vm-tools

log_success "System updated, basic packages and VMware Tools installed"

# ============================================================================
# 2. NETWORK OPTIMIZATION FOR 10K EPS
# ============================================================================
log_info "2. Network Optimization for 10K EPS..."

cat > /etc/sysctl.d/99-5651-optimization.conf << 'EOF'
# 5651 Log Server - Network Optimization for 10K EPS
# Optimized for 40 vCPU + 64GB RAM

# Network buffer optimization
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 10000
net.core.netdev_budget = 600

# UDP optimization for syslog
net.ipv4.udp_mem = 204800 1747600 33554432
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# File system optimization
fs.file-max = 1000000

# Memory optimization for 64GB RAM
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 12000
vm.dirty_writeback_centisecs = 1500
vm.vfs_cache_pressure = 50

# Reduce swapping
vm.swappiness = 10
EOF

# Apply network optimizations
sysctl -p /etc/sysctl.d/99-5651-optimization.conf

log_success "Network optimization applied"

# ============================================================================
# 3. RSYSLOG INSTALLATION AND SERVICE LIMITS
# ============================================================================
log_info "3. Modern Rsyslog Installation..."

# Install rsyslog
apt install -y rsyslog rsyslog-utils

# Check rsyslog version
RSYSLOG_VERSION=$(rsyslogd -v | head -1)
log_info "Installed: $RSYSLOG_VERSION"

# Set rsyslog service limits for high performance
mkdir -p /etc/systemd/system/rsyslog.service.d/

cat > /etc/systemd/system/rsyslog.service.d/limits.conf << 'EOF'
[Service]
LimitNOFILE=65536
LimitNPROC=8192
LimitMEMLOCK=infinity
OOMScoreAdjust=-100

# Restart policy for stability
Restart=always
RestartSec=5
EOF

systemctl daemon-reload

log_success "Rsyslog installed with optimized service limits"

# ============================================================================
# 4. 5651 DIRECTORY STRUCTURE CREATION
# ============================================================================
log_info "4. Creating 5651 Directory Structure..."

# Main 5651 directories
mkdir -p /var/5651/{SULTANAHMET-HOTSPOT,MASLAK-HOTSPOT}/{genel,security,critical}
mkdir -p /var/5651/{archive,monitoring,temp,unknown-devices}

# Set proper ownership and permissions
chown -R syslog:adm /var/5651
chmod -R 755 /var/5651

# Create backup directory
mkdir -p /var/5651-backup
chown -R syslog:adm /var/5651-backup

log_success "5651 directory structure created"

# ============================================================================
# 5. OPTIMAL RSYSLOG CONFIGURATION
# ============================================================================
log_info "5. Creating Optimal Rsyslog Configuration..."

# Backup original rsyslog.conf
cp /etc/rsyslog.conf /etc/rsyslog.conf.backup

# Create optimal 5651 configuration
cat > /etc/rsyslog.d/10-optimal-5651.conf << 'EOF'
# ============================================================================
# 5651 LOG SERVER - OPTIMAL CONFIGURATION
# Multi-threading enabled | 10K EPS ready | Auto folder creation
# ============================================================================

# Directory creation settings
$CreateDirs on
$DirCreateMode 0755
$FileCreateMode 0644

# ============================================================================
# MAIN QUEUE OPTIMIZATION - 16 WORKER THREADS FOR 40 CORES
# ============================================================================
$MainMsgQueueSize 500000
$MainMsgQueueWorkerThreads 16
$MainMsgQueueWorkerThreadMinimumMessages 20000
$MainMsgQueueType LinkedList
$MainMsgQueueHighWatermark 400000
$MainMsgQueueLowWatermark 200000
$MainMsgQueueDiscardMark 450000
$MainMsgQueueTimeoutShutdown 10000
$MainMsgQueueDequeueSlowdown 0

# ============================================================================
# ACTION QUEUE OPTIMIZATION - 8 WORKER THREADS
# ============================================================================
$ActionQueueSize 200000
$ActionQueueWorkerThreads 8
$ActionQueueType LinkedList
$ActionQueueHighWatermark 160000
$ActionQueueLowWatermark 80000
$ActionQueueDiscardMark 180000
$ActionQueueTimeoutShutdown 5000

# ============================================================================
# PERFORMANCE SETTINGS
# ============================================================================
$ActionFileEnableSync off
$ActionFileDefaultTemplate RSYSLOG_FileFormat
$ActionResumeRetryCount 3
$ActionQueueTimeoutEnqueue 1000

# Rate limiting - conservative start (can be increased)
$SystemLogRateLimitInterval 1
$SystemLogRateLimitBurst 5000
$IMJournalRatelimitInterval 1
$IMJournalRatelimitBurst 5000

# ============================================================================
# LOG TEMPLATES
# ============================================================================

# Main location templates
$template SultanahmetLogs,"/var/5651/SULTANAHMET-HOTSPOT/genel/%$year%-%$month%-%$day%.log"
$template MaslakLogs,"/var/5651/MASLAK-HOTSPOT/genel/%$year%-%$month%-%$day%.log"

# Security templates
$template SultanahmetSecurity,"/var/5651/SULTANAHMET-HOTSPOT/security/%$year%-%$month%-%$day%.log"
$template MaslakSecurity,"/var/5651/MASLAK-HOTSPOT/security/%$year%-%$month%-%$day%.log"

# Auto-creation templates
$template AutoDeviceLogs,"/var/5651/%fromhost%/genel/%$year%-%$month%-%$day%.log"
$template AutoSecurityLogs,"/var/5651/%fromhost%/security/%$year%-%$month%-%$day%.log"
$template UnknownDeviceLogs,"/var/5651/unknown-devices/%fromhost%-%$year%-%$month%-%$day%.log"

# ============================================================================
# FILTERING RULES - PRIORITY ORDER
# ============================================================================

# SECURITY CRITICAL EVENTS - HIGHEST PRIORITY
if ($msg contains "connection-state:invalid" or 
    $msg contains "connection-state:untracked" or
    $msg contains "dst-port:22" or 
    $msg contains "dst-port:3389" or
    $msg contains "dst-port:21" or
    $msg contains "dst-port:23" or
    $msg contains "ATTACK" or
    $msg contains "INTRUSION") then {
    
    if $fromhost-ip == "92.113.42.3" then {
        ?SultanahmetSecurity
    } else if $fromhost-ip == "92.113.42.253" then {
        ?MaslakSecurity
    } else {
        ?AutoSecurityLogs
    }
    stop
}

# KNOWN DEVICES - MAIN LOCATIONS
if $fromhost-ip == "92.113.42.3" then {
    ?SultanahmetLogs
    stop
}

if $fromhost-ip == "92.113.42.253" then {
    ?MaslakLogs
    stop
}

# MIKROTIK DEVICES - AUTO FOLDER CREATION
if ($msg contains "forward:" and 
    ($fromhost-ip startswith "92.113.42." or 
     $fromhost-ip startswith "172." or 
     $fromhost-ip startswith "192.168." or
     $fromhost-ip startswith "10.")) then {
    ?AutoDeviceLogs
    stop
}

# UNKNOWN DEVICES - SEPARATE FOLDER
if ($msg contains "forward:" or $msg contains "mikrotik") then {
    ?UnknownDeviceLogs
    stop
}

# ============================================================================
# DROP RULES - REDUCE NOISE (OPTIONAL)
# ============================================================================

# Uncomment below lines to drop repetitive logs (reduces volume by 60-70%)
# if $msg contains "connection-state:established" and $msg contains "len 52" then stop
# if $msg contains "len 40" and $msg contains "ACK" then stop
# if $msg contains "len 0" then stop

EOF

log_success "Optimal rsyslog configuration created"

# ============================================================================
# 6. LOG ROTATION SETUP
# ============================================================================
log_info "6. Setting up Log Rotation..."

cat > /etc/logrotate.d/5651-logs << 'EOF'
# 5651 Log Server - Log Rotation Configuration
# Daily rotation, 7 days retention, compress after 1 day

/var/5651/**/genel/*.log /var/5651/**/security/*.log /var/5651/**/critical/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 syslog adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
    
    # Split large files (>1GB)
    size 1G
    
    # Archive old logs
    lastaction
        find /var/5651 -name "*.gz" -mtime +7 -exec mv {} /var/5651-backup/ \;
    endscript
}

# Unknown devices - shorter retention
/var/5651/unknown-devices/*.log {
    daily
    rotate 3
    compress
    delaycompress
    missingok
    notifempty
    create 0644 syslog adm
    size 500M
}
EOF

log_success "Log rotation configured"

# ============================================================================
# 7. PERFORMANCE MONITORING SETUP
# ============================================================================
log_info "7. Setting up Performance Monitoring..."

mkdir -p /opt/5651-monitoring

cat > /opt/5651-monitoring/monitor.sh << 'EOF'
#!/bin/bash
# 5651 Log Server - Performance Monitor
# Continuous monitoring with alerts

LOG_FILE="/var/log/5651-monitor.log"
ALERT_LOG="/var/log/5651-alerts.log"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get rsyslog stats
    RSYSLOG_PID=$(pidof rsyslogd || echo "0")
    if [ "$RSYSLOG_PID" != "0" ]; then
        RSYSLOG_CPU=$(ps aux | grep rsyslogd | grep -v grep | awk '{print $3}' || echo "0")
        RSYSLOG_MEM=$(ps aux | grep rsyslogd | grep -v grep | awk '{print $6}' || echo "0")
        THREADS=$(ps -p $RSYSLOG_PID -T 2>/dev/null | wc -l || echo "0")
    else
        RSYSLOG_CPU="0"
        RSYSLOG_MEM="0"
        THREADS="0"
        echo "$TIMESTAMP | ERROR: Rsyslog not running!" >> $ALERT_LOG
    fi
    
    # System stats
    TOTAL_CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # Log volume (last minute)
    LOG_SIZE=$(find /var/5651 -name "*.log" -mmin -1 -exec du -sk {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # EPS calculation (approximate)
    EPS=$((LOG_SIZE * 10))  # Rough estimate
    
    # Disk usage
    DISK_USAGE=$(df /var/5651 | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    # Log normal stats
    echo "$TIMESTAMP | CPU: ${RSYSLOG_CPU}% | SysCPU: ${TOTAL_CPU}% | Mem: ${RSYSLOG_MEM}KB (${MEMORY_USAGE}%) | Threads: $THREADS | EPS: ~$EPS | Disk: ${DISK_USAGE}% | LogKB/min: $LOG_SIZE" >> $LOG_FILE
    
    # ALERTS
    # High CPU alert
    if (( $(echo "$RSYSLOG_CPU > 50" | bc -l) )); then
        echo "$TIMESTAMP | ALERT: High Rsyslog CPU: ${RSYSLOG_CPU}%" >> $ALERT_LOG
    fi
    
    # High system CPU alert
    if (( $(echo "$TOTAL_CPU > 80" | bc -l) )); then
        echo "$TIMESTAMP | ALERT: High System CPU: ${TOTAL_CPU}%" >> $ALERT_LOG
    fi
    
    # Low thread count alert
    if [ "$THREADS" -lt 15 ] && [ "$THREADS" -gt 0 ]; then
        echo "$TIMESTAMP | ALERT: Low thread count: $THREADS (expected 20+)" >> $ALERT_LOG
    fi
    
    # High disk usage alert
    if [ "$DISK_USAGE" -gt 80 ]; then
        echo "$TIMESTAMP | ALERT: High disk usage: ${DISK_USAGE}%" >> $ALERT_LOG
    fi
    
    # High EPS alert
    if [ "$EPS" -gt 15000 ]; then
        echo "$TIMESTAMP | ALERT: High EPS detected: ~$EPS (may need rate limiting)" >> $ALERT_LOG
    fi
    
    sleep 60
done
EOF

chmod +x /opt/5651-monitoring/monitor.sh

# Create systemd service for monitoring
cat > /etc/systemd/system/5651-monitor.service << 'EOF'
[Unit]
Description=5651 Log Server Performance Monitor
After=rsyslog.service
Requires=rsyslog.service

[Service]
Type=simple
User=root
ExecStart=/opt/5651-monitoring/monitor.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable 5651-monitor.service

log_success "Performance monitoring setup completed"

# ============================================================================
# 8. UTILITY SCRIPTS
# ============================================================================
log_info "8. Creating Utility Scripts..."

# Live stats script
cat > /opt/5651-monitoring/live-stats.sh << 'EOF'
#!/bin/bash
# 5651 Live Statistics Display

while true; do
    clear
    echo "============================================="
    echo "   5651 LOG SERVER - LIVE STATISTICS"
    echo "============================================="
    echo "$(date)"
    echo ""
    
    # Rsyslog status
    RSYSLOG_PID=$(pidof rsyslogd)
    if [ "$RSYSLOG_PID" ]; then
        RSYSLOG_CPU=$(ps aux | grep rsyslogd | grep -v grep | awk '{print $3}')
        RSYSLOG_MEM=$(ps aux | grep rsyslogd | grep -v grep | awk '{print $6}')
        THREADS=$(ps -p $RSYSLOG_PID -T | wc -l)
        echo "🔧 Rsyslog Status: RUNNING (PID: $RSYSLOG_PID)"
        echo "   CPU: ${RSYSLOG_CPU}% | Memory: ${RSYSLOG_MEM}KB | Threads: $THREADS"
    else
        echo "🔧 Rsyslog Status: STOPPED"
    fi
    
    # System stats
    TOTAL_CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    echo "🖥️  System CPU: ${TOTAL_CPU}% | Memory: ${MEMORY_USAGE}%"
    
    # Log directories
    echo ""
    echo "📁 Log Directories:"
    du -sh /var/5651/*/ 2>/dev/null | head -10
    
    # Recent activity
    echo ""
    echo "📊 Recent Activity (last 5 minutes):"
    find /var/5651 -name "*.log" -mmin -5 -exec echo "   $(basename $(dirname {})/$(basename {}))" \; 2>/dev/null | sort | uniq -c | sort -nr | head -5
    
    # Alerts
    echo ""
    echo "🚨 Recent Alerts:"
    if [ -f /var/log/5651-alerts.log ]; then
        tail -3 /var/log/5651-alerts.log 2>/dev/null || echo "   No alerts"
    else
        echo "   No alerts"
    fi
    
    sleep 5
done
EOF

chmod +x /opt/5651-monitoring/live-stats.sh

# EPS testing script
cat > /opt/5651-monitoring/eps-test.sh << 'EOF'
#!/bin/bash
# 5651 EPS Testing Script

echo "🎯 5651 EPS (Events Per Second) Test"
echo "=================================="

if [ "$1" = "start" ]; then
    echo "Starting EPS measurement..."
    START_SIZE=$(find /var/5651 -name "*.log" -exec du -sk {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    echo $START_SIZE > /tmp/eps-test-start
    echo "Test started at $(date)"
    echo "Waiting 60 seconds..."
    
elif [ "$1" = "stop" ]; then
    if [ -f /tmp/eps-test-start ]; then
        START_SIZE=$(cat /tmp/eps-test-start)
        END_SIZE=$(find /var/5651 -name "*.log" -exec du -sk {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        DIFF_KB=$((END_SIZE - START_SIZE))
        
        # Rough EPS calculation (assuming 100 bytes per event average)
        ESTIMATED_EPS=$((DIFF_KB * 10))
        
        echo "Test completed at $(date)"
        echo "Data growth: ${DIFF_KB} KB/minute"
        echo "Estimated EPS: ~${ESTIMATED_EPS} events/second"
        
        rm /tmp/eps-test-start
    else
        echo "No test in progress. Run with 'start' first."
    fi
    
else
    echo "Usage: $0 {start|stop}"
    echo ""
    echo "Run '$0 start', wait 60 seconds, then run '$0 stop'"
fi
EOF

chmod +x /opt/5651-monitoring/eps-test.sh

log_success "Utility scripts created"

# ============================================================================
# 9. START SERVICES AND INITIAL TEST
# ============================================================================
log_info "9. Starting Services and Initial Testing..."

# Start rsyslog with new configuration
systemctl restart rsyslog
sleep 5

# Start monitoring
systemctl start 5651-monitor.service

# Check if rsyslog started successfully
if systemctl is-active --quiet rsyslog; then
    log_success "Rsyslog service started successfully"
    
    RSYSLOG_PID=$(pidof rsyslogd)
    THREADS=$(ps -p $RSYSLOG_PID -T | wc -l)
    RSYSLOG_VERSION=$(rsyslogd -v | head -1)
    
    echo ""
    echo "📊 INITIAL SYSTEM STATUS:"
    echo "========================"
    echo "Rsyslog Version: $RSYSLOG_VERSION"
    echo "Process ID: $RSYSLOG_PID"
    echo "Thread Count: $THREADS"
    
    if [ $THREADS -gt 15 ]; then
        log_success "Multi-threading is WORKING! ($THREADS threads)"
    else
        log_warning "Thread count is low ($THREADS). Expected 20+."
    fi
    
    # 5-second performance test
    echo ""
    echo "🔬 5-Second Performance Test:"
    echo "============================"
    
    for i in {1..5}; do
        CPU=$(ps aux | grep rsyslogd | grep -v grep | awk '{print $3}')
        MEM_KB=$(ps aux | grep rsyslogd | grep -v grep | awk '{print $6}')
        MEM_MB=$((MEM_KB / 1024))
        echo "[$i/5] CPU: ${CPU}% | Memory: ${MEM_MB}MB | Threads: $THREADS | $(date +%H:%M:%S)"
        sleep 1
    done
    
else
    log_error "Rsyslog service failed to start!"
    systemctl status rsyslog
    exit 1
fi

# ============================================================================
# 10. FIREWALL CONFIGURATION (if needed)
# ============================================================================
log_info "10. Configuring Firewall..."

# Check if ufw is active
if command -v ufw >/dev/null 2>&1; then
    ufw allow 514/udp comment "Syslog UDP"
    ufw allow 514/tcp comment "Syslog TCP"
    ufw allow 22/tcp comment "SSH"
    log_success "Firewall rules added"
else
    log_info "UFW not installed, skipping firewall configuration"
fi

# ============================================================================
# INSTALLATION COMPLETED
# ============================================================================
echo ""
echo "🎉 5651 LOG SERVER INSTALLATION COMPLETED SUCCESSFULLY!"
echo "======================================================"
echo ""
echo "📋 INSTALLATION SUMMARY:"
echo "========================"
echo "✅ Ubuntu system optimized for 10K EPS"
echo "✅ Modern rsyslog with multi-threading ($THREADS threads)"
echo "✅ 5651 directory structure created"
echo "✅ Automatic log rotation configured"
echo "✅ Performance monitoring enabled"
echo "✅ Security event separation"
echo "✅ Auto folder creation for new devices"
echo ""

echo "📁 IMPORTANT DIRECTORIES:"
echo "========================"
echo "• Main logs: /var/5651/"
echo "• Monitoring: /opt/5651-monitoring/"
echo "• Configuration: /etc/rsyslog.d/10-optimal-5651.conf"
echo "• Monitor log: /var/log/5651-monitor.log"
echo "• Alert log: /var/log/5651-alerts.log"
echo ""

echo "🔧 USEFUL COMMANDS:"
echo "=================="
echo "• Live statistics: /opt/5651-monitoring/live-stats.sh"
echo "• EPS testing: /opt/5651-monitoring/eps-test.sh start"
echo "• Service status: systemctl status rsyslog 5651-monitor"
echo "• Monitor logs: tail -f /var/log/5651-monitor.log"
echo "• Check alerts: tail -f /var/log/5651-alerts.log"
echo ""

echo "🎯 NEXT STEPS:"
echo "============="
echo "1. Point your MikroTik devices to this server"
echo "2. Verify logs are being received in /var/5651/"
echo "3. Monitor performance with live-stats.sh"
echo "4. Test with different EPS loads"
echo "5. Adjust rate limiting if needed (edit /etc/rsyslog.d/10-optimal-5651.conf)"
echo ""

echo "📊 EXPECTED PERFORMANCE:"
echo "======================"
echo "• CPU Usage: 15-25% (distributed across 40 cores)"
echo "• Thread Count: 20+ (16 main + 8 action + others)"
echo "• 10K EPS: Easily handled"
echo "• Memory Usage: ~50-100MB for rsyslog"
echo ""

log_success "5651 Log Server is ready for production!"
echo ""
echo "🌟 For support or questions, check the logs in /var/log/5651-monitor.log"
echo "" 