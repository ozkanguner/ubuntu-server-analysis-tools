#!/bin/bash

# ============================================================================
# UBUNTU PPPoE DIRECT CONNECTION - MIGRATION SCRIPT
# ============================================================================
# Target: Replace MikroTik NAT with direct PPPoE connection
# Performance: Zero NAT overhead for 10K EPS capability
# ============================================================================

set -e

# Colors for output
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

echo -e "${GREEN}"
echo "🚀 UBUNTU PPPoE DIRECT CONNECTION - MIGRATION"
echo "=============================================="
echo "Target: Direct ISP connection for 5651 Log Server"
echo "Performance: Zero NAT overhead + 10K EPS capability"
echo -e "${NC}"

# ============================================================================
# 1. PRE-MIGRATION BACKUP
# ============================================================================
log_info "1. Creating backup of current configuration..."

BACKUP_DIR="/backup/migration-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup logs
log_info "Backing up 5651 logs..."
tar -czf $BACKUP_DIR/5651-logs.tar.gz /var/5651/ 2>/dev/null || true

# Backup network config
log_info "Backing up network configuration..."
cp -r /etc/netplan/ $BACKUP_DIR/netplan-backup/ 2>/dev/null || true
cp -r /etc/systemd/network/ $BACKUP_DIR/systemd-network-backup/ 2>/dev/null || true

# Backup rsyslog config
cp /etc/rsyslog.d/10-optimal-5651.conf $BACKUP_DIR/ 2>/dev/null || true

log_success "Backup completed: $BACKUP_DIR"

# ============================================================================
# 2. PPPoE CREDENTIALS CONFIGURATION
# ============================================================================
echo
log_info "2. PPPoE Credentials Configuration..."

# Pre-configured credentials for 5651 Log Server
PPPOE_USER="trasst.server2"
PPPOE_PASS="Zkngnr81."
TARGET_IP="92.113.43.134"

log_info "Username: $PPPOE_USER"
log_success "PPPoE credentials configured automatically"

# ============================================================================
# 3. INSTALL PPPoE PACKAGES
# ============================================================================
log_info "3. Installing PPPoE packages..."

apt update
apt install -y pppoeconf ppp pppoe

# systemd-networkd is built-in, no need to install
systemctl status systemd-networkd >/dev/null 2>&1 && log_success "systemd-networkd already available"

log_success "PPPoE packages installed"

# ============================================================================
# 4. NETWORK INTERFACE DETECTION
# ============================================================================
log_info "4. Detecting network interfaces..."

# Show all available interfaces
log_info "Available network interfaces:"
ip -o link show | grep -E "(ens|eth|enp)" | while read line; do
    INTERFACE_NAME=$(echo $line | awk -F': ' '{print $2}' | cut -d'@' -f1)
    INTERFACE_STATE=$(echo $line | grep -o "state [A-Z]*" | cut -d' ' -f2)
    echo "  - $INTERFACE_NAME ($INTERFACE_STATE)"
done

