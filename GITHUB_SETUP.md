# 🚀 GitHub Repository Kurulum Talimatları

## 📋 Adım Adım Kurulum

### 1. GitHub'da Yeni Repository Oluşturma

1. **GitHub.com**'a gidin ve hesabınıza giriş yapın
2. **"New repository"** butonuna tıklayın
3. Repository adını girin: `ubuntu-server-analysis-tools`
4. Açıklama ekleyin: `Ubuntu sunucu analizi ve 5651 Log Server performans optimizasyonu araçları`
5. **Public** seçin
6. **"Create repository"** butonuna tıklayın

### 2. Remote Repository Ekleme

Repository oluşturduktan sonra, aşağıdaki komutları çalıştırın:

```bash
# Remote repository ekleyin (USERNAME kısmını kendi kullanıcı adınızla değiştirin)
git remote add origin https://github.com/USERNAME/ubuntu-server-analysis-tools.git

# Main branch'i ayarlayın
git branch -M main

# Dosyaları push edin
git push -u origin main
```

### 3. Alternatif: SSH ile Bağlanma

SSH key'iniz varsa:

```bash
# SSH remote ekleyin
git remote add origin git@github.com:USERNAME/ubuntu-server-analysis-tools.git

# Push edin
git push -u origin main
```

## 📁 Repository İçeriği

Bu repository şu dosyaları içerir:

- ✅ `ubuntu-server-analyzer.sh` - Kapsamlı sunucu analiz scripti
- ✅ `ubuntu-pppoe-migration.sh` - PPPoE migration scripti
- ✅ `README.md` - Detaylı dokümantasyon
- ✅ `LICENSE` - MIT lisansı
- ✅ `.gitignore` - Git ignore kuralları

## 🔧 Sonraki Adımlar

1. **Repository'yi test edin**: README.md dosyasını kontrol edin
2. **Issues açın**: Geliştirme önerileri için
3. **Releases oluşturun**: Versiyon yönetimi için
4. **Wiki ekleyin**: Ek dokümantasyon için

## 📞 Destek

Herhangi bir sorun yaşarsanız:
- GitHub Issues kullanın
- README.md dosyasını inceleyin
- Script'lerdeki yorumları okuyun

---

**🎉 Repository başarıyla oluşturuldu!** 