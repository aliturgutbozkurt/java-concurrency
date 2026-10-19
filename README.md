# ⚡ Aptala Anlatır Gibi: MAANG Java Concurrency & Multithreading Masterclass
### *Explain Like I'm 5 (ELI5): Modern Java 25 LTS, Project Loom Virtual Threads, JMM & Lock-Free Architecture*

[![Java 25 LTS](https://img.shields.io/badge/Java-25%20LTS-orange.svg?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Project Loom](https://img.shields.io/badge/Project%20Loom-Virtual%20Threads-blue.svg)](https://openjdk.org/projects/loom/)
[![Typst 0.15+](https://img.shields.io/badge/Compiled%20With-Typst-239dad.svg)](https://typst.app/)
[![Bilingual](https://img.shields.io/badge/Language-Turkish%20%7C%20English-emerald.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Projenin Amacı / Executive Summary

Bu proje; **Meta, Amazon, Apple, Netflix, Google (MAANG / FAANG)**, Tier-1 teknoloji şirketleri ve yüksek frekanslı finans (**HFT / FinTech**) firmalarının **Senior, Staff ve Principal Yazılım Mühendisi** mülakatlarına hazırlanan mühendisler için tasarlanmış **60 derslik, 10 bölümlük, çift dilli (Türkçe 🇹🇷 ve İngilizce 🇬🇧)** kapsamlı bir başvuru kaynağıdır.

Klasik Java kitaplarının aksine bu müfredat; karmaşık teorik kavramları **"Bir Aptala Anlatır Gibi" (ELI5)** yalın analojiler, **ASCII bellek ve thread durum akış şemaları**, HotSpot JVM iç mekanizmaları ve **Modern Java 25 LTS** kod örnekleriyle sunar.

---

## 📦 Proje Çıktıları ve Dağıtım / Deliverables

1. **71 Yayın Kalitesinde PDF Kitapçığı:**
   - 📖 **1 Master Mega-Kitap (`output/book/Java_Concurrency_MAANG_ELI5.pdf` - 2.7 MB):** Tüm 60 ders, 10 bölüm, önsöz, içindekiler ve mezuniyet sertifikası içeren tek ciltlik başucu eseri.
   - 📦 **10 Bölüm Paketi (`output/modules/module_01.pdf` ... `module_10.pdf`):** Her bölümün 6 dersini bir arada toplayan modüler PDF fasikülleri.
   - 📄 **60 Tekil Ders PDF'i (`output/individual/lesson_01.pdf` ... `lesson_60.pdf`):** Her konuyu bağımsız çalışmak için hazırlanmış tekil ders notları.
2. **🌐 İnteraktif Web Companion Reader (`web/`):**
   - Anlık arama (Live search), modül filtreleme, dil değiştirici (🌐 İkisi / 🇹🇷 TR / 🇬🇧 EN), tek tıkla kod kopyalama ve PDF indirme modalı.
   - Hem HTTP sunucu hem de çift tıklamayla `file:///` protokolü üzerinden tamamen çevrimdışı (offline) çalışabilir.
3. **💻 Çalıştırılabilir Java 25 LTS Referans Projeleri (`examples/`):**
   - `LruCacheDemo.java`: $O(1)$ Thread-Safe LRU Cache.
   - `DisruptorRingBufferDemo.java`: LMAX Disruptor tarzı Kilit-Siz RingBuffer (5.7 Milyon ops/sn!).
   - `TokenBucketRateLimiterDemo.java`: CAS tabanlı Tembel Doldurmalı Hız Sınırlayıcı.
   - `VirtualThreadStructuredScopeDemo.java`: Java 25 Yapısal Eşzamanlılık (`StructuredTaskScope.open()`).

---

## 🗺️ Müfredat Haritası (10 Bölüm • 60 Ders)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│             MAANG JAVA CONCURRENCY & MULTITHREADING 60-LESSON MAP           │
└─────────────────────────────────────────────────────────────────────────────┘
  BÖLÜM 1: Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri (Ders 1-6)
  BÖLÜM 2: Volatile, Atomiklik & Bellek Bariyerleri (Ders 7-12)
  BÖLÜM 3: Klasik Senkronizasyon, Monitörler & Kilitler (Ders 13-18)
  BÖLÜM 4: İleri Düzey Senkronizasyon & Kilit-Siz Araçlar (Ders 19-24)
  BÖLÜM 5: Thread Havuzları, Executor'lar & Work-Stealing (Ders 25-30)
  BÖLÜM 6: Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları (Ders 31-36)
  BÖLÜM 7: Asenkron Boru Hatları & CompletableFuture (Ders 37-42)
  BÖLÜM 8: Project Loom & Sanal Thread'ler (Virtual Threads) (Ders 43-48)
  BÖLÜM 9: Eşzamanlılık Hataları, Teşhis & Düşük Seviyeli Primitifler (Ders 49-54)
  BÖLÜM 10: MAANG Eşzamanlılık Mülakatı & Sistem Tasarımı Ustalığı (Ders 55-60)
```

### Bölüm Detayları

#### Bölüm 1: Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri
- **Ders 01:** İşlem (Process) vs İş Parçacığı (Thread): OS Çekirdeği, PCB & TCB
- **Ders 02:** Java Thread Yaşam Döngüsü: 6 Çekirdek Durum (NEW, RUNNABLE, BLOCKED, WAITING, TIMED_WAITING, TERMINATED)
- **Ders 03:** Donanım Mimarisi: CPU Önbellekleri (L1/L2/L3), Store Buffer & Sahte Paylaşım (False Sharing)
- **Ders 04:** Java Bellek Modeli (JMM) & Happens-Before İlkesi: Görünürlük Garantileri
- **Ders 05:** Komut Yeniden Sıralaması (Instruction Reordering) & As-If-Serial Kuralı
- **Ders 06:** Thread Oluşturma Yolları: Thread.Builder vs Lambda vs Callable & Java 25

#### Bölüm 2: Volatile, Atomiklik & Bellek Bariyerleri
- **Ders 07:** Volatile vs Atomiklik: Görünürlük Yeterli midir? (count++ Tuzağı)
- **Ders 08:** Donanımsal Bellek Bariyerleri: StoreLoad, StoreStore, LoadLoad & LoadStore Fences
- **Ders 09:** Piggybacking on Volatile: Görünürlük Etkilerini Sırtlama Deseni
- **Ders 10:** Double-Checked Locking (DCL) & Singleton Tuzağı: Neden volatile Şarttır?
- **Ders 11:** AtomicInteger, AtomicLong & Donanımsal CAS (Compare-And-Swap / CMPXCHG)
- **Ders 12:** Striped64 Mimarisi: LongAdder vs AtomicLong Çekişme Analizi

#### Bölüm 3: Klasik Senkronizasyon, Monitörler & Kilitler
- **Ders 13:** synchronized Derinliği: Nesne Monitörleri, monitorenter & monitorexit
- **Ders 14:** HotSpot Kilit Şişmesi: Biased Lock, Lightweight Lock & Heavyweight OS Kilitleri
- **Ders 15:** wait(), notify(), notifyAll() İç Mekanizması & Kaçırılan Sinyaller (Missed Signals)
- **Ders 16:** ReentrantLock Mimarisi: Adil (Fair) vs Adil Olmayan (Non-Fair) Kilitler
- **Ders 17:** Condition Değişkenleri: Çoklu Bekleme Kuyrukları (notFull & notEmpty)
- **Ders 18:** ReentrantReadWriteLock: Okuma/Yazma Ayrımı, Kilit İndirme & Yükseltme Yasakları

#### Bölüm 4: İleri Düzey Senkronizasyon & Kilit-Siz Araçlar
- **Ders 19:** StampedLock: İyimser Okuma (Optimistic Reading) & Validasyon Döngüsü
- **Ders 20:** CountDownLatch: Tek Seferlik Geri Sayım & Dağıtık Başlatma Kapıları
- **Ders 21:** CyclicBarrier: Yeniden Kullanılabilir Buluşma Noktaları & Bariyer Eylemleri
- **Ders 22:** Semaphore: İzin Tabanlı Havuzlama & Backpressure Akış Kontrolü
- **Ders 23:** Exchanger: İki Thread Arasında Sıfır Kopyalı Çift Değişimi
- **Ders 24:** Phaser: Dinamik Katılımcılı & Çok Fazlı Eşzamanlılık Koordinasyonu

#### Bölüm 5: Thread Havuzları, Executor'lar & Work-Stealing
- **Ders 25:** ThreadPoolExecutor İç Mimarisi: CorePool, MaxPool & Kuyruk Büyüme Kuralları
- **Ders 26:** 4 Reddetme Politikası (Abort, CallerRuns, Discard, DiscardOldest)
- **Ders 27:** Executors Fabrikası Tuzakları: newFixedThreadPool OOM & Unbounded Queue Tehlikesi
- **Ders 28:** ScheduledThreadPoolExecutor: Gecikmeli Görevler, Sessiz Ölüm & İstisna Yutulması
- **Ders 29:** Fork/Join Çerçevesi & Work-Stealing Algoritması: Çift Uçlu Deque Dinamikleri
- **Ders 30:** Thread Havuzu Kapatma Sanatı: İki Aşamalı Kapatma & Poison Pill Deseni

#### Bölüm 6: Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları
- **Ders 31:** ConcurrentHashMap İç Mimarisi: Node CAS, Kova Kilitleri & TreeBin
- **Ders 32:** CopyOnWriteArrayList: Anlık Görüntü (Snapshot) İterasyonu & Ağır Yazma Bedeli
- **Ders 33:** Bloklayıcı Kuyruklar: ArrayBlockingQueue vs LinkedBlockingQueue vs PriorityBlockingQueue
- **Ders 34:** SynchronousQueue vs LinkedTransferQueue: Sıfır Kapasiteli El Sıkışma
- **Ders 35:** Lock-Free ConcurrentLinkedQueue: Michael-Scott CAS Algoritması
- **Ders 36:** ConcurrentSkipListMap: Kilit-Siz Sıralı Ağaçlar & William Pugh Atlamalı Listeleri

#### Bölüm 7: Asenkron Boru Hatları & CompletableFuture
- **Ders 37:** Future vs CompletableFuture: Polling Kâbusundan Reaktif İtmeye Geçiş
- **Ders 38:** Dönüşüm Boru Hatları: thenApply vs thenAccept vs thenRun & Thread Havuzu Geçişleri
- **Ders 39:** Bileşim ve Birleştirme: thenCompose (FlatMap) vs thenCombine (Zip)
- **Ders 40:** Fan-Out & Fan-In Orkestrasyonu: CompletableFuture.allOf vs anyOf
- **Ders 41:** Hata Kurtarma Zincirleri: exceptionally vs handle vs whenComplete
- **Ders 42:** Zaman Aşımı ve Varsayılanlar: orTimeout() vs completeOnTimeout()

#### Bölüm 8: Project Loom & Sanal Thread'ler (Virtual Threads)
- **Ders 43:** Platform Thread vs Sanal Thread: M:N Mimarisi & Milyonlarca Eşzamanlı İş Parçacığı
- **Ders 44:** Carrier Thread, Mounting & Unmounting: Loom Non-Blocking I/O ile Nasıl Park Eder?
- **Ders 45:** Pinning Tehlikesi: synchronized vs ReentrantLock & Native Kod Tuzakları
- **Ders 46:** ThreadLocal Tehlikeleri: Sanal Thread Dünyasında Milyonluk Bellek Patlaması
- **Ders 47:** Structured Concurrency: StructuredTaskScope ile Kaotik Thread'leri Hizaya Sokma
- **Ders 48:** ScopedValue Devrimi: Java 25 ile Değişmez, Miras Alınabilir & Sıfır Bellek Bağlamı

#### Bölüm 9: Eşzamanlılık Hataları, Teşhis & Düşük Seviyeli Primitifler
- **Ders 49:** Klasik Yarış Durumları (Race Conditions): Check-Then-Act ve Read-Modify-Write
- **Ders 50:** Deadlock Forenziği: Coffman Koşulları, Kilit Sıralaması & ThreadMXBean
- **Ders 51:** Livelock, Thread Starvation & Priority Inversion: Sessiz Katiller
- **Ders 52:** ABA Problemi & Damgalı Referanslar: AtomicStampedReference vs MarkableReference
- **Ders 53:** Production Thread Dump Analizi: jstack, jcmd, Thread Durumları & CPU Tavanlarını Teşhis
- **Ders 54:** VarHandle & Düşük Seviyeli Bellek Çitleri: Modern Java'da Unsafe'in Yerine Geçiş

#### Bölüm 10: MAANG Eşzamanlılık Mülakatı & Sistem Tasarımı Ustalığı
- **Ders 55:** MAANG Vaka 1: Thread-Safe O(1) LRU Cache Mimarisi (ReentrantReadWriteLock + Çift Bağlı Liste)
- **Ders 56:** MAANG Vaka 2: LMAX Disruptor Deseni & Lock-Free RingBuffer ile Ultra-Düşük Gecikme
- **Ders 57:** MAANG Vaka 3: Dağıtık Token-Bucket & Leaky-Bucket Hız Sınırlayıcı (Rate Limiter)
- **Ders 58:** MAANG Vaka 4: HikariCP FastPath Bağlantı Havuzu Mekaniği (ConcurrentBag & ThreadLocal Handoff)
- **Ders 59:** Eşzamanlılık Beyaz Tahta Planı: 45 Dakikalık MAANG Mülakat Yönetim Stratejisi
- **Ders 60:** Staff+ Concurrency Mimarı: Canlı Sistem Çöküş Otopsisi & Çok Çekirdekli Ayarlar

---

## 🛠️ Kurulum ve Çalıştırma / Getting Started

### 1. Gereksinimler
- **Java 25 LTS** (veya Java 21+): [OpenJDK](https://jdk.java.net/25/)
- **Python 3.10+**
- **Typst CLI 0.15+**: `brew install typst` (PDF derlemesi için)

### 2. Kod Örneklerini Çalıştırma
```bash
# 1. Thread-Safe O(1) LRU Cache
java examples/LruCacheDemo.java

# 2. LMAX Disruptor Lock-Free RingBuffer (5.7M ops/sec)
java examples/DisruptorRingBufferDemo.java

# 3. Lock-Free Atomic Token Bucket Rate Limiter
java examples/TokenBucketRateLimiterDemo.java

# 4. Java 25 Yapısal Eşzamanlılık (Project Loom StructuredTaskScope)
java --enable-preview examples/VirtualThreadStructuredScopeDemo.java
```

### 3. Tüm PDF'leri Sıfırdan Derleme
```bash
# Sadece dosyaları oluştur ve web JSON'unu dışa aktar
python3 build_all.py --gen-only

# Tüm 71 PDF'i (Master Kitap + 10 Modül + 60 Ders) derle
python3 build_all.py --all
```

### 4. Web Companion Reader'ı Başlatma
```bash
# Yerel HTTP sunucusu ile başlat (Önerilen port: 4597)
python3 -m http.server 4597

# Tarayıcınızda açın:
# http://localhost:4597/web/index.html
```
*(Ayrıca `web/index.html` dosyasına çift tıklayarak doğrudan herhangi bir tarayıcıda çevrimdışı olarak da inceleyebilirsiniz).*

---

## 📄 Lisans / License

Bu proje açık kaynaklıdır ve [MIT Lisansı](LICENSE) kapsamında sunulmaktadır.
Eğitim, mülakat hazırlığı ve ticari projelerde referans mimari olarak serbestçe kullanılabilir.
