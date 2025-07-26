#!/bin/bash

# ============================================================================
# USB ANALİZ YEDEKLEME VE GITHUB YÜKLEME SCRIPTİ
# ============================================================================
# Amaç: Analiz sonuçlarını USB'ye kaydetme ve GitHub'a yükleme
# ============================================================================

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

echo -e "${GREEN}"
echo "💾 USB ANALİZ YEDEKLEME VE GITHUB YÜKLEME"
echo "=========================================="
echo -e "${NC}"

# ============================================================================
# 1. PPPoE MONITOR SERVİSİNİ KALDIR
# ============================================================================
log_header "1. PPPoE MONITOR SERVİSİ KALDIRILIYOR"
echo "==========================================="

log_info "PPPoE monitor servisi kontrol ediliyor..."

if systemctl list-unit-files | grep -q pppoe-monitor; then
    log_info "PPPoE monitor servisi bulundu, kaldırılıyor..."
    
    # Servisi durdur ve devre dışı bırak
    systemctl stop pppoe-monitor 2>/dev/null || true
    systemctl disable pppoe-monitor 2>/dev/null || true
    
    # Servis dosyasını kaldır
    rm -f /etc/systemd/system/pppoe-monitor.service
    rm -f /opt/pppoe-monitor.sh
    
    # systemd'yi yeniden yükle
    systemctl daemon-reload
    
    log_success "PPPoE monitor servisi kaldırıldı"
else
    log_info "PPPoE monitor servisi zaten yok"
fi

# ============================================================================
# 2. USB CİHAZLARINI TESPİT ET
# ============================================================================
log_header "2. USB CİHAZLARI TESPİT EDİLİYOR"
echo "======================================"

log_info "USB cihazları aranıyor..."

# USB cihazlarını listele
USB_DEVICES=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "(sd|usb)" | grep -v "loop")

if [[ -z "$USB_DEVICES" ]]; then
    log_warning "USB cihaz bulunamadı!"
    log_info "USB cihazını takın ve tekrar deneyin"
    exit 1
fi

echo "📱 Bulunan USB cihazları:"
echo "$USB_DEVICES"

# ============================================================================
# 3. USB MOUNT NOKTASINI BUL
# ============================================================================
log_header "3. USB MOUNT NOKTASI BULUNUYOR"
echo "==================================="

# Mount edilmiş USB'leri bul
MOUNTED_USB=$(df -h | grep -E "/media|/mnt" | grep -v "tmpfs")

if [[ -z "$MOUNTED_USB" ]]; then
    log_warning "Mount edilmiş USB bulunamadı!"
    log_info "USB'yi manuel olarak mount edin:"
    echo "sudo mount /dev/sdX1 /mnt/usb"
    exit 1
fi

echo "📂 Mount edilmiş USB'ler:"
echo "$MOUNTED_USB"

# İlk mount noktasını kullan
USB_MOUNT=$(echo "$MOUNTED_USB" | head -1 | awk '{print $6}')
log_success "USB mount noktası: $USB_MOUNT"

# ============================================================================
# 4. ANALİZ SONUÇLARINI USB'YE KOPYALA
# ============================================================================
log_header "4. ANALİZ SONUÇLARI USB'YE KOPYALANIYOR"
echo "============================================="

# Analiz dizini oluştur
ANALYSIS_DIR="$USB_MOUNT/ubuntu-analysis-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ANALYSIS_DIR"

log_info "Analiz dizini oluşturuldu: $ANALYSIS_DIR"

# En son analiz dosyalarını bul ve kopyala
LATEST_TXT=$(ls -t /tmp/ubuntu-server-analysis-*.txt 2>/dev/null | head -1)
LATEST_JSON=$(ls -t /tmp/ubuntu-server-analysis-*.json 2>/dev/null | head -1)

if [[ -n "$LATEST_TXT" ]]; then
    cp "$LATEST_TXT" "$ANALYSIS_DIR/"
    log_success "TXT rapor kopyalandı: $(basename $LATEST_TXT)"
fi

if [[ -n "$LATEST_JSON" ]]; then
    cp "$LATEST_JSON" "$ANALYSIS_DIR/"
    log_success "JSON rapor kopyalandı: $(basename $LATEST_JSON)"
fi

# Sistem bilgilerini de ekle
cat > "$ANALYSIS_DIR/system-info.txt" << EOF
# Ubuntu Sunucu Sistem Bilgileri
# Tarih: $(date '+%Y-%m-%d %H:%M:%S')
# Hostname: $(hostname)

=== SİSTEM BİLGİLERİ ===
$(uname -a)

=== CPU BİLGİLERİ ===
$(lscpu | head -20)

=== BELLEK DURUMU ===
$(free -h)

=== DİSK KULLANIMI ===
$(df -h)

=== AĞ ARAYÜZLERİ ===
$(ip -o link show)

=== IP ADRESLERİ ===
$(ip addr show | head -30)

=== SERVİS DURUMLARI ===
systemd-networkd: $(systemctl is-active systemd-networkd 2>/dev/null || echo "UNKNOWN")
rsyslog: $(systemctl is-active rsyslog 2>/dev/null || echo "UNKNOWN")
SSH: $(systemctl is-active ssh 2>/dev/null || echo "UNKNOWN")

=== 5651 LOG SERVER ===
Directory: $(if [ -d "/var/5651" ]; then echo "EXISTS"; else echo "NOT FOUND"; fi)
Log Files: $(find /var/5651/ -name "*.log" -type f 2>/dev/null | wc -l)
Total Size: $(du -sh /var/5651/ 2>/dev/null | awk '{print $1}' || echo "N/A")

