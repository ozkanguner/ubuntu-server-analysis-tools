# 🔒 Güvenli 10K EPS Ubuntu Server Kurulumu

Bu repository, 10,000 Events Per Second (EPS) kapasitesine sahip güvenli bir Ubuntu Log Server kurulumu için geliştirilmiştir.

## 🎯 Hedef

- **10,000 EPS** performans kapasitesi
- **NAT güvenliği** (MikroTik router ile)
- **Yüksek performans** optimizasyonu
- **5651 Log Server** entegrasyonu

## 📋 Sistem Gereksinimleri

### Minimum Donanım:
- **CPU**: 4+ cores (8+ önerilir)
- **RAM**: 8GB+ (16GB önerilir)
- **Disk**: 100GB+ SSD (500GB+ önerilir)
- **Ağ**: 1Gbps (2.5Gbps önerilir)

### Ağ Topolojisi:
```
[Internet] → [MikroTik Router] → [Ubuntu 5651 Server]
                (NAT + Firewall)     (10K EPS)
```

## 🚀 Hızlı Kurulum

### 1. Ubuntu Server Kurulumu:
```bash
# Ubuntu 22.04 LTS Server
- Minimal kurulum
- SSH server dahil
- Güvenlik duvarı: Hayır (manuel yapılandırma)
```

### 2. Script'i İndirin:
```bash
# Repository'yi klonlayın
git clone https://github.com/ozkanguner/ubuntu-server-analysis-tools.git
cd ubuntu-server-analysis-tools

# Script'i çalıştırılabilir yapın
chmod +x secure-10k-eps-setup.sh

# Kurulumu başlatın
sudo ./secure-10k-eps-setup.sh
```

## 📁 Kurulum İçeriği

### Otomatik Yapılandırmalar:
- ✅ **Ağ yapılandırması** (192.168.88.100)
- ✅ **Güvenlik duvarı** (UFW)
- ✅ **Kernel optimizasyonu** (10K EPS için)
- ✅ **rsyslog optimizasyonu** (Queue sistemi)
- ✅ **Sistem servisleri** (systemd limitleri)
- ✅ **Monitoring** (otomatik log takibi)
- ✅ **Log rotation** (disk yönetimi)

### Oluşturulan Dizinler:
```
/var/5651/
├── mikrotik/          # MikroTik logları
├── other-devices/     # Diğer cihaz logları
└── default/          # Varsayılan loglar
```

## 🔧 MikroTik Router Konfigürasyonu

Kurulum sonrası `/root/mikrotik-config.txt` dosyasında detaylı talimatlar bulunur:

### Temel Konfigürasyon:
```bash
# Ağ yapılandırması
/ip address add address=192.168.88.1/24 interface=ether2

# NAT konfigürasyonu
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade

# Port forwarding (10K EPS için)
/ip firewall nat add chain=dstnat protocol=udp dst-port=514 action=dst-nat to-addresses=192.168.88.100 to-ports=514

# Log yönlendirme
/tool logging add action=remote topics=info,debug remote=192.168.88.100:514
```

## 📊 Performans Özellikleri

### 10K EPS Optimizasyonları:
- **Kernel parametreleri**: TCP/UDP buffer optimizasyonu
- **rsyslog queue**: LinkedList queue sistemi
- **Disk I/O**: SSD optimizasyonu
- **Bellek**: Swappiness ve dirty ratio ayarları
- **Ağ**: BBR congestion control

### Güvenlik Özellikleri:
- **NAT koruması**: MikroTik router
- **Firewall**: UFW kuralları
- **Port forwarding**: Sadece gerekli portlar
- **Rate limiting**: DDoS koruması

## 🧪 Test ve Doğrulama

### Kurulum Sonrası Testler:
```bash
# Ağ bağlantısı
ping 192.168.88.1

# rsyslog servisi
systemctl status rsyslog

# Port dinleme
ss -tulpn | grep :514

# Test mesajı
logger -n 192.168.88.100 -P 514 "Test message"

# Log kontrolü
ls -la /var/5651/
tail -f /var/5651/mikrotik/$(date +%Y-%m-%d).log
```

### Monitoring:
```bash
# Performans monitoring
tail -f /var/log/5651-monitoring.log

# Sistem durumu
htop
df -h /var/5651
```

## 📈 Performans Metrikleri

### Beklenen Performans:
- **10,000 EPS** kapasitesi
- **< 1ms** gecikme
- **99.9%** uptime
- **Otomatik** log rotation
- **Gerçek zamanlı** monitoring

### Disk Kullanımı:
- **Günlük**: ~1-5GB (log boyutuna göre)
- **Aylık**: ~30-150GB
- **Yıllık**: ~365-1825GB

## 🔍 Sorun Giderme

### Yaygın Sorunlar:

#### rsyslog Başlamıyor:
```bash
# Konfigürasyon kontrolü
rsyslogd -N1

# Servis durumu
systemctl status rsyslog

# Log kontrolü
journalctl -u rsyslog
```

#### Ağ Bağlantısı Yok:
```bash
# IP kontrolü
ip addr show

# Gateway kontrolü
ip route show

# DNS kontrolü
nslookup google.com
```

#### Performans Düşük:
```bash
# Kernel parametreleri
sysctl -a | grep net.core

# rsyslog queue durumu
ss -tulpn | grep :514

# Disk I/O
iostat -x 1 3
```

## 📞 Destek

- **Issues**: GitHub Issues kullanın
- **Dokümantasyon**: Bu README dosyasını inceleyin
- **Loglar**: `/var/log/5651-monitoring.log`

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

---

**🎉 10K EPS kapasitesi ile güvenli ve yüksek performanslı Log Server hazır!** 