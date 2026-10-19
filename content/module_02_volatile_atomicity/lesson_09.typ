#import "/template.typ": *

#show: doc => setup_book(title: "Ders 9: Piggybacking on volatile: Güvenli Durum Yayınlama (Safe Publication)", doc)

#lesson_header(
  9,
  "Piggybacking on volatile: Güvenli Durum Yayınlama (Safe Publication)",
  "Piggybacking on volatile: Safe State Publication & Ordering Guarantees",
  "Volatile Anahtar Kelimesi, Atomiklik & Görünürlük",
  "The volatile Keyword, Atomicity & Visibility"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 PIGGYBACKING (SIRTA BİNME) HAPPENS-BEFORE KURALI            │
└─────────────────────────────────────────────────────────────────────────────┘
  NON-VOLATILE DEĞİŞKENLER:             VOLATILE DEĞİŞKEN (KORUYUCU MELEK):
  int a = 10;
  String name = "MAANG";
  List<String> items = new ArrayList();
  items.add("Data");
                                        volatile int trigger = 1; // ◄── YAZMA!
  ─────────────────────────────────────────────────────────────────────────────
  BÜTÜN BU NORMAL DEĞİŞKENLER, TRIGGER'IN ARKASINA TAKILARAK RAM'E BASILIR!
  
  OKUYUCU THREAD:
  if (trigger == 1) { // ◄── VOLATILE OKUMA!
      // a, name ve items listesi KESİNLİKLE tam ve güncel olarak görünür!
  }
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Havaalanında uçağa binerken pasaportu olmayan 3 çocuk düşünün (Normal değişkenler). Kapıdaki polis tek tek çocukları içeri almaz. Ama yanlarında diplomatik pasaporta sahip bir büyükelçi (volatile değişken) vardır. Büyükelçi kapıdan geçerken 'Bu çocuklar benimle' dediği anda, bütün çocuklar büyükelçinin sırtına binerek (Piggybacking) içeriye güvenle sızarlar! Tek bir volatile değişken, kendisinden önce yazılan onlarca normal değişkeni de beraberinde görünür kılar!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Imagine three passengers lacking boarding passes (regular non-volatile fields). Airport security refuses them entry. However, they walk alongside an accredited diplomat holding an all-access pass (a single `volatile` variable). When the diplomat clears the gate, the Happens-Before protocol dictates that everyone preceding the diplomat in line is admitted simultaneously (Piggybacking). A single volatile write flushes all preceding non-volatile state mutations into global visibility!]
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
      Piggybacking Mekanizması ve JMM Transitivity Kuralı: 1) Happens-Before Transitivity: Eğer `A -> B` (Program Order) ve `B -> C` (Volatile kuralı) ise, o zaman `A -> C`'dir. Burada A normal değişken yazmaları, B volatile yazma, C ise başka bir thread'in o volatile değişkeni okumasıdır. 2) Java Standart Kütüphanesindeki Yeri: `java.util.concurrent` paketindeki birçok sınıf (ör. `AbstractQueuedSynchronizer` - AQS ve `ConcurrentHashMap`) bu hileyi yoğun şekilde kullanır. Tüm alanları `volatile` yapmak yerine, tek bir `volatile int state` değişkenine yazarak sınıftaki diğer tüm düz alanları görünür kılarlar. Bu sayede gereksiz bellek bariyeri maliyetlerinden kaçınarak inanılmaz bir throughput elde edilir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[Piggybacking Formalism & JDK Engineering: 1) Transitively Inherited Visibility: JSR-133 guarantees that if Action A (non-volatile writes) happens-before Action B (volatile write), and Action B happens-before Action C (volatile read by Thread 2), then Action A happens-before Action C. 2) High-Performance JDK Exploitation: `AbstractQueuedSynchronizer` (AQS) powers ReentrantLock, Semaphore, and CountDownLatch. AQS does not mark internal queue node pointers as volatile; instead, it relies on piggybacking off mutations to `volatile int state` to safely publish entire linked-node updates, evading catastrophic memory fence penalties.]
    ]
  )
]

#java25_box[
```java
// Java 25: Piggybacking ile Düz Değişkenleri Güvenle Yayınlama
import java.util.HashMap;
import java.util.Map;

public class PiggybackingPublisher {
    // Bu map normal bir HashMap'tir (Thread-safe DEĞİLDİR!)
    private Map<String, String> internalConfig = new HashMap<>();
    
    // Sihirli koruyucu: Tek bir volatile tetikleyici
    private volatile boolean published = false;

    public void prepareAndPublish() {
        // 1. Normal, senkronize olmayan map manipülasyonu
        internalConfig.put("db.user", "admin");
        internalConfig.put("db.password", "secret");
        internalConfig.put("cache.ttl", "3600");
        
        // 2. Piggybacking tetikleyici: Volatile yazma!
        // Kendisinden önceki BÜTÜN map verilerini bellek bariyeriyle RAM'e döker.
        published = true;
    }

    public void readConfig() {
        if (published) { // Volatile okuma
            // internalConfig KESİNLİKLE eksiksiz ve güvenle okunur!
            IO.println("Kullanıcı: " + internalConfig.get("db.user"));
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
      Kritik Kodlama Tuzağı: Piggybacking yaparken kod sıralamasına çok dikkat edilmelidir! Eğer `published = true;` satırını map'e veri eklemeden ÖNCE yazarsanız, reordering yüzünden okuyucu thread boş veya yarım doldurulmuş map ile karşılaşır!
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Dangerous Trap: The order of statements is lethal in piggybacking! If you assign `published = true` BEFORE mutating `internalConfig`, the happens-before chain is severed. Observers will read partially constructed, corrupted data structures.]
    ]
  )
]

#takeaways_box((
    ("Piggybacking, normal değişkenleri volatile bir yazmanın arkasına takarak görünür kılmaktır.", "Piggybacking piggybacks non-volatile updates onto the back of a volatile write."),
    ("JMM'nin Geçişlilik (Transitivity) kuralı sayesinde A -> B ve B -> C ise A -> C olur.", "Happens-before transitivity legally guarantees that preceding non-volatile state is visible."),
    ("JDK'nın AQS altyapısı yüksek performans için piggybacking prensibini kullanır.", "JDK concurrency engines (AQS) leverage piggybacking to minimize memory fence overhead."),
))
