#!/bin/bash

# ============================================================================
# ANALİZ SONUÇLARINI GITHUB'A YÜKLEME SCRIPTİ
# ============================================================================
# Amaç: Ubuntu sunucu analiz sonuçlarını GitHub'a otomatik yükleme
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
echo "📤 ANALİZ SONUÇLARINI GITHUB'A YÜKLEME"
echo "======================================="
echo -e "${NC}"

# ============================================================================
# 1. ANALİZ SONUÇLARINI BUL
# ============================================================================
log_info "Analiz sonuçları aranıyor..."

# En son analiz dosyalarını bul
LATEST_TXT=$(ls -t /tmp/ubuntu-server-analysis-*.txt 2>/dev/null | head -1)
LATEST_JSON=$(ls -t /tmp/ubuntu-server-analysis-*.json 2>/dev/null | head -1)

if [[ -z "$LATEST_TXT" ]] && [[ -z "$LATEST_JSON" ]]; then
    log_warning "Analiz sonuçları bulunamadı!"
    log_info "Önce analiz scriptini çalıştırın:"
    echo "sudo ./ubuntu-server-analyzer.sh"
    exit 1
fi

log_success "Analiz dosyaları bulundu:"
if [[ -n "$LATEST_TXT" ]]; then
    echo "  📄 $LATEST_TXT"
fi
if [[ -n "$LATEST_JSON" ]]; then
    echo "  📊 $LATEST_JSON"
fi

# ============================================================================
# 2. GİT DURUMUNU KONTROL ET
# ============================================================================
log_info "Git durumu kontrol ediliyor..."

if ! git status >/dev/null 2>&1; then
    log_warning "Git repository bulunamadı!"
    log_info "Repository'yi klonlayın:"
    echo "git clone https://github.com/ozkanguner/ubuntu-server-analysis-tools.git"
    exit 1
fi

# Git konfigürasyonunu kontrol et ve ayarla
log_info "Git konfigürasyonu kontrol ediliyor..."

if [[ -z "$(git config user.name)" ]] || [[ -z "$(git config user.email)" ]]; then
    log_warning "Git kullanıcı bilgileri eksik!"
    log_info "Otomatik konfigürasyon yapılıyor..."
    
    # Hostname'den kullanıcı adı oluştur
    USER_NAME=$(hostname | cut -d'.' -f1)
    USER_EMAIL="${USER_NAME}@$(hostname).local"
    
    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    
    log_success "Git konfigürasyonu ayarlandı:"
    echo "  👤 User: $USER_NAME"
    echo "  📧 Email: $USER_EMAIL"
fi

# ============================================================================
# 3. YENİ BRANCH OLUŞTUR
# ============================================================================
BRANCH_NAME="analysis-$(date +%Y%m%d-%H%M%S)"
log_info "Yeni branch oluşturuluyor: $BRANCH_NAME"

git checkout -b $BRANCH_NAME

# ============================================================================
# 4. ANALİZ SONUÇLARINI EKLE
# ============================================================================
log_info "Analiz sonuçları ekleniyor..."

# Sonuçları results/ dizinine kopyala
mkdir -p results
if [[ -n "$LATEST_TXT" ]]; then
    cp "$LATEST_TXT" "results/$(basename $LATEST_TXT)"
fi
if [[ -n "$LATEST_JSON" ]]; then
    cp "$LATEST_JSON" "results/$(basename $LATEST_JSON)"
fi

# Git'e ekle
git add results/

# ============================================================================
# 5. ÖZET RAPOR OLUŞTUR
# ============================================================================
log_info "Özet rapor oluşturuluyor..."

SUMMARY_FILE="results/analysis-summary-$(date +%Y%m%d-%H%M%S).md"

cat > $SUMMARY_FILE << EOF
# 📊 Ubuntu Sunucu Analiz Özeti

**Tarih:** $(date '+%Y-%m-%d %H:%M:%S')  
**Hostname:** $(hostname)  
**Kernel:** $(uname -r)  

## 🔍 Sistem Bilgileri

- **CPU:** $(nproc) cores
- **Memory:** $(free -h | grep Mem | awk '{print $2}')
- **Disk Usage:** $(df -h / | tail -1 | awk '{print $5}')
- **Uptime:** $(uptime -p)

## 🌐 Ağ Bilgileri

- **External IP:** $(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "Bağlantı yok")
- **PPPoE Active:** $(if ip addr show ppp0 >/dev/null 2>&1; then echo "YES"; else echo "NO"; fi)

## 🔧 Servis Durumları

- **systemd-networkd:** $(systemctl is-active systemd-networkd 2>/dev/null || echo "UNKNOWN")
- **rsyslog:** $(systemctl is-active rsyslog 2>/dev/null || echo "UNKNOWN")
- **SSH:** $(systemctl is-active ssh 2>/dev/null || echo "UNKNOWN")

## 📁 5651 Log Server

- **Directory:** $(if [ -d "/var/5651" ]; then echo "EXISTS"; else echo "NOT FOUND"; fi)
- **Log Files:** $(find /var/5651/ -name "*.log" -type f 2>/dev/null | wc -l)
- **Total Size:** $(du -sh /var/5651/ 2>/dev/null | awk '{print $1}' || echo "N/A")

## 📈 Performans

- **CPU Usage:** $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%
- **Memory Usage:** $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%
- **Load Average:** $(uptime | awk -F'load average:' '{print $2}' | xargs)

---

**📄 Detaylı rapor:** $(basename $LATEST_TXT)  
**📊 JSON veri:** $(basename $LATEST_JSON)
EOF

git add $SUMMARY_FILE

# ============================================================================
# 6. COMMIT VE PUSH
# ============================================================================
log_info "Değişiklikler commit ediliyor..."

git commit -m "📊 Ubuntu sunucu analiz sonuçları - $(date '+%Y-%m-%d %H:%M')"

log_info "GitHub'a push ediliyor..."

if git push origin $BRANCH_NAME; then
    log_success "Analiz sonuçları başarıyla GitHub'a yüklendi!"
    echo
    echo "🔗 Pull Request oluşturmak için:"
    echo "https://github.com/ozkanguner/ubuntu-server-analysis-tools/compare/main...$BRANCH_NAME"
    echo
    echo "📁 Yüklenen dosyalar:"
    ls -la results/
else
    log_warning "Push başarısız! Manuel olarak push edin:"
    echo "git push origin $BRANCH_NAME"
fi

# ============================================================================
# 7. TEMİZLİK
# ============================================================================
log_info "Temizlik yapılıyor..."

# Ana branch'e geri dön
git checkout main

log_success "İşlem tamamlandı!" 