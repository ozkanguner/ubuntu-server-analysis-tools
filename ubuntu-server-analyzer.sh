#!/bin/bash

# ============================================================================
# UBUNTU SUNUCU ANALİZ SCRIPTİ
# ============================================================================
# Amaç: Ubuntu sunucunun detaylı analizi ve raporlama
# Hedef: 5651 Log Server performans optimizasyonu
# ============================================================================

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log fonksiyonları
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

log_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Rapor dosyası
REPORT_FILE="/tmp/ubuntu-server-analysis-$(date +%Y%m%d-%H%M%S).txt"
JSON_FILE="/tmp/ubuntu-server-analysis-$(date +%Y%m%d-%H%M%S).json"

echo -e "${GREEN}"
echo "🔍 UBUNTU SUNUCU ANALİZ SCRIPTİ"
echo "================================="
echo "Hedef: 5651 Log Server Performans Analizi"
echo "Rapor: $REPORT_FILE"
echo "JSON: $JSON_FILE"
echo -e "${NC}"

# ============================================================================
# 1. SİSTEM TEMEL BİLGİLERİ
# ============================================================================
log_header "1. SİSTEM TEMEL BİLGİLERİ"
echo "=================================" | tee -a $REPORT_FILE

log_info "Sistem bilgileri toplanıyor..."

# Sistem bilgileri
echo "=== SİSTEM BİLGİLERİ ===" | tee -a $REPORT_FILE
uname -a | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# CPU bilgileri
echo "=== CPU BİLGİLERİ ===" | tee -a $REPORT_FILE
lscpu | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Bellek bilgileri
echo "=== BELLEK DURUMU ===" | tee -a $REPORT_FILE
free -h | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Disk kullanımı
echo "=== DİSK KULLANIMI ===" | tee -a $REPORT_FILE
df -h | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 2. AĞ YAPILANDIRMASI
# ============================================================================
log_header "2. AĞ YAPILANDIRMASI"
echo "=========================" | tee -a $REPORT_FILE

log_info "Ağ yapılandırması analiz ediliyor..."

# Ağ arayüzleri
echo "=== AĞ ARAYÜZLERİ ===" | tee -a $REPORT_FILE
ip -o link show | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# IP adresleri
echo "=== IP ADRESLERİ ===" | tee -a $REPORT_FILE
ip addr show | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Routing tablosu
echo "=== ROUTING TABLOSU ===" | tee -a $REPORT_FILE
ip route show | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# PPPoE bağlantı durumu
echo "=== PPPoE BAĞLANTI DURUMU ===" | tee -a $REPORT_FILE
if ip addr show ppp0 >/dev/null 2>&1; then
    ip addr show ppp0 | tee -a $REPORT_FILE
    echo "PPPoE Interface: ACTIVE" | tee -a $REPORT_FILE
else
    echo "PPPoE Interface: NOT FOUND" | tee -a $REPORT_FILE
fi
echo "" | tee -a $REPORT_FILE

# Dış IP adresi
echo "=== DIŞ IP ADRESİ ===" | tee -a $REPORT_FILE
EXTERNAL_IP=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "BAĞLANTI YOK")
echo "External IP: $EXTERNAL_IP" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 3. SERVİS DURUMLARI
# ============================================================================
log_header "3. SERVİS DURUMLARI"
echo "=======================" | tee -a $REPORT_FILE

log_info "Kritik servisler kontrol ediliyor..."

# systemd-networkd
echo "=== SYSTEMD-NETWORKD ===" | tee -a $REPORT_FILE
systemctl status systemd-networkd --no-pager | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# rsyslog
echo "=== RSYSLOG ===" | tee -a $REPORT_FILE
systemctl status rsyslog --no-pager | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# PPPoE monitor
echo "=== PPPoE MONITOR ===" | tee -a $REPORT_FILE
if systemctl list-unit-files | grep -q pppoe-monitor; then
    systemctl status pppoe-monitor --no-pager | tee -a $REPORT_FILE
else
    echo "PPPoE Monitor service not found" | tee -a $REPORT_FILE
fi
echo "" | tee -a $REPORT_FILE

# SSH
echo "=== SSH ===" | tee -a $REPORT_FILE
systemctl status ssh --no-pager | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 4. FIREWALL VE GÜVENLİK
# ============================================================================
log_header "4. FIREWALL VE GÜVENLİK"
echo "=============================" | tee -a $REPORT_FILE

log_info "Firewall durumu kontrol ediliyor..."

