#import "/template.typ": *

#show: doc => setup_book(title: "Ders 12: Yüksek Ölçekli Sayaçlar: LongAdder vs AtomicLong (Striped64 & Dağıtık Hücreler)", doc)

#lesson_header(
  12,
  "Yüksek Ölçekli Sayaçlar: LongAdder vs AtomicLong (Striped64 & Dağıtık Hücreler)",
  "High-Throughput Scalability: LongAdder vs AtomicLong (Striped64 & Cell Arrays)",
  "Volatile Anahtar Kelimesi, Atomiklik & Görünürlük",
  "The volatile Keyword, Atomicity & Visibility"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 ATOMICLONG (DARBOĞAZ) vs LONGADDER (ÖLÇEKLENEBİLİR)         │
└─────────────────────────────────────────────────────────────────────────────┘
  ATOMICLONG (Tek Bir Değişken Üzerinde Kavga):
  Thread 1 ──┐
  Thread 2 ──┼──▶ [ Tek bir volatile long 'value' ] ──▶ CAS Çarpışması!
  Thread 3 ──┤      (Herkes aynı 64-baytlık cache satırına saldırır)
  Thread 4 ──┘

  LONGADDER / STRIPED64 (Dağıtık Hücre Mimarisi):
  Thread 1 ──▶ [ Cell 0 ] (Core 0 L1 Cache)
  Thread 2 ──▶ [ Cell 1 ] (Core 1 L1 Cache)  ──▶ SIFIR ÇARPIŞMA!
  Thread 3 ──▶ [ Cell 2 ] (Core 2 L1 Cache)  ──▶ ULTRA YÜKSEK HIZ!
  Thread 4 ──▶ [ Cell 3 ] (Core 3 L1 Cache)
                     │
                     ▼ (sum() çağrıldığında)
       Toplam = Base + Cell 0 + Cell 1 + Cell 2 + Cell 3
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir süpermarkette tek bir kasa olduğunu düşünün (AtomicLong). 50 müşteri aynı anda tek bir kasiyere para ödemeye çalışırsa birbirini ezer, kuyruk uzar. LongAdder ise süpermarkete 8 ayrı kasa açmak gibidir! Müşteriler farklı kasalara (Cell) dağılır, kimse kimseyi beklemeden parasını öder. Günün sonunda patron kasaların hepsini toplar (sum()) ve toplam ciroyu bulur! Okuma nadir, yazma çoksa LongAdder 100 kat daha hızlıdır!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Picture a stadium with a single concession register (AtomicLong). Thousands of fans violently rush that lone cashier simultaneously, resulting in massive bottlenecks and dropped orders. LongAdder opens 16 parallel registers distributed across the stadium (Cell array). Fans transact at their nearest register with zero friction. At halftime, the accountant aggregates balances across all registers (`sum()`). When writes dominate, LongAdder outpaces AtomicLong by orders of magnitude!]
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
      Striped64 Mimarisi ve LongAdder Derinliği: 1) Çekişme Azaltma (Contention Mitigation): `AtomicLong` tek bir bellek adresi üzerinde CAS yapar; thread sayısı arttıkça L1 cache geçersiz kılma (cache invalidation) fırtınası kopar. 2) `Cell[]` Dizisi: LongAdder, Doug Lea tarafından yazılan `Striped64` sınıfından türer. Çekişme tespit edildiğinde thread ID'sinin hash'ine göre dinamik olarak `Cell` dizisi büyütülür (2, 4, 8, 16...). Her `Cell` kendi içinde `\@Contended` anotasyonu ile 128 bayt doldurulmuştur (Padding), böylece False Sharing tamamen önlenir! 3) Ne Zaman AtomicLong, Ne Zaman LongAdder?: Eğer atomik bir sıra numarası (Sequence ID: `incrementAndGet()`) gerekiyorsa `AtomicLong` zorunludur. Eğer sadece metrik toplama, sayaç tutma veya istatistik yapılıyorsa kesinlikle `LongAdder` tercih edilmelidir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Internal Mechanics of Striped64: 1) The Contention Bottleneck of AtomicLong: AtomicLong forces all concurrent cores to serialize writes to a single memory offset, saturating the cache bus with MESI invalidation traffic. 2) Striped64 Cell Dynamism: LongAdder maintains a `base` variable. If a CAS on `base` fails due to contention, it allocates a `Cell[]` table sized to a power of two (capped at CPU core count). Each thread hashes into a specific `Cell`. Crucially, each `Cell` is annotated with `\@jdk.internal.vm.annotation.Contended`, enforcing 128-byte cache-line isolation to eliminate false sharing. 3) Architectural Trade-Off: `LongAdder.sum()` is an eventual snapshot, not an atomic instantaneous freeze. Use `AtomicLong` when sequential order or exact compare-and-set guards are required (`compareAndSet()`); use `LongAdder` for high-frequency telemetry, request counting, and metrics.]
    ]
  )
]

#java25_box[
```java
// Java 25: Yüksek Ölçekli Metrik Toplama için LongAdder
import java.util.concurrent.atomic.LongAdder;

public class MetricsCollector {
    // Saniyede 1 milyon HTTP isteğini kaydetmek için idealdir
    private final LongAdder requestCount = new LongAdder();

    public void onRequestReceived() {
        requestCount.increment(); // Çarpışmasız, dağıtık hücreye yazar
    }

    public long getTotalRequests() {
        return requestCount.sum(); // Tüm hücreleri toplar
    }

    void main() throws InterruptedException {
        var metrics = new MetricsCollector();
        int threads = 8;
        int reqPerThread = 500_000;

        Thread[] workers = new Thread[threads];
        for (int i = 0; i < threads; i++) {
            workers[i] = Thread.ofPlatform().start(() -> {
                for (int j = 0; j < reqPerThread; j++) {
                    metrics.onRequestReceived();
                }
            });
        }

        for (Thread t : workers) t.join();

        IO.println("Toplam Başarılı İstek: " + metrics.getTotalRequests()); // 4,000,000
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
      Mülakat Tuzağı: 'Banka hesap bakiyesi veya sıra numarası için LongAdder kullanabilir miyiz?' Yanıt: 'HAYIR! LongAdder atomik bir `compareAndSet` veya anlık kesin okuma sunmaz. `sum()` çağrısı yapılırken arka planda yazmalar devam edebilir. Sıra numarası için daima AtomicLong kullanılmalıdır!'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Critical Interview Distinction: 'Can we use LongAdder to issue unique order IDs or manage account balances?' Answer: 'NO! LongAdder does not provide an atomic `compareAndSet()` or transactional read-and-mutate guarantee. `sum()` yields an eventual aggregate, not an isolated lockstep snapshot. Unique sequences require AtomicLong.']
    ]
  )
]

#takeaways_box((
    ("LongAdder, yüksek çekişmeli yazma işlemlerinde AtomicLong'dan 10-100 kat daha hızlıdır.", "LongAdder achieves 10-100x throughput over AtomicLong under high write contention."),
    ("Striped64 hücreleri \@Contended ile pad edildiği için False Sharing yaşanmaz.", "Striped64 cells are padded to prevent False Sharing across CPU cache lines."),
    ("Benzersiz sıra numarası (Sequence ID) için AtomicLong; metrikler için LongAdder seçilir.", "Use AtomicLong for atomic sequential IDs; use LongAdder for high-volume metrics."),
))
