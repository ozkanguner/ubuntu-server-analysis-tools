#!/bin/bash

echo "🎯 MikroTik Otomatik Cihaz Algılama Kurulumu"
echo "=============================================="

# Yedek al
echo "📁 Mevcut konfigürasyon yedekleniyor..."
cp /etc/rsyslog.d/50-mikrotik-smart-filter.conf /etc/rsyslog.d/50-mikrotik-smart-filter.conf.backup.$(date +%Y%m%d_%H%M%S)

# Yeni konfigürasyonu kopyala
echo "⚙️ Otomatik algılama konfigürasyonu kuruluyor..."
cp ./50-mikrotik-auto-detect.conf /etc/rsyslog.d/50-mikrotik-auto-detect.conf

# Eski konfigürasyonu devre dışı bırak (rename)
if [ -f /etc/rsyslog.d/50-mikrotik-smart-filter.conf ]; then
    mv /etc/rsyslog.d/50-mikrotik-smart-filter.conf /etc/rsyslog.d/50-mikrotik-smart-filter.conf.disabled
    echo "✅ Eski konfigürasyon devre dışı bırakıldı"
fi

# Syntax test
echo "🔍 Rsyslog syntax kontrolü..."
rsyslogd -N1
if [ $? -eq 0 ]; then
    echo "✅ Syntax OK!"
    
    # Rsyslog restart
    echo "🔄 Rsyslog restart ediliyor..."
    systemctl restart rsyslog
    
    if [ $? -eq 0 ]; then
        echo "✅ Rsyslog başarıyla restart edildi!"
        
        # Status kontrol
        echo "📊 Servis durumu:"
        systemctl status rsyslog --no-pager -l
        
        echo ""
        echo "🎉 KURULUM TAMAMLANDI!"
        echo ""
        echo "🔥 ÖZELLİKLER:"
        echo "   ✅ Yeni IP'ler için otomatik klasör oluşturma"
        echo "   ✅ Hostname tabanlı klasörleme" 
        echo "   ✅ IP tabanlı fallback"
        echo "   ✅ MikroTik ağ aralığı otomatik algılama"
        echo ""
        echo "📁 Test için:"
        echo "   watch 'ls -la /var/5651/'"
        
    else
        echo "❌ Rsyslog restart başarısız!"
        echo "🔄 Eski konfigürasyona geri dönülüyor..."
        mv /etc/rsyslog.d/50-mikrotik-smart-filter.conf.disabled /etc/rsyslog.d/50-mikrotik-smart-filter.conf
        rm /etc/rsyslog.d/50-mikrotik-auto-detect.conf
        systemctl restart rsyslog
        exit 1
    fi
else
    echo "❌ Syntax hatası! Kurulum iptal edildi."
    rm /etc/rsyslog.d/50-mikrotik-auto-detect.conf
    exit 1
fi

echo ""
echo "🧪 YENİ CİHAZ TEST EDİN:"
echo "logger -n 127.0.0.1 -P 514 'Test mesajı yeni cihazdan'" 