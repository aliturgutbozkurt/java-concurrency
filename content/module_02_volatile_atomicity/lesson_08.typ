#import "/template.typ": *

#show: doc => setup_book(title: "Ders 8: volatile Mekaniği: Donanımsal Bellek Bariyerleri (Memory Barriers / Fences)", doc)

#lesson_header(
  8,
  "volatile Mekaniği: Donanımsal Bellek Bariyerleri (Memory Barriers / Fences)",
  "The Mechanics of volatile: Hardware Memory Barriers (StoreLoad, StoreStore, LoadLoad)",
  "Volatile Anahtar Kelimesi, Atomiklik & Görünürlük",
  "The volatile Keyword, Atomicity & Visibility"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 VOLATILE İÇİN DONANIMSAL BELLEK BARİYERLERİ                 │
└─────────────────────────────────────────────────────────────────────────────┘
  VOLATILE READ (Okuma):
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ [ VOLATILE READ ]                                                       │
  │ ──▶ LoadLoad Bariyeri : Kendisinden sonraki normal okumaların öne geçmesini engeller
  │ ──▶ LoadStore Bariyeri: Kendisinden sonraki normal yazmaların öne geçmesini engeller
  └─────────────────────────────────────────────────────────────────────────┘

  VOLATILE WRITE (Yazma):
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ ──▶ StoreStore Bariyeri: Kendisinden önceki normal yazmaların sonraya sarkmasını engeller
  │ [ VOLATILE WRITE ]                                                      │
  │ ──▶ StoreLoad Bariyeri : (EN PAHALISI!) Yazmanın hemen RAM'e düşmesini sağlar,
  │                          sonraki okumalarla yer değiştirmesini engeller (CPU FENCE).
  └─────────────────────────────────────────────────────────────────────────┘
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir postacı düşünün: Mektupları kafasına göre sıraya dizip dağıtıyor (CPU Reordering). Ama patron kapıya bir polis bariyeri (Memory Barrier) dikiyor: 'Bu kırmızı mühürlü mektubu (volatile write) çantandan çıkarmadan önce, elindeki bütün diğer zarfları teslim etmiş olmak zorundasın! Ve bu kırmızı mektubu vermeden sıradaki hiçbir mektubu açamazsın!' İşte Memory Barrier, CPU'nun hızlanmak için yaptığı bütün sıralama hilelerini anında donduran sert bir polis barikatıdır!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Think of a courier optimizing deliveries by dropping packages out of order. A Memory Barrier is an armed checkpoint officer standing in the roadway: 'Before you hand over this top-priority VIP document (volatile write), every single regular letter previously in your satchel MUST already be delivered! And you cannot open any future parcels until this VIP document clears!' A Memory Barrier is hardware silicon instructions freezing speculative reordering.]
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
      Donanım Seviyesinde 4 Bellek Bariyeri: 1) LoadLoad: `Load1; LoadLoad; Load2` -> Load1 verisi çekilmeden Load2 verisi çekilemez. 2) StoreStore: `Store1; StoreStore; Store2` -> Store1 verisi diğer CPU'lara görünür olmadan Store2 yazılamaz. 3) LoadStore: `Load1; LoadStore; Store2` -> Load1 bitmeden Store2 belleğe basılamaz. 4) StoreLoad (En Ağır Bariyer): `Store1; StoreLoad; Load2` -> Store1'in Store Buffer'dan tamamen temizlenip tüm CPU'lara görünür olmasını garanti eder; aksi takdirde sonraki Load2 bayat veri okuyabilir. x86 mimarisinde donanım zaten güçlü bir bellek modeline (Total Store Order - TSO) sahip olduğu için LoadLoad, LoadStore ve StoreStore bedavadır (NOOP); ancak StoreLoad için pahalı bir `lock addl` veya `mfence` talimatı üretilir. ARM64 ve Apple Silicon zayıf bellek modeline (Weak Memory Model) sahip olduğu için açık `dmb ish` bariyerleri koyar.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Hardware Barrier Topologies: 1) LoadLoad & LoadStore: Inhibit subsequent loads/stores from bypassing an initial load. 2) StoreStore: Guarantees preceding stores are flushed to cache hierarchy before subsequent stores become visible. 3) StoreLoad (The Heavyweight Fence): Forces full pipeline serialization. The CPU store buffer must fully drain to L1 before any subsequent load can execute. 4) Architecture Specifics (x86 vs ARM): x86 enforces Total Store Order (TSO) in hardware, making LoadLoad, LoadStore, and StoreStore zero-cost NOOPs; `volatile write` emits a single `lock addl ... 0` instruction to achieve StoreLoad. ARM64/Apple Silicon features a relaxed memory model, emitting explicit `dmb ishld` and `dmb ish` barrier instructions.]
    ]
  )
]

#java25_box[
```java
// Java 25: Memory Barrier Mantığını Simüle Eden Durum Yayınlama
public class MemoryBarrierPublisher {
    private int configValue = 0;
    private String serverHost = null;
    private volatile boolean initialized = false;

    // Yazan Thread:
    public void initSystem() {
        configValue = 8080;                  // 1. Normal yazma
        serverHost = "api.maang.internal";   // 2. Normal yazma
        // StoreStore Bariyeri buraya yerleşir!
        initialized = true;                  // 3. Volatile yazma (StoreLoad bariyeri tetikler)
    }

    // Okuyan Thread:
    public void handleRequest() {
        if (initialized) { // Volatile okuma (LoadLoad & LoadStore bariyeri)
            // JMM Garantisi: configValue=8080 ve serverHost KESİNLİKLE görünürdür!
            IO.println("Sistem hazır: " + serverHost + ":" + configValue);
        }
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
      Performans Uyarısı: Mülakatta 'volatile değişken okumak mı yoksa yazmak mı daha pahalıdır?' diye sorulursa; 'Volatile yazma işlemi StoreLoad bariyeri (x86'da mfence / lock prefix) tetiklediği ve CPU Store Buffer'ı boşalmaya zorladığı için yazma işlemi okumadan çok daha pahalıdır!' cevabı verilmelidir.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Performance Trap: 'Is a volatile read or a volatile write more expensive?' Senior Answer: 'A volatile write is significantly more expensive on modern CPUs. It forces a StoreLoad memory barrier (e.g. `lock addl` on x86), which stalls execution until the CPU store buffer drains completely to the cache coherency bus.']
    ]
  )
]

#takeaways_box((
    ("volatile anahtar kelimesi CPU seviyesinde Memory Barrier talimatları üretir.", "The volatile keyword compiles into explicit hardware memory barrier instructions."),
    ("StoreLoad bariyeri en pahalı bariyerdir; Store Buffer'ı tamamen boşaltır.", "The StoreLoad fence is the most expensive barrier, serializing CPU store buffers."),
    ("x86 mimarisinde TSO nedeniyle sadece StoreLoad maliyetlidir; ARM64'te açık bariyerler kullanılır.", "x86 TSO absorbs most barriers as NOOPs; ARM64 requires explicit fence instructions."),
))
