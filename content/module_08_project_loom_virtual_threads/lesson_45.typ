#import "/template.typ": *

#show: doc => setup_book(title: "Ders 45: The Pinning Hazard (Sabitlenme Tehlikesi): synchronized vs ReentrantLock & Native Kod Tuzakları", doc)

#lesson_header(
  45,
  "The Pinning Hazard (Sabitlenme Tehlikesi): synchronized vs ReentrantLock & Native Kod Tuzakları",
  "The Pinning Hazard: synchronized vs ReentrantLock & Native Methods",
  "Project Loom & Sanal Thread'ler (Virtual Threads)",
  "Project Loom & Virtual Threads"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CARRIER THREAD PINNING (SABİTLENME TUZAĞI)                │
└─────────────────────────────────────────────────────────────────────────────┘
  SENARYO 1: DOĞRU (ReentrantLock ile Bloklama):
  Virtual Thread ──▶ lock.lock() ──▶ [ BLOKLANDI! ]
                         │
                         ▼ (Carrier Thread'den AYRILIR / UNMOUNT EDİLİR!)
  Carrier Thread ──▶ BOŞA ÇIKTI! Diğer sanal thread'leri çalıştırmaya devam eder.

  SENARYO 2: YANLIŞ / TEHLİKELİ (synchronized veya JNI Native İçinde Bloklama):
  Virtual Thread ──▶ synchronized(lock) { socket.read(); } ──▶ [ PINNED! ]
                         │
                         ▼ (Carrier Thread'e ÇİVİLENDİ! AYRILAMAZ!)
  Carrier Thread ──▶ 💥 KİLİTLENDİ! Ne unmount olabilir ne başka bir iş alabilir!
                     Tüm Carrier Thread'ler pinlineirse JVM FELÇ OLUR!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Sanal thread bir posta güvercini gibidir; mektubu bırakıp hemen uçar. Ancak güvercinin ayağına ağır bir demir gülle bağlarsan uçamaz. 'Pinning' tam olarak budur: Eğer sanal thread `synchronized` bloğu veya eski C kütüphanesi (JNI) içindeyken ağdan veri beklerse, altındaki devasa platform thread'e çivilenir! Platform thread kımıldayamaz hale gelir. 16 çekirdeğin varsa ve 16 sanal thread pinlineirse bütün sunucu kilitlenir!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[A virtual thread is an agile gymnast capable of leaping off the balance beam at any moment. Carrier Pinning is like super-gluing the gymnast's feet to the beam. If a virtual thread enters a blocking I/O operation inside a legacy `synchronized` block or a native JNI C-library call, it cannot unmount! The underlying OS carrier thread is held hostage. If all carrier threads become pinned, the entire JVM throughput collapses to zero!]
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
      HotSpot Pinning Mekanizması ve Çözümler: 1) Neden Sabitlenir (Pinning)? Bir thread native C frame'i (`JNI`) yürütüyorsa veya bir nesnenin monitörüne (`synchronized`) sahipken bloklayan bir işlem yaparsa, HotSpot C++ çalışma zamanı monitör sahipliğini native stack'ten ayıramaz. Buna `Pinned Carrier Thread` denir. 2) Sonuçları: Carrier thread unmount edilemez; diğer binlerce sanal thread kuyrukta açlıktan ölür (starvation). HotSpot telafi etmek için geçici olarak `ForkJoinPool`'a ek carrier thread ekler, ancak bu OS thread patlamasına yol açar. 3) Teşhis: JVM `-Djdk.tracePinnedThreads=full` veya `short` parametresiyle başlatılarak pinlineen yerler loglanır. 4) Çözüm: Bloklayan I/O içeren tüm `synchronized` blokları derhal `java.util.concurrent.locks.ReentrantLock` ile değiştirilmelidir. (Not: Java 24/25'te synchronized pinning'i büyük ölçüde hafifletilmiştir ancak native JNI ve kritik bölümler için ReentrantLock endüstri standardıdır).
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[HotSpot Pinning Internals & Diagnostic Protocol: 1) Root Cause: A virtual thread cannot be unmounted when its call frame contains native frames (JNI) or when holding an object monitor inside a `synchronized` block/method that enters `park()`. The HotSpot native frame metadata is bound to the carrier's OS stack. 2) Catastrophic Degradation: With all carrier threads pinned, the `ForkJoinPool` cannot service pending virtual threads. HotSpot attempts compensatory thread injection, spiking OS kernel thread counts and memory consumption. 3) Diagnostics: Enable JVM flag `-Djdk.tracePinnedThreads=full` to print stack traces whenever pinning occurs. 4) Modern Remediation: Replace blocking `synchronized` sections with `ReentrantLock`, which relies on `LockSupport.park()` and fully unmounts virtual threads without pinning.]
    ]
  )
]

#java25_box[
```java
// Java 25: Pinning Tuzağı ve ReentrantLock ile Güvenli Dönüşüm
import java.util.concurrent.Executors;
import java.util.concurrent.locks.ReentrantLock;

public class PinningPreventionDemo {
    private final ReentrantLock modernLock = new ReentrantLock();
    private final Object legacyLock = new Object();

    // ❌ TEHLİKELİ ESKİ YÖNTEM: synchronized içinde I/O (Pinning Yaratır!)
    public void hazardousMethod() {
        synchronized (legacyLock) {
            try {
                // Pinning alarmı! Carrier thread unmount olamaz!
                Thread.sleep(100);
            } catch (InterruptedException _) {}
        }
    }

    // ✅ GÜVENLİ MODERN YÖNTEM: ReentrantLock (Carrier Thread Serbest Kalır!)
    public void resilientMethod() {
        modernLock.lock();
        try {
            // Virtual thread unmount olur, carrier thread serbestçe diğer işleri yapar!
            Thread.sleep(100);
        } catch (InterruptedException _) {
            Thread.currentThread().interrupt();
        } finally {
            modernLock.unlock();
        }
    }

    void main() {
        System.setProperty("jdk.tracePinnedThreads", "short");
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 5; i++) {
                executor.submit(this::resilientMethod);
            }
        }
        System.out.println("Tüm sanal thread'ler sıfır pinning ile başarıyla tamamlandı!");
    }
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
      Eski JDBC sürücüleri ve üçüncü parti kütüphanelerin derinliklerinde socket okumaları synchronized blokları içine sarılmış olabilir! Projenizi Sanal Thread'lere geçirirken kesinlikle `-Djdk.tracePinnedThreads=full` bayrağını açıp harici kütüphanelerdeki pinning noktalarını denetleyin.
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Legacy JDBC drivers, XML parsers, and HTTP clients often wrap socket reads in `synchronized` blocks. When migrating production services to Virtual Threads, always audit dependencies with `-Djdk.tracePinnedThreads=full` to eliminate stealth carrier thread starvation.]
    ]
  )
]

#takeaways_box((
    ("synchronized veya JNI içinde I/O yapmak Carrier Thread'i kilitler (Pinning). Bloklayan I/O bölgelerinde daima ReentrantLock kullanın.", "Blocking I/O inside `synchronized` or JNI pins the carrier thread. Replace `synchronized` blocks wrapping I/O with `ReentrantLock`."),
))
