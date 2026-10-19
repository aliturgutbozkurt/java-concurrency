#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_all.py
Master generator and compiler for the 10-Module, 60-Lesson Bilingual ELI5
MAANG Java Concurrency & Multithreading Masterclass (Java 25 LTS & Project Loom).

Outputs:
  - content/module_XX/lesson_YY.typ (60 files)
  - content/module_XX/module_XX.typ (10 files)
  - book.typ (Master unified book)
  - output/individual/lesson_XX.pdf (60 PDFs)
  - output/modules/module_XX.pdf (10 PDFs)
  - output/book/Java_Concurrency_MAANG_ELI5.pdf (1 Master Mega-PDF)
  - web/data/lessons.json (Structured JSON for Web Companion Reader)
  - web/data/lessons.js (Offline window.LESSONS_DATA bundle)
"""

import os
import sys
import json
import re
import argparse
import subprocess
from pathlib import Path

BASE_DIR = Path("/Users/aliturgutbozkurt/Desktop/java-concurrency")
MODULES_DATA_DIR = BASE_DIR / "modules_data"
CONTENT_DIR = BASE_DIR / "content"
OUTPUT_DIR = BASE_DIR / "output"
WEB_DIR = BASE_DIR / "web"

sys.path.insert(0, str(MODULES_DATA_DIR))
import mod01_threads_jmm_basics
import mod02_volatile_atomicity
import mod03_sync_monitors_locks
import mod04_advanced_sync_primitives
import mod05_thread_pools_executors
import mod06_concurrent_collections
import mod07_async_completable_future
import mod08_project_loom_virtual_threads
import mod09_concurrency_bugs_debugging
import mod10_maang_system_design_mastery

MODULES = [
    mod01_threads_jmm_basics.MODULE,
    mod02_volatile_atomicity.MODULE,
    mod03_sync_monitors_locks.MODULE,
    mod04_advanced_sync_primitives.MODULE,
    mod05_thread_pools_executors.MODULE,
    mod06_concurrent_collections.MODULE,
    mod07_async_completable_future.MODULE,
    mod08_project_loom_virtual_threads.MODULE,
    mod09_concurrency_bugs_debugging.MODULE,
    mod10_maang_system_design_mastery.MODULE,
]

def sanitize_typst_text(s: str) -> str:
    """Escapes dollar signs, <, @, and unescaped underscores outside backticks."""
    if not s:
        return ""
    s = s.replace("```", "'''")
    s = s.replace("$", "\\$")
    s = re.sub(r"(?<!\\)<", r"\<", s)
    s = re.sub(r"(?<!\\)@", r"\@", s)
    
    # Escape underscores outside backtick code spans to prevent unclosed delimiter errors
    parts = s.split("`")
    for i in range(0, len(parts), 2):
        parts[i] = parts[i].replace("_", "\\_")
    return "`".join(parts)

def get_lesson_takeaways(l: dict):
    if "takeaways" in l and isinstance(l["takeaways"], list):
        return l["takeaways"]
    elif "takeaway_tr" in l and "takeaway_en" in l:
        return [(l["takeaway_tr"], l["takeaway_en"])]
    return [("Eşzamanlılık kurallarını uygulayın.", "Follow core concurrency invariants.")]

def generate_lesson_typ(m: dict, l: dict) -> str:
    takeaways = get_lesson_takeaways(l)
    takeaways_typ = ""
    for item in takeaways:
        tr_item = sanitize_typst_text(item[0]).replace('"', '\\"')
        en_item = sanitize_typst_text(item[1]).replace('"', '\\"')
        takeaways_typ += f'    ("{tr_item}", "{en_item}"),\n'

    eli5_tr = sanitize_typst_text(l['eli5_tr'])
    eli5_en = sanitize_typst_text(l['eli5_en'])
    deep_tr = sanitize_typst_text(l['deep_tr'])
    deep_en = sanitize_typst_text(l['deep_en'])
    warning_tr = sanitize_typst_text(l['warning_tr'])
    warning_en = sanitize_typst_text(l['warning_en'])

    title_tr = l['title_tr'].replace('"', '\\"')
    title_en = l['title_en'].replace('"', '\\"')
    mod_title_tr = m['title_tr'].replace('"', '\\"')
    mod_title_en = m['title_en'].replace('"', '\\"')

    content = f'''#import "/template.typ": *

#show: doc => setup_book(title: "Ders {l['num']}: {title_tr}", doc)

#lesson_header(
  {l['num']},
  "{title_tr}",
  "{title_en}",
  "{mod_title_tr}",
  "{mod_title_en}"
)

#diagram_box[
```text
{l['diagram']}
```
]

#eli5_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("1e40af"), size: 9pt)[🇹🇷 TÜRKÇE (ELI5)]\\
      #v(3pt)
      {eli5_tr}
    ],
    [
      #text(weight: "bold", fill: rgb("1d4ed8"), size: 9pt)[🇬🇧 ENGLISH (ELI5)]\\
      #v(3pt)
      #text(fill: rgb("334155"))[{eli5_en}]
    ]
  )
]

#deep_dive_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("334155"), size: 9pt)[🇹🇷 MAANG DERİNLEMESİNE ANALİZ]\\
      #v(3pt)
      {deep_tr}
    ],
    [
      #text(weight: "bold", fill: rgb("475569"), size: 9pt)[🇬🇧 MAANG TECHNICAL DEEP-DIVE]\\
      #v(3pt)
      #text(fill: rgb("334155"))[{deep_en}]
    ]
  )
]

#java25_box[
```java
{l['java_code']}
```
]

#warning_box[
  #grid(
    columns: (1fr, 1fr),
    gutter: 14pt,
    [
      #text(weight: "bold", fill: rgb("b45309"), size: 9pt)[🇹🇷 MÜLAKAT TUZAĞI VE TEHLİKE]\\
      #v(3pt)
      {warning_tr}
    ],
    [
      #text(weight: "bold", fill: rgb("92400e"), size: 9pt)[🇬🇧 INTERVIEW TRAP & CONCURRENCY HAZARD]\\
      #v(3pt)
      #text(fill: rgb("78350f"))[{warning_en}]
    ]
  )
]

#takeaways_box((
{takeaways_typ}))
'''
    return content

def generate_module_typ(m: dict) -> str:
    desc_tr = sanitize_typst_text(m['desc_tr']).replace('"', '\\"')
    desc_en = sanitize_typst_text(m['desc_en']).replace('"', '\\"')
    title_tr = m['title_tr'].replace('"', '\\"')
    title_en = m['title_en'].replace('"', '\\"')

    content = f'''#import "/template.typ": *

#show: doc => setup_book(title: "Bölüm {m['id']}: {title_tr}", doc)

#module_cover(
  {m['id']},
  "{title_tr}",
  "{title_en}",
  "{desc_tr}",
  "{desc_en}"
)

'''
    for l in m['lessons']:
        filename = f"lesson_{l['num']:02d}.typ"
        content += f'#include "{filename}"\n#v(16pt)\n\n'
    return content

def generate_master_book_typ() -> str:
    content = '''#import "/template.typ": *

#show: doc => setup_book(
  title: "Aptala Anlatır Gibi MAANG Java Concurrency El Kitabı",
  author: "Antigravity & MAANG Concurrency Guild",
  doc
)

#book_front_cover()

#pagebreak()
#v(20pt)
#align(center)[
  #text(size: 20pt, weight: "bold", fill: rgb("0f172a"))[Önsöz ve Başlarken / Preface & Getting Started]
]
#v(16pt)

#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  [
    == 🇹🇷 Bu Eğitim Hakkında
    Bu kitap; Meta, Amazon, Apple, Netflix, Google (MAANG) ve yüksek frekanslı finans (HFT / FinTech) teknoloji şirketlerinin *Senior, Staff ve Principal Yazılım Mühendisi* mülakatlarına hazırlanan mühendisler için özel olarak hazırlanmıştır.

    Java Concurrency; yalnızca `Thread` açıp `synchronized` yazmaktan ibaret değildir. Donanımsal L1/L2/L3 CPU önbellekleri, MESI önbellek tutarlılık protokolü, Store Buffer, bellek bariyerleri (Memory Barriers), Java Bellek Modeli (JMM Happens-Before), HotSpot kilitleme optimizasyonları ve kilit-siz (Lock-Free) CAS veri yapıları gibi donanım ve çalışma zamanı dinamiklerini derinlemesine kavramayı gerektirir.

    Ayrıca modern *Java 25 LTS* ile birlikte gelen Project Loom Sanal Thread'leri (Virtual Threads M:N), Taşıyıcı Thread (Carrier Thread) montajı, Pinning tehlikesi, Yapısal Eşzamanlılık (StructuredTaskScope) ve ScopedValue devrimi çoklu iş parçacığı paradigmasını kökten değiştirmiştir.

    Bu 60 derslik kapsamlı müfredatta;
    - İşletim sistemi çekirdek thread'leri ile JVM thread durumlarını,
    - Volatile, atomiklik ve False Sharing önbellek satırı dolgusunu,
    - HotSpot Monitör şişmesini (Biased, Lightweight, Heavyweight Lock),
    - ReentrantLock, StampedLock, CountDownLatch, Semaphore ve Phaser primitiflerini,
    - ThreadPoolExecutor büyüme dinamiklerini ve Fork/Join Work-Stealing algoritmasını,
    - ConcurrentHashMap iç yapısını (Node CAS, Bin-Level Kilitleri ve TreeBin),
    - CompletableFuture asenkron boru hatlarını ve zaman aşımı yönetimini,
    - Sanal Thread'leri, Carrier unmounting döngüsünü ve Pinning önleme stratejilerini,
    - Deadlock, Livelock, Starvation ve ABA problemlerini ve thread dump analizini,
    - MAANG beyaz tahta sistem tasarımı vakalarını (O(1) LRU Cache, LMAX Disruptor, Token Bucket, HikariCP ConcurrentBag)
    *bir aptala anlatır gibi* en yalın analojiler, mimari ASCII akış şemaları ve çalışan modern Java 25 kodlarıyla inceleyeceksiniz.
  ],
  [
    == 🇬🇧 About This Masterclass
    This handbook is engineered for software engineers, distributed systems architects, and low-latency engineers targeting Senior, Staff, and Principal roles at Tier-1 tech giants (MAANG / FAANG) and High-Frequency Trading (HFT) firms.

    Java Concurrency transcends simple locking and threads. True mastery demands an uncompromising understanding of CPU hardware caches, StoreLoad memory barriers, the Java Memory Model (JMM happens-before guarantees), HotSpot lock inflation lifecycles, and lock-free atomic CAS primitives.

    Furthermore, the arrival of modern *Java 25 LTS* and Project Loom has redefined the concurrency landscape: M:N Virtual Threads, carrier thread mounting/unmounting, carrier pinning hazards, Structured Concurrency (`StructuredTaskScope`), and immutable `ScopedValue` context propagation.

    Across 60 deep-dive lessons organized into 10 structured modules, and powered by *Java 25 LTS*, you will master:
    - OS kernel threads, 6 JVM states, and hardware cache lines,
    - Volatile visibility semantics, memory barriers, and false sharing,
    - HotSpot monitor inflation, lightweight spin-locks, and ReentrantLock,
    - StampedLock optimistic reads, Semaphore pooling, and dynamic Phasers,
    - ThreadPoolExecutor queue dynamics and Fork/Join work-stealing algorithms,
    - Modern ConcurrentHashMap internals (Node CAS, bin-locking, and TreeBins),
    - Reactive CompletableFuture DAG pipelines, scatter-gather, and fallbacks,
    - Project Loom Virtual Threads, Epoll continuation unmounting, and pinning remedies,
    - Coffman deadlock forensics, live production thread dump analysis (jstack/jcmd),
    - Legendary MAANG concurrency whiteboard challenges: O(1) LRU Cache, LMAX Disruptor RingBuffer, Token-Bucket Rate Limiter, and HikariCP ConcurrentBag.
  ]
)

#v(20pt)
#line(length: 100%, stroke: 0.8pt + rgb("e2e8f0"))
#v(10pt)

#outline(
  title: [İçindekiler / Table of Contents],
  depth: 2,
  indent: auto
)

#pagebreak()
'''
    for m in MODULES:
        desc_tr = sanitize_typst_text(m['desc_tr']).replace('"', '\\"')
        desc_en = sanitize_typst_text(m['desc_en']).replace('"', '\\"')
        title_tr = m['title_tr'].replace('"', '\\"')
        title_en = m['title_en'].replace('"', '\\"')
        content += f'''
#module_cover(
  {m['id']},
  "{title_tr}",
  "{title_en}",
  "{desc_tr}",
  "{desc_en}"
)

'''
        for l in m['lessons']:
            rel_path = f"/content/{m['dir']}/lesson_{l['num']:02d}.typ"
            content += f'#include "{rel_path}"\n#v(14pt)\n\n'

    content += '''
#pagebreak()
#v(40pt)
#align(center)[
  #rect(fill: rgb("08111e"), radius: 10pt, inset: (x: 24pt, y: 32pt), width: 90%)[
    #text(size: 24pt, fill: rgb("fb923c"), weight: "bold")[🎓 TEBRİKLER! / CONGRATULATIONS!]\
    #v(10pt)
    #text(size: 14pt, fill: white)[60 Derslik MAANG Java Concurrency & Multithreading Yolculuğunu Başarıyla Tamamladınız!]\
    #v(6pt)
    #text(size: 11pt, fill: rgb("94a3b8"))[You have conquered all 60 lessons of the MAANG Java Concurrency & Multithreading Masterclass!]\
    #v(20pt)
    #line(length: 60%, stroke: 1pt + rgb("f97316"))
    #v(15pt)
    #text(size: 10pt, fill: rgb("cbd5e1"))[
      Java 25 LTS • Virtual Threads • JMM • Lock-Free Algorithms • LMAX Disruptor • HikariCP
    ]
  ]
]
'''
    return content

def generate_web_json():
    normalized_modules = []
    for m in MODULES:
        mod_copy = dict(m)
        lessons_copy = []
        for l in m['lessons']:
            l_copy = dict(l)
            l_copy['takeaways'] = get_lesson_takeaways(l)
            if 'takeaway_tr' not in l_copy and len(l_copy['takeaways']) > 0:
                l_copy['takeaway_tr'] = l_copy['takeaways'][0][0]
            if 'takeaway_en' not in l_copy and len(l_copy['takeaways']) > 0:
                l_copy['takeaway_en'] = l_copy['takeaways'][0][1]
            lessons_copy.append(l_copy)
        mod_copy['lessons'] = lessons_copy
        normalized_modules.append(mod_copy)

    data = {
        "title_tr": "Aptala Anlatır Gibi MAANG Java Concurrency & Multithreading",
        "title_en": "Explain Like I'm 5: MAANG Java Concurrency & Multithreading Masterclass",
        "description": "60 Ders • 10 Bölüm • Çift Dilli (TR & EN) • Mimari Şemalar • Java 25 LTS • Project Loom • Lock-Free",
        "modules": normalized_modules
    }
    web_data_dir = WEB_DIR / "data"
    web_data_dir.mkdir(parents=True, exist_ok=True)
    with open(web_data_dir / "lessons.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    with open(web_data_dir / "lessons.js", "w", encoding="utf-8") as f:
        f.write("window.LESSONS_DATA = " + json.dumps(data, ensure_ascii=False) + ";\n")
    print(f"✔ Exported web data to {web_data_dir / 'lessons.json'} and lessons.js")

def write_all_typst_files():
    CONTENT_DIR.mkdir(parents=True, exist_ok=True)
    for m in MODULES:
        mod_dir = CONTENT_DIR / m['dir']
        mod_dir.mkdir(parents=True, exist_ok=True)
        for l in m['lessons']:
            lesson_typ = generate_lesson_typ(m, l)
            lesson_path = mod_dir / f"lesson_{l['num']:02d}.typ"
            with open(lesson_path, "w", encoding="utf-8") as f:
                f.write(lesson_typ)
        
        module_typ = generate_module_typ(m)
        module_path = mod_dir / f"module_{m['id']:02d}.typ"
        with open(module_path, "w", encoding="utf-8") as f:
            f.write(module_typ)
    
    book_typ = generate_master_book_typ()
    with open(BASE_DIR / "book.typ", "w", encoding="utf-8") as f:
        f.write(book_typ)
    print("✔ All Typst source files generated successfully!")

def compile_typst(src: Path, out: Path) -> bool:
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "typst", "compile",
        "--root", str(BASE_DIR),
        str(src),
        str(out)
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"❌ Error compiling {src.name} -> {out.name}:")
        print(res.stderr)
        return False
    return True

def compile_individual_lessons():
    print("\n--- Compiling 60 Individual Lesson PDFs ---")
    indiv_dir = OUTPUT_DIR / "individual"
    success_count = 0
    for m in MODULES:
        for l in m['lessons']:
            src = CONTENT_DIR / m['dir'] / f"lesson_{l['num']:02d}.typ"
            out = indiv_dir / f"lesson_{l['num']:02d}.pdf"
            if compile_typst(src, out):
                success_count += 1
                print(f"[{l['num']:02d}/60] Generated: {out.name}")
            else:
                print(f"FAILED: {out.name}")
    print(f"✔ Individual Lessons: {success_count}/60 compiled successfully.")
    return success_count == 60

def compile_modules():
    print("\n--- Compiling 10 Module Bundle PDFs ---")
    mods_dir = OUTPUT_DIR / "modules"
    success_count = 0
    for m in MODULES:
        src = CONTENT_DIR / m['dir'] / f"module_{m['id']:02d}.typ"
        out = mods_dir / f"module_{m['id']:02d}.pdf"
        if compile_typst(src, out):
            success_count += 1
            print(f"[{m['id']:02d}/10] Generated: {out.name}")
        else:
            print(f"FAILED: {out.name}")
    print(f"✔ Module Bundles: {success_count}/10 compiled successfully.")
    return success_count == 10

def compile_master_book():
    print("\n--- Compiling Master Unified Book PDF ---")
    book_src = BASE_DIR / "book.typ"
    book_out = OUTPUT_DIR / "book" / "Java_Concurrency_MAANG_ELI5.pdf"
    if compile_typst(book_src, book_out):
        size_mb = book_out.stat().st_size / (1024 * 1024)
        print(f"✔ MASTER BOOK COMPILED SUCCESSFULLY: {book_out.name} ({size_mb:.2f} MB)")
        return True
    else:
        print("❌ FAILED to compile master book!")
        return False

def main():
    parser = argparse.ArgumentParser(description="Build MAANG Java Concurrency Curriculum")
    parser.add_argument("--gen-only", action="store_true", help="Only generate Typst and JSON files without compiling")
    parser.add_argument("--lessons-only", action="store_true", help="Compile only individual lessons")
    parser.add_argument("--modules-only", action="store_true", help="Compile only module bundles")
    parser.add_argument("--book-only", action="store_true", help="Compile only the master book")
    parser.add_argument("--all", action="store_true", help="Generate all files and compile all 71 PDFs")
    args = parser.parse_args()

    print("==================================================================")
    print("🚀 MAANG Java Concurrency & Multithreading Build Engine (Java 25)")
    print("==================================================================")

    # 1. Export Web JSON
    generate_web_json()

    # 2. Write all Typst files
    write_all_typst_files()

    if args.gen_only:
        print("✔ Generation complete. Skipping compilation as requested.")
        return

    compile_all = args.all or (not args.lessons_only and not args.modules_only and not args.book_only)

    if compile_all or args.lessons_only:
        compile_individual_lessons()

    if compile_all or args.modules_only:
        compile_modules()

    if compile_all or args.book_only:
        compile_master_book()

    print("\n🎉 Build Pipeline Execution Completed!")

if __name__ == "__main__":
    main()
