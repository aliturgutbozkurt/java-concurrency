#import "/template.typ": *

#show: doc => setup_book(title: "Ders 2: Java Thread Yaşam Döngüsü: 6 Kritik Durum (State Transitions)", doc)

#lesson_header(
  2,
  "Java Thread Yaşam Döngüsü: 6 Kritik Durum (State Transitions)",
  "Java Thread Lifecycle: The 6 Core JVM States & State Transitions",
  "Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri",
  "Threads, OS Kernels & Java Memory Model (JMM) Fundamentals"
)

#diagram_box[
```text
               [ NEW ] ──▶ (thread.start() çağrıldı)
                  │
                  ▼
          ┌───────────────┐  OS Scheduler     ┌────────────────┐
          │   RUNNABLE    │ ◀───────────────▶ │ RUNNING (CPU)  │
          │ (Ready to run)│   Context Switch  │ (İşlem yapıyor)│
          └───────┬───────┘                   └────────────────┘
                  │
        ┌─────────┼────────────────────────┐
        │         │                        │
        ▼ (Lock)  ▼ (wait / join)          ▼ (sleep / wait with timeout)
  ┌──────────┐ ┌─────────┐         ┌───────────────┐
  │ BLOCKED  │ │ WAITING │         │ TIMED_WAITING │
  └────┬─────┘ └────┬────┘         └───────┬───────┘
       │           │                       │
       └───────────┼───────────────────────┘
                   ▼ (İş bitti veya Exception fırladı)
             [ TERMINATED ]
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir işçinin gün içindeki 6 hali vardır: 1) NEW: İşe yeni alındı, masasında oturuyor ama henüz 'Başla' denmedi. 2) RUNNABLE: Masasında hazır bekliyor veya harıl harıl çalışıyor. 3) BLOCKED: Tuvalet kapısının önünde bekliyor çünkü içeride biri var (Kilit kavgası). 4) WAITING: Patron 'Ben sana haber verene kadar kenarda bekle' dedi (Süresiz bekleme). 5) TIMED\_WAITING: '20 dakika öğle uykusuna yat' dendi (Süreli bekleme). 6) TERMINATED: Mesaisi bitti, evine gitti!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[An employee's lifecycle stages: 1) NEW: Hired and given a badge, but hasn't clocked in yet. 2) RUNNABLE: Either actively typing at the desk or standing ready for an assignment. 3) BLOCKED: Waiting outside the restroom because a colleague locked the door from inside (Lock Contention). 4) WAITING: Sitting in the lounge waiting indefinitely for a manager's signal. 5) TIMED\_WAITING: Taking an exact 15-minute coffee break. 6) TERMINATED: Shift finished, clocked out forever!]
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
      Thread.State enum değerleri ve mülakat derinliği: 1) NEW: `new Thread()` yapılmış ancak `start()` çağrılmamıştır. `start()` yerine doğrudan `run()` çağrılırsa yeni thread açılmaz, çağıran thread içinde senkron çalışır! 2) RUNNABLE: JVM seviyesinde thread koşmaya hazırdır veya CPU'da çalışıyordur. JVM, işletim sisteminin 'Ready' ve 'Running' durumlarını tek bir RUNNABLE altında toplar. 3) BLOCKED: Thread bir `synchronized` bloğuna girmek için Monitor Lock (Intrinsic Lock) beklemektedir. 4) WAITING: `Object.wait()`, `Thread.join()` veya `LockSupport.park()` ile süresiz askıya alınmıştır; başka bir thread `notify()` veya `unpark()` çağırana kadar CPU tüketmez. 5) TIMED\_WAITING: `Thread.sleep(ms)`, `wait(ms)` veya `parkNanos()` ile zaman sınırıyla bekler. 6) TERMINATED: `run()` metodu doğal yolla bitmiş veya yakalanmamış bir exception ile sonlanmıştır.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[HotSpot Thread State nuances: 1) NEW to RUNNABLE: Calling `start()` triggers OS `pthread_create()`. Invoking `run()` directly bypasses thread creation, executing synchronously on the caller's stack. 2) RUNNABLE Collapsing: The JVM intentionally does not distinguish between OS 'Ready' (in kernel runqueue) and OS 'Executing' (on CPU core); both report as RUNNABLE. 3) BLOCKED vs WAITING: A critical distinction in thread dumps! BLOCKED strictly means waiting for a synchronized monitor lock. WAITING means parked via `LockSupport.park()` or `Object.wait()`, awaiting a signal. 4) TERMINATED: Dead threads cannot be restarted. Calling `start()` on a TERMINATED thread throws `IllegalThreadStateException`.]
    ]
  )
]

#java25_box[
```java
// Java 25: Thread Durum Geçişlerini İnceleme
void main() throws InterruptedException {
    final Object lock = new Object();

    Thread worker = new Thread(() -> {
        try {
            Thread.sleep(100); // TIMED_WAITING
            synchronized (lock) {
                lock.wait();   // WAITING
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    });

    IO.println("1. Durum: " + worker.getState()); // NEW
    worker.start();
    IO.println("2. Durum: " + worker.getState()); // RUNNABLE

    Thread.sleep(50);
    IO.println("3. Durum (Sleep anı): " + worker.getState()); // TIMED_WAITING

    Thread.sleep(100);
    synchronized (lock) {
        IO.println("4. Durum (Wait anı): " + worker.getState()); // WAITING
        lock.notify();
    }

    worker.join();
    IO.println("5. Durum (Bitti): " + worker.getState()); // TERMINATED
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
      Mülakat Tuzağı: 'ReentrantLock bekleyen bir thread hangi duruma geçer?' Yanıt: BLOCKED DEĞİL, WAITING (veya TIMED\_WAITING) durumuna geçer! Çünkü ReentrantLock `LockSupport.park()` kullanır; BLOCKED durumu SADECE `synchronized` monitor lock için geçerlidir!
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Classic Interview Trap: 'What state is a thread in when blocked on a ReentrantLock?' Answer: 'WAITING (or TIMED\_WAITING), NOT BLOCKED! ReentrantLock is built on AbstractQueuedSynchronizer (AQS) using LockSupport.park(). BLOCKED is strictly reserved for intrinsic synchronized monitors.']
    ]
  )
]

#takeaways_box((
    ("JVM'de 6 thread durumu vardır: NEW, RUNNABLE, BLOCKED, WAITING, TIMED\_WAITING, TERMINATED.", "JVM threads traverse 6 states: NEW, RUNNABLE, BLOCKED, WAITING, TIMED\_WAITING, TERMINATED."),
    ("BLOCKED sadece synchronized içindir; ReentrantLock bekleyen thread WAITING olur.", "BLOCKED is exclusive to synchronized; AQS locks park threads in WAITING state."),
    ("Ölmüş (TERMINATED) bir thread yeniden `start()` edilemez.", "A TERMINATED thread cannot be restarted; doing so throws IllegalThreadStateException."),
))
