#import "/template.typ": *

#show: doc => setup_book(title: "Ders 41: Hata Kurtarma Zincirleri: exceptionally vs handle vs whenComplete ile Dayanıklılık", doc)

#lesson_header(
  41,
  "Hata Kurtarma Zincirleri: exceptionally vs handle vs whenComplete ile Dayanıklılık",
  "Resilience & Exception Handling: exceptionally vs handle vs whenComplete",
  "Asenkron Boru Hatları & CompletableFuture",
  "Asynchronous Pipelines & CompletableFuture"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       HATA YAKALAMA VE KURTARMA STRATEJİSİ                  │
└─────────────────────────────────────────────────────────────────────────────┘
  BAŞARILI AKIŞ:  [ Veri Çek ] ──▶ [ Veri Dönüştür ] ──▶ [ Kaydet ]
                        │
                        ▼ (HATA OLUŞTU!)
  1. exceptionally(ex -> fallback):
     Hatayı yakalar, yedek bir varsayılan değer üretir; akış normale döner!

  2. handle((data, ex) -> result):
     HEM başarılı veriyi HEM hatayı yakalar; veriyi dönüştürür veya alternatif üretir.

  3. whenComplete((data, ex) -> sideEffect):
     Akışı DEĞİŞTİRMEZ! Sadece loglama veya kaynak temizliği yapar (try-finally gibi).
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir kargo teslimatı düşünün: 1) exceptionally: Müşteri evde yoksa kargoyu kapıcıya bırakmaktır (hata olursa yedek plan devreye girer, paket teslim edilmiş sayılır). 2) handle: Kuryenin kapıyı çaldıktan sonra 'Paketi teslim ettim' veya 'Evde yoktu, şubeye yönlendirdim' diye merkez sisteme rapor hazırlamasıdır (hem başarıyı hem hatayı tek bir yeni sonuca çevirir). 3) whenComplete: Paket teslim edilse de kaybolsa da kuryenin araba günlüğüne 'Bu adrese uğrandı' diye imza atmasıdır (akışı değiştirmez, sadece log tutar).
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[1) `exceptionally`: Like a fallback generator. If the primary power grid cuts out, the backup diesel generator fires up seamlessly, supplying replacement power downstream. 2) `handle`: An inspection checkpoint. It receives both `(result, throwable)`. Whether the product is pristine or shattered, it packs it into an inspected report object for downstream consumers. 3) `whenComplete`: Pure side-effect auditing (like `finally`). It logs whether the transaction succeeded or threw an error, but re-emits the exact upstream state downstream without alteration.]
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
      Metot İmzaları ve İstisna Kapsülleme (CompletionException): CompletableFuture içindeki kontrol edilmeyen hatalar HotSpot tarafından otomatik olarak `CompletionException` ile sarılır. 1) `exceptionally(Function\<Throwable, T>)`: Yalnızca istisna durumunda tetiklenir. İstisnayı yutar ve geriye geçerli bir `T` değeri döndürerek pipeline'ı kurtarır. 2) `handle(BiFunction\<T, Throwable, U>)`: İstisna olsun veya olmasın her durumda tetiklenir. Eğer `ex != null` ise hata işlenir, aksi halde `res` işlenir. Yeni bir `U` tipi döndürür. 3) `whenComplete(BiConsumer\<T, Throwable>)`: Gözlemcidir (side-effect). Geriye değer döndürmez (`void`). Orijinal stage'in sonucunu veya istisnasını aynen sonraki aşamalara geçirir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[HotSpot Exception Handling Mechanics: Unchecked exceptions in asynchronous pipelines are wrapped in `CompletionException`. 1) `exceptionally`: Invoked exclusively on stage failure. Catches the `Throwable`, recovers with an alternative value `T`, and transitions the downstream stage to normal completion. 2) `handle`: Invoked unconditionally on dual outcomes `(T result, Throwable ex)`. Transforms either state into `U`. 3) `whenComplete`: Passive terminal/audit stage taking `BiConsumer\<T, Throwable>`. It executes side-effects (metrics, auditing) without intercepting or altering the original value/exception payload.]
    ]
  )
]

#java25_box[
```java
// Java 25: CompletableFuture Dayanıklı Hata Kurtarma
import java.util.concurrent.CompletableFuture;

public class ResilientPipelineDemo {
    record Price(String symbol, double amount, boolean isFallback) {}

    static CompletableFuture<Double> fetchLivePriceFromExchange(String symbol) {
        return CompletableFuture.supplyAsync(() -> {
            if ("BTC".equals(symbol)) {
                throw new IllegalStateException("Kripto Borsası Çöktü (503 Service Unavailable)!");
            }
            return 65000.0;
        });
    }

    void main() {
        String symbol = "BTC";

        CompletableFuture<Price> priceFuture = fetchLivePriceFromExchange(symbol)
            // 1. exceptionally ile hatayı yakala ve önbellekten fallback dön!
            .exceptionally(ex -> {
                System.err.println("⚠️ Hata Yakalandı: " + ex.getMessage() + ". Önbelleğe dönülüyor...");
                return 62000.0; // Cached fallback price
            })
            // 2. handle ile veriyi modelle
            .handle((val, ex) -> {
                boolean isFallback = (val == 62000.0);
                return new Price(symbol, val, isFallback);
            })
            // 3. whenComplete ile metrik logla (akışı bozmaz!)
            .whenComplete((price, ex) -> {
                System.out.println("📊 Audit Log: Fiyat başarıyla belirlendi -> " + price);
            });

        Price finalPrice = priceFuture.join();
        System.out.println("Sonuç: " + finalPrice);
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
      exceptionallyAsync kullanmazsanız, hata anında fallback üretme kodu hatanın patladığı worker thread üzerinde çalışır. Fallback kodu veritabanına veya diske gidiyorsa thread'i kilitler; bu tür I/O kurtarmalarında exceptionallyCompose veya exceptionallyAsync tercih edilmelidir.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Unless `exceptionallyAsync` is used, the fallback logic executes synchronously on whichever worker thread encountered the upstream exception. If your fallback invokes blocking I/O (e.g. disk or cache reads), use `exceptionallyComposeAsync` to avoid carrier thread exhaustion.]
    ]
  )
]

#takeaways_box((
    ("exceptionally hatayı varsayılan değerle kurtarır. handle hem hatayı hem başarıyı dönüştürür. whenComplete ise yan etkisiz loglama yapar.", "`exceptionally` recovers from failure with a fallback. `handle` translates dual states into a new value. `whenComplete` performs side-effects without altering state."),
))
