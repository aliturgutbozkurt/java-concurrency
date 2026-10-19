#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 2: Volatile Anahtar Kelimesi, Atomiklik & Görünürlük", doc)

#module_cover(
  2,
  "Volatile Anahtar Kelimesi, Atomiklik & Görünürlük",
  "The volatile Keyword, Atomicity & Visibility",
  "Görünürlük (Visibility) ve Atomiklik farkı, `volatile` bellek bariyerleri (Memory Barriers), Double-Checked Locking (DCL) tuzağı, CAS döngüleri ve `LongAdder` vs `AtomicLong` ölçeklenme mimarisi.",
  "Visibility vs Atomicity, hardware memory barriers backing `volatile`, the Double-Checked Locking (DCL) singleton hazard, lock-free CAS loops, and `LongAdder` vs `AtomicLong` scalability."
)

#include "lesson_07.typ"
#v(16pt)

#include "lesson_08.typ"
#v(16pt)

#include "lesson_09.typ"
#v(16pt)

#include "lesson_10.typ"
#v(16pt)

#include "lesson_11.typ"
#v(16pt)

#include "lesson_12.typ"
#v(16pt)

