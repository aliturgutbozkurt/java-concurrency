#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 1: Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri", doc)

#module_cover(
  1,
  "Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri",
  "Threads, OS Kernels & Java Memory Model (JMM) Fundamentals",
  "Process vs Thread farkı, JVM thread durumları, donanım önbellekleri (L1/L2/L3), False Sharing, JMM Happens-Before garantisi ve modern Java 25 thread oluşturma mekanizmaları.",
  "Process vs Thread dichotomy, JVM thread states, CPU cache hierarchies (L1/L2/L3), False Sharing, the JMM Happens-Before relationship, and modern Java 25 thread creation."
)

#include "lesson_01.typ"
#v(16pt)

#include "lesson_02.typ"
#v(16pt)

#include "lesson_03.typ"
#v(16pt)

#include "lesson_04.typ"
#v(16pt)

#include "lesson_05.typ"
#v(16pt)

#include "lesson_06.typ"
#v(16pt)

