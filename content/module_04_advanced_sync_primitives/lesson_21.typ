#import "/template.typ": *

#show: doc => setup_book(title: "Ders 21: CyclicBarrier: Tekrar Kullanılabilir Buluşma Noktaları & Bariyer Eylemi", doc)

#lesson_header(
  21,
  "CyclicBarrier: Tekrar Kullanılabilir Buluşma Noktaları & Bariyer Eylemi",
  "CyclicBarrier: Reusable Multi-Thread Rendezvous & Barrier Actions",
  "İleri Düzey Senkronizasyon & Kilit-Siz Araçlar",
  "Advanced Synchronization & Lock-Free Primitives"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 CYCLICBARRIER: DÖNGÜSEL BULUŞMA VE TUR MİMARİSİ             │
└─────────────────────────────────────────────────────────────────────────────┘
  CyclicBarrier barrier = new CyclicBarrier(3, () -> print("TUR TAMAMLANDI!"));

  [ TUR 1 ]:
  Thread A: Hesaplamayı yap ──▶ barrier.await(); (Bekler...)
  Thread B: Hesaplamayı yap ──▶ barrier.await(); (Bekler...)
  Thread C: Hesaplamayı yap ──▶ barrier.await(); (3 KİŞİ BULUŞTU!)
                                      │
                                      ▼
                        BARRIER ACTION ÇALIŞIR:
                        "TUR TAMAMLANDI! Sonuçları Dosyaya Yaz."
                                      │
                                      ▼
  [ TUR 2 BAŞLAR (Bariyer Otomatik Resetlendi / Döngüsel!)]:
  Thread A, B, C serbest kalır ve bir sonraki tura geçer!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir lunaparktaki 4 kişilik gondol düşünün. Gondol 4 kişi dolmadan ASLA hareket etmez. İlk binen 3 kişi gondolun içinde oturup 4. kişiyi bekler (`await()`). 4. kişi bindiği anda kilitler kapanır ve gondol sallanır (Barrier Action). Tur bitince herkes iner ve gondol TEKRAR boşalır; sonraki 4 kişi için baştan kullanılır (Cyclic / Döngüsel)! CountDownLatch gibi çöpe atılmaz!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Picture a 4-person whitewater rafting crew. The raft cannot depart until all 4 rowers take their seats. The first three climbers sit with paddles ready (`await()`). The instant the fourth rower steps aboard, the team pushes off down the rapids together (Barrier Action). At the bottom of the river, the raft is carried back up and re-used for the next round! Unlike single-use countdown latches, CyclicBarrier automatically resets for subsequent cycles.]
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
      CyclicBarrier ve CountDownLatch Farkları: 1) Tekrar Kullanılabilirlik (Cyclic): CyclicBarrier, tüm thread'ler buluştuğunda iç sayacını otomatik olarak ilk değerine geri sıfırlar. Matris çarpımları, genetik algoritmalar ve çok adımlı paralel simülasyonlar için biçilmiş kaftandır. 2) Barrier Action: Tüm thread'ler bariyere ulaştığında, içlerinden rastgele bir tanesi verilen `Runnable` görevini (ör. tur sonuçlarını diskte birleştirme) tek başına çalıştırır; bitince tüm thread'ler bir sonraki adıma serbest bırakılır. 3) Kırık Bariyer (BrokenBarrierException): Eğer bekleyen thread'lerden biri zaman aşımına uğrar veya `interrupt` edilirse, tüm bariyer kırılır (Broken state). Diğer tüm bekleyen thread'ler `BrokenBarrierException` alarak çöker; böylece eksik veriyle yanlış işlem yapılması donanımsal olarak engellenir.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[CyclicBarrier Mechanics & Failure Handling: 1) Cyclic Reset: CyclicBarrier resets its internal count automatically once the parties count reaches zero, advancing to a new 'Generation'. It is specifically tuned for iterative algorithms (e.g. parallel Jacobi relaxation or map-reduce matrix passes). 2) Barrier Action Execution: When the last thread trips the barrier, it synchronously executes the barrier action Runnable on its own stack before releasing the awaiting parties. 3) Broken Barriers: If any thread in the barrier is interrupted or times out, the barrier enters the 'Broken' state, unparking all other threads with a `BrokenBarrierException` to prevent deadlock and state corruption.]
    ]
  )
]

#java25_box[
```java
// Java 25: Çok Turlu Paralel Simülasyonda CyclicBarrier Kullanımı
import java.util.concurrent.CyclicBarrier;

public class ParallelMatrixSimulation {
    void main() {
        int workerCount = 3;
        
        // 3 işçi buluştuğunda çalışacak ortak bariyer eylemi
        var barrier = new CyclicBarrier(workerCount, () -> {
            IO.println("=== TUR BİTTİ: Ara sonuçlar birleştirildi. Yeni tura geçiliyor! ===\n");
        });

        for (int i = 1; i <= workerCount; i++) {
            final int id = i;
            Thread.ofPlatform().name("Worker-" + id).start(() -> {
                try {
                    for (int round = 1; round <= 2; round++) {
                        IO.println("İşçi " + id + " | Tur " + round + " hesaplıyor...");
                        Thread.sleep(100 * id); // Farklı hızlarda hesaplarlar
                        
                        IO.println("İşçi " + id + " bariyere vardı, diğerlerini bekliyor...");
                        barrier.await(); // 3 kişi tamamlanana kadar bekle
                    }
                } catch (Exception e) {
                    Thread.currentThread().interrupt();
                }
            });
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
      Mülakat Tuzağı: Mülakatçı 'CountDownLatch ile CyclicBarrier arasındaki en temel iki fark nedir?' diye sorarsa: '1) CountDownLatch tek kullanımlıktır, CyclicBarrier sonsuz döngüde tekrar kullanılabilir (resetlenir). 2) CountDownLatch thread'lerin bir olayı beklemesini sağlar; CyclicBarrier ise thread'lerin birbirini beklemesini sağlar!' denmelidir.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Top MAANG Difference Question: 'What are the two foundational differences between CountDownLatch and CyclicBarrier?' Senior Answer: '1) CountDownLatch is single-use and cannot be reset; CyclicBarrier is cyclic and auto-resets per generation. 2) CountDownLatch waits for events/tasks to finish (threads don't wait for each other); CyclicBarrier forces concurrent threads to wait for each other at a mutual rendezvous.']
    ]
  )
]

#takeaways_box((
    ("CyclicBarrier her turda kendini sıfırlayarak sonsuz kez tekrar kullanılabilir.", "CyclicBarrier auto-resets its count, enabling iterative multi-phase processing."),
    ("Barrier Action, son gelen thread tarafından tek başına yürütülür.", "The barrier action is executed by the final arriving thread before unparking the pool."),
    ("Bir thread kesilirse bariyer Broken state'e geçer ve tüm thread'leri korur.", "Thread interruption breaks the barrier, throwing BrokenBarrierException across all parties."),
))
