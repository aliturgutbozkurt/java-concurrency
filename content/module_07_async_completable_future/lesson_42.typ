#import "/template.typ": *

#show: doc => setup_book(title: "Ders 42: Zaman Aşımı ve Varsayılanlar: orTimeout() vs completeOnTimeout() ile Gecikme Yönetimi", doc)

#lesson_header(
  42,
  "Zaman Aşımı ve Varsayılanlar: orTimeout() vs completeOnTimeout() ile Gecikme Yönetimi",
  "Timeouts & Default Fallbacks: orTimeout() and completeOnTimeout()",
  "Asenkron Boru Hatları & CompletableFuture",
  "Asynchronous Pipelines & CompletableFuture"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ZAMAN AŞIMI YÖNETİMİ (TIMEOUT PIPELINE)               │
└─────────────────────────────────────────────────────────────────────────────┘
  İstek Başladı (T = 0s)
     │
     ├──[ 500ms içinde bitti mi? ] ──EVET──▶ Normal Sonuç Döndürülür
     │
     └──HAYIR (500ms DOLDU!) ──┬──▶ orTimeout(500, TimeUnit.MILLISECONDS)
                               │    💥 TimeoutException Fırlatılır!
                               │
                               └──▶ completeOnTimeout(DEFAULT, 500, MILLISECONDS)
                                    🛡️ Sessizce Güvenli Varsayılan Değer Verilir!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir restoranda sipariş verdiniz ve garsona dediniz ki: 1) orTimeout: '15 dakikada yemeğim gelmezse masayı terk eder, bağırarak çıkarım!' (Süre dolunca ortalığı ayağa kaldıran bir TimeoutException patlar). 2) completeOnTimeout: '15 dakikada biftek pişmezse bana hazır olan soğuk sandviçi getirin, karnımı doyurayım' demektir (Süre dolunca kimse üzülmez, önceden belirlenen yedek sandviç servis edilir).
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[`orTimeout()` is hard SLA enforcement: 'If data does not arrive in 200ms, abort the mission and throw a `TimeoutException` immediately!' `completeOnTimeout()` is graceful degradation: 'If the recommendation AI does not respond within 50ms, return a default list of trending items so the homepage never loads blank'.]
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
      Java 9+ ve Java 25 Zaman Aşımı Mimarisi: Java 8'de CompletableFuture için zaman aşımı desteği yoktu; harici bir `ScheduledExecutorService` ile geleceğe cancel/complete basmak gerekiyordu. Modern Java iki güçlü yöntem sunar: 1) `orTimeout(long timeout, TimeUnit unit)`: Süre aşıldığında future'ı `java.util.concurrent.TimeoutException` ile anormal şekilde tamamlar (`completeExceptionally`). 2) `completeOnTimeout(T value, long timeout, TimeUnit unit)`: Belirtilen süre dolduğunda eğer future henüz tamamlanmamışsa, verilen `value` ile normal olarak tamamlanır (`complete(value)`). Bu mekanizma arka planda HotSpot'un paylaşımlı `Delayer` zamanlayıcı thread'ini kullanır; her talep için yeni thread açmaz.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Java 9+ Timeout Architecture: Prior to Java 9, developers had to manually schedule cancellation tasks via `ScheduledExecutorService`. Modern CompletableFuture incorporates: 1) `orTimeout()`: If incomplete when duration elapses, it forces exceptional completion with `TimeoutException`. 2) `completeOnTimeout()`: If incomplete upon timer expiration, it transitions the future to normal completion using the designated fallback object. Both methods register non-blocking delays using an internal daemon `CompletableFuture.Delayer` wheel timer, avoiding per-timeout thread allocations.]
    ]
  )
]

#java25_box[
```java
// Java 25: completeOnTimeout ile MAANG Servislerinde Graceful Degradation
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

public class TimeoutManagementDemo {
    record Recommendation(String productId, String category) {}

    static CompletableFuture<Recommendation> fetchAiRecommendations() {
        return CompletableFuture.supplyAsync(() -> {
            try {
                // Yapay zeka servisinin 800ms geciktiğini simüle et
                Thread.sleep(800);
            } catch (InterruptedException _) {}
            return new Recommendation("PROD-AI-99", "Personalized");
        });
    }

    void main() {
        Recommendation defaultFallback = new Recommendation("PROD-POPULAR-01", "Trending Now");

        // 200 ms SLA: 200 ms içinde gelmezse defaultFallback değerini bas!
        CompletableFuture<Recommendation> recoFuture = fetchAiRecommendations()
            .completeOnTimeout(defaultFallback, 200, TimeUnit.MILLISECONDS)
            .thenApply(reco -> {
                System.out.println("Kullanıcıya Gösterilen Ürün: " + reco);
                return reco;
            });

        Recommendation result = recoFuture.join();
        System.out.println("Ekrana Basılan Nihai Sonuç: " + result);
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
      completeOnTimeout çağrısı arka planda geciken asenkron işlemi İPTAL ETMEZ! Arka plandaki işçi thread geciken HTTP çağrısını yapmaya devam edebilir. Gerçekten soket veya thread iptali gerekiyorsa future.cancel(true) veya HTTP client zaman aşımları yapılandırılmalıdır.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[`completeOnTimeout` does NOT cancel the underlying upstream task! The worker thread running the database or HTTP call continues until completion in the background. To abort remote sockets, configure client-level timeouts alongside CompletableFuture.]
    ]
  )
]

#takeaways_box((
    ("orTimeout süre dolduğunda TimeoutException fırlatır. completeOnTimeout ise sessizce yedek bir varsayılan değerle aşamayı tamamlar.", "`orTimeout` aborts exceptionally with `TimeoutException`. `completeOnTimeout` silently injects a safe fallback upon SLA breach."),
))
