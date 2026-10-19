#import "/template.typ": *

#show: doc => setup_book(title: "Ders 54: VarHandle & Düşük Seviyeli Bellek Çitleri: Modern Java'da Unsafe'in Yerine Geçiş", doc)

#lesson_header(
  54,
  "VarHandle & Düşük Seviyeli Bellek Çitleri: Modern Java'da Unsafe'in Yerine Geçiş",
  "Low-Level VarHandle & Memory Fences: Replacing sun.misc.Unsafe",
  "Eşzamanlılık Hataları, Teşhis & Düşük Seviyeli Primitifler",
  "Concurrency Bugs, Anti-Patterns & Low-Level Primitives"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    VARHANDLE BELLEK ERİŞİM MODLARI                          │
└─────────────────────────────────────────────────────────────────────────────┘
  Mod Adı         │ Bellek Semantiği              │ CPU Bariyeri
  ────────────────┼───────────────────────────────┼───────────────────────────
  get() / set()   │ Plain (Düz Okuma/Yazma)       │ SIFIR Bariyer (En Hızlı)
  getOpaque()     │ Opaque (Derleyici optimiz. yok)│ Reordering yok, bariyer yok
  getAcquire()    │ Acquire (Okuma Bariyeri)      │ LoadLoad + LoadStore
  setRelease()    │ Release (Yazma Bariyeri)      │ StoreStore + LoadStore
  getVolatile()   │ Volatile (Tam Sıralama)       │ StoreLoad (En Katı)

  Atomic RMW:
  handle.compareAndSet(this, expected, update) ──▶ Donanımsal CMPXCHG
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Eski `Unsafe` sınıfı, eline dinamit verilmiş bir inşaat işçisi gibidir. Çok hızlıdır ama yanlışlıkla duvar yerine ana taşıyıcı kolonu patlatıp tüm JVM'i çökertebilir. Java 9 ve 25'teki `VarHandle` ise koruyucu kaskı, lazer hizalayıcısı ve sigortası olan yüksek teknolojili bir cerrahi alettir! Belleğe doğrudan, kilit almadan, ışık hızında dokunmanı sağlar ama hafızayı bozamayacağın güvenlik bariyerleriyle donatılmıştır.
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Legacy `sun.misc.Unsafe` was handing a construction worker live dynamite. It bypassed all safety checks, but a 1-byte off-by-one pointer error crashed the JVM instantly with a Segfault. `VarHandle` (Java 9 - Java 25) is a precision laser scalpel. It offers the exact same raw, zero-allocation hardware access and atomic memory fences as `Unsafe`, but is fully type-safe, bounds-checked, and natively optimized by the JIT compiler.]
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
      VarHandle Bellek Modeli ve Erişim Semantikleri: 1) Unsafe'in Emekliliği: `sun.misc.Unsafe` doğrudan bellek adresleriyle çalıştığı için JVM güvenliğini (Memory Safety) ihlal ediyordu. `java.lang.invoke.VarHandle`, MethodHandles API'si üzerinden değişkenlere atomik ve düşük seviyeli erişim sunar. 2) 5 Farklı Erişim Modu: a) Plain: Standart alan erişimi, reordering serbesttir. b) Opaque: Bytecode döngülerinde değişkenin önbelleğe alınmasını (hoisting) engeller, atomiktir ancak bellek bariyeri koymaz. c) Acquire/Release: Tek yönlü bariyerlerdir. `setRelease` öncesindeki yazmaların bu yazmadan sonra görünmesini garanti eder; tam `volatile` kadar pahalı değildir. d) Volatile: Çift yönlü tam bellek bariyeri (StoreLoad). 3) Düşük Seviyeli Bellek Çitleri: `VarHandle.fullFence()`, `acquireFence()`, `releaseFence()` gibi metotlarla CPU düzeyinde donanımsal bellek bariyerleri manuel olarak da tetiklenebilir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[VarHandle Architecture & JVM Memory Modes: 1) Superseding `sun.misc.Unsafe`: `Unsafe` permitted raw memory dereferencing, provoking hard JVM segmentation faults. `VarHandle` integrates with `MethodHandles.Lookup`, enforcing variable type safety and reference validation while compiling down to native assembly intrinsics. 2) Granular Memory Access Modes: a) Plain: Normal reads/writes without fences. b) Opaque: Bitwise atomic with program-order coherence, preventing compiler hoisting while avoiding bus locks. c) Acquire/Release: One-way memory barriers. `setRelease` flushes preceding writes; `getAcquire` guarantees subsequent reads see updated state without incurring total StoreLoad fence penalties. d) Volatile: Enforces sequential consistency with global `StoreLoad` barriers. 3) Native CPU Fences: Exposes hardware primitives via `VarHandle.fullFence()` and `loadLoadFence()` for ultra-low-latency frameworks (e.g. Aeron, Disruptor).]
    ]
  )
]

#java25_box[
```java
// Java 25: VarHandle ile Kilit-Siz Atomik Sayaç ve Acquire/Release Semantiği
import java.lang.invoke.MethodHandles;
import java.lang.invoke.VarHandle;

public class VarHandleCounter {
    private volatile int count = 0;

    // VarHandle tanımlayıcısı
    private static final VarHandle COUNT_HANDLE;

    static {
        try {
            // Field erişim kontrolü ve VarHandle oluşturma
            MethodHandles.Lookup lookup = MethodHandles.lookup();
            COUNT_HANDLE = lookup.findVarHandle(VarHandleCounter.class, "count", int.class);
        } catch (ReflectiveOperationException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    public void incrementRelaxed() {
        // Opaque veya Release modunda artırma (Volatile'dan daha ucuz CPU döngüsü!)
        int current;
        do {
            current = (int) COUNT_HANDLE.getOpaque(this);
        } while (!COUNT_HANDLE.compareAndSet(this, current, current + 1));
    }

    public int getAcquire() {
        return (int) COUNT_HANDLE.getAcquire(this);
    }

    void main() {
        var counter = new VarHandleCounter();
        counter.incrementRelaxed();
        System.out.println("VarHandle ile güncellenen sayaç: " + counter.getAcquire());
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
      VarHandle tanımlayıcıları (MethodHandles.Lookup) MUTLAKA `private static final` olarak tanımlanmalıdır! Eğer nesne düzeyinde (instance variable) veya metot içinde lookup yaparsanız JIT derleyicisi çağrıyı inline edemez ve performans 100 kat düşer.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[`VarHandle` references MUST be declared `private static final`! If lookups are performed dynamically inside instance methods, the JIT C2 compiler cannot constant-fold the callsite into direct native assembly intrinsics, causing a catastrophic 100x performance drop.]
    ]
  )
]

#takeaways_box((
    ("VarHandle, Unsafe'in güvenli ve modern halidir. Plain, Opaque, Acquire/Release ve Volatile modlarıyla CPU bariyerlerini milimetrik kontrol etmenizi sağlar.", "VarHandle replaces `sun.misc.Unsafe` with type-safe, JIT-intrinsic memory operations across Plain, Opaque, Acquire/Release, and Volatile barrier modes."),
))