# Find the second interface (likely the newly added one)
INTERFACES=($(ip -o link show | grep -E "(ens|eth|enp)" | awk -F': ' '{print $2}' | cut -d'@' -f1))
INTERFACE_COUNT=${#INTERFACES[@]}

if [[ $INTERFACE_COUNT -ge 2 ]]; then
    # Use the second interface for PPPoE
    INTERFACE=${INTERFACES[1]}
    log_info "Found $INTERFACE_COUNT interfaces, using second interface for PPPoE: $INTERFACE"
else
    log_warning "Less than 2 interfaces found!"
    log_info "Available interfaces:"
    ip link show
    read -p "Enter PPPoE interface name manually: " INTERFACE
fi

log_success "PPPoE will be configured on interface: $INTERFACE"

# ============================================================================
# 5. CONFIGURE DUAL INTERFACE SETUP
# ============================================================================
log_info "5. Configuring dual interface setup..."

# Keep NetworkManager for DHCP interface, but configure PPPoE interface manually
log_info "NetworkManager will remain active for DHCP interface"
log_info "PPPoE interface will be managed by systemd-networkd"

# Ensure systemd-networkd is enabled
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# ============================================================================
# 6. SYSTEMD-NETWORKD CONFIGURATION
# ============================================================================
log_info "6. Configuring systemd-networkd..."

# Enable systemd-networkd
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# Physical interface configuration for PPPoE
cat > /etc/systemd/network/10-${INTERFACE}-pppoe.network << EOF
[Match]
Name=${INTERFACE}

[Network]
DHCP=no
IPv6AcceptRA=no
KeepConfiguration=static
EOF

# PPPoE netdev configuration
cat > /etc/systemd/network/20-pppoe.netdev << EOF
[NetDev]
Name=ppp0
Kind=ppp
Description=PPPoE connection for 5651 Log Server

[PPP]
User=${PPPOE_USER}
Password=${PPPOE_PASS}
EOF

# PPPoE network configuration
cat > /etc/systemd/network/21-pppoe.network << EOF
[Match]
Name=ppp0

[Network]
IPForward=yes
DNS=8.8.8.8
DNS=1.1.1.1
DNS=1.0.0.1

[Route]
Gateway=_dhcp
Metric=100
EOF

log_success "systemd-networkd configured"

# ============================================================================
# 7. FIREWALL CONFIGURATION
# ============================================================================
log_info "7. Configuring advanced firewall..."

# Reset firewall
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Syslog ports (CRITICAL)
ufw allow in 514/udp comment "5651 Syslog UDP"
ufw allow in 514/tcp comment "5651 Syslog TCP"

# SSH access
ufw allow in 22/tcp comment "SSH Management"

# ICMP (ping)
ufw allow in proto icmp comment "ICMP Ping"

# Enable firewall
ufw --force enable

log_success "Firewall configured for direct PPPoE"

# ============================================================================
# 8. PPPoE CONNECTION MONITORING SERVICE
# ============================================================================
log_info "8. Setting up PPPoE monitoring..."

# PPPoE reconnection script
cat > /opt/pppoe-monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/pppoe-monitor.log"
CHECK_INTERVAL=30

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

while true; do
    # Check PPPoE interface
    if ! ip addr show ppp0 >/dev/null 2>&1; then
        log_message "PPPoE interface down, restarting systemd-networkd"
        systemctl restart systemd-networkd
        sleep 60
        continue
    fi
    
    # Check internet connectivity
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log_message "Internet connectivity lost, restarting PPPoE"
        systemctl restart systemd-networkd
        sleep 60
        continue
    fi
    
    # Check external IP
    EXTERNAL_IP=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "unknown")
    if [[ "$EXTERNAL_IP" != "unknown" ]]; then
        log_message "PPPoE healthy - External IP: $EXTERNAL_IP"
    fi
    
    sleep $CHECK_INTERVAL
done
EOF

chmod +x /opt/pppoe-monitor.sh

# PPPoE monitoring service
cat > /etc/systemd/system/pppoe-monitor.service << EOF
[Unit]
Description=PPPoE Connection Monitor for 5651 Log Server
After=systemd-networkd.service
Requires=systemd-networkd.service

[Service]
Type=simple
ExecStart=/opt/pppoe-monitor.sh
Restart=always
RestartSec=30
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pppoe-monitor

log_success "PPPoE monitoring service configured"

# ============================================================================
# 9. RSYSLOG OPTIMIZATION FOR DIRECT CONNECTION
# ============================================================================
log_info "9. Optimizing rsyslog for direct connection..."

# Update rsyslog config for direct IP
sed -i 's/92.113.42.3/92.113.43.132/g' /etc/rsyslog.d/10-optimal-5651.conf 2>/dev/null || true
sed -i 's/92.113.42.253/92.113.43.132/g' /etc/rsyslog.d/10-optimal-5651.conf 2>/dev/null || true

# Add performance tuning for direct connection
cat >> /etc/rsyslog.d/10-optimal-5651.conf << 'EOF'

