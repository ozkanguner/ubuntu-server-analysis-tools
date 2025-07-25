#!/bin/bash

# ============================================================================
# GITHUB'DAN ANALİZ SONUÇLARINI İNDİRME VE ANALİZ SCRIPTİ
# ============================================================================
# Amaç: GitHub'dan analiz sonuçlarını indirip detaylı analiz yapma
# ============================================================================

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
echo "📥 GITHUB'DAN ANALİZ SONUÇLARINI İNDİRME VE ANALİZ"
echo "=================================================="
echo -e "${NC}"

# ============================================================================
# 1. GİTHUB API İLE BRANCH'LERİ LİSTELE
# ============================================================================
log_header "1. GITHUB BRANCH'LERİ LİSTELENİYOR"
echo "======================================="

REPO="ozkanguner/ubuntu-server-analysis-tools"
API_URL="https://api.github.com/repos/$REPO/branches"

log_info "GitHub API'den branch'ler alınıyor..."

# Branch'leri al
BRANCHES=$(curl -s "$API_URL" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | grep "analysis-")

if [[ -z "$BRANCHES" ]]; then
    log_warning "Analiz branch'i bulunamadı!"
    log_info "Mevcut branch'ler:"
    curl -s "$API_URL" | grep -o '"name":"[^"]*"' | cut -d'"' -f4
    exit 1
fi

echo "📋 Bulunan analiz branch'leri:"
echo "$BRANCHES" | while read branch; do
    echo "  🌿 $branch"
done

# En son branch'i seç
LATEST_BRANCH=$(echo "$BRANCHES" | tail -1)
log_success "En son analiz branch'i: $LATEST_BRANCH"

# ============================================================================
# 2. BRANCH'İ KLONLA
# ============================================================================
log_header "2. BRANCH KLONLANIYOR"
echo "========================="

WORK_DIR="analysis-download-$(date +%Y%m%d-%H%M%S)"
log_info "Çalışma dizini oluşturuluyor: $WORK_DIR"

mkdir -p $WORK_DIR
cd $WORK_DIR

# Repository'yi klonla
log_info "Repository klonlanıyor..."
git clone -b $LATEST_BRANCH https://github.com/$REPO.git temp-repo

# Results dizinini kopyala
if [[ -d "temp-repo/results" ]]; then
    cp -r temp-repo/results .
    log_success "Analiz sonuçları kopyalandı"
else
    log_warning "Results dizini bulunamadı!"
    exit 1
fi

# Geçici dizini temizle
rm -rf temp-repo

# ============================================================================
# 3. ANALİZ DOSYALARINI BUL
# ============================================================================
log_header "3. ANALİZ DOSYALARI BULUNUYOR"
echo "=================================="

log_info "Analiz dosyaları aranıyor..."

TXT_FILES=$(find . -name "*.txt" -type f)
JSON_FILES=$(find . -name "*.json" -type f)
MD_FILES=$(find . -name "*.md" -type f)

echo "📄 Bulunan dosyalar:"
if [[ -n "$TXT_FILES" ]]; then
    echo "$TXT_FILES" | while read file; do
        echo "  📄 $(basename $file)"
    done
fi

if [[ -n "$JSON_FILES" ]]; then
    echo "$JSON_FILES" | while read file; do
        echo "  📊 $(basename $file)"
    done
fi

if [[ -n "$MD_FILES" ]]; then
    echo "$MD_FILES" | while read file; do
        echo "  📝 $(basename $file)"
    done
fi

# ============================================================================
# 4. ÖZET RAPORU ANALİZ ET
# ============================================================================
log_header "4. ÖZET RAPOR ANALİZİ"
echo "========================="

SUMMARY_FILE=$(find . -name "*summary*.md" -type f | head -1)

if [[ -n "$SUMMARY_FILE" ]]; then
    log_info "Özet rapor analiz ediliyor: $(basename $SUMMARY_FILE)"
    echo
    cat "$SUMMARY_FILE"
    echo
else
    log_warning "Özet rapor bulunamadı!"
fi

# ============================================================================
# 5. JSON VERİLERİ ANALİZ ET
# ============================================================================
log_header "5. JSON VERİ ANALİZİ"
echo "========================"

JSON_FILE=$(find . -name "*.json" -type f | head -1)

