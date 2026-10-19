#import "/template.typ": *

#show: doc => setup_book(title: "Ders 26: Ret Politikaları (Rejection Policies): Abort, CallerRuns, Discard & DiscardOldest", doc)

#lesson_header(
  26,
  "Ret Politikaları (Rejection Policies): Abort, CallerRuns, Discard & DiscardOldest",
  "Task Rejection Policies: AbortPolicy, CallerRuns, Discard & DiscardOldest",
  "Thread Havuzları, Executor'lar & Work-Stealing",
  "Thread Pools, Executors & Work-Stealing Algorithms"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 THREAD POOL 4 RET POLİTİKASI (REJECTION POLICIES)           │
└─────────────────────────────────────────────────────────────────────────────┘
  KUYRUK DOLU VE MAX THREAD'LER MEŞGUL İKEN YENİ GÖREV GELDİĞİNDE:

  1. AbortPolicy (Varsayılan / Sert):
     ──▶ RejectedExecutionException fırlatır! "Ben tıkandım, işlemi reddediyorum!"
     
  2. CallerRunsPolicy (En Popüler / Doğal Backpressure):
     ──▶ Görevi havuz değil, görevi havuza GÖNDEREN THREAD (Örn: Tomcat HTTP) çalıştırır!
     ──▶ Gönderen thread meşgul olunca yeni istek kabul edemez; sistem doğal olarak yavaşlar!
     
  3. DiscardPolicy (Sessiz Çöp):
     ──▶ Görevi hiçbir hata fırlatmadan SESSİZCE ÇÖPE ATAR! (Örn: Önemsiz log/metrik)
     
  4. DiscardOldestPolicy (En Eskiye Tekme):
     ──▶ Kuyruğun başındaki en eski görevi silip atar, yeni görevi kuyruğa sokar!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir pizzacı dükkanı düşünün. Fırınlar dolu, masalar dolu, kuryeler meşgul. Kapıdan yeni bir müşteri girip pizza istediğinde pizzacı ne yapar? 1) Abort: Müşterinin yüzüne kapıyı çarpar: 'Sipariş alamam!' der (Hata fırlatır). 2) CallerRuns: Müşterinin eline önlük tutuşturur: 'Çok istiyorsan mutfağa gir kendin pişir!' der (İsteği getiren kişi kendi işini kendi yapar, böylece kapıda yeni müşteri birikmez). 3) Discard: Sipariş fişini alır ve müşteri arkasını döndüğü anda çöpe atar (Sessizce yutar). 4) DiscardOldest: Bekleyen en eski müşterinin siparişini iptal eder, yeni gelen müşteriyi sıraya alır!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Imagine a bakery operating at maximum capacity. The oven is full, counters overflowing. When a customer orders a cake: 1) AbortPolicy: The baker slams the shutter and shouts 'Denied!' (`RejectedExecutionException`). 2) CallerRunsPolicy: The baker hands the customer an apron: 'Bake it yourself!' The caller executes the task on their own thread, naturally throttling new orders. 3) DiscardPolicy: The baker silently drops the order slip into the trash (silent drop). 4) DiscardOldestPolicy: The baker evicts the oldest stale ticket waiting in line and enqueues the fresh order.]
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
      CallerRunsPolicy ile Doğal Backpressure (Geri Basınç): 1) Neden Üretimde CallerRuns Tercih Edilir?: Web sunucularında (Tomcat, Netty, Spring Boot) arka plandaki thread havuzu tıkandığında `CallerRunsPolicy` seçilirse, görevi havuza atan HTTP Acceptor thread'i görevi kendi üzerinde koşturmaya başlar. Bu süre zarfında soketten yeni HTTP istekleri kabul edilemez; işletim sistemi TCP SYN kuyruğunda bekletir veya yük dengeleyiciye (Load Balancer) 'Ben doluyum' sinyali gider. Bu, sistemin OOM çöküşünü önleyen en zarif mimari savunmadır. 2) DiscardOldest Tehlikesi: `PriorityBlockingQueue` ile kullanılırsa, en eski görev yerine en yüksek öncelikli görev çöpe atılabilir!
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[CallerRunsPolicy & The Elegance of Organic Backpressure: 1) Mitigating Cascading Failures: When a downstream worker pool saturates, `CallerRunsPolicy` delegates execution to the invoking thread (e.g. Tomcat/Jetty worker). Because the calling thread is now occupied executing computation, it stops accepting new requests from the network socket. The TCP receive buffer fills, and upstream load balancers detect backpressure, rerouting traffic away from the saturated node. 2) DiscardOldest Hazard: When paired with a `PriorityBlockingQueue`, `DiscardOldest` evicts the head of the queue, which is the HIGHEST priority task, not the oldest chronologically!]
    ]
  )
]

#java25_box[
```java
// Java 25: CallerRunsPolicy ile Doğal Backpressure Gösterimi
import java.util.concurrent.*;

public class RejectionPolicyDemo {
    void main() {
        // 1 Thread, 1 Kuyruk Kapasitesi (Toplam 2 görev alabilir)
        var executor = new ThreadPoolExecutor(
            1, 1, 0L, TimeUnit.SECONDS,
            new ArrayBlockingQueue<>(1),
            new ThreadPoolExecutor.CallerRunsPolicy() // Backpressure kalkanı
        );

        for (int i = 1; i <= 4; i++) {
            final int taskId = i;
            executor.execute(() -> {
                IO.println("Görev #" + taskId + " çalıştırılıyor. Thread: " + Thread.currentThread().getName());
                try { Thread.sleep(200); } catch (InterruptedException ignored) {}
            });
        }

        executor.shutdown();
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
      Mülakat Tuzağı: Mülakatçı 'CallerRunsPolicy kullandığımızda ana thread kilitlenebilir mi?' diye sorar. Yanıt: 'Evet! Eğer havuza atılan görev uzun süren bir işlemse veya bloke oluyorsa, ana thread (ör. UI thread veya Netty event-loop) o görevi çalıştırırken donar ve tüm uygulamanın tepki süresi (responsiveness) durur!'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Architectural Hazard: 'Can CallerRunsPolicy degrade the application main loop?' Answer: 'YES! If the calling thread is a Netty EventLoop or a UI dispatcher, forcing it to run long-running CPU or blocking I/O tasks halts the entire event-loop, starving all other multiplexed channels.']
    ]
  )
]

#takeaways_box((
    ("AbortPolicy varsayılandır ve RejectedExecutionException fırlatır.", "AbortPolicy is the default, throwing RejectedExecutionException on saturation."),
    ("CallerRunsPolicy, çağıran thread'i çalıştırarak doğal bir backpressure kalkanı oluşturur.", "CallerRunsPolicy creates natural backpressure by forcing the submitting thread to execute the work."),
    ("DiscardPolicy sessizce görevi yutar; yalnızca önemsiz telemetri loglarında kullanılmalıdır.", "DiscardPolicy silently drops tasks and should only be applied to dispensable metrics."),
))
