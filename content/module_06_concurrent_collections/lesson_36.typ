#import "/template.typ": *

#show: doc => setup_book(title: "Ders 36: ConcurrentSkipListMap: Thread-Safe Sıralı Haritalar & Logaritmik Arama", doc)

#lesson_header(
  36,
  "ConcurrentSkipListMap: Thread-Safe Sıralı Haritalar & Logaritmik Arama",
  "ConcurrentSkipListMap: Thread-Safe Sorted Maps & Logarithmic Skip-Lists",
  "Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları",
  "Concurrent Collections & Thread-Safe Data Structures"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 CONCURRENTSKIPLISTMAP: ÇOK KATMANLI ATLAMA LİSTESİ          │
└─────────────────────────────────────────────────────────────────────────────┘
  Katman 3: [ 1 ] ──────────────────────────────────────────▶ [ 50 ] ──▶ null
              │                                                 │
  Katman 2: [ 1 ] ──────────────▶ [ 25 ] ───────────────────▶ [ 50 ] ──▶ null
              │                     │                           │
  Katman 1: [ 1 ] ──▶ [ 10 ] ───▶ [ 25 ] ──▶ [ 30 ] ────────▶ [ 50 ] ──▶ null
              │         │           │         │                 │
  Katman 0: [ 1 ]-[5]-[10]-[15]-[20]-[25]-[28]-[30]-[35]-[40]-[45]-[50] ──▶ null
  
  ARAMA (Örn: 30):
  Katman 3'ten başla ──▶ 1'den bak, 50 çok büyük! ──▶ Katman 2'ye in.
  Katman 2'de 25'e atla ──▶ 50 çok büyük! ──▶ Katman 1'e in.
  Katman 1'de 30'u BULDUN! (O(log N) Karmaşıklıkta KİLİT-SİZ ARAMA!)
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir tren hattı düşünün. En alttaki tren her istasyonda durur (Yerel banliyö treni: 1, 2, 3, 4...). Yolculuk saatler sürer. Ama üstte bir ekspres tren vardır; sadece büyük şehirlerde durur (1, 25, 50...). Siz önce ekspres trene binip hedefinize en yakın büyük şehre gidersiniz, oradan inip yerel trene binersiniz! SkipList tam olarak budur: Sıralı veriyi kilit kullanmadan O(log N) hızında arayan çok katmanlı ekspres tren hattıdır!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Think of an express subway system. The local train on the bottom track stops at every single station (1, 2, 3... 50). Riding it takes forever. But directly above it runs an Express line stopping only at major hubs (1, 25, 50). To find Station 30, you ride the top express line to Station 25, hop down one flight of stairs to the local track, and arrive at 30 in seconds! SkipLists provide lock-free logarithmic search (O(log N)) without rebalancing locks!]
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
      ConcurrentSkipListMap vs TreeMap Mimarisi: 1) TreeMap Neden Thread-Safe Yapılamaz?: Kırmızı-Siyah Ağaçlar (Red-Black Trees) ekleme veya silme yapıldığında ağacı dengelemek (Rotation) zorundadır. Ağaç döndürme işlemi kök düğüm dahil birden fazla düğümü kilitler; kilit-siz (lock-free) bir AVL veya Red-Black Tree yazmak pratikte imkansızdır. 2) William Pugh Skip-List Mimarisi: Düğümler olasılıksal olarak yazı-tura atılarak (Coin Flipping) rastgele katmanlara terfi ettirilir. Ekleme ve silme sadece yerel komşu düğümler üzerinde CAS ile yapılır; global ağaç döndürme gerekmez! 3) Thread-Safe Sıralı Gezinme: `subMap()`, `headMap()`, `tailMap()` gibi aralık (Range-Query) sorguları çoklu thread ortamında yüksek başarımla çalışır.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[SkipList Topology vs Red-Black Trees: 1) The Impossibility of Lock-Free Trees: Balancing binary search trees (AVL, Red-Black) requires multi-node structural rotations. Synchronizing rotations across concurrent mutations creates massive contention bottlenecks, making lock-free balanced trees practically intractable. 2) Probabilistic Level Promotion: William Pugh's Skip-List utilizes random coin flips (1/2 probability) to build index levels. Mutations require CAS modifications strictly on local adjacent pointers without structural rebalancing! 3) Range Query Superiority: `ConcurrentSkipListMap` delivers thread-safe NavigableMap semantics, enabling concurrent subMap and range scans with bounded O(log N) search latency under heavy concurrent writes.]
    ]
  )
]

#java25_box[
```java
// Java 25: ConcurrentSkipListMap ile Sıralı Liderlik Tablosu (Leaderboard)
import java.util.concurrent.ConcurrentSkipListMap;

public class HighFrequencyLeaderboard {
    // Skorlara göre doğal sıralı thread-safe harita
    private final ConcurrentSkipListMap<Integer, String> scores = new ConcurrentSkipListMap<>();

    public void addScore(int score, String player) {
        scores.put(score, player); // O(log N) kilit-siz ekleme
    }

    public void printTopScores(int minScore) {
        // minScore üzerindeki oyuncuları sıralı getir (Range Query)
        var topTier = scores.tailMap(minScore);
        IO.println("Liderlik Tablosu (" + minScore + "+ Puan):");
        topTier.descendingMap().forEach((score, player) -> 
            IO.println("• " + player + " : " + score + " Puan")
        );
    }

    void main() {
        var board = new HighFrequencyLeaderboard();
        board.addScore(9800, "Alice");
        board.addScore(4500, "Bob");
        board.addScore(12400, "Charlie");
        board.printTopScores(9000);
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
      Mülakat Sorusu: 'Collections.synchronizedSortedMap(new TreeMap()) varken neden ConcurrentSkipListMap kullanalım?' Yanıt: 'synchronizedSortedMap tek bir kaba kilit (Mutex) kullanır; aynı anda sadece tek bir thread işlem yapabilir. ConcurrentSkipListMap ise kilit-siz (lock-free CAS) çalışır; yüzlerce thread aynı anda haritayı okuyup yazabilir!'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[MAANG Interview Comparison: 'Why prefer ConcurrentSkipListMap over Collections.synchronizedSortedMap(new TreeMap())?' Senior Answer: '`synchronizedSortedMap` wraps a single coarse-grained lock around every method, serializing all threads. `ConcurrentSkipListMap` employs lock-free CAS pointer manipulation on local nodes, scaling concurrently across hundreds of CPU cores.']
    ]
  )
]

#takeaways_box((
    ("ConcurrentSkipListMap, TreeMap'in thread-safe ve kilit-siz alternatifidir.", "ConcurrentSkipListMap is the lock-free, thread-safe counterpart to TreeMap."),
    ("Skip-List yapısı rastgele katmanlarla O(log N) arama, ekleme ve silme sunar.", "Skip-Lists employ probabilistic index levels to achieve O(log N) operational bounds."),
    ("Kırmızı-Siyah ağaç rotasyonlarına ihtiyaç duymadığı için lock-free ölçeklenir.", "Eliminating tree rotations allows skip-lists to scale concurrently under heavy writes."),
))
