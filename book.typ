#import "/template.typ": *

#show: doc => setup_book(
  title: "Aptala Anlatır Gibi MAANG Java Concurrency El Kitabı",
  author: "Antigravity & MAANG Concurrency Guild",
  doc
)

#book_front_cover()

#pagebreak()
#v(20pt)
#align(center)[
  #text(size: 20pt, weight: "bold", fill: rgb("0f172a"))[Önsöz ve Başlarken / Preface & Getting Started]
]
#v(16pt)

#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  [
    == 🇹🇷 Bu Eğitim Hakkında
    Bu kitap; Meta, Amazon, Apple, Netflix, Google (MAANG) ve yüksek frekanslı finans (HFT / FinTech) teknoloji şirketlerinin *Senior, Staff ve Principal Yazılım Mühendisi* mülakatlarına hazırlanan mühendisler için özel olarak hazırlanmıştır.

    Java Concurrency; yalnızca `Thread` açıp `synchronized` yazmaktan ibaret değildir. Donanımsal L1/L2/L3 CPU önbellekleri, MESI önbellek tutarlılık protokolü, Store Buffer, bellek bariyerleri (Memory Barriers), Java Bellek Modeli (JMM Happens-Before), HotSpot kilitleme optimizasyonları ve kilit-siz (Lock-Free) CAS veri yapıları gibi donanım ve çalışma zamanı dinamiklerini derinlemesine kavramayı gerektirir.

    Ayrıca modern *Java 25 LTS* ile birlikte gelen Project Loom Sanal Thread'leri (Virtual Threads M:N), Taşıyıcı Thread (Carrier Thread) montajı, Pinning tehlikesi, Yapısal Eşzamanlılık (StructuredTaskScope) ve ScopedValue devrimi çoklu iş parçacığı paradigmasını kökten değiştirmiştir.

    Bu 60 derslik kapsamlı müfredatta;
    - İşletim sistemi çekirdek thread'leri ile JVM thread durumlarını,
    - Volatile, atomiklik ve False Sharing önbellek satırı dolgusunu,
    - HotSpot Monitör şişmesini (Biased, Lightweight, Heavyweight Lock),
    - ReentrantLock, StampedLock, CountDownLatch, Semaphore ve Phaser primitiflerini,
    - ThreadPoolExecutor büyüme dinamiklerini ve Fork/Join Work-Stealing algoritmasını,
    - ConcurrentHashMap iç yapısını (Node CAS, Bin-Level Kilitleri ve TreeBin),
    - CompletableFuture asenkron boru hatlarını ve zaman aşımı yönetimini,
    - Sanal Thread'leri, Carrier unmounting döngüsünü ve Pinning önleme stratejilerini,
    - Deadlock, Livelock, Starvation ve ABA problemlerini ve thread dump analizini,
    - MAANG beyaz tahta sistem tasarımı vakalarını (O(1) LRU Cache, LMAX Disruptor, Token Bucket, HikariCP ConcurrentBag)
    *bir aptala anlatır gibi* en yalın analojiler, mimari ASCII akış şemaları ve çalışan modern Java 25 kodlarıyla inceleyeceksiniz.
  ],
  [
    == 🇬🇧 About This Masterclass
    This handbook is engineered for software engineers, distributed systems architects, and low-latency engineers targeting Senior, Staff, and Principal roles at Tier-1 tech giants (MAANG / FAANG) and High-Frequency Trading (HFT) firms.

    Java Concurrency transcends simple locking and threads. True mastery demands an uncompromising understanding of CPU hardware caches, StoreLoad memory barriers, the Java Memory Model (JMM happens-before guarantees), HotSpot lock inflation lifecycles, and lock-free atomic CAS primitives.

    Furthermore, the arrival of modern *Java 25 LTS* and Project Loom has redefined the concurrency landscape: M:N Virtual Threads, carrier thread mounting/unmounting, carrier pinning hazards, Structured Concurrency (`StructuredTaskScope`), and immutable `ScopedValue` context propagation.

    Across 60 deep-dive lessons organized into 10 structured modules, and powered by *Java 25 LTS*, you will master:
    - OS kernel threads, 6 JVM states, and hardware cache lines,
    - Volatile visibility semantics, memory barriers, and false sharing,
    - HotSpot monitor inflation, lightweight spin-locks, and ReentrantLock,
    - StampedLock optimistic reads, Semaphore pooling, and dynamic Phasers,
    - ThreadPoolExecutor queue dynamics and Fork/Join work-stealing algorithms,
    - Modern ConcurrentHashMap internals (Node CAS, bin-locking, and TreeBins),
    - Reactive CompletableFuture DAG pipelines, scatter-gather, and fallbacks,
    - Project Loom Virtual Threads, Epoll continuation unmounting, and pinning remedies,
    - Coffman deadlock forensics, live production thread dump analysis (jstack/jcmd),
    - Legendary MAANG concurrency whiteboard challenges: O(1) LRU Cache, LMAX Disruptor RingBuffer, Token-Bucket Rate Limiter, and HikariCP ConcurrentBag.
  ]
)

