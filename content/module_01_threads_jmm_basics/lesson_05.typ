#import "/template.typ": *

#show: doc => setup_book(title: "Ders 5: Komut Yeniden Sıralama (Instruction Reordering) & Derleyici Optimizasyonları", doc)

#lesson_header(
  5,
  "Komut Yeniden Sıralama (Instruction Reordering) & Derleyici Optimizasyonları",
  "Instruction Reordering & Compiler Optimizations: Why Code Runs Out of Order",
  "Thread'ler, İşletim Sistemi Çekirdeği & JMM Temelleri",
  "Threads, OS Kernels & Java Memory Model (JMM) Fundamentals"
)

#diagram_box[
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 KOMUT YENİDEN SIRALAMANIN 3 FARKLI KATMANI                  │
└─────────────────────────────────────────────────────────────────────────────┘
  YAZILAN KOD:                    DERLEYİCİ SIRASI (JIT):         DONANIM SIRASI (CPU):
  int a = 1;                      int b = 2;                      int b = 2;
  int b = 2;                      int a = 1;                      [Store Buffer Gecikmesi]
  boolean ready = true;           boolean ready = true;           boolean ready = true;
                                                                  int a = 1;

                              AS-IF-SERIAL PRENSİBİ:
  "Tek bir thread içinden bakıldığında kod yazıldığı gibi çalışıyormuş gibi görünmelidir."
  ANCAK başka bir thread dışarıdan baktığında bu sıralama taklasını FARK EDER!
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\
      #v(3pt)
      Bir aşçı düşünün: Tarifte '1. Havuçları soy, 2. Eti marine et, 3. Tencereye yağ dök' yazıyor. Akıllı aşçı bakar ki yağın kızması 3 dakika sürüyor; önce yağı ocağa koyar, o ısınırken havuçları soyar! Tek başına mutfakta olduğu sürece yemek aynı lezzette çıkar (As-If-Serial). Ama mutfağa aniden ikinci bir çırak girip 'Yağ ocakta olduğuna göre havuçlar çoktan doğranmıştır' diye tencereye boş elini atarsa eli yanar! Çoklu thread dünyasında bu sıralama hileleri felakete yol açar!
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\
      #v(3pt)
      #text(fill: rgb("334155"))[Consider a master chef reading a recipe: '1. Peel carrots, 2. Season steak, 3. Heat oil in skillet'. Because heating oil takes 4 minutes, the chef turns on the stove burner first, then peels carrots while the pan heats up. To the chef working alone, the final meal tastes identical (As-If-Serial rule). But if an assistant rushes in and assumes 'The stove is hot, therefore chopped carrots must already be prepared!', disaster strikes. In multithreading, reordering tricks destroy uncoordinated observers!]
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
      Üç Seviyeli Yeniden Sıralama: 1) Derleyici Yeniden Sıralaması (Compiler Reordering): javac ve HotSpot JIT (C1/C2), register tahsisini ve döngü verimliliğini optimize etmek için bağımsız talimatların yerini değiştirir. 2) İşlemci Yeniden Sıralaması (CPU Out-of-Order Execution): Modern süperskalar CPU'lar boru hattını (Pipeline) dolu tutmak için bağımsız yönergeleri eşzamanlı veya sıra dışı yürütür. 3) Bellek Sistemi Sıralaması (Memory Hierarchy Reordering): Store Buffer ve Invalidation Queue'lar yüzünden yazma işlemleri hemen RAM'e düşmez; okuma işlemleri bekleyen yazmaların önüne geçebilir (StoreLoad reordering). 4) As-If-Serial Semantiği: JVM ve donanım, tek thread içinde veri bağımlılığı (Data Dependency: Read-After-Write, Write-After-Read, Write-After-Write) olan komutların sırasını ASLA bozmaz.
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\
      #v(3pt)
      #text(fill: rgb("334155"))[The Three Tiers of Reordering: 1) Compiler Reordering: HotSpot C2 JIT reorders instructions to maximize register utilization and eliminate redundant loads. 2) Processor Reordering: Superscalar architectures employ reservation stations and out-of-order execution pipelines to avoid stall cycles during cache misses. 3) Memory Subsystem Reordering: Store Buffers allow the CPU to continue processing while memory writes are lazily drained, allowing subsequent loads to bypass stale stores. 4) The As-If-Serial Invariant: Compilers and silicon pledge that single-threaded execution behavior is indistinguishable from strict serial execution. However, they make ZERO guarantees to concurrent observer threads without explicit memory fences.]
    ]
  )
]

#java25_box[
```java
// Java 25: Instruction Reordering Kanıtı (jcstress Mantığı)
public class ReorderingTest {
    private int x = 0, y = 0;
    private int r1 = 0, r2 = 0;

    // Thread 1 çalıştırır:
    public void actor1() {
        x = 1;   // Yazma 1
        r1 = y;  // Okuma 1
    }

    // Thread 2 çalıştırır:
    public void actor2() {
        y = 1;   // Yazma 2
        r2 = x;  // Okuma 2
    }

    // Olası Sonuçlar:
    // r1=0, r2=1 (Thread 1 önce bitti)
    // r1=1, r2=0 (Thread 2 önce bitti)
    // r1=1, r2=1 (İki yazma da önce bitti)
    // r1=0, r2=0 (İMKANSIZ GİBİ GÖRÜNÜR AMA REORDERING YÜZÜNDEN GERÇEKLEŞİR!)
    void main() {
        IO.println("Instruction Reordering: Donanım StoreLoad taklası r1=0, r2=0 sonucunu doğurabilir!");
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
      Mülakat Sorusu: 'Tek bir thread içinde `x = 1; y = 2;` yazarsak CPU hangisini önce çalıştırır?' Doğru Yanıt: 'Aralarında veri bağımlılığı olmadığı için CPU veya JIT dilediğini önce çalıştırabilir! Tek thread için sonuç fark etmez ama başka bir thread araya girerse patlar.'
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\
      #v(3pt)
      #text(fill: rgb("78350f"))[Sharp Interview Question: 'In `x = 1; y = 2;`, does the JVM guarantee x is written before y?' Correct Answer: 'No! There is zero data dependency between x and y. The compiler or CPU can flip their execution order freely. To enforce ordering across threads, memory barriers (`volatile` or locks) are mandatory.']
    ]
  )
]

#takeaways_box((
    ("As-if-serial kuralı sıralama garantisini yalnızca tek bir thread için verir.", "The as-if-serial contract guarantees preservation of program semantics strictly for single threads."),
    ("Modern CPU'lar bellek gecikmesini gizlemek için komutları sıra dışı (out-of-order) çalıştırır.", "Hardware speculatively reorders instructions out-of-order to hide memory latency."),
    ("Farklı thread'ler arasındaki sıralama yalnızca Memory Barrier (Fences) ile zorlanabilir.", "Cross-thread instruction ordering requires explicit hardware memory barriers."),
))
