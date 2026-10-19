#import "/template.typ": *

#show: doc => setup_book(title: "Ders 35: Kilit-Siz Kuyruklar: ConcurrentLinkedQueue & Michael-Scott Algoritması", doc)

#lesson_header(
  35,
  "Kilit-Siz Kuyruklar: ConcurrentLinkedQueue & Michael-Scott Algoritması",
  "Lock-Free Queues: ConcurrentLinkedQueue & The Michael-Scott Algorithm",
  "Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları",
  "Concurrent Collections & Thread-Safe Data Structures"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 MICHAEL-SCOTT LOCK-FREE BAĞLI LİSTE KUYRUĞU                 │
└─────────────────────────────────────────────────────────────────────────────┘
  [ DUMMY HEAD NODE ] ──▶ [ NODE 1 ] ──▶ [ NODE 2 ] ──▶ null
          ▲                                  ▲
          │                                  │
     head pointer                       tail pointer

  YENİ ELEMAN EKLEME (ENQUEUE - 2 ADIMLI CAS):
  Adım 1: tail.next referansını CAS ile yeni düğüme bağla:
          [ NODE 2 ].next = [ YENİ NODE 3 ] ──▶ (CAS Başarılı!)
          
  Adım 2: tail pointer'ını bir ileri kaydır:
          tail = [ YENİ NODE 3 ] ──▶ (CAS ile kaydır)

  YARDIMLAŞMA PRENSİBİ (HELPING):
  Eğer bir thread Adım 1'i yapıp Adım 2'yi yapamadan CPU'dan düşerse;
  Gelen başka bir thread tail'in geride kaldığını fark eder ve tail'i ONUN YERİNE
  ileri kaydırır (Helping mechanism)! Sistem ASLA kilitlenmez!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir bayrak yarışı düşünün. Koşucular bayrağı birbirine devrederken sırayı durdurup hakemden izin almazlar (Kilit yok). Eğer bir koşucu bayrağı bir sonraki arkadaşına uzatıp tam çizgiye basamadan ayağı takılıp düşerse, arkadan gelen takım arkadaşı onun düşmesine aldırmaz; hemen eğilip onun yapamadığı adımı onun yerine tamamlar (Helping)! Kimse durmaz, bayrak yarışı ışık hızında devam eder!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Imagine a relay race with no referee stopping the clock for handoffs (Lock-Free). If Runner A clips the baton to Runner B's hand but trips before advancing the lane marker, Runner C arriving behind them doesn't panic. Runner C notices the unadvanced marker, nudges it forward on Runner A's behalf (The Helping Mechanism), and proceeds! Nobody waits for fallen runners; active threads complete stalled work cooperatively!]
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
      Michael-Scott Kuyruk Algoritması Derinliği: 1) Non-Blocking Garanti: Maged M. Michael ve Michael L. Scott tarafından 1996'da tasarlanan bu algoritma, `ConcurrentLinkedQueue`'nun kalbidir. Sistemin bütününde en az bir thread daima ilerleme (Progress guarantee) kaydeder. 2) Dummy Node (Yalancı Baş Düğüm): Kuyruk hiçbir zaman tamamen boş kalmaz; daima verisiz bir dummy node ile başlar. Bu sayede `head == tail` durumu özel bir kontrol gerektirmez. 3) Hop Count Optimizasyonu: HotSpot uygulamasında tail her `offer()` çağrısında değil, iki adımda bir güncellenir (`hops >= 2`). Bu sayede her eklemede iki kez CAS yapma maliyeti yarıya indirilir! 4) Bloklanmaz (Non-Blocking): `take()` gibi bloklayan bir metodu yoktur; boşsa `poll()` anında `null` döner.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Michael-Scott Lock-Free Queue Mechanics: 1) Theoretical Significance: Formally proven non-blocking queue published in 1996, foundational to `ConcurrentLinkedQueue`. It guarantees lock-free system-wide progress. 2) The Sentinel Dummy Node: The queue is initialized with a dummy sentinel node where `head == tail`. Enqueue operations never encounter an empty reference, eliminating null checks during concurrent pointer updates. 3) The Helping Hand Protocol: Enqueue is a two-step operation: swing `tail.next` to the new node, then swing `tail` to the new node. If Thread A stalls after step 1, Thread B detects `tail.next != null` and autonomously completes step 2 for Thread A before proceeding with its own enqueue! 4) Hop Batching: HotSpot batches tail updates every two hops, halving the number of expensive CAS cache-invalidation cycles.]
    ]
  )
]

#java25_box[
```java
// Java 25: ConcurrentLinkedQueue ile Kilit-Siz Yüksek Hızlı Kuyruk
import java.util.concurrent.ConcurrentLinkedQueue;

public class LockFreeQueueBenchmark {
    void main() throws InterruptedException {
        var queue = new ConcurrentLinkedQueue<Integer>();

        int producers = 4;
        int itemsPerProducer = 100_000;
        Thread[] threads = new Thread[producers];

        long start = System.currentTimeMillis();

        for (int i = 0; i < producers; i++) {
            threads[i] = Thread.ofPlatform().start(() -> {
                for (int j = 0; j < itemsPerProducer; j++) {
                    queue.offer(j); // SIFIR KİLİT! Tamamen CAS ile ekleme
                }
            });
        }

        for (Thread t : threads) t.join();
        long elapsed = System.currentTimeMillis() - start;

        IO.println("400.000 eleman kilit-siz eklendi. Süre: " + elapsed + " ms");
        IO.println("Kuyruk boyutu: " + queue.size());
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
      Performans Uyarısı: `ConcurrentLinkedQueue.size()` metodunu döngü içinde KESİNLİKLE çağırmayın! Çünkü kilit-siz kuyrukta sabit bir `size` değişkeni tutulamaz (tüm thread'lerin o değişkende kilitlenmesi gerekirdi). Bu yüzden `size()` metodu her çağrıldığında tüm kuyruğu baştan sona tek tek sayar (O(N) karmaşıklık)! Kuyruğun boş olup olmadığını anlamak için `isEmpty()` kullanılmalıdır (O(1)).
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Severe Performance Trap: Never invoke `ConcurrentLinkedQueue.size()` in a tight loop! Because a lock-free queue cannot maintain an atomic size counter without crippling CAS scalability, `size()` iterates the entire linked list from head to tail (\$O(N)\$ runtime). Always invoke `isEmpty()` which checks `head.next == null` in \$O(1)\$ time.]
    ]
  )
]

#takeaways_box((
    ("ConcurrentLinkedQueue, Michael-Scott kilit-siz kuyruk algoritmasını kullanır.", "ConcurrentLinkedQueue is built upon the Michael-Scott non-blocking queue algorithm."),
    ("Helping mekanizması sayesinde geri kalan pointer'lar diğer thread'ler tarafından tamamlanır.", "Cooperative helping allows active threads to swing stalled tail pointers forward."),
    ("size() metodu O(N) karmaşıklıktadır; boşluk kontrolü için daima isEmpty() kullanılmalıdır.", "size() runs in O(N) linear time; always use isEmpty() for O(1) empty checks."),
))
