#import "/template.typ": *

#show: doc => setup_book(title: "Ders 7: Görünürlük (Visibility) vs Atomiklik (Atomicity): 'volatile int counter++' Neden Çöker?", doc)

#lesson_header(
  7,
  "Görünürlük (Visibility) vs Atomiklik (Atomicity): 'volatile int counter++' Neden Çöker?",
  "Visibility vs Atomicity: Why 'volatile int counter++' is a Silent Catastrophe",
  "Volatile Anahtar Kelimesi, Atomiklik & Görünürlük",
  "The volatile Keyword, Atomicity & Visibility"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 'volatile int count++' İŞLEMİNİN GERÇEK ANATOMİSİ           │
└─────────────────────────────────────────────────────────────────────────────┘
  `count++` TEK BİR ATOMİK İŞLEM DEĞİLDİR! 3 AYRI ADIMDAN OLUŞUR:
  1. LOAD  : Bellekten o anki değeri oku (Örn: 5)
  2. MODIFY: Değere 1 ekle (5 + 1 = 6)
  3. STORE : Yeni değeri belleğe yaz (6)

  THREAD 1 (Core 0)                      THREAD 2 (Core 1)
  ┌───────────────────────────────┐      ┌───────────────────────────────┐
  │ 1. LOAD: count'u oku (5)      │      │                               │
  │                               │      │ 1. LOAD: count'u oku (5)      │
  │ 2. MODIFY: 5 + 1 = 6          │      │ 2. MODIFY: 5 + 1 = 6          │
  │ 3. STORE: 6'yı belleğe yaz    │      │                               │
  │                               │      │ 3. STORE: 6'yı belleğe yaz    │
  └───────────────────────────────┘      └───────────────────────────────┘
  BEKLENEN SONUÇ: 7 | GERÇEK SONUÇ: 6! (KAYIP GÜNCELLEME / LOST UPDATE!)
  `volatile` SADECE GÖRÜNÜRLÜĞÜ SAĞLAR, ATOMİKLİĞİ (LOCK) SAĞLAMAZ!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir kütüphanedeki tahtaya tebeşirle sayı yazıldığını düşünün. 'volatile' demek, tahtanın üzerine süper parlak bir spot ışığı yakmak gibidir; tahtada ne yazıyorsa bütün oda anında görür (Görünürlük)! Ama iki kişi aynı anda tahtaya koşup 'Mevcut sayıyı silip 1 fazlasını yazayım' derse ne olur? İkisi de aynı anda '5' sayısını görür, ikisi de kafasında 6 hesaplar, ikisi de tahtaya 6 yazar! 2 kere artması gereken sayı sadece 1 kere artar! Spot ışığı (volatile) insanların birbirinin eline çarpmasını (Atomiklik) engellemez!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Imagine a shared blackboard in an office. Declaring a variable `volatile` is like installing a 10,000-lumen spotlight directly onto the board: the instant a number is inscribed, every engineer across the room sees it immediately (Visibility). But what happens when two engineers run to the board at the same second to increment the number? Both observe '5', both mentally calculate '5 + 1 = 6', and both scribble '6' over the board! The count increments once instead of twice! Spotlights guarantee sight, not turn-taking (Atomicity)!]
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
      Read-Modify-Write Döngüsü ve volatile Sınırları: 1) Görünürlük Garantisi: `volatile` bir değişkene yazıldığında, CPU yerel Store Buffer'ı ana belleğe boşaltır (Flush). Okunduğunda ise CPU yerel cache'i geçersiz kılar (Invalidate) ve RAM/L3'ten taze veri çeker. 2) Atomiklik İhlali: Java bytecode seviyesinde `count++` işlemi: `GETFIELD`, `ICONST_1`, `IADD`, `PUTFIELD` olmak üzere 4 talimata ayrılır. İki thread bu talimatları iç içe (interleaved) çalıştırdığında 'Lost Update' meydana gelir. 3) Kural: `volatile` yalnızca ve yalnızca yazılan yeni değer eski değerden tamamen bağımsızsa (örneğin bir boolean bayrak: `running = false`) güvenlidir. Eğer yeni değer eski değere bağlıysa (`count = count + 1`), `volatile` yetersizdir; `AtomicInteger` veya `synchronized` zorunludur.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Dissecting the Read-Modify-Write Hazard: 1) Hardware Visibility Semantics: A `volatile` write issues a memory barrier draining the local store buffer to the cache coherency fabric. A `volatile` read bypasses stale L1 entries. 2) Bytecode Non-Atomicity: The expression `count++` compiles into non-atomic instructions: `getfield`, `iconst_1`, `iadd`, `putfield`. Context switches occurring between `getfield` and `putfield` produce severe data races (Lost Updates). 3) The Axiom of Volatile: `volatile` is thread-safe IF AND ONLY IF state mutations do not depend on current state (e.g. status flags: `volatile boolean shutdownRequested`). When reads dictate writes, CAS primitives (`AtomicInteger`) or mutual exclusion are non-negotiable.]
    ]
  )
]

#java25_box[
```java
// Java 25: Volatile Atomiklik İllüzyonu ve Kayıp Güncelleme Kanıtı
public class VolatileBrokenCounter {
    private volatile int count = 0;

    public void increment() {
        count++; // TEHLİKELİ! Atomik değildir!
    }

    void main() throws InterruptedException {
        var demo = new VolatileBrokenCounter();
        int threadCount = 10;
        int incrementsPerThread = 1000;

        Thread[] threads = new Thread[threadCount];
        for (int i = 0; i < threadCount; i++) {
            threads[i] = Thread.ofPlatform().start(() -> {
                for (int j = 0; j < incrementsPerThread; j++) {
                    demo.increment();
                }
            });
        }

        for (Thread t : threads) t.join();

        IO.println("Beklenen Sayaç: " + (threadCount * incrementsPerThread)); // 10,000
        IO.println("Gerçek Sayaç  : " + demo.count); // Çoğunlukla 9,200 civarı çıkar!
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
      Mülakat Klasiği: 'Volatile anahtar kelimesi senkronizasyon için ne zaman yeterlidir?' Yanıt: 'Sadece tek bir thread yazıp diğer tüm thread'ler okurken (Single-Writer Multiple-Reader) veya değişken sadece durum bildiren bir bayraksa (`volatile boolean stopped`). Birden fazla thread yazıyorsa volatile tek başına ASLA yetmez!'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Top Interview Screen: 'When is volatile sufficient for thread safety?' Senior Answer: 'Exclusively in Single-Writer / Multiple-Reader topologies, or for state flag publication (`volatile boolean cancelled`). If multiple concurrent threads execute read-modify-write operations, volatile guarantees zero safety without locks or CAS operations.']
    ]
  )
]

#takeaways_box((
    ("volatile sadece görünürlüğü (visibility) sağlar; atomiklik (atomicity) sağlamaz.", "volatile guarantees memory visibility; it provides zero transactional atomicity."),
    ("count++ arka planda 3 ayrı işlem olduğu için lost update hatasına yol açar.", "count++ encompasses 3 discrete CPU instructions, suffering lost updates under concurrency."),
    ("Değişkene birden fazla thread yazıyorsa Atomic sınıfları veya kilitler zorunludur.", "When multiple threads mutate shared state, Atomic types or mutexes are mandatory."),
))