#v(20pt)
#line(length: 100%, stroke: 0.8pt + rgb("e2e8f0"))
#v(10pt)

#outline(
  title: [İçindekiler / Table of Contents],
  depth: 2,
  indent: auto
)

#pagebreak()

#module_cover(
  1,
  "Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri",
  "Threads, OS Kernels & Java Memory Model (JMM) Fundamentals",
  "Process vs Thread farkı, JVM thread durumları, donanım önbellekleri (L1/L2/L3), False Sharing, JMM Happens-Before garantisi ve modern Java 25 thread oluşturma mekanizmaları.",
  "Process vs Thread dichotomy, JVM thread states, CPU cache hierarchies (L1/L2/L3), False Sharing, the JMM Happens-Before relationship, and modern Java 25 thread creation."
)

#include "/content/module_01_threads_jmm_basics/lesson_01.typ"
#v(14pt)

#include "/content/module_01_threads_jmm_basics/lesson_02.typ"
#v(14pt)

#include "/content/module_01_threads_jmm_basics/lesson_03.typ"
#v(14pt)

#include "/content/module_01_threads_jmm_basics/lesson_04.typ"
#v(14pt)

#include "/content/module_01_threads_jmm_basics/lesson_05.typ"
#v(14pt)

#include "/content/module_01_threads_jmm_basics/lesson_06.typ"
#v(14pt)


#module_cover(
  2,
  "Volatile Anahtar Kelimesi, Atomiklik & Görünürlük",
  "The volatile Keyword, Atomicity & Visibility",
  "Görünürlük (Visibility) ve Atomiklik farkı, `volatile` bellek bariyerleri (Memory Barriers), Double-Checked Locking (DCL) tuzağı, CAS döngüleri ve `LongAdder` vs `AtomicLong` ölçeklenme mimarisi.",
  "Visibility vs Atomicity, hardware memory barriers backing `volatile`, the Double-Checked Locking (DCL) singleton hazard, lock-free CAS loops, and `LongAdder` vs `AtomicLong` scalability."
)

#include "/content/module_02_volatile_atomicity/lesson_07.typ"
#v(14pt)

#include "/content/module_02_volatile_atomicity/lesson_08.typ"
#v(14pt)

#include "/content/module_02_volatile_atomicity/lesson_09.typ"
#v(14pt)

#include "/content/module_02_volatile_atomicity/lesson_10.typ"
#v(14pt)

#include "/content/module_02_volatile_atomicity/lesson_11.typ"
#v(14pt)

#include "/content/module_02_volatile_atomicity/lesson_12.typ"
#v(14pt)


#module_cover(
  3,
  "Klasik Senkronizasyon, Monitörler & Kilitler",
  "Classical Synchronization, Monitors & Locks",
  "synchronized iç kilit mekanizması (Intrinsic Lock), HotSpot monitör seviyeleri (Biased, Lightweight, Heavyweight), wait/notify signal tuzakları, ReentrantLock, Condition kuyrukları ve ReentrantReadWriteLock.",
  "JVM intrinsic locks via synchronized, HotSpot lock inflation levels, wait/notify missed signals, ReentrantLock reentrancy, Condition queues, and ReadWriteLock degradation."
)

#include "/content/module_03_sync_monitors_locks/lesson_13.typ"
#v(14pt)

#include "/content/module_03_sync_monitors_locks/lesson_14.typ"
#v(14pt)

#include "/content/module_03_sync_monitors_locks/lesson_15.typ"
#v(14pt)

#include "/content/module_03_sync_monitors_locks/lesson_16.typ"
#v(14pt)

#include "/content/module_03_sync_monitors_locks/lesson_17.typ"
#v(14pt)

#include "/content/module_03_sync_monitors_locks/lesson_18.typ"
#v(14pt)


#module_cover(
  4,
  "İleri Düzey Senkronizasyon & Kilit-Siz Araçlar",
  "Advanced Synchronization & Lock-Free Primitives",
  "StampedLock iyimser okuma mekanizması, CountDownLatch tek seferlik kapılar, CyclicBarrier tekrar kullanılabilir buluşma noktaları, Semaphore kaynak havuzları, Exchanger ve dinamik Phaser mimarisi.",
  "StampedLock optimistic reading stamps, CountDownLatch fan-out gates, CyclicBarrier reusable rendezvous, Semaphore resource pools, pairwise Exchanger, and dynamic multi-phase Phaser."
)

