#import "/template.typ": *

#show: doc => setup_book(title: "Ders 40: Fan-Out & Fan-In Orkestrasyonu: CompletableFuture.allOf vs anyOf ile Dağıtık Koordinasyon", doc)

#lesson_header(
  40,
  "Fan-Out & Fan-In Orkestrasyonu: CompletableFuture.allOf vs anyOf ile Dağıtık Koordinasyon",
  "Fan-Out & Fan-In Coordination: CompletableFuture.allOf vs anyOf",
  "Asenkron Boru Hatları & CompletableFuture",
  "Asynchronous Pipelines & CompletableFuture"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FAN-OUT (DAĞITMA) & FAN-IN (TOPLAMA)                     │
└─────────────────────────────────────────────────────────────────────────────┘
  1. allOf (Tüm Adayları Bekle - Scatter-Gather):
     Sorgu ──┬──▶ THY Bilet Servisi    ──┐
             ├──▶ Pegasus Bilet Servisi ──┼──▶ allOf.join() ──▶ [ En Ucuzunu Seç ]
             └──▶ SunExpress Servisi    ──┘
     ⚠️ allOf geriye CompletableFuture<Void> döner! Sonuçlar tek tek toplanmalıdır.

  2. anyOf (İlk Yanıt Vereni Al - Hedged Requests):
     DNS Sorgusu ──┬──▶ Google DNS (8.8.8.8)     ──┐
                   ├──▶ Cloudflare DNS (1.1.1.1) ──┼──▶ anyOf() ──▶ [ İlk Gelen Yanıtı Kullan ]
                   └──▶ Quad9 DNS (9.9.9.9)      ──┘
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      allOf: Bir otobüs şoförünün tüm yolcuların (uçak bileti arayan 5 farklı sitenin) binmesini beklemesi gibidir. Herkes binmeden otobüs kalkmaz; sonra yolcuların biletlerini sayarsın. anyOf ise bir taksi durağında sıraya girip ilk gelen boş taksiye binmektir. 3 taksiyi birden çağırırsın, kapıya ilk yanaşan taksiye biner gidersin; diğerleri boşa çıkar!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[`CompletableFuture.allOf` is scatter-gather: A travel aggregator querying 5 airline APIs concurrently. The master request waits until every single airline responds before filtering the lowest price. `CompletableFuture.anyOf` is hedged requests: Querying 3 redundant DNS mirrors (Google, Cloudflare, Quad9) simultaneously and immediately returning whichever responds first, discarding trailing packets.]
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
      HotSpot allOf ve anyOf İç Mantığı: 1) `allOf(CompletableFuture\<?>... cfs)`: Dahili olarak bir `BiRelay` ağacı kurar. Her bir future tamamlandığında bir sayaç eksiltilir. Sayaç 0'a ulaştığında bileşik future tetiklenir. DÖNÜŞ TİPİ `CompletableFuture\<Void>`'dir! Sonuçları almak için orijinal future dizisi stream edilip `CompletableFuture::join` ile toplanır (bu noktada tümü bittiği için join ASLA bloklamaz). 2) `anyOf(CompletableFuture\<?>... cfs)`: İlk tamamlanan (veya ilk istisna fırlatan) future bileşik nesneyi çözer. DÖNÜŞ TİPİ `CompletableFuture\<Object>`'tir ve tip dönüşümü (cast) gerektirir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[HotSpot Implementation Details: 1) `allOf`: Constructs a binary tree of completion relays. Each completing leaf decrements an atomic countdown latch. Returns `CompletableFuture\<Void>` by design to accommodate heterogeneous return types. To extract payloads, stream over the input list mapping via `CompletableFuture::join`—which is guaranteed non-blocking because all tasks are already resolved. 2) `anyOf`: Binds an identical completion handler to all upstream stages; the first node to transition invokes `completeRelay()`. Returns `CompletableFuture\<Object>`, requiring explicit downcasting.]
    ]
  )
]

#java25_box[
```java
// Java 25: allOf ile Scatter-Gather Fiyat Toplama
import java.util.List;
import java.util.concurrent.CompletableFuture;

public class ScatterGatherAggregator {
    record PriceQuote(String provider, double price) {}

    static CompletableFuture<PriceQuote> fetchQuote(String provider, double price, long delayMs) {
        return CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(delayMs); } catch (InterruptedException _) {}
            return new PriceQuote(provider, price);
        });
    }

    void main() {
        var futures = List.of(
            fetchQuote("Airline-A", 180.0, 50),
            fetchQuote("Airline-B", 150.0, 80),
            fetchQuote("Airline-C", 210.0, 30)
        );

        // allOf ile tüm servislerin bitmesini bekle
        CompletableFuture<Void> allDone = CompletableFuture.allOf(
            futures.toArray(new CompletableFuture[0])
        );

        // Non-blocking toplama (join garantili olarak anında döner!)
        CompletableFuture<List<PriceQuote>> quotesFuture = allDone.thenApply(_ ->
            futures.stream().map(CompletableFuture::join).toList()
        );

        List<PriceQuote> quotes = quotesFuture.join();
        PriceQuote bestQuote = quotes.stream()
            .min((q1, q2) -> Double.compare(q1.price(), q2.price()))
            .orElseThrow();

        System.out.println("En İyi Teklif: " + bestQuote);
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
      allOf içinde tek bir future patlarsa (exception), allOf da anında patlar! Ancak diğer çalışan future'lar arka planda çalışmaya ve kaynak tüketmeye devam eder. Dağıtık sistemlerde allOf kullanırken her alt task'ın içine 'exceptionally' koyarak default fallback üretmesini sağlayın.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[If any child future fails inside `allOf`, the composite future fails immediately. However, surviving peer futures continue running in the background, squandering resources. Always attach `.exceptionally()` or fallback handlers to individual stages before passing them into `allOf`.]
    ]
  )
]

#takeaways_box((
    ("allOf tüm görevlerin bitmesini bekler (scatter-gather, Void döner). anyOf ilk biteni alır (hedged request, Object döner).", "`allOf` waits for all stages to conclude (scatter-gather, returns `Void`). `anyOf` yields the first finished stage (hedged calls, returns `Object`)."),
))
