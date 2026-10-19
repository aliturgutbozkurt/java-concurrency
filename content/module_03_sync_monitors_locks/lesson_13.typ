#import "/template.typ": *

#show: doc => setup_book(title: "Ders 13: synchronized Anahtar Kelimesi: Intrinsic Lock & JVM Object Monitor Mimarisi", doc)

#lesson_header(
  13,
  "synchronized Anahtar Kelimesi: Intrinsic Lock & JVM Object Monitor Mimarisi",
  "The synchronized Keyword: Intrinsic Locks & JVM Object Monitors",
  "Klasik Senkronizasyon, Monitörler & Kilitler",
  "Classical Synchronization, Monitors & Locks"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 JVM OBJECT MONITOR (NESNE BAŞLIĞI / MARK WORD)              │
└─────────────────────────────────────────────────────────────────────────────┘
  HER JAVA NESNESİNİN BAŞINDA (MARK WORD) BİR MONITOR KİLİDİ BULUNUR:
  
  [ JAVA OBJECT HEADER: Mark Word (64-bit) | Klass Word | Instance Data ]
                            │
                            ▼
              ┌───────────────────────────┐
              │    OBJECT MONITOR YAPISI  │
              ├───────────────────────────┤
              │ _owner : Thread A (Sahip) │
              │ _count : 1 (Reentrant)    │
              ├───────────────────────────┤
              │ _EntryList : [Th B, Th C] │ ◀── Kilit bekleyenler (BLOCKED)
              ├───────────────────────────┤
              │ _WaitSet   : [Th D, Th E] │ ◀── wait() çağıranlar (WAITING)
              └───────────────────────────┘
  BYTECODE TALİMATLARI:
  `monitorenter` ──▶ Kilit sayacını artır, sahibini Thread A yap.
  `monitorexit`  ──▶ Kilit sayacını düşür, 0 olunca kilidi bırak (Finally garantisi!).
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Her Java nesnesi, kapısında özel bir anahtar deliği olan bir oda gibidir. Bir odaya `synchronized` ile girdiğinizde (monitorenter), içeriden kapıyı kilitlersiniz. Odanın sahibi siz olursunuz (\_owner). Kapıda iki tane bekleme salonu vardır: 1) Koridor (\_EntryList): İçeri girmek için sıraya girenler (BLOCKED). 2) Balkon (\_WaitSet): İçerideyken 'Patron haber verene kadar burada dinleniyorum' diyerek kenara çekilenler (WAITING). Siz odadan çıkarken (monitorexit) anahtarı bırakırsınız ve koridordaki bir kişiyi içeri alırsınız!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Every Java object is born with a private hotel room keyhole inside its memory header (Mark Word). When a thread enters a `synchronized` block, it executes `monitorenter`, turning the deadbolt from the inside and claiming ownership (`_owner`). Outside sit two distinct waiting rooms: 1) The Hallway (`_EntryList`): Threads aggressively competing to enter the room (BLOCKED). 2) The Balcony (`_WaitSet`): Threads that were inside, voluntarily surrendered the key via `wait()`, and are resting until signaled (WAITING). Exiting triggers `monitorexit`, unlocking the door for hallway contenders.]
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
      Object Monitor ve Bytecode Derinliği: 1) Mark Word: 64-bit HotSpot JVM'de nesne başlığının en alt 2-biti kilit durumunu tutar (01: Kilitsiz, 00: Hafif Kilit, 10: Ağır Monitör Kilidi). 2) Reentrancy (Yeniden Girilebilirlik): Bir thread zaten sahip olduğu bir kilide tekrar girerse (örneğin synchronized metodun içinden başka bir synchronized metot çağırmak), JVM `_count` sayacını 1 artırır; kilitlenip deadlock olmaz. Çıkarken de sayaç düşer. 3) Derleyici Garantisi: `synchronized` bloğu javac tarafından try-finally bloğu gibi derlenir. Metot içinde beklenmedik bir RuntimeException veya Error fırlasa dahi JVM `monitorexit` talimatını kesinlikle çalıştırır; kilit asla askıda kalmaz.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[HotSpot Monitor Internals & Bytecode: 1) Mark Word State Bits: On 64-bit architectures, the lowest two bits designate monitor states (01 = Unlocked, 00 = Lightweight/Thin, 10 = Heavyweight Inflated Monitor). 2) Reentrancy Mechanism: If Thread A holds a monitor and enters another synchronized block on the same object, the JVM simply increments `_count`. It does not re-acquire or block, preventing self-deadlock. The monitor is released when `_count` hits zero. 3) Bytecode Invariant: javac generates dual `monitorexit` opcodes: one for normal control flow completion and another wrapped in an all-encompassing exception handler, ensuring monitors are guaranteed released even under fatal panics.]
    ]
  )
]

#java25_box[
```java
// Java 25: Synchronized Reentrancy ve Monitor Davranışı
public class SynchronizedMonitorDemo {
    private final Object lock = new Object();
    private int sharedBalance = 1000;

    public void withdraw(int amount) {
        synchronized (lock) { // monitorenter
            IO.println("Kilit alındı: " + Thread.currentThread().getName());
            auditLog(); // Reentrant çağrı (Aynı kilit, sayaç 2 olur!)
            sharedBalance -= amount;
        } // monitorexit
    }

    private void auditLog() {
        synchronized (lock) { // Aynı thread olduğu için bloke olmaz!
            IO.println("Audit kaydı işlendi. Kalan bakiye: " + sharedBalance);
        }
    }

    void main() {
        var demo = new SynchronizedMonitorDemo();
        demo.withdraw(250);
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
      Mülakat Tuzağı: 'synchronized(new Object()) veya synchronized(new String("lock")) yazarsak ne olur?' Yanıt: 'Her thread farklı bir nesne referansı üzerinde kilitleneceği için hiçbir senkronizasyon sağlanamaz! Kilit nesneleri DAİMA `private final Object lock = new Object();` olarak tanımlanmalıdır.'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Junior Trap in Interviews: 'What is the catastrophe of `synchronized(new Object())` or `synchronized("literal")`?' Answer: '`new Object()` creates a brand-new monitor per invocation, providing ZERO mutual exclusion. Locking on interned Strings risks accidental cross-library deadlocks. Always declare `private final Object lock = new Object();`.']
    ]
  )
]

#takeaways_box((
    ("Her Java nesnesi başlığında (Mark Word) bir Object Monitor taşır.", "Every Java object carries an intrinsic monitor inside its Mark Word header."),
    ("synchronized kilitleri reentrant'tır; aynı thread aynı kilide defalarca girebilir.", "Intrinsic locks are fully reentrant, incrementing an internal recursion counter."),
    ("Kilit nesneleri referans değişimini önlemek için daima private final olmalıdır.", "Lock target instances must always be private and final to prevent reference mutation."),
))
