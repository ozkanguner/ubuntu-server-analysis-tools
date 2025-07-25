# 🔍 Ubuntu Sunucu Analiz Araçları

Bu repository, Ubuntu sunucularının kapsamlı analizi ve 5651 Log Server performans optimizasyonu için geliştirilmiş araçları içerir.

## 📋 İçerik

### 1. `ubuntu-server-analyzer.sh`
Kapsamlı Ubuntu sunucu analiz scripti:
- **Sistem bilgileri** (CPU, RAM, Disk)
- **Ağ yapılandırması** (PPPoE, IP adresleri, routing)
- **Servis durumları** (systemd-networkd, rsyslog, SSH)
- **Firewall ve güvenlik** (UFW, açık portlar)
- **5651 Log Server analizi** (log dosyaları, performans)
- **Performans metrikleri** (CPU, bellek, disk I/O)
- **Sistem logları** (journalctl, PPPoE, rsyslog)
- **JSON formatında özet rapor**

### 2. `ubuntu-pppoe-migration.sh`
PPPoE direkt bağlantı migration scripti:
- **MikroTik NAT'tan direkt PPPoE'ye geçiş**
- **Zero NAT overhead** ile 10K EPS performansı
- **Otomatik yeniden bağlanma** ve monitoring
- **Dual interface** yapılandırması
- **Firewall optimizasyonu**

## 🚀 Kurulum ve Kullanım

### Analiz Scripti Çalıştırma

```bash
# Script'i çalıştırılabilir yapın
chmod +x ubuntu-server-analyzer.sh

# Analizi başlatın
sudo ./ubuntu-server-analyzer.sh
```

### PPPoE Migration

```bash
# Migration script'ini çalıştırılabilir yapın
chmod +x ubuntu-pppoe-migration.sh

# Migration'ı başlatın (DİKKAT: Mevcut ağ yapılandırmasını değiştirir)
sudo ./ubuntu-pppoe-migration.sh
```

## 📊 Çıktılar

### Analiz Raporu
- **Metin raporu**: `/tmp/ubuntu-server-analysis-YYYYMMDD-HHMMSS.txt`
- **JSON raporu**: `/tmp/ubuntu-server-analysis-YYYYMMDD-HHMMSS.json`

### Örnek JSON Çıktısı
```json
{
  "analysis_timestamp": "2024-01-15T10:30:00+03:00",
  "system_info": {
    "hostname": "ubuntu-server",
    "kernel": "5.15.0-91-generic",
    "architecture": "x86_64"
  },
  "hardware": {
    "cpu_cores": 8,
    "memory_total": "16G",
    "disk_usage": "45%"
  },
  "network": {
    "external_ip": "92.113.43.132",
    "pppoe_active": true
  },
  "5651_log_server": {
    "directory_exists": true,
    "log_files_count": 1250,
    "total_size": "2.5G"
  }
}
```

## 🎯 Hedefler

### Performans Optimizasyonu
- **10K EPS** (Events Per Second) kapasitesi
- **Zero NAT overhead** ile direkt ISP bağlantısı
- **Otomatik failover** ve monitoring
- **Gerçek zamanlı** performans takibi

### Güvenlik
- **UFW firewall** yapılandırması
- **SSH güvenliği** (port 22)
- **Syslog portları** (514 UDP/TCP)
- **ICMP kontrolü** (ping)

## 🔧 Sistem Gereksinimleri

- **Ubuntu 20.04+** (LTS önerilir)
- **Bash shell**
- **sudo yetkileri**
- **PPPoE bağlantısı** (migration için)
- **Minimum 4GB RAM**
- **SSD disk** (performans için)

## 📈 Monitoring ve Bakım

### Otomatik Monitoring
```bash
# PPPoE monitoring servisi
systemctl status pppoe-monitor

# Log takibi
tail -f /var/log/pppoe-monitor.log

# Performans izleme
/opt/5651-monitoring/live-stats.sh
```

### Manuel Kontroller
```bash
# PPPoE durumu
ip addr show ppp0

# Servis durumları
systemctl status systemd-networkd rsyslog ssh

# Disk kullanımı
df -h /var/5651/

# Açık portlar
ss -tulpn | grep :514
```

## 🚨 Önemli Notlar

### Migration Öncesi
- **Yedek alın**: `/backup/migration-YYYYMMDD-HHMMSS/`
- **PPPoE bilgilerini** doğrulayın
- **Ağ bağlantısını** test edin
- **Kritik servisleri** durdurun

### Güvenlik
- **Firewall kurallarını** gözden geçirin
- **SSH erişimini** koruyun
- **Log dosyalarını** düzenli temizleyin
- **Performans metriklerini** izleyin

## 🤝 Katkıda Bulunma

1. Repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Değişikliklerinizi commit edin (`git commit -am 'Yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request oluşturun

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

## 📞 Destek

- **Issues**: GitHub Issues kullanın
- **Dokümantasyon**: Bu README dosyasını inceleyin
- **Loglar**: `/var/log/pppoe-monitor.log` ve `/var/log/syslog`

---

**🎉 5651 Log Server performans optimizasyonu için geliştirilmiştir!** 