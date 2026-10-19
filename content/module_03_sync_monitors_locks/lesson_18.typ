#import "/template.typ": *

#show: doc => setup_book(title: "Ders 18: ReentrantReadWriteLock: Okuma Yoğun Sistemler & Kilit Düşürme (Lock Downgrading)", doc)

#lesson_header(
  18,
  "ReentrantReadWriteLock: Okuma Yoğun Sistemler & Kilit Düşürme (Lock Downgrading)",
  "ReentrantReadWriteLock: Read-Intensive Scaling & Lock Downgrading Mechanics",
  "Klasik Senkronizasyon, Monitörler & Kilitler",
  "Classical Synchronization, Monitors & Locks"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 REENTRANTREADWRITELOCK: PAYLAŞIMLI vs ÖZEL KİLİT            │
└─────────────────────────────────────────────────────────────────────────────┘
  OKUMA KİLİDİ (ReadLock - Shared):
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ Thread 1 │  │ Thread 2 │  │ Thread 3 │ ──▶ AYNI ANDA BİNLERCE THREAD OKUYABİLİR!
  └──────────┘  └──────────┘  └──────────┘
  
  YAZMA KİLİDİ (WriteLock - Exclusive / Mutex):
  ┌──────────┐
  │ Thread W │ ──▶ SADECE TEK BİR THREAD YAZABİLİR! (Tüm okuyucular bloke edilir)
  └──────────┘

  LOCK DOWNGRADING (Kilit Düşürme):
  WriteLock AL ──▶ Veriyi Güncelle ──▶ ReadLock AL ──▶ WriteLock BIRAK ──▶ Okumaya Devam Et!
  (Veri tutarlılığını kaybetmeden güvenli kilit seviyesi düşürme)
  
  ⚠️ DİKKAT: Lock Upgrading (Okumadan Yazmaya Geçiş) DESTEKLENMEZ! (Deadlock Yaratır!)
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir kütüphanedeki büyük ansiklopedi düşünün. Aynı anda 100 öğrenci gelip ansiklopediyi sessizce okuyabilir (Okuma Kilidi / ReadLock); kimse kimseyi engellemez. Ama ansiklopedideki hatalı bir sayfayı yırtıp yenisini yapıştıracak olan matbaacı (Yazma Kilidi / WriteLock) geldiğinde, kütüphanedeki bütün öğrencileri dışarı çıkartır ve kapıyı kilitler! İşini bitirince kapıyı açar ve öğrenciler tekrar içeri dolar. Okuma çok, yazma azsa sistem roket gibi hızlanır!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Imagine a public stock ticker display. Thousands of traders can stare at the display concurrently without interfering with one another (Shared Read Lock). However, when the exchange operator updates the asset prices (Exclusive Write Lock), everyone must pause until the prices settle. If 99% of requests are reads and 1% are writes, a ReadWriteLock boosts concurrency a thousandfold compared to a blunt mutex!]
    ]
  )
]

#deep_dive_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("334155"), size: 9pt)[🇹🇷 MAANG DERİNLEMESİNE ANALİZ]\
      #v(3pt)
      ReadWriteLock Mimarisi ve Kilit Düşürme Kuralları: 1) Durum Yönetimi (State Split): AQS'in 32-bitlik tek `state` tamsayısı ikiye bölünür: Üst 16 bit okuma kilidi sayısını (Shared count), alt 16 bit ise yazma kilidi sayısını (Exclusive count) tutar. 2) Lock Downgrading (Kilit Düşürme): Yazma kilidini tutarken önce okuma kilidi alınır, ardından yazma kilidi bırakılır. Bu sayede yazma ile okuma arasına başka bir yazıcının girmesi engellenerek veri tazeliği garanti edilir. 3) Lock Upgrading Neden Yoktur?: Eğer iki okuyucu thread aynı anda yazma kilidine yükselmek (upgrade) isterse, ikisi de birbirinin okuma kilidini bırakmasını bekler ve anında kilitlenir (Deadlock). Bu yüzden Java'da kilit yükseltme yasaktır!
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[ReadWriteLock Internals & Downgrade Protocols: 1) 32-Bit State Partitioning: AQS encodes dual locks within a single atomic integer: the high 16 bits record shared read acquisitions; the low 16 bits record exclusive write hold counts. 2) Lock Downgrade Sequence: While holding the write lock, acquire the read lock, then release the write lock. This preserves atomic continuity; no competing writer can slip in between the write release and read acquisition. 3) The Ban on Lock Upgrading: Upgrading from read lock to write lock is strictly disallowed. If Thread A and Thread B both hold read locks and attempt to upgrade, both freeze waiting for the other to release, creating an immediate deadlock.]
    ]
  )
]

#java25_box[
```java
// Java 25: Lock Downgrading (Kilit Düşürme) Deseni
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class CacheWithLockDowngrade {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private String cachedData = "Initial Data";
    private boolean cacheValid = false;

    public void processData() {
        rwLock.readLock().lock();
        if (!cacheValid) {
            // Önce okuma kilidini bırakmak zorundayız!
            rwLock.readLock().unlock();
            
            // Yazma kilidini al
            rwLock.writeLock().lock();
            try {
                if (!cacheValid) { // Re-check
                    cachedData = "Fresh Data from DB";
                    cacheValid = true;
                }
                // ⚠️ KİLİT DÜŞÜRME (LOCK DOWNGRADE) BURADA BAŞLAR:
                rwLock.readLock().lock(); // 1. Okuma kilidini AL
            } finally {
                rwLock.writeLock().unlock(); // 2. Yazma kilidini BIRAK (Kilit düşürüldü!)
            }
        }

        try {
            // Veriyi güvenle oku
            IO.println("İşlenen Veri: " + cachedData);
        } finally {
            rwLock.readLock().unlock(); // 3. Son okuma kilidini BIRAK
        }
    }

    void main() {
        new CacheWithLockDowngrade().processData();
    }
}
```
]

#warning_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("b45309"), size: 9pt)[🇹🇷 MÜLAKAT TUZAĞI VE TEHLİKE]\
      #v(3pt)
      Mülakat Tuzağı: Mülakatçı 'ReentrantReadWriteLock kullanırken okuma kilidi içindeyken yazma kilidi alabilir miyiz (Lock Upgrading)?' diye sorar. Yanıt: 'HAYIR! Kilit yükseltme (Lock Upgrading) Deadlock riski nedeniyle Java'da desteklenmez; thread sonsuza dek kilitlenir. Ancak Kilit Düşürme (Lock Downgrading) tamamen desteklenir!'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Classic MAANG Trap: 'Can a thread holding a read lock directly upgrade to a write lock?' Senior Answer: 'NO! Lock upgrading is strictly prohibited in Java to prevent deadlocks. Attempting to acquire a write lock while holding a read lock deadlocks the thread forever. However, Lock Downgrading (write to read) is fully supported.']
    ]
  )
]

#takeaways_box((
    ("ReadWriteLock, okuma yoğun (%90+ okuma) sistemlerde devasa verim artışı sağlar.", "ReadWriteLock shines in read-heavy workloads (90%+ reads)."),
    ("Kilit Düşürme (Downgrade: Write -> Read) güvenle desteklenir.", "Lock Downgrading (WriteLock -> ReadLock -> unlock WriteLock) is fully supported."),
    ("Kilit Yükseltme (Upgrade: Read -> Write) deadlock nedeniyle yasaktır.", "Lock Upgrading is strictly prohibited due to inherent cyclic deadlocks."),
))