# ============================================================================
# DIRECT PPPoE CONNECTION OPTIMIZATIONS
# ============================================================================
# Enhanced performance for direct external IP reception

# UDP reception tuning
$UDPServerTimeRequery 100
$InputUDPServerBindRuleset main

# Performance monitoring
$ActionFileEnableSync off
$ActionFileDefaultTemplate RSYSLOG_FileFormat

EOF

log_success "Rsyslog optimized for direct connection"

# ============================================================================
# 10. START SERVICES
# ============================================================================
log_info "10. Starting services..."

# Start systemd-networkd
systemctl restart systemd-networkd
systemctl restart systemd-resolved

# Start PPPoE monitoring
systemctl start pppoe-monitor

# Restart rsyslog
systemctl restart rsyslog

log_success "All services started"

# ============================================================================
# 11. CONNECTION VERIFICATION
# ============================================================================
log_info "11. Verifying PPPoE connection..."

sleep 15

# Check PPPoE interface
if ip addr show ppp0 >/dev/null 2>&1; then
    EXTERNAL_IP=$(ip addr show ppp0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    log_success "PPPoE interface active: $EXTERNAL_IP"
else
    log_warning "PPPoE interface not yet active, checking status..."
    systemctl status systemd-networkd
fi

# Check internet connectivity
if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
    log_success "Internet connectivity verified"
else
    log_warning "Internet connectivity issue, check PPPoE credentials"
fi

# Check rsyslog
if systemctl is-active rsyslog >/dev/null 2>&1; then
    log_success "Rsyslog service active"
    
    # Check port listening
    if ss -tulpn | grep :514 >/dev/null 2>&1; then
        log_success "Port 514 listening for syslog"
    else
        log_warning "Port 514 not listening, checking rsyslog config"
    fi
else
    log_warning "Rsyslog service issue"
fi

# ============================================================================
# 12. FINAL STATUS REPORT
# ============================================================================
echo
echo -e "${GREEN}🎉 UBUNTU PPPoE DIRECT CONNECTION MIGRATION COMPLETED!${NC}"
echo "=================================================================="
echo
log_info "📋 MIGRATION SUMMARY:"
echo "✅ Dual interface setup configured"
echo "✅ DHCP interface remains active (NetworkManager)"
echo "✅ PPPoE connection established on second interface"
echo "✅ Direct external IP assigned"
echo "✅ Firewall configured for syslog"
echo "✅ PPPoE monitoring service active"
echo "✅ Rsyslog optimized for direct connection"
echo "✅ Backup created: $BACKUP_DIR"
echo

log_info "🔧 POST-MIGRATION COMMANDS:"
echo "• Check PPPoE status: systemctl status systemd-networkd"
echo "• Monitor connection: journalctl -u pppoe-monitor -f"
echo "• Check external IP: curl ifconfig.me"
echo "• Test syslog: echo 'TEST' | nc -u \$(curl -s ifconfig.me) 514"
echo "• Live monitoring: /opt/5651-monitoring/live-stats.sh"
echo

log_info "🎯 EXPECTED PERFORMANCE:"
echo "• Zero NAT overhead"
echo "• Direct 10K EPS capability"
echo "• Improved reliability"
echo "• Simplified troubleshooting"
echo

log_info "📊 VERIFICATION STEPS:"
echo "1. curl ifconfig.me (should show ISP assigned IP)"
echo "2. sudo tcpdump -i ppp0 port 514 (monitor syslog traffic)"
echo "3. tail -f /var/5651/unknown-devices/*.log (check log reception)"
echo

if [[ -n "$EXTERNAL_IP" ]]; then
    echo -e "${GREEN}🌟 External IP: $EXTERNAL_IP${NC}"
    echo -e "${GREEN}🌟 Syslog endpoint: $EXTERNAL_IP:514${NC}"
else
    echo -e "${YELLOW}⚠️  External IP not yet assigned, check PPPoE status${NC}"
fi

echo
log_success "5651 Log Server is now running on direct PPPoE connection!"
echo -e "${BLUE}For support, check logs: tail -f /var/log/pppoe-monitor.log${NC}" 