#include "/content/module_04_advanced_sync_primitives/lesson_19.typ"
#v(14pt)

#include "/content/module_04_advanced_sync_primitives/lesson_20.typ"
#v(14pt)

#include "/content/module_04_advanced_sync_primitives/lesson_21.typ"
#v(14pt)

#include "/content/module_04_advanced_sync_primitives/lesson_22.typ"
#v(14pt)

#include "/content/module_04_advanced_sync_primitives/lesson_23.typ"
#v(14pt)

#include "/content/module_04_advanced_sync_primitives/lesson_24.typ"
#v(14pt)


#module_cover(
  5,
  "Thread Havuzları, Executor'lar & Work-Stealing",
  "Thread Pools, Executors & Work-Stealing Algorithms",
  "ThreadPoolExecutor iç yapısı, 4 ret politikası (Rejection Policies), Executors sınıfının üretim felaketleri (OOM riskleri), ScheduledThreadPool, Fork/Join work-stealing algoritması ve Graceful Shutdown.",
  "ThreadPoolExecutor mechanics, the 4 task rejection policies, production OOM hazards of Executors factory methods, ScheduledExecutor delay drift, Fork/Join work-stealing, and graceful shutdown."
)

#include "/content/module_05_thread_pools_executors/lesson_25.typ"
#v(14pt)

#include "/content/module_05_thread_pools_executors/lesson_26.typ"
#v(14pt)

#include "/content/module_05_thread_pools_executors/lesson_27.typ"
#v(14pt)

#include "/content/module_05_thread_pools_executors/lesson_28.typ"
#v(14pt)

#include "/content/module_05_thread_pools_executors/lesson_29.typ"
#v(14pt)

#include "/content/module_05_thread_pools_executors/lesson_30.typ"
#v(14pt)


#module_cover(
  6,
  "Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları",
  "Concurrent Collections & Thread-Safe Data Structures",
  "ConcurrentHashMap iç mekaniği (CAS ve Kova Kilitleme), CopyOnWriteArrayList anlık görüntü kopyalaması, BlockingQueue varyantları, SynchronousQueue sıfır kapasite takası ve Lock-Free kuyruklar.",
  "ConcurrentHashMap internals (CAS and Bin-Level locking), CopyOnWriteArrayList snapshot iteration, BlockingQueue variants, SynchronousQueue zero-capacity handoffs, and lock-free queues."
)

#include "/content/module_06_concurrent_collections/lesson_31.typ"
#v(14pt)

#include "/content/module_06_concurrent_collections/lesson_32.typ"
#v(14pt)

#include "/content/module_06_concurrent_collections/lesson_33.typ"
#v(14pt)

#include "/content/module_06_concurrent_collections/lesson_34.typ"
#v(14pt)

#include "/content/module_06_concurrent_collections/lesson_35.typ"
#v(14pt)

#include "/content/module_06_concurrent_collections/lesson_36.typ"
#v(14pt)


#module_cover(
  7,
  "Asenkron Boru Hatları & CompletableFuture",
  "Asynchronous Pipelines & CompletableFuture",
  "Geleneksel Future engellemelerinden (blocking get) kurtuluş, CompletableFuture ile reaktif veri akışları, thenCompose/thenCombine bileşimleri, allOf/anyOf orkestrasyonu, hata kurtarma zincirleri ve zaman aşımı yönetimi.",
  "Escaping traditional blocking Future traps, CompletableFuture reactive processing pipelines, thenCompose/thenCombine functional chains, allOf/anyOf orchestration, resilient error recovery, and timeout handling."
)

#include "/content/module_07_async_completable_future/lesson_37.typ"
#v(14pt)

#include "/content/module_07_async_completable_future/lesson_38.typ"
#v(14pt)

#include "/content/module_07_async_completable_future/lesson_39.typ"
#v(14pt)

#include "/content/module_07_async_completable_future/lesson_40.typ"
#v(14pt)

#include "/content/module_07_async_completable_future/lesson_41.typ"
#v(14pt)

#include "/content/module_07_async_completable_future/lesson_42.typ"
#v(14pt)


#module_cover(
  8,
  "Project Loom & Sanal Thread'ler (Virtual Threads)",
  "Project Loom & Virtual Threads",
  "Platform thread'leri ile sanal thread'lerin farkı (M:N mimarisi), Carrier thread'lere bağlanma/ayrılma (Mounting/Unmounting), Pinning tuzağı ve ReentrantLock çözümü, ThreadLocal bellek sızıntıları, Structured Concurrency ve Java 25 ScopedValue devrimi.",
  "Platform threads vs Virtual Threads (M:N fibers), Carrier thread mounting and unmounting dynamics, the carrier pinning hazard and ReentrantLock remedy, ThreadLocal memory explosion, Structured Concurrency orchestration, and the Java 25 ScopedValue revolution."
)

