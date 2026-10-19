#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm 5: Thread Havuzları, Executor'lar & Work-Stealing", doc)

#module_cover(
  5,
  "Thread Havuzları, Executor'lar & Work-Stealing",
  "Thread Pools, Executors & Work-Stealing Algorithms",
  "ThreadPoolExecutor iç yapısı, 4 ret politikası (Rejection Policies), Executors sınıfının üretim felaketleri (OOM riskleri), ScheduledThreadPool, Fork/Join work-stealing algoritması ve Graceful Shutdown.",
  "ThreadPoolExecutor mechanics, the 4 task rejection policies, production OOM hazards of Executors factory methods, ScheduledExecutor delay drift, Fork/Join work-stealing, and graceful shutdown."
)

#include "lesson_25.typ"
#v(16pt)

#include "lesson_26.typ"
#v(16pt)

#include "lesson_27.typ"
#v(16pt)

#include "lesson_28.typ"
#v(16pt)

#include "lesson_29.typ"
#v(16pt)

#include "lesson_30.typ"
#v(16pt)

