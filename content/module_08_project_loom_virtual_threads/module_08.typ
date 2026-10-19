#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 8: Project Loom & Sanal Thread'ler (Virtual Threads)", doc)

#module_cover(
  8,
  "Project Loom & Sanal Thread'ler (Virtual Threads)",
  "Project Loom & Virtual Threads",
  "Platform thread'leri ile sanal thread'lerin farkı (M:N mimarisi), Carrier thread'lere bağlanma/ayrılma (Mounting/Unmounting), Pinning tuzağı ve ReentrantLock çözümü, ThreadLocal bellek sızıntıları, Structured Concurrency ve Java 25 ScopedValue devrimi.",
  "Platform threads vs Virtual Threads (M:N fibers), Carrier thread mounting and unmounting dynamics, the carrier pinning hazard and ReentrantLock remedy, ThreadLocal memory explosion, Structured Concurrency orchestration, and the Java 25 ScopedValue revolution."
)

#include "lesson_43.typ"
#v(16pt)

#include "lesson_44.typ"
#v(16pt)

#include "lesson_45.typ"
#v(16pt)

#include "lesson_46.typ"
#v(16pt)

#include "lesson_47.typ"
#v(16pt)

#include "lesson_48.typ"
#v(16pt)