# UFW durumu
echo "=== UFW DURUMU ===" | tee -a $REPORT_FILE
ufw status verbose | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Açık portlar
echo "=== AÇIK PORTLAR ===" | tee -a $REPORT_FILE
ss -tulpn | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 5. 5651 LOG SERVER ANALİZİ
# ============================================================================
log_header "5. 5651 LOG SERVER ANALİZİ"
echo "===============================" | tee -a $REPORT_FILE

log_info "5651 log server durumu analiz ediliyor..."

# 5651 dizini
echo "=== 5651 DİZİN YAPISI ===" | tee -a $REPORT_FILE
if [ -d "/var/5651" ]; then
    ls -la /var/5651/ | tee -a $REPORT_FILE
    echo "" | tee -a $REPORT_FILE
    
    # Log dosyaları
    echo "=== LOG DOSYALARI ===" | tee -a $REPORT_FILE
    find /var/5651/ -name "*.log" -type f | head -20 | tee -a $REPORT_FILE
    echo "" | tee -a $REPORT_FILE
    
    # Disk kullanımı
    echo "=== 5651 DİSK KULLANIMI ===" | tee -a $REPORT_FILE
    du -sh /var/5651/* 2>/dev/null | tee -a $REPORT_FILE
    echo "" | tee -a $REPORT_FILE
else
    echo "5651 dizini bulunamadı" | tee -a $REPORT_FILE
    echo "" | tee -a $REPORT_FILE
fi

# Rsyslog konfigürasyonu
echo "=== RSYSLOG KONFİGÜRASYONU ===" | tee -a $REPORT_FILE
if [ -f "/etc/rsyslog.d/10-optimal-5651.conf" ]; then
    cat /etc/rsyslog.d/10-optimal-5651.conf | tee -a $REPORT_FILE
else
    echo "5651 rsyslog konfigürasyonu bulunamadı" | tee -a $REPORT_FILE
fi
echo "" | tee -a $REPORT_FILE

# Syslog port dinleme
echo "=== SYSLOG PORT DİNLEME ===" | tee -a $REPORT_FILE
ss -tulpn | grep :514 | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 6. PERFORMANS METRİKLERİ
# ============================================================================
log_header "6. PERFORMANS METRİKLERİ"
echo "=============================" | tee -a $REPORT_FILE

log_info "Performans metrikleri toplanıyor..."

# CPU kullanımı
echo "=== CPU KULLANIMI ===" | tee -a $REPORT_FILE
top -bn1 | grep "Cpu(s)" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Bellek kullanımı
echo "=== BELLEK KULLANIMI ===" | tee -a $REPORT_FILE
vmstat 1 3 | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Disk I/O
echo "=== DİSK I/O ===" | tee -a $REPORT_FILE
iostat -x 1 3 2>/dev/null || echo "iostat bulunamadı" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# Ağ trafiği
echo "=== AĞ TRAFİĞİ ===" | tee -a $REPORT_FILE
ss -i | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 7. SİSTEM LOGLARI
# ============================================================================
log_header "7. SİSTEM LOGLARI"
echo "====================" | tee -a $REPORT_FILE

log_info "Sistem logları analiz ediliyor..."

# Son sistem mesajları
echo "=== SON SİSTEM MESAJLARI ===" | tee -a $REPORT_FILE
journalctl --no-pager -n 50 | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# PPPoE logları
echo "=== PPPoE LOGLARI ===" | tee -a $REPORT_FILE
if [ -f "/var/log/pppoe-monitor.log" ]; then
    tail -20 /var/log/pppoe-monitor.log | tee -a $REPORT_FILE
else
    echo "PPPoE monitor log dosyası bulunamadı" | tee -a $REPORT_FILE
fi
echo "" | tee -a $REPORT_FILE

# Rsyslog logları
echo "=== RSYSLOG LOGLARI ===" | tee -a $REPORT_FILE
tail -20 /var/log/syslog | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 8. JSON RAPOR OLUŞTURMA
# ============================================================================
log_info "JSON rapor oluşturuluyor..."

cat > $JSON_FILE << EOF
{
  "analysis_timestamp": "$(date -Iseconds)",
  "system_info": {
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "architecture": "$(uname -m)",
    "os_version": "$(lsb_release -d | cut -f2 2>/dev/null || echo 'Unknown')"
  },
  "hardware": {
    "cpu_cores": $(nproc),
    "cpu_model": "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)",
    "memory_total": "$(free -h | grep Mem | awk '{print $2}')",
    "memory_available": "$(free -h | grep Mem | awk '{print $7}')",
    "disk_usage": "$(df -h / | tail -1 | awk '{print $5}')"
  },
  "network": {
    "external_ip": "$EXTERNAL_IP",
    "pppoe_active": $(if ip addr show ppp0 >/dev/null 2>&1; then echo "true"; else echo "false"; fi),
    "open_ports": [$(ss -tulpn | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -u | tr '\n' ',' | sed 's/,$//')]
  },
  "services": {
    "systemd_networkd": "$(systemctl is-active systemd-networkd 2>/dev/null || echo 'unknown')",
    "rsyslog": "$(systemctl is-active rsyslog 2>/dev/null || echo 'unknown')",
    "ssh": "$(systemctl is-active ssh 2>/dev/null || echo 'unknown')",
    "pppoe_monitor": "$(systemctl is-active pppoe-monitor 2>/dev/null || echo 'unknown')"
  },
  "5651_log_server": {
    "directory_exists": $(if [ -d "/var/5651" ]; then echo "true"; else echo "false"; fi),
    "log_files_count": $(find /var/5651/ -name "*.log" -type f 2>/dev/null | wc -l),
    "total_size": "$(du -sh /var/5651/ 2>/dev/null | awk '{print $1}' || echo 'N/A')"
  },
  "performance": {
    "cpu_usage": "$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%",
    "memory_usage": "$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%",
    "load_average": "$(uptime | awk -F'load average:' '{print $2}' | xargs)"
  }
}
EOF

# ============================================================================
# 9. ÖZET RAPOR
# ============================================================================
log_header "9. ÖZET RAPOR"
echo "=================" | tee -a $REPORT_FILE

log_info "Özet rapor oluşturuluyor..."

echo "=== SİSTEM ÖZETİ ===" | tee -a $REPORT_FILE
echo "Hostname: $(hostname)" | tee -a $REPORT_FILE
echo "Kernel: $(uname -r)" | tee -a $REPORT_FILE
echo "CPU: $(nproc) cores" | tee -a $REPORT_FILE
echo "Memory: $(free -h | grep Mem | awk '{print $2}')" | tee -a $REPORT_FILE
echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')" | tee -a $REPORT_FILE
echo "External IP: $EXTERNAL_IP" | tee -a $REPORT_FILE
echo "PPPoE Active: $(if ip addr show ppp0 >/dev/null 2>&1; then echo 'YES'; else echo 'NO'; fi)" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

echo "=== SERVİS DURUMLARI ===" | tee -a $REPORT_FILE
echo "systemd-networkd: $(systemctl is-active systemd-networkd 2>/dev/null || echo 'UNKNOWN')" | tee -a $REPORT_FILE
echo "rsyslog: $(systemctl is-active rsyslog 2>/dev/null || echo 'UNKNOWN')" | tee -a $REPORT_FILE
echo "SSH: $(systemctl is-active ssh 2>/dev/null || echo 'UNKNOWN')" | tee -a $REPORT_FILE
echo "PPPoE Monitor: $(systemctl is-active pppoe-monitor 2>/dev/null || echo 'UNKNOWN')" | tee -a $REPORT_FILE
echo "" | tee -a $REPORT_FILE

echo "=== 5651 LOG SERVER ===" | tee -a $REPORT_FILE
if [ -d "/var/5651" ]; then
    echo "Directory: EXISTS" | tee -a $REPORT_FILE
    echo "Log Files: $(find /var/5651/ -name "*.log" -type f 2>/dev/null | wc -l)" | tee -a $REPORT_FILE
    echo "Total Size: $(du -sh /var/5651/ 2>/dev/null | awk '{print $1}' || echo 'N/A')" | tee -a $REPORT_FILE
else
    echo "Directory: NOT FOUND" | tee -a $REPORT_FILE
fi
echo "" | tee -a $REPORT_FILE

# ============================================================================
# 10. TAMAMLAMA
# ============================================================================
echo -e "${GREEN}"
echo "🎉 UBUNTU SUNUCU ANALİZİ TAMAMLANDI!"
echo "====================================="
echo -e "${NC}"

log_success "Rapor dosyası: $REPORT_FILE"
log_success "JSON rapor: $JSON_FILE"

echo
log_info "📊 RAPOR İÇERİĞİ:"
echo "✅ Sistem temel bilgileri"
echo "✅ Ağ yapılandırması"
echo "✅ Servis durumları"
echo "✅ Firewall ve güvenlik"
echo "✅ 5651 Log Server analizi"
echo "✅ Performans metrikleri"
echo "✅ Sistem logları"
echo "✅ JSON formatında özet"

echo
log_info "🔧 SONRAKI ADIMLAR:"
echo "• Raporu inceleyin: cat $REPORT_FILE"
echo "• JSON verilerini kullanın: cat $JSON_FILE"
echo "• Performans optimizasyonu için önerileri değerlendirin"
echo "• 5651 Log Server konfigürasyonunu gözden geçirin"

echo
log_success "5651 Log Server analizi başarıyla tamamlandı!" 