if [[ -n "$JSON_FILE" ]]; then
    log_info "JSON veri analiz ediliyor: $(basename $JSON_FILE)"
    
    # JSON'u güzel formatta göster
    if command -v jq >/dev/null 2>&1; then
        echo "📊 JSON Veri Özeti:"
        jq '.' "$JSON_FILE" | head -50
        echo "..."
    else
        echo "📊 JSON Veri Özeti:"
        cat "$JSON_FILE" | head -20
        echo "..."
    fi
    
    # Kritik metrikleri çıkar
    echo
    echo "🔍 KRİTİK METRİKLER:"
    if command -v jq >/dev/null 2>&1; then
        echo "  🖥️  CPU Cores: $(jq -r '.hardware.cpu_cores' "$JSON_FILE")"
        echo "  💾 Memory: $(jq -r '.hardware.memory_total' "$JSON_FILE")"
        echo "  💿 Disk Usage: $(jq -r '.hardware.disk_usage' "$JSON_FILE")"
        echo "  🌐 External IP: $(jq -r '.network.external_ip' "$JSON_FILE")"
        echo "  🔌 PPPoE Active: $(jq -r '.network.pppoe_active' "$JSON_FILE")"
        echo "  📁 5651 Directory: $(jq -r '.5651_log_server.directory_exists' "$JSON_FILE")"
        echo "  📊 Log Files: $(jq -r '.5651_log_server.log_files_count' "$JSON_FILE")"
        echo "  📈 CPU Usage: $(jq -r '.performance.cpu_usage' "$JSON_FILE")"
        echo "  📈 Memory Usage: $(jq -r '.performance.memory_usage' "$JSON_FILE")"
    else
        echo "  ⚠️  jq komutu bulunamadı, JSON analizi sınırlı"
    fi
else
    log_warning "JSON dosyası bulunamadı!"
fi

# ============================================================================
# 6. DETAYLI RAPORU ANALİZ ET
# ============================================================================
log_header "6. DETAYLI RAPOR ANALİZİ"
echo "============================="

TXT_FILE=$(find . -name "*.txt" -type f | head -1)

if [[ -n "$TXT_FILE" ]]; then
    log_info "Detaylı rapor analiz ediliyor: $(basename $TXT_FILE)"
    
    echo "📋 RAPOR ÖZETİ:"
    echo "==============="
    
    # Sistem bilgileri
    echo "🖥️  SİSTEM BİLGİLERİ:"
    if grep -q "Hostname:" "$TXT_FILE"; then
        grep -A 5 "SİSTEM ÖZETİ" "$TXT_FILE" | head -10
    fi
    
    # Servis durumları
    echo
    echo "🔧 SERVİS DURUMLARI:"
    if grep -q "SERVİS DURUMLARI" "$TXT_FILE"; then
        grep -A 10 "SERVİS DURUMLARI" "$TXT_FILE" | head -10
    fi
    
    # 5651 Log Server
    echo
    echo "📁 5651 LOG SERVER:"
    if grep -q "5651 LOG SERVER" "$TXT_FILE"; then
        grep -A 10 "5651 LOG SERVER" "$TXT_FILE" | head -10
    fi
    
    # Performans
    echo
    echo "📈 PERFORMANS:"
    if grep -q "PERFORMANS METRİKLERİ" "$TXT_FILE"; then
        grep -A 15 "PERFORMANS METRİKLERİ" "$TXT_FILE" | head -15
    fi
    
else
    log_warning "Detaylı rapor dosyası bulunamadı!"
fi

# ============================================================================
# 7. ANALİZ RAPORU OLUŞTUR
# ============================================================================
log_header "7. ANALİZ RAPORU OLUŞTURULUYOR"
echo "===================================="

ANALYSIS_REPORT="analysis-report-$(date +%Y%m%d-%H%M%S).md"

cat > $ANALYSIS_REPORT << EOF
# 📊 Ubuntu Sunucu Analiz Raporu

**İndirme Tarihi:** $(date '+%Y-%m-%d %H:%M:%S')  
**Kaynak Branch:** $LATEST_BRANCH  
**Repository:** https://github.com/$REPO  

## 📋 Dosya Listesi

$(find . -name "*.txt" -o -name "*.json" -o -name "*.md" | while read file; do
    echo "- $(basename $file)"
done)

