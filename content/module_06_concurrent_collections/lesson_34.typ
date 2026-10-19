#import "/template.typ": *

#show: doc => setup_book(title: "Ders 34: Sıfır Kapasiteli El Sıkışma: SynchronousQueue vs TransferQueue", doc)

#lesson_header(
  34,
  "Sıfır Kapasiteli El Sıkışma: SynchronousQueue vs TransferQueue",
  "Zero-Capacity Direct Handoffs: SynchronousQueue vs TransferQueue",
  "Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları",
  "Concurrent Collections & Thread-Safe Data Structures"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 SYNCHRONOUSQUEUE: SIFIR KAPASİTELİ EL SIKIŞMA               │
└─────────────────────────────────────────────────────────────────────────────┘
  KAPASİTE = 0 (HİÇBİR ELEMANI İÇİNDE SAKLAMAZ!)
  
  Thread A (Üretici):                          Thread B (Tüketici):
  queue.put("GÖREV");                           
          │                                             
          ▼                                             
  [ HAVADA ASILI BEKLER! ]                              
  (Tüketici gelene kadar bloke olur!)                    
          │                                             
          │                                     queue.take();
          │                                             │
          └──────────────────────┬──────────────────────┘
                                 │
                                 ▼
                     DOĞRUDAN EL SIKIŞMA (HANDOFF)
                     Veri tamponlanmadan el değiştirir!

  LinkedTransferQueue:
  transfer(x) ──▶ Tüketici o an varsa doğrudan ver, yoksa kuyruğa koy bekle!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Normal bir restoranda aşçı yemeği yapar, tezgahın üzerine koyar (Tamponlu kuyruk). SynchronousQueue'da ise tezgah YOKTUR (Kapasite = 0)! Aşçı sıcak tabağı elinde havada tutar (`put()`). Bir garson gelip tabağı aşçının elinden alana kadar (`take()`) aşçı kaskatı bekler! Tabak elden ele doğrudan teslim edilir. Arada hiçbir bekleme masası yoktur. Eğer hemen teslim alamayacaksan, aşçı yemeği pişirmeye bile kalkışmaz!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[In a standard cafeteria, chefs set plates onto a warming counter (Buffering). A SynchronousQueue HAS NO COUNTER (Capacity = 0). The chef holds the scalding plate in mid-air (`put()`). The chef stands frozen in place until a server arrives to take the plate directly from their hands (`take()`). The transfer is an immediate atomic handoff from one thread's registers to another. If no server is waiting, the producer blocks instantly.]
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
      Doğrudan El Sıkışma (Direct Handoff) ve Dual Stack/Queue Mimarisi: 1) Sıfır Kapasite Felsefesi: `SynchronousQueue.size()` daima 0 döner; `peek()` daima null döner. Bir elemanı kuyruğa koymak ile o elemanın başka bir thread tarafından teslim alınması aynı zaman diliminde gerçekleşmek zorundadır. 2) Non-blocking Dual Queue (Scherer-Scott Algoritması): SynchronousQueue içsel olarak kilit kullanmaz; bekleyen üreticileri veya tüketicileri temsil eden düğümleri (QNode) lock-free bir yığında (TransferStack) veya kuyrukta (TransferQueue) CAS ile yönetir. 3) LinkedTransferQueue: Java 7 ile gelen bu yapı hem `BlockingQueue` hem de `TransferQueue` özelliklerini birleştirir. `tryTransfer(e)` metodu eğer bekleyen tüketici varsa anında el sıkışır, yoksa beklemeden false döner.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Zero-Capacity Handoff Mechanics: 1) The Non-Buffering Invariant: `SynchronousQueue` has zero internal storage. `put(e)` blocks until a concurrent `take()` arrives; `take()` blocks until a concurrent `put(e)` arrives. 2) Scherer-Scott Dual Stack/Queue: Implemented via lock-free dual data structures. Nodes represent either data requests or data fulfillment. Threads match against opposite-mode nodes using atomic CAS operations, eliminating monitor overhead. 3) `LinkedTransferQueue`: Blends `LinkedBlockingQueue` buffering with `SynchronousQueue` handoffs. The `transfer()` method blocks until a consumer accepts the item; `tryTransfer()` offers instant zero-wait handoffs.]
    ]
  )
]

#java25_box[
```java
// Java 25: SynchronousQueue ile Doğrudan Handoff Gösterimi
import java.util.concurrent.SynchronousQueue;

public class DirectHandoffDemo {
    void main() throws InterruptedException {
        var syncQueue = new SynchronousQueue<String>();

        // Tüketici Thread (1 saniye geç başlıyor)
        Thread.ofPlatform().name("Consumer").start(() -> {
            try {
                Thread.sleep(1000);
                IO.println("Tüketici geldi, veriyi elden alıyor...");
                String item = syncQueue.take();
                IO.println("Tüketici teslim aldı: " + item);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        // Üretici Thread
        IO.println("Üretici: Veri teslim edilmeye çalışılıyor (put)...");
        long start = System.currentTimeMillis();
        syncQueue.put("Ultra-Önemli VIP Mesaj"); // Tüketici gelene kadar 1 saniye burada BLOKE OLUR!
        long elapsed = System.currentTimeMillis() - start;

        IO.println("Üretici: Veri el sıkışarak teslim edildi! Geçen süre: " + elapsed + " ms");
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
      Mülakat Klasiği: 'Executors.newCachedThreadPool() hangi kuyruğu kullanır ve neden?' Yanıt: 'SynchronousQueue kullanır! Çünkü gelen görevi hiçbir ara tamponda bekletmeden hemen boşta bekleyen bir thread'e teslim etmek ister; boşta thread yoksa anında yeni bir thread açar!'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Crucial Interview Question: 'Which queue powers `Executors.newCachedThreadPool()` and why?' Answer: 'It uses `SynchronousQueue`! It demands immediate direct handoff to an idle worker. If all workers are busy, the handoff fails immediately, forcing the pool to spawn a new native thread instantly.']
    ]
  )
]

#takeaways_box((
    ("SynchronousQueue'nun kapasitesi sıfırdır; veriyi asla bellekte tutmaz.", "SynchronousQueue has zero internal capacity and never buffers elements."),
    ("put() çağrısı başka bir thread take() çağırana kadar bloke bekler.", "put() blocks until a matching take() arrives, executing an atomic thread-to-thread handoff."),
    ("Executors.newCachedThreadPool doğrudan handoff için SynchronousQueue kullanır.", "newCachedThreadPool relies on SynchronousQueue to enforce immediate task assignment."),
))
