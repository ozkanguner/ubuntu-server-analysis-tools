# ESXi - 5651 LOG SERVER OPTIMAL VM AYARLARI
## Ubuntu 22.04 LTS + 10K EPS Performance

### 🚀 VM OLUŞTURMA AYARLARI

#### 1. BASIC VM CONFIGURATION
```
VM Name: LogServer5651  ← SAFER NAME (no special characters)
Guest OS: Linux → Ubuntu Linux (64-bit)
Compatibility: ESXi 7.0 and later

🎯 ALTERNATIVE SAFE NAMES:
• LogServer5651 (recommended)
• Log5651 (short)
• SRV5651LOG (enterprise style)
• LogMaster5651 (descriptive)
```

#### 2. HARDWARE CONFIGURATION

##### CPU AYARLARI:
```
CPU: 40 vCPU ✅
Cores per Socket: 10  ← OPTIMAL (4 socket)
Sockets: 4           ← PERFORMANCE BOOST

❌ SCREENSHOT'TAKİ HATA:
• Cores per Socket: 4 ← YANLIŞ! 10 olmalı
• Sockets: 10 ← YANLIŞ! 4 olmalı  
• Reservation: None ← YANLIŞ! 32000 MHz olmalı

🎯 DOĞRU DEĞERLER:
• Cores per Socket: 10 (4 değil!)
• Sockets: 4 (10 değil!)
• Reservation: 32000 MHz
• Shares: High ✅ DOĞRU

⚠️ ÖNEMLİ CPU AYARLARI:
• CPU Hot Add: DISABLED (performance için) ✅ DOĞRU
• Memory Hot Add: DISABLED (performance için)
• Expose hardware assisted virtualization: ENABLED ✅ DOĞRU
• CPU Performance Counters: ENABLED ✅ DOĞRU
• NUMA Spanning: DISABLED (locality için)
```

##### MEMORY AYARLARI:
```
Memory: 64 GB (65536 MB)

⚠️ ÖNEMLİ MEMORY AYARLARI:
• Memory Hot Add: DISABLED
• Reserve all guest memory (All locked): ENABLED
  (Bu ayar çok önemli - memory swapping'i önler)
```

##### DISK AYARLARI:
```
Hard Disk 1: 1 TB
Provisioning: Thick Provision Eager Zeroed (performance için)
SCSI Controller: VMware Paravirtual (daha hızlı)

⚠️ ÖNEMLİ DISK AYARLARI:
• Disk Mode: Independent - Persistent ← Dependent'dan değiştirin!
• Virtual Device Node: SCSI (0:0)
• Shares: High (2000) ← Normal'den High'a çevirin!
• Limit IOPs: Unlimited
```

##### NETWORK AYARLARI:
```
Network Adapter 1: VMXNET3 (en hızlı)
Network Label: PORTAL_GROUP (production network)
Connection: Connect at Power On

⚠️ ÖNEMLİ NETWORK AYARLARI:
• Adapter Type: VMXNET3 (e1000'den çok daha hızlı) ✅ DOĞRU
• MAC Address: Automatic ✅ DOĞRU
• Connect at power on: ENABLED ✅ DOĞRU
• Shares: High (eğer görünüyorsa, 2000 yapın)
• DirectPath I/O: Enable (eğer host destekliyorsa)
```

#### 3. ADVANCED VM OPTIONS (ÇOK ÖNEMLİ!)

##### VM OPTIONS TAB:
```
Boot Options:
• Firmware: BIOS (Ubuntu için recommended)
• Boot Delay: 0 milliseconds
• Force BIOS Setup: NO

VMware Tools:
• VMware Tools time synchronization: ENABLED
• Run VMware Tools scripts: ENABLED
```

##### ADVANCED CONFIGURATION (Edit Configuration → Advanced):

**Bu parametreleri ekleyin:**
```
sched.cpu.latencySensitivity = high
numa.nodeAffinity = 0,1
sched.cpu.min = 32000
sched.mem.min = 32768
mainMem.useNamedFile = FALSE
prefvmx.useRecommendedLockedMemSize = TRUE
prefvmx.minVmMemPct = 100
isolation.tools.unity.disable = TRUE
isolation.tools.ghi.autologon.disable = TRUE
isolation.tools.hgfs.disable = TRUE
log.keepOld = 3
log.rotateSize = 1000000
ethernet0.filter4.name = dvfilter-maclearn
ethernet0.filter4.onFailure = failOpen
```

