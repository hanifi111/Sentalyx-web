# SENTRALYX - KULLANICI EL KİTABI

## İÇİNDEKİLER

1. [Mimari Felsefesi](#mimari-felsefesi)
2. [Güvenlik ve Risk Yönetimi](#güvenlik-ve-risk-yönetimi)
3. [Self-Healing Sistemi](#self-healing-sistemi)
4. [Arayüz Rehberi](#arayüz-rehberi)
5. [Donanım Önerileri](#donanım-önerileri)
6. [Kurulum ve İlk Adımlar](#kurulum-ve-ilk-adımlar)
7. [İleri Seviye Konfigürasyon](#ileri-seviye-konfigürasyon)
8. [Sorun Giderme](#sorun-giderme)

---

## 🏛️ MİMARİ FELSEFESİ

### Privacy-First Tasarım Prensibi

SENTRALYX, **Sıfır Aracı Riski** (Zero Broker Risk) felsefesiyle tasarlanmıştır. Sistem, tüm kritik işlemleri ve verileri lokalde tutarak maksimum güvenlik sağlar.

#### Neden Lokal Çalışır?

**1. Veri Gizliliği Kalkanı**
- Tüm strateji verileri, indikatör ayarları ve işlem parametreleri sadece sizin makinenizde saklanır
- Hiçbir şekilde bulut veya üçüncü parti sunuculara gönderilmez
- API anahtarlarınız şifrelenerek lokal diskte korunur

**2. Strateji Güvenliği**
- Kâr stratejileriniz rakiplere veya aracı kurumlara sızdırılamaz
- Algoritmik trading mantığınız tamamen sizin kontrolünüzdedir
- Backtest sonuçları ve optimizasyon verileri gizli kalır

**3. Regülatuar Koruma**
- Yerel veri işleme, GDPR ve KVKK gibi veri koruma yasalarına tam uyum sağlar
- Finansal verileriniz uluslararası transfer riskine maruz kalmaz

#### Teknik Altyapı

**Runtime Config Mimarisi**
```
config/runtime_config.json → Tüm ayarların tek gerçek kaynağı
├── settings/          → Genel ve API ayarları
├── indicators/        → İndikatör konfigürasyonları  
├── strategies/        → Strateji tanımları
└── risk/             → Risk yönetimi parametreleri
```

**Modüler Component Yapısı**
- **core/**: İşlem motoru, pozisyon yönetimi, risk kontrolü
- **ui_qt/**: Modern Qt6 tabanlı arayüz
- **exchanges/**: Borsa bağlantı katmanı
- **strategies/**: Strateji motoru

---

## 🔒 GÜVENLİK VE RİSK YÖNETİMİ

### Server-Side Emir Yönetimi

SENTRALYX, emirlerin borsa sunucularında tutulması prensibiyle çalışır. Bu yaklaşım, internet ve elektrik kesintilerinde bile kullanıcıyı korur.

#### SL/TP Mekanizması

**Stop Loss (SL) Koruma**
```
1. Emir borsaya gönderildiğinde SL seviyesi belirlenir
2. SL emri doğrudan borsa sunucusunda saklanır  
3. İnternet kesintisi olsa bile SL aktif kalır
4. Fiyat SL seviyesine ulaştığında otomatik kapanır
```

**Take Profit (TP) Güvencesi**
```
1. TP seviyesi emirle birlikte borsaya iletilir
2. Sunucu tarafında sürekli takip edilir
3. Hedef fiyata ulaşıldığında pozisyon kapanır
4. Kesinti anında bile kâr korunur
```

#### Acil Durum Senaryoları

**İnternet Kesintisi**
- ✅ Açık pozisyonlar güvende
- ✅ SL/TP emirleri aktif  
- ✅ Risk yönetimi devam eder
- ❌ Yeni emir gönderilemez (güvenlik önlemi)

**Elektrik Kesintisi**  
- ✅ Borsadaki SL/TP koruyor
- ✅ Sistem yeniden başladığında pozisyonlar görünecek
- ✅ Raporlama ve loglama devam eder

**Borsa API Hatası**
- ✅ Yerel risk yönetimi çalışır
- ✅ Pozisyon takibi devam eder  
- ✅ Manuel müdahale mümkün

### Risk Yönetimi Katmanları

**1. Pre-Trade Validation**
```
- Bakiye kontrolü
- Risk/Oran analizi  
- Maksimum pozisyon limiti
- Cooldown kontrolü
```

**2. Real-Time Monitoring**
```
- Fiyat spike tespiti
- Stale price kontrolü
- Anomali tespiti
- P&L takibi
```

**3. Emergency Protocols**
```
- Global stop mechanism
- Force close capability  
- Circuit breaker
- Manual override
```

---

## 🔄 SELF-HEALING SİSTEMİ

### ThreadWatchdog Mimarisi

SENTRALYX, **ThreadWatchdog** sistemi ile kendi kendini iyileştirme yeteneğine sahiptir. Bu sistem, tüm kritik thread'leri 7/24 izler ve otomatik olarak yeniden başlatır.

#### İzleme Mekanizması

**Thread Health Monitoring**
```python
class ThreadWatchdog:
    def __init__(self):
        self.monitored_threads = {}      # İzlenen thread'ler
        self.thread_health = {}          # Sağlık durumu
        self.check_interval = 30s       # Kontrol aralığı
        self.max_restart_attempts = 3   # Maksimum restart
```

**Heartbeat Kontrolü**
- Scanner thread'i için özel heartbeat sistemi
- 60 saniye veri gelmezse "frozen" alarmı
- Otomatik kullanıcı uyarısı ve güvenli durdurma

#### Kurtarma Süreci

**Otomatik Restart Logic**
```
1. Thread durumu kontrol edilir (30sn arayla)
2. Çökmüş thread tespit edilirse
3. Restart fonksiyonu çağrılır  
4. Maksimum 3 deneme hakkı
5. Başarısız olursa kullanıcıya bildirim
```

**State-Safe Restart**
- Pozisyon verileri korur
- Strateji durumunu muhafaza eder
- Risk yönetimi parametrelerini saklar

### Rate-Limit Retry Sistemi

**API Rate Limit Handling**
```python
# Akıllı bekleme mekanizması
retry_delays = [1s, 2s, 4s, 8s, 16s, 32s]  # Exponential backoff
max_retries = 5
```

**Bağlantı Kurtarma**
- Network timeout tespiti
- Otomatik reconnection
- Fallback exchange bağlantısı
- Graceful degradation

---

## 🖥️ ARAYÜZ REHBERİ

### Ana Sekmeler ve Fonksiyonları

#### 1. TARAMA SEKMESİ

**Ana Panel**
```
┌─ STRATEJİ SEÇİMİ ─────────────────────┐
│ ▼ Mevcut Strateji: RSI_MACD_HYBRID    │
│ 📊 Strateji Açıklaması:               │
│ - RSI oversold/overbought sinyalleri │  
│ - MACD crossover doğrulaması         │
│ - Multi-timeframe uyumu               │
└───────────────────────────────────────┘
```

**Parametreler**
- **Scan Interval**: Tarama sıklığı (5-60 saniye)
- **Timeframe**: Zaman dilimi (1m, 5m, 15m, 1h, 4h)
- **Symbols**: Taranacak semboller (manuel/otomatik)
- **Auto Trade**: Otomatik işlem aç/kapa

**Sinyal Tablosu**
```
│ Sembol    │ Fiyat   │ Sinyal │ Güç │ Zaman      │
│ BTCUSDT   │ 67500   │ BUY    │ 85% │ 14:32:15   │
│ ETHUSDT   │ 3400    │ SELL   │ 92% │ 14:32:12   │
```

**Log Paneli**
- Gerçek zamanlı işlem logları
- [UI_LOG] etiketli önemli mesajlar
- Pozisyon açılış/kapanış bildirimleri

#### 2. AÇIK POZİSYONLAR SEKMESİ

**Pozisyon Özeti**
```
┌─ TOPLAM DURUM ───────────────────────┐
│ Açık Pozisyon: 3                     │
│ Toplam P&L: +$125.50 (+2.1%)         │
│ Risk Marjı: 15%                      │
└───────────────────────────────────────┘
```

**Pozisyon Detayları**
```
│ Sembol   │ Tip   │ Giriş    │ Mevcut  │ P&L    │ SL     │ TP     │
│ BTCUSDT  │ BUY   │ 67000    │ 67500   │ +0.7%  │ 65000  │ 69000  │
│ ETHUSDT  │ SELL  │ 3450     │ 3400    │ +1.4%  │ 3500   │ 3300   │
```

**Manuel Kontroller**
- **Close Position**: Anında pozisyon kapatma
- **Modify SL/TP**: Stop-loss ve take-profit düzenleme
- **Partial Close**: Kısmi kâr realizasyonu

#### 3. KAPALI POZİSYONLAR SEKMESİ

**Performans Analizi**
```
┌─ GÜNLÜK RAPOR ───────────────────────┐
│ Kapanan Pozisyon: 12                  │
│ Toplam Kâr: $456.80                   │
│ Win Rate: 68.5%                       │
│ Ort. Kâr: $38.07                      │
└───────────────────────────────────────┘
```

**Geçmiş Tablosu**
```
│ Tarih      │ Sembol │ Tip │ Giriş │ Çıkış │ P&L    │ Sebep     │
│ 05.01.2024 │ BTC   │ BUY │ 66000 │ 68000 │ +3.0% │ TAKE_PROFIT│
│ 05.01.2024 │ ETH   │ SELL│ 3500  │ 3400  │ +2.8% │ STOP_LOSS │
```

#### 4. RAPORLAR SEKMESİ

**Analitik Grafikler**
- P&L eğrisi
- Win/loss dağılımı  
- Risk-return analizi
- Strateji performansı

**Export Özellikleri**
- CSV export
- PDF rapor
- Excel formatı

#### 5. AYARLAR SEKMESİ

**API Ayarları**
```
┌─ EXCHANGE BAĞLANTISI ─────────────────┐
│ Exchange: [Binance ▼]                 │
│ API Key: [••••••••••••••••••••••••••] │
│ Secret:   [••••••••••••••••••••••••••] │
│ Mode:     [Demo ▼]                    │
│ Testnet:  [☑] Aktif                  │
└───────────────────────────────────────┘
```

**Risk Parametreleri**
```
┌─ RİSK YÖNETİMİ ───────────────────────┐
│ Stop Loss:     [2.0%  ▲▼]              │
│ Take Profit:   [5.0%  ▲▼]              │
│ Max Duration:  [240dk ▲▼]              │
│ Daily Loss:    [$500 ▲▼]              │
│ Position Size: [10%   ▲▼]              │
└───────────────────────────────────────┘
```

**Genel Ayarlar**
- Tema seçimi (Dark/Light)
- Log seviyesi
- Bildirimler
- Otomatik kaydetme

#### 6. İNDİKATÖR AYARLARI SEKMESİ

**RSI Konfigürasyonu**
```
┌─ RSI (Relative Strength Index) ────────┐
│ Enabled: [☑]                           │
│ Length:  [14 ▲▼]                       │
│ Buy Level:  [<30 ▲▼]                   │
│ Sell Level: [>70 ▲▼]                   │
│ Weight:   [1.0 ▲▼]                     │
└───────────────────────────────────────┘
```

**MACD Ayarları**
```
┌─ MACD (Moving Average Convergence) ───┐
│ Enabled: [☑]                           │
│ Fast EMA: [12 ▲▼]                      │
│ Slow EMA: [26 ▲▼]                      │
│ Signal:   [9 ▲▼]                       │
│ Weight:   [1.5 ▲▼]                     │
└───────────────────────────────────────┘
```

**Diğer İndikatörler**
- Bollinger Bands
- Stochastic Oscillator  
- Volume Profile
- Moving Averages

#### 7. STRATEJİLER SEKMESİ

**Strateji Seçimi**
```
┌─ MEVCUT STRATEJİLER ───────────────────┐
│ ☑ RSI_MACD_HYBRID                      │
│ ☐ TREND_FOLLOWING                     │
│ ☐ MEAN_REVERSION                       │
│ ☐ BREAKOUT_SCALPING                   │
│ ☐ CUSTOM_STRATEGY_1                   │
└───────────────────────────────────────┘
```

**Strateji Detayları**
- Giriş/çıkış kuralları
- Zaman dilimi uyumu
- Risk parametreleri
- Backtest sonuçları

---

## 💻 DONANIM ÖNERİLERİ

### Minimum Sistem Gereksinimleri

**İşlemci**
- Intel i5 8.nesil veya üstü
- AMD Ryzen 5 3000 serisi veya üstü
- 4+ çekirdek, 2.5GHz+ hız

**Bellek**
- Minimum: 8GB RAM
- Tavsiye: 16GB RAM
- Optimum: 32GB RAM (çoklu strateji için)

**Depolama**
- SSD zorunlu (HDD kabul edilmez)
- Minimum: 50GB boş alan
- Tavsiye: NVMe SSD

**Ağ Bağlantısı**
- Kablo bağlantı (WiFi önerilmez)
- Minimum: 10Mbps download/upload
- Tavsiye: 100Mbps+ fiber

### Stabilite için Zorunlu Donanımlar

#### 1. STATİK IP ADRESİ

**Neden Gerekli?**
- API bağlantı kesintilerini önler
- IP değişiminden kaynaklanan hataları engeller
- Borsa rate limit'leri daha stabil çalışır

**Yapılandırma**
```
Router → DHCP Reservation → SENTRALYX Makinesi
IP: 192.168.1.100 (sabit)
Gateway: 192.168.1.1  
DNS: 8.8.8.8, 8.8.4.4
```

#### 2. UPS (Kesintisiz Güç Kaynağı)

**Minimum Özellikler**
- 1500VA / 900W kapasite
- 15+ dakika çalışma süresi
- Otomatik kapanma desteği

**Kurulum**
```
Bilgisayar → UPS → Priz
USB bağlantısı → Otomatik kapanma yazılımı
```

**Avantajları**
- Elektrik kesintisinde pozisyonlar güvende
- SL/TP emirleri aktif kalır
- Sistem düzgün kapanır

#### 3. Ağ Optimizasyonu

**QoS Ayarları**
```
Router QoS → SENTRALYX IP'si → High Priority
Port: 443 (HTTPS), 9243 (Binance WebSocket)
```

**Firewall Kuralları**
```
Gelen: Kapalı (güvenlik için)
Giden: 443, 9243 açık
```

### İleri Seviye Donanım Konfigürasyonu

**Trading Sunucusu Setup**
```
CPU: Intel i7/i9 Xeon serisi
RAM: 64GB ECC RAM
SSD: 2x NVMe RAID-1
Network: 2x Ethernet (failover)
UPS: 3000VA Online UPS
```

**Yedekleme Sistemi**
```
Ana Sistem → Yedek Sunucu (heartbeat)
Otomatik failover (5sn içinde)
Veri senkronizasyonu (real-time)
```

---

## 🚀 KURULUM VE İLK ADIMLAR

### Lisans Aktivasyonu

**1. HWID Tespiti**
- Uygulama ilk çalıştığında otomatik HWID oluşturulur
- Donanım değişikliğinde yeni HWID gerekir

**2. Lisans Talebi**
```
HWID: ABC123-XYZ789-DEF456
Telegram: @sentralyx_bot
Mesaj: HWID:ABC123-XYZ789-DEF456
```

**3. Lisans Yükleme**
- Lisans dosyasını `license.lic` olarak kaydedin
- Uygulamayı yeniden başlatın

### İlk Konfigürasyon

**1. API Ayarları**
```
Settings → API → Exchange: Binance
API Key: [Binance API Key]
Secret: [Binance Secret Key]
Mode: Demo (öğrenme için)
Testnet: ☑ (demo için)
```

**2. Risk Parametreleri**
```
Settings → Risk
Stop Loss: 2.0%
Take Profit: 5.0%  
Max Duration: 240 dakika
Daily Loss Limit: $500
Position Size: 10%
```

**3. Strateji Seçimi**
```
Strategies → RSI_MACD_HYBRID
Timeframe: 15M
Symbols: BTCUSDT, ETHUSDT, BNBUSDT
Auto Trade: ❌ (ilk başta)
```

### Test ve Doğrulama

**1. Bağlantı Testi**
```
Settings → Test Connection
✅ API Connected
✅ Market Data Available  
✅ Account Info Loaded
```

**2. Strateji Testi**
```
Scanner → Start Scanner (no auto-trade)
Sinyalleri gözlemleyin
Performansı analiz edin
```

**3. Demo Trading**
```
Scanner → Enable Auto-Trade
Küçük position size ile başlayın
Sonuçları takip edin
```

---

## ⚙️ İLERİ SEVİYE KONFİGÜRASYON

### Runtime Config Yapılandırması

**runtime_config.json Detayları**
```json
{
  "settings": {
    "api": {
      "execution_mode": "virtual|real",
      "trade_mode": "spot|full_futures|hybrid",
      "leverage": "1x|2x|3x|5x|10x"
    },
    "risk": {
      "stop_loss_percent": 2.0,
      "take_profit_percent": 5.0,
      "daily_loss_usdt": 500,
      "max_duration_minutes": 240,
      "price_spike_diff_ratio_max": 0.10,
      "partial_take_profit": {
        "trigger_percent": 50,
        "sell_ratio": 0.5
      }
    }
  }
}
```

### İndikatör Optimizasyonu

**Multi-Timeframe Setup**
```json
{
  "indicators": {
    "rsi": {
      "enabled": true,
      "timeframes": ["15m", "1h", "4h"],
      "params": {
        "length": {"value": 14}
      },
      "logic": {
        "type": "threshold",
        "rules": [
          {
            "action": "BUY",
            "conditions": [
              {"var": "value", "op": "<", "val": 30}
            ]
          }
        ]
      }
    }
  }
}
```

### Strateji Geliştirme

**Custom Strategy Structure**
```python
class CustomStrategy:
    def __init__(self, indicators, settings):
        self.rsi = indicators.get('rsi')
        self.macd = indicators.get('macd')
        
    def generate_signal(self, market_data):
        rsi_value = self.rsi.calculate(market_data)
        macd_signal = self.macd.calculate(market_data)
        
        if rsi_value < 30 and macd_signal > 0:
            return "BUY", 0.8
        elif rsi_value > 70 and macd_signal < 0:
            return "SELL", 0.8
        return "HOLD", 0.0
```

---

## 🔧 SORUN GİDERME

### Yaygın Sorunlar ve Çözümleri

**1. API Bağlantı Hatası**
```
Sorun: "API connection failed"
Çözüm: 
- API key/secret kontrolü
- Network bağlantısı testi
- IP whitelist kontrolü
- Rate limit bekleme
```

**2. Scanner Çalışmıyor**
```
Sorun: "Scanner frozen"
Çözüm:
- ThreadWatchdog log kontrolü
- Market data bağlantısı
- Strateji konfigürasyonu
- Restart manuel
```

**3. Pozisyon Güncellenmiyor**
```
Sorun: "Position not updating"
Çözüm:
- Exchange connector kontrolü
- WebSocket bağlantısı
- Position manager restart
```

**4. SL/TP Çalışmıyor**
```
Sorun: "Stop loss not triggered"
Çözüm:
- Borsa API kontrolü
- Emir tipi doğrulama
- Fiyat precision
- Minimum not kontrolü
```

### Log Analizi

**Kritik Log Dosyaları**
```
logs/app.log           → Ana uygulama logları
logs/scanner.log       → Scanner logları  
logs/trades.log        → İşlem kayıtları
logs/error.log         → Hata raporları
```

**Log Pattern'leri**
```
[WATCHDOG] Thread monitoring started
[ERROR] Exchange connection failed
[UI_LOG] POZİSYON AÇILDI: BTCUSDT
[CRITICAL] Scanner dondu (heartbeat yok)
```

### Performans Optimizasyonu

**Memory Management**
```python
# Python memory optimization
import gc
gc.collect()  # Garbage collection

# Position cache cleanup
position_manager.cleanup_expired_positions()
```

**Database Optimization**
```sql
-- SQLite optimization
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = 10000;
```

### Emergency Procedures

**Global Stop**
```
1. Scanner → Stop Scanner
2. Auto Trade → Disable  
3. Settings → Emergency Stop
4. All positions → Close (manuel)
```

**System Recovery**
```
1. Application restart
2. Config validation
3. License check
4. API reconnection
5. Strategy reload
```

---

## 📞 DESTEK VE İLETİŞİM

### Teknik Destek
- **Telegram**: @sentralyx_bot
- **Lisans**: HWID üzerinden talep
- **Acil Durum**: Emergency procedures manual

### Dokümantasyon
- **API Reference**: exchanges/README.md
- **Strategy Guide**: strategies/README.md  
- **Troubleshooting**: docs/troubleshooting.md

### Community
- **Telegram Grup**: Sentralyx Users
- **GitHub**: Issues ve discussions
- **Updates**: Release notes

---

**© 2024 SENTRALYX Trading Terminal - Tüm hakları saklıdır.**

*Bu el kitabı, SENTRALYX'in tüm özelliklerini kapsamlı şekilde açıklamak için tasarlanmıştır. Herhangi bir sorunuz veya öneriniz olduğunda lütfen destek kanallarımızla iletişime geçin.*

---

**⚠️ RİSK UYARISI**: Kripto para trading'i yüksek risk içerir. Bu yazılım yatırım tavsiyesi niteliğinde değildir. Kaybedebileceğiniz miktarla işlem yapın.
