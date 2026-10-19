#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 4: İleri Düzey Senkronizasyon & Kilit-Siz Araçlar", doc)

#module_cover(
  4,
  "İleri Düzey Senkronizasyon & Kilit-Siz Araçlar",
  "Advanced Synchronization & Lock-Free Primitives",
  "StampedLock iyimser okuma mekanizması, CountDownLatch tek seferlik kapılar, CyclicBarrier tekrar kullanılabilir buluşma noktaları, Semaphore kaynak havuzları, Exchanger ve dinamik Phaser mimarisi.",
  "StampedLock optimistic reading stamps, CountDownLatch fan-out gates, CyclicBarrier reusable rendezvous, Semaphore resource pools, pairwise Exchanger, and dynamic multi-phase Phaser."
)

#include "lesson_19.typ"
#v(16pt)

#include "lesson_20.typ"
#v(16pt)

#include "lesson_21.typ"
#v(16pt)

#include "lesson_22.typ"
#v(16pt)

#include "lesson_23.typ"
#v(16pt)

#include "lesson_24.typ"
#v(16pt)

