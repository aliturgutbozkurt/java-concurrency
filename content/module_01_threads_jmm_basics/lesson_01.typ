#import "/template.typ": *

#show: doc => setup_book(title: "Ders 1: Thread Nedir? Process vs Thread, OS Context Switching & CPU Çekirdekleri", doc)

#lesson_header(
  1,
  "Thread Nedir? Process vs Thread, OS Context Switching & CPU Çekirdekleri",
  "What is a Thread? Process vs Thread, OS Context Switching & CPU Cores",
  "Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri",
  "Threads, OS Kernels & Java Memory Model (JMM) Fundamentals"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 OS PROCESS (İşlem / Müstakil Fabrika Alanı)                 │
│  [ Adres Uzayı: Heap Memory, Dosya Tanımlayıcıları (FD), Ortam Değişkenleri]│
├─────────────────────────────────────────────────────────────────────────────┤
│  THREAD 1 (İşçi 1)              THREAD 2 (İşçi 2)             THREAD 3      │
│  ┌───────────────────────┐      ┌───────────────────────┐     ┌───────────┐ │
│  │ Program Counter (PC)  │      │ Program Counter (PC)  │     │ PC        │ │
│  │ Stack Frame (1MB)     │      │ Stack Frame (1MB)     │     │ Stack     │ │
│  │ Yerel Değişkenler     │      │ Yerel Değişkenler     │     │ Locals    │ │
│  └───────────────────────┘      └───────────────────────┘     └───────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼ (Donanım Seviyesi)
┌─────────────────────────────────────────────────────────────────────────────┐
│ CPU CORE 0: [ALU, Register, L1 Cache] ◀── [OS Context Switch ~1-3 µs Maliyet]│
└─────────────────────────────────────────────────────────────────────────────┘
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir Process (İşlem), etrafı yüksek duvarlarla çevrili koca bir fabrikadır. Kendi su tesisatı, elektrik sayacı ve tapusu (ayrı RAM adres alanı) vardır. Bir fabrikanın diğer fabrikanın odalarına izinsiz girmesi yasaktır! Thread (İş parçacığı) ise o fabrikanın içinde koşturan işçilerdir. Bütün işçiler aynı fabrikanın ortak deposunu (Heap Memory) paylaşırlar; ama her işçinin cebinde kendi özel not defteri (Thread Stack) vardır. İki işçi aynı depodaki aynı kutuya (Paylaşılan Değişken) haberleşmeden aynı anda dalarsa ortalık karışır (Race Condition)!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[A Process is an entire secure factory compound with its own private land, utilities, and security gate (isolated virtual address space). Process A cannot inspect Process B's floor plan. A Thread is a worker inside that factory. All workers walk the same shared factory warehouse floor (Heap Memory), but each worker carries a personal pocket notepad (Thread Stack). If two workers update the same inventory box simultaneously without coordination, inventory records corrupt instantly (Race Condition)!]
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
      MAANG seviyesinde Process vs Thread anatomisi: 1) Bellek İzolasyonu: Process'ler MMU (Memory Management Unit) ve Page Table ile sanal adres alanlarında tamamen izole edilir. İletişim IPC (Inter-Process Communication: Sockets, Shared Memory, Pipes) gerektirir ve pahalıdır. 2) Thread Paylaşımı: Bir JVM process'indeki tüm platform thread'leri Heap, Metaspace ve dosya tanıtıcılarını (FD) paylaşır; ancak her thread kendi Stack alanına (~1MB varsayılan), Program Counter (PC) register'ına ve Native Method Stack'ine sahiptir. 3) Context Switch Maliyeti: İşletim sistemi çekirdeği (Kernel) iki platform thread'i arasında geçiş yaparken CPU register'larını kaydeder, TLB (Translation Lookaside Buffer) önbelleğini temizler ve L1/L2 CPU cache'lerini bozar (Cache Pollution). Bu maliyet 1-3 mikrosaniyedir ve saniyede milyonlarca istek alan MAANG sistemlerinde verim kaybına yol açar.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[MAANG-level architectural mechanics: 1) Address Space Isolation: Processes operate in distinct virtual memory boundaries governed by the hardware MMU and OS page tables. Cross-process IPC requires context-switching into ring-0 kernel space. 2) Intra-Process Thread Concurrency: Java platform threads map 1:1 to OS native threads (POSIX pthreads / Windows kernel threads). They share the JVM Heap and Metaspace, but retain private Program Counters and runtime call stacks (~1MB default). 3) Context Switching Overhead: When the OS scheduler pre-empts Thread A for Thread B, it saves instruction pointers and registers to kernel memory, often triggering TLB invalidation and L1/L2 cache misses (Cache Pollution), incurring ~1-3 microseconds of pure CPU latency per switch.]
    ]
  )
]

#java25_box[
```java
// Java 25: Platform Thread vs Donanım Çekirdekleri Bilgisi
void main() {
    int availableCores = Runtime.getRuntime().availableProcessors();
    long totalMemoryMb = Runtime.getRuntime().totalMemory() / (1024 * 1024);
    
    IO.println("CPU Donanım Çekirdek Sayısı: " + availableCores);
    IO.println("JVM Tahsis Edilen Heap Bellek: " + totalMemoryMb + " MB");
    
    // Geleneksel Platform Thread başlatma
    Thread osThread = new Thread(() -> {
        var current = Thread.currentThread();
        IO.println("Çalışan İşçi: " + current.getName() + " | Platform Thread mi: " + !current.isVirtual());
    }, "MAANG-Worker-01");
    
    osThread.start();
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
      Mülakat Tuzağı: Mülakatçı 'Daha fazla thread açarsak sistemimiz her zaman daha mı hızlanır?' diye sorar. Yanıt: Hayır! CPU çekirdek sayısından çok fazla platform thread açılırsa, CPU zamanını iş yapmaya değil işçiler arasında geçiş yapmaya (Context Switching thrashing) harcar ve throughput çöker!
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Interview Trap: The interviewer asks: 'Can we endlessly boost throughput simply by adding more threads?' Senior Answer: 'No! If runnable platform thread count drastically exceeds physical CPU cores, the kernel spends more clock cycles on thread context switching and cache invalidation than actual task computation, precipitating throughput collapse.']
    ]
  )
]

#takeaways_box((
    ("Process'ler izole adres alanlarına sahiptir; Thread'ler ise aynı Heap alanını paylaşır.", "Processes own isolated virtual address spaces; threads share the JVM heap."),
    ("Platform thread'leri 1:1 işletim sistemi kernel thread'lerine eşlenir (~1MB stack).", "Platform threads map 1:1 to kernel threads, incurring ~1MB memory footprint."),
    ("Gereğinden fazla thread context-switching thrashing'e yol açarak sistemi kilitler.", "Oversubscribing threads degrades throughput via context-switch thrashing."),
))