#### 4. DATASTORE PLACEMENT
```
⚠️ DATASTORE SEÇİMİ:
• En hızlı storage'a yerleştirin (SSD/NVMe preferred)
• RAID 10 configuration önerili
• Local storage > Shared storage (performance için)
```

#### 5. RESOURCE ALLOCATION

##### CPU ALLOCATION:
```
Reservation: 32000 MHz (tüm CPU'nun 80%'i)
Limit: Unlimited
Shares: High (2000)
```

##### MEMORY ALLOCATION:
```
Reservation: 61440 MB (64GB'ın 95%'i) ← MUTLAKA SET EDİN!
Limit: Unlimited  
Shares: High (2000) ← Normal'den High'a çevirin!

🚨 ÖNEMLİ: Hem "Reserve all guest memory" checkbox'ı İŞARETLİ olmalı
         HEM DE manuel reservation 61440 MB olmalı!
```

### 🎯 ESXi HOST AYARLARI

#### HOST LEVEL OPTIMIZATIONS:

##### 1. CPU POWER MANAGEMENT:
```
ESXi Shell'de çalıştırın:
esxcli hardware cpu policy set --policy=high-performance
esxcli system settings advanced set -o /Power/CpuPolicy -i 0
```

##### 2. NETWORK BUFFER OPTIMIZATION:
```
esxcli system settings advanced set -o /Net/TcpipHeapSize -i 32
esxcli system settings advanced set -o /Net/TcpipHeapMax -i 128
```

##### 3. MEMORY MANAGEMENT:
```
esxcli system settings advanced set -o /Mem/ShareForceSalting -i 2
```

### ⚙️ VM CREATION CHECKLIST

#### ✅ KURULUM ÖNCESİ KONTROL:
```
□ VM 40 vCPU allocated
□ Memory 64GB allocated ve "Reserve all guest memory" enabled
□ Disk 1TB, Thick Provision Eager Zeroed
□ Network VMXNET3 adapter
□ Advanced parameters added
□ Resource reservations set
□ Host CPU policy = high-performance
```

#### ✅ UBUNTU KURULUM AYARLARI:
```
□ Ubuntu 22.04 LTS Server
□ Minimal installation
□ SSH server enabled
□ User: logadmin
□ Hostname: logserver-new
□ Partition: Single partition (entire disk)
□ File system: ext4
```

### 🚀 KURULUM SONRASI

#### UBUNTU KURULUMU TAMAMLANDIKTAN SONRA:

1. **SSH ile bağlanın:**
```bash
ssh logadmin@<vm-ip>
```

2. **Fresh install script'ini çalıştırın:**
```bash
# Script'i VM'e transfer edin (SCP ile)
scp 5651-fresh-install-complete.sh logadmin@<vm-ip>:

# Veya wget ile (eğer dosya web'de ise)
wget <script-url> -O 5651-fresh-install-complete.sh
chmod +x 5651-fresh-install-complete.sh

# Root olarak çalıştırın
sudo ./5651-fresh-install-complete.sh
```

### 🚨 DATASTORE UPLOAD SORUNLARI

#### ESXi'da "Unknown" dosya hatası için:
```
1. Corrupted dosyayı silin
2. Proper naming convention kullanın
3. Complete upload'ı bekleyin
4. ISO dosyaları için .iso extension gerekli
5. Script dosyaları VM oluştuktan sonra upload edin
```

### 📊 EXPECTED PERFORMANCE AFTER OPTIMIZATION:

```
✅ CPU Usage: 15-25% (distributed across 40 cores)
✅ Memory Usage: 50-100MB for rsyslog process
✅ Thread Count: 20+ threads
✅ Network Latency: <1ms
✅ Disk I/O: >1000 IOPS
✅ 10K EPS: Easily handled
✅ Log Rotation: Automatic
✅ Monitoring: Real-time
```

### 🚨 KRITIK NOTLAR:

1. **"Reserve all guest memory" MUTLAKA enable olmalı** - Bu olmadan memory performance çok düşer
2. **VMXNET3 network adapter kullanın** - e1000'den 3-4x daha hızlı
3. **Thick Provision Eager Zeroed disk** - Random I/O performance için kritik
4. **Host CPU policy high-performance** olmalı
5. **VM'e 32GB+ memory reservation** yapın

### 🎯 TROUBLESHOOTING:

#### Performance düşükse kontrol edin:
```
□ Memory reservation yapıldı mı?
□ CPU latency sensitivity = high mı?
□ VMXNET3 adapter kullanılıyor mu?
□ Host CPU policy high-performance mı?
□ Disk Thick Provision mı?
```

Bu ayarlarla optimal 5651 log server elde edeceksiniz! 🚀 