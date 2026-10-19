#import "/template.typ": *

#show: doc => setup_book(title: "Ders 4: Java Memory Model (JMM): Happens-Before Garantisi Nedir?", doc)

#lesson_header(
  4,
  "Java Memory Model (JMM): Happens-Before Garantisi Nedir?",
  "Java Memory Model (JMM): The Happens-Before Relationship Decoded",
  "Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri",
  "Threads, OS Kernels & Java Memory Model (JMM) Fundamentals"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       JMM: HAPPENS-BEFORE KURAL ZİNCİRİ                     │
└─────────────────────────────────────────────────────────────────────────────┘
  THREAD A (Yazan)                              THREAD B (Okuyan)
  ┌─────────────────────────┐                   ┌─────────────────────────┐
  │ 1. normalVeri = 42;     │                   │                         │
  │ 2. volatile bayrak=true;│ ──Happens-Before─▶│ 3. if (bayrak == true)  │
  └─────────────────────────┘   (Bellek Bariyeri│ 4. print(normalVeri);  │
                                     Garantisi) └─────────────────────────┘
                                                Sonuç: KESİNLİKLE 42 GÖRÜLÜR!
                                                (Asla 0 veya bayat veri görmez)

  TEMEL HAPPENS-BEFORE KURALLARI:
  1. Program Order Rule: Aynı thread içindeki eylemler yazılış sırasıyla gerçekleşir.
  2. Monitor Lock Rule: Bir kilidin bırakılması (unlock), sonraki kilitlemeden (lock) önce gelir.
  3. Volatile Variable Rule: Bir volatile yazma, sonraki volatile okumadan önce gelir.
  4. Thread Start Rule: thread.start() çağrısı, thread içindeki ilk eylemden önce gelir.
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      İki kişi farklı odalarda kağıda yazı yazıyor olsun. Biri yazdığı kağıdı çekmeceye koymadan (RAM'e basmadan) öbürü o kağıdı göremez. 'Happens-Before' kuralı, iki yabancı işçi arasındaki yasal noter sözleşmesidir: 'A işçisi bayrağı kaldırdığı anda, o bayrağı kaldırmadan önce masaya koyduğu BÜTÜN evraklar B işçisine görünür olmak zorundadır!' Eğer bu yasal sözleşme (Happens-Before) yoksa, B işçisi bayrağı kalkmış görse bile evrakları hala bomboş (0 veya null) görebilir!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Imagine two clerks working in separate soundproof rooms. Clerk A drafts a contract, then rings a service bell. The Happens-Before guarantee is the legal protocol ensuring that when Clerk B hears that bell, ALL documents Clerk A drafted prior to ringing MUST be visibly sitting in the shared transfer tray. Without a formal Happens-Before edge, Clerk B might hear the bell but open the tray to find blank paper because Clerk A's edits are still stuck in their private desk drawer (Store Buffer)!]
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
      JSR-133 ve JMM Spesifikasyonu: 1) Görünürlük Sorunu (Visibility): Modern CPU'lar yazma işlemlerini hemen ana belleğe yazmaz; Store Buffer'a atar. Happens-Before ilişkisi kurulmazsa, Thread B değişkenin güncel halini dakikalarca göremeyebilir. 2) 8 Temel Happens-Before Kuralı: a) Program Order: Tek thread içi ardışıklık. b) Monitor Lock: `unlock` -> sonraki `lock`. c) Volatile Variable: `volatile write` -> sonraki `volatile read`. d) Thread Start: `t.start()` -> `t` içindeki kodlar. e) Thread Join: `t`'nin bitişi -> `t.join()` dönüşü. f) Interruption: `interrupt()` -> kesintiyi tespit eden thread. g) Finalizer: Constructor bitişi -> `finalize()` başlangıcı. h) Transitivity (Geçişlilik): Eğer A -> B ve B -> C ise, A -> C'dir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[JSR-133 JMM Formalism: 1) The Memory Visibility Illusion: CPUs utilize out-of-order execution, store buffers, and invalidation queues. Memory operations do not occur globally in instant lockstep. 2) Formal Definition of Happens-Before (HB): An execution order defined over actions. If action X happens-before action Y, then the memory mutations performed by X are guaranteed visible to Y, and X is ordered before Y. 3) Transitivity Property: If action A happens-before B (via program order), and action B happens-before C (via volatile write-read or lock release-acquire), then A transitively happens-before C, safely publishing all non-volatile state preceding B.]
    ]
  )
]

#java25_box[
```java
// Java 25: Happens-Before Transitivite Güvencesi
public class HappensBeforeDemo {
    private int regularData = 0;
    private volatile boolean ready = false;

    public void writerThread() {
        regularData = 100; // 1. Normal yazma
        ready = true;      // 2. Volatile yazma (Happens-Before Bariyeri kurar!)
    }

    public void readerThread() {
        if (ready) { // 3. Volatile okuma
            // JMM Garantisi: ready=true ise regularData KESİNLİKLE 100'dür!
            IO.println("Veri güvenle okundu: " + regularData);
        }
    }

    void main() throws InterruptedException {
        var demo = new HappensBeforeDemo();
        Thread t1 = new Thread(demo::writerThread);
        Thread t2 = new Thread(demo::readerThread);
        
        t1.start();
        t1.join();
        t2.start();
        t2.join();
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
      Ölümcül Hata: Happens-Before kurulmazsa, derleyici ve CPU kodun sırasını değiştirebilir! Yani `ready = true` işlemi `regularData = 100` işleminden ÖNCE hafızaya basılabilir! Okuyucu thread `ready == true` görür ama `regularData` hala `0` çıkar!
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Fatal Interview Trap: Without an explicit Happens-Before edge, the JIT compiler and hardware can reorder instructions! The CPU might publish `ready = true` to shared memory BEFORE `regularData = 100` drains from the store buffer. The reader sees `ready == true` but reads `regularData == 0`!]
    ]
  )
]

#takeaways_box((
    ("Happens-Before, bir thread'in yazmasının diğerine ne zaman görüneceğini garanti eder.", "Happens-Before formally dictates when mutations by Thread A become visible to Thread B."),
    ("Volatile yazma, kendisinden önceki tüm normal yazmaları da görünür kılar (Transitivity).", "A volatile write flushes all preceding non-volatile writes via transitive happens-before."),
    ("Happens-Before yoksa derleyici ve CPU talimatları rastgele yeniden sıralayabilir.", "Without happens-before, hardware and JIT aggressively reorder memory instructions."),
))