=== PERFORMANS ===
CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%
Memory Usage: $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%
Load Average: $(uptime | awk -F'load average:' '{print $2}' | xargs)
EOF

log_success "Sistem bilgileri kaydedildi: system-info.txt"

# ============================================================================
# 5. GITHUB YÜKLEME SCRIPTİ OLUŞTUR
# ============================================================================
log_header "5. GITHUB YÜKLEME SCRIPTİ OLUŞTURULUYOR"
echo "=============================================="

GITHUB_SCRIPT="$ANALYSIS_DIR/upload-to-github.sh"

cat > "$GITHUB_SCRIPT" << 'EOF'
#!/bin/bash

# ============================================================================
# GITHUB YÜKLEME SCRIPTİ
# ============================================================================
# Kullanım: ./upload-to-github.sh [GITHUB_TOKEN]
# ============================================================================

set -e

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${GREEN}"
echo "🚀 GITHUB YÜKLEME SCRIPTİ"
echo "========================="
echo -e "${NC}"

# Token kontrolü
if [[ -z "$1" ]]; then
    log_warning "GitHub token gerekli!"
    echo "Kullanım: $0 [GITHUB_TOKEN]"
    echo
    echo "GitHub token oluşturmak için:"
    echo "1. GitHub.com → Settings → Developer settings → Personal access tokens"
    echo "2. Generate new token (classic)"
    echo "3. Scopes: repo seçin"
    echo "4. Token'ı kopyalayın"
    exit 1
fi

GITHUB_TOKEN="$1"
REPO="ozkanguner/ubuntu-server-analysis-tools"

# Git konfigürasyonu
git config user.name "ozkanguner"
git config user.email "ozkanguner@github.com"

# Yeni branch oluştur
BRANCH_NAME="usb-analysis-$(date +%Y%m%d-%H%M%S)"
git checkout -b $BRANCH_NAME

# Dosyaları ekle
mkdir -p results
cp *.txt *.json results/ 2>/dev/null || true

# Commit
git add results/
git commit -m "📊 USB'den analiz sonuçları - $(date '+%Y-%m-%d %H:%M')"

# Push
log_info "GitHub'a yükleniyor..."
git push https://${GITHUB_TOKEN}@github.com/$REPO.git $BRANCH_NAME

log_success "Analiz sonuçları GitHub'a yüklendi!"
echo "🔗 Pull Request: https://github.com/$REPO/compare/main...$BRANCH_NAME"

# Ana branch'e dön
git checkout main
EOF

chmod +x "$GITHUB_SCRIPT"
log_success "GitHub yükleme scripti oluşturuldu: upload-to-github.sh"

# ============================================================================
# 6. KULLANIM TALİMATLARI
# ============================================================================
log_header "6. KULLANIM TALİMATLARI"
echo "=========================="

cat > "$ANALYSIS_DIR/README.md" << EOF
# 📊 Ubuntu Sunucu Analiz Sonuçları

**Tarih:** $(date '+%Y-%m-%d %H:%M:%S')  
**Hostname:** $(hostname)  
**USB Mount:** $USB_MOUNT  

## 📁 Dosyalar

- \`system-info.txt\` - Sistem bilgileri
- \`ubuntu-server-analysis-*.txt\` - Detaylı analiz raporu
- \`ubuntu-server-analysis-*.json\` - JSON formatında veri
- \`upload-to-github.sh\` - GitHub yükleme scripti

## 🚀 GitHub'a Yükleme

1. GitHub token oluşturun:
   - GitHub.com → Settings → Developer settings → Personal access tokens
   - Generate new token (classic)
   - Scopes: repo seçin

2. Token ile yükleyin:
   \`\`\`bash
   ./upload-to-github.sh YOUR_TOKEN_HERE
   \`\`\`

## 📊 Sistem Durumu

- **CPU Cores:** $(nproc)
- **Memory:** $(free -h | grep Mem | awk '{print $2}')
- **Disk Usage:** $(df -h / | tail -1 | awk '{print $5}')
- **5651 Log Server:** $(if [ -d "/var/5651" ]; then echo "EXISTS"; else echo "NOT FOUND"; fi)
- **Log Files:** $(find /var/5651/ -name "*.log" -type f 2>/dev/null | wc -l)
- **Total Size:** $(du -sh /var/5651/ 2>/dev/null | awk '{print $1}' || echo "N/A")

## 🔧 Servis Durumları

- **systemd-networkd:** $(systemctl is-active systemd-networkd 2>/dev/null || echo "UNKNOWN")
- **rsyslog:** $(systemctl is-active rsyslog 2>/dev/null || echo "UNKNOWN")
- **SSH:** $(systemctl is-active ssh 2>/dev/null || echo "UNKNOWN")

---

**💾 USB'ye kaydedildi: $ANALYSIS_DIR**
EOF

log_success "Kullanım talimatları oluşturuldu: README.md"

# ============================================================================
# 7. SONUÇ
# ============================================================================
echo -e "${GREEN}"
echo "🎉 USB YEDEKLEME TAMAMLANDI!"
echo "============================="
echo -e "${NC}"

log_success "Analiz sonuçları USB'ye kaydedildi: $ANALYSIS_DIR"
log_success "PPPoE monitor servisi kaldırıldı"

echo
log_info "📁 USB'deki dosyalar:"
ls -la "$ANALYSIS_DIR"

echo
log_info "🚀 GitHub'a yüklemek için:"
echo "cd $ANALYSIS_DIR"
echo "./upload-to-github.sh YOUR_TOKEN_HERE"

echo
log_success "İşlem tamamlandı! USB'yi güvenle çıkarabilirsiniz." 