## 🔍 Sistem Durumu

$(if [[ -n "$SUMMARY_FILE" ]]; then
    cat "$SUMMARY_FILE" | grep -E "^-|^##" | head -20
fi)

## 📈 Performans Analizi

$(if [[ -n "$JSON_FILE" ]] && command -v jq >/dev/null 2>&1; then
    echo "### Donanım"
    echo "- CPU Cores: $(jq -r '.hardware.cpu_cores' "$JSON_FILE")"
    echo "- Memory: $(jq -r '.hardware.memory_total' "$JSON_FILE")"
    echo "- Disk Usage: $(jq -r '.hardware.disk_usage' "$JSON_FILE")"
    echo
    echo "### Ağ"
    echo "- External IP: $(jq -r '.network.external_ip' "$JSON_FILE")"
    echo "- PPPoE Active: $(jq -r '.network.pppoe_active' "$JSON_FILE")"
    echo
    echo "### 5651 Log Server"
    echo "- Directory Exists: $(jq -r '.5651_log_server.directory_exists' "$JSON_FILE")"
    echo "- Log Files Count: $(jq -r '.5651_log_server.log_files_count' "$JSON_FILE")"
    echo "- Total Size: $(jq -r '.5651_log_server.total_size' "$JSON_FILE")"
    echo
    echo "### Performans"
    echo "- CPU Usage: $(jq -r '.performance.cpu_usage' "$JSON_FILE")"
    echo "- Memory Usage: $(jq -r '.performance.memory_usage' "$JSON_FILE")"
    echo "- Load Average: $(jq -r '.performance.load_average' "$JSON_FILE")"
fi)

## 🚨 Öneriler

$(if [[ -n "$JSON_FILE" ]] && command -v jq >/dev/null 2>&1; then
    CPU_USAGE=$(jq -r '.performance.cpu_usage' "$JSON_FILE" | sed 's/%//')
    MEMORY_USAGE=$(jq -r '.performance.memory_usage' "$JSON_FILE" | sed 's/%//')
    DISK_USAGE=$(jq -r '.hardware.disk_usage' "$JSON_FILE" | sed 's/%//')
    
    echo "### Performans Önerileri"
    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        echo "- ⚠️  CPU kullanımı yüksek ($CPU_USAGE%). Daha güçlü CPU veya optimizasyon gerekli."
    fi
    
    if (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
        echo "- ⚠️  Bellek kullanımı yüksek ($MEMORY_USAGE%). RAM artırımı önerilir."
    fi
    
    if (( $(echo "$DISK_USAGE > 80" | bc -l) )); then
        echo "- ⚠️  Disk kullanımı yüksek ($DISK_USAGE%). Disk alanı artırımı gerekli."
    fi
    
    PPPOE_ACTIVE=$(jq -r '.network.pppoe_active' "$JSON_FILE")
    if [[ "$PPPOE_ACTIVE" == "false" ]]; then
        echo "- 🔌 PPPoE bağlantısı aktif değil. Ağ bağlantısını kontrol edin."
    fi
    
    LOG_DIR_EXISTS=$(jq -r '.5651_log_server.directory_exists' "$JSON_FILE")
    if [[ "$LOG_DIR_EXISTS" == "false" ]]; then
        echo "- 📁 5651 log dizini bulunamadı. Kurulumu kontrol edin."
    fi
fi)

---

**📄 Tam rapor:** $(basename $TXT_FILE)  
**📊 JSON veri:** $(basename $JSON_FILE)  
**📝 Özet:** $(basename $SUMMARY_FILE)
EOF

log_success "Analiz raporu oluşturuldu: $ANALYSIS_REPORT"

# ============================================================================
# 8. SONUÇ
# ============================================================================
echo -e "${GREEN}"
echo "🎉 ANALİZ TAMAMLANDI!"
echo "====================="
echo -e "${NC}"

log_success "Çalışma dizini: $WORK_DIR"
log_success "Analiz raporu: $ANALYSIS_REPORT"

echo
log_info "📁 İndirilen dosyalar:"
ls -la

echo
log_info "📊 Raporu görüntülemek için:"
echo "cat $ANALYSIS_REPORT"

echo
log_success "Ubuntu sunucu analizi başarıyla tamamlandı!" 