#include "/content/module_08_project_loom_virtual_threads/lesson_43.typ"
#v(14pt)

#include "/content/module_08_project_loom_virtual_threads/lesson_44.typ"
#v(14pt)

#include "/content/module_08_project_loom_virtual_threads/lesson_45.typ"
#v(14pt)

#include "/content/module_08_project_loom_virtual_threads/lesson_46.typ"
#v(14pt)

#include "/content/module_08_project_loom_virtual_threads/lesson_47.typ"
#v(14pt)

#include "/content/module_08_project_loom_virtual_threads/lesson_48.typ"
#v(14pt)


#module_cover(
  9,
  "Eşzamanlılık Hataları, Teşhis & Düşük Seviyeli Primitifler",
  "Concurrency Bugs, Anti-Patterns & Low-Level Primitives",
  "Klasik yarış durumları (Check-then-Act, Read-Modify-Write), Coffman ölümcül kilitlenme (Deadlock) koşulları ve tespiti, Livelock ve Starvation, ABA problemi ve AtomicStampedReference, jstack/jcmd thread dump adli analizi, ve modern VarHandle bellek çitleri.",
  "Classic race conditions (Check-then-Act, Read-Modify-Write), Coffman deadlock prerequisites and programmatic detection, Livelock and thread starvation, ABA memory hazard and AtomicStampedReference, production thread dump forensics with jstack/jcmd, and modern VarHandle memory fences."
)

#include "/content/module_09_concurrency_bugs_debugging/lesson_49.typ"
#v(14pt)

#include "/content/module_09_concurrency_bugs_debugging/lesson_50.typ"
#v(14pt)

#include "/content/module_09_concurrency_bugs_debugging/lesson_51.typ"
#v(14pt)

#include "/content/module_09_concurrency_bugs_debugging/lesson_52.typ"
#v(14pt)

#include "/content/module_09_concurrency_bugs_debugging/lesson_53.typ"
#v(14pt)

#include "/content/module_09_concurrency_bugs_debugging/lesson_54.typ"
#v(14pt)


#module_cover(
  10,
  "MAANG Eşzamanlılık Mülakatı & Sistem Tasarımı Ustalığı",
  "MAANG Concurrency Whiteboard & System Design Mastery",
  "MAANG mülakatlarında sorulan 4 efsanevi sistem tasarımı vakası: Thread-Safe O(1) LRU Cache, LMAX Disruptor RingBuffer kilit-siz mesajlaşma, Token-Bucket & Leaky-Bucket hız sınırlayıcı, HikariCP FastPath havuz mekaniği; 45 dakikalık mülakat stratejisi ve Staff+ mimar değerlendirme kriterleri.",
  "Four legendary MAANG concurrency whiteboard challenges: Thread-Safe O(1) LRU Cache, LMAX Disruptor lock-free RingBuffer, Token-Bucket & Leaky-Bucket rate limiting, HikariCP ConcurrentBag connection pool architecture; plus the 45-minute interview blueprint and Staff+ architect evaluation criteria."
)

#include "/content/module_10_maang_system_design_mastery/lesson_55.typ"
#v(14pt)

#include "/content/module_10_maang_system_design_mastery/lesson_56.typ"
#v(14pt)

#include "/content/module_10_maang_system_design_mastery/lesson_57.typ"
#v(14pt)

#include "/content/module_10_maang_system_design_mastery/lesson_58.typ"
#v(14pt)

#include "/content/module_10_maang_system_design_mastery/lesson_59.typ"
#v(14pt)

#include "/content/module_10_maang_system_design_mastery/lesson_60.typ"
#v(14pt)


#pagebreak()
#v(40pt)
#align(center)[
  #rect(fill: rgb("08111e"), radius: 10pt, inset: (x: 24pt, y: 32pt), width: 90%)[
    #text(size: 24pt, fill: rgb("fb923c"), weight: "bold")[🎓 TEBRİKLER! / CONGRATULATIONS!]    #v(10pt)
    #text(size: 14pt, fill: white)[60 Derslik MAANG Java Concurrency & Multithreading Yolculuğunu Başarıyla Tamamladınız!]    #v(6pt)
    #text(size: 11pt, fill: rgb("94a3b8"))[You have conquered all 60 lessons of the MAANG Java Concurrency & Multithreading Masterclass!]    #v(20pt)
    #line(length: 60%, stroke: 1pt + rgb("f97316"))
    #v(15pt)
    #text(size: 10pt, fill: rgb("cbd5e1"))[
      Java 25 LTS • Virtual Threads • JMM • Lock-Free Algorithms • LMAX Disruptor • HikariCP
    ]
  ]
]
