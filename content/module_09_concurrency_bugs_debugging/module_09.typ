#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 9: Eşzamanlılık Hataları, Teşhis & Düşük Seviyeli Primitifler", doc)

#module_cover(
  9,
  "Eşzamanlılık Hataları, Teşhis & Düşük Seviyeli Primitifler",
  "Concurrency Bugs, Anti-Patterns & Low-Level Primitives",
  "Klasik yarış durumları (Check-then-Act, Read-Modify-Write), Coffman ölümcül kilitlenme (Deadlock) koşulları ve tespiti, Livelock ve Starvation, ABA problemi ve AtomicStampedReference, jstack/jcmd thread dump adli analizi, ve modern VarHandle bellek çitleri.",
  "Classic race conditions (Check-then-Act, Read-Modify-Write), Coffman deadlock prerequisites and programmatic detection, Livelock and thread starvation, ABA memory hazard and AtomicStampedReference, production thread dump forensics with jstack/jcmd, and modern VarHandle memory fences."
)

#include "lesson_49.typ"
#v(16pt)

#include "lesson_50.typ"
#v(16pt)

#include "lesson_51.typ"
#v(16pt)

#include "lesson_52.typ"
#v(16pt)

#include "lesson_53.typ"
#v(16pt)

#include "lesson_54.typ"
#v(16pt)

