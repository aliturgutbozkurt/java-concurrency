#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 6: Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları", doc)

#module_cover(
  6,
  "Eşzamanlı Koleksiyonlar & Thread-Safe Veri Yapıları",
  "Concurrent Collections & Thread-Safe Data Structures",
  "ConcurrentHashMap iç mekaniği (CAS ve Kova Kilitleme), CopyOnWriteArrayList anlık görüntü kopyalaması, BlockingQueue varyantları, SynchronousQueue sıfır kapasite takası ve Lock-Free kuyruklar.",
  "ConcurrentHashMap internals (CAS and Bin-Level locking), CopyOnWriteArrayList snapshot iteration, BlockingQueue variants, SynchronousQueue zero-capacity handoffs, and lock-free queues."
)

#include "lesson_31.typ"
#v(16pt)

#include "lesson_32.typ"
#v(16pt)

#include "lesson_33.typ"
#v(16pt)

#include "lesson_34.typ"
#v(16pt)

#include "lesson_35.typ"
#v(16pt)

#include "lesson_36.typ"
#v(16pt)

