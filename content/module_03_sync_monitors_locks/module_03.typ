#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 3: Klasik Senkronizasyon, Monitörler & Kilitler", doc)

#module_cover(
  3,
  "Klasik Senkronizasyon, Monitörler & Kilitler",
  "Classical Synchronization, Monitors & Locks",
  "synchronized iç kilit mekanizması (Intrinsic Lock), HotSpot monitör seviyeleri (Biased, Lightweight, Heavyweight), wait/notify signal tuzakları, ReentrantLock, Condition kuyrukları ve ReentrantReadWriteLock.",
  "JVM intrinsic locks via synchronized, HotSpot lock inflation levels, wait/notify missed signals, ReentrantLock reentrancy, Condition queues, and ReadWriteLock degradation."
)

#include "lesson_13.typ"
#v(16pt)

#include "lesson_14.typ"
#v(16pt)

#include "lesson_15.typ"
#v(16pt)

#include "lesson_16.typ"
#v(16pt)

#include "lesson_17.typ"
#v(16pt)

#include "lesson_18.typ"
#v(16pt)

