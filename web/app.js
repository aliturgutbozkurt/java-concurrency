/* ==============================================================================
   MAANG JAVA CONCURRENCY & MULTITHREADING ELI5 - JAVASCRIPT APP CONTROLLER
   Offline-first (file:// and http:// compatible), Instant Search, Multi-language
   ============================================================================== */

let appData = null;
let currentLessonNum = 1;
let currentLanguage = 'split'; // 'split', 'tr', 'en'
let allLessonsFlat = [];

document.addEventListener('DOMContentLoaded', async () => {
  await initData();
  initUI();
  handleRouting();
});

// Load curriculum data from window.LESSONS_DATA or fetch fallback
async function initData() {
  if (window.LESSONS_DATA && window.LESSONS_DATA.modules) {
    appData = window.LESSONS_DATA;
  } else {
    try {
      const response = await fetch('data/lessons.json');
      appData = await response.json();
    } catch (e) {
      console.warn("Could not fetch data via fetch API, relying on window.LESSONS_DATA:", e);
    }
  }

  if (!appData || !appData.modules) {
    alert("Hata: Ders verileri yüklenemedi. Lütfen 'lessons.js' dosyasının var olduğundan emin olun.");
    return;
  }

  // Flatten lessons for quick lookup
  allLessonsFlat = [];
  appData.modules.forEach(m => {
    m.lessons.forEach(l => {
      allLessonsFlat.push({ ...l, module: m });
    });
  });
}

function initUI() {
  renderSidebar(appData.modules);
  setupLanguageSwitcher();
  setupSearch();
  setupPdfModal();
  setupKeyboardShortcuts();
  window.addEventListener('hashchange', handleRouting);
}

// Router based on hash (#lesson-12)
function handleRouting() {
  const hash = window.location.hash;
  let targetLesson = 1;
  if (hash.startsWith('#lesson-')) {
    const num = parseInt(hash.replace('#lesson-', ''), 10);
    if (!isNaN(num) && num >= 1 && num <= 60) {
      targetLesson = num;
    }
  }
  selectLesson(targetLesson);
}

// Render Sidebar Accordion
function renderSidebar(modules) {
  const container = document.getElementById('moduleAccordion');
  if (!container) return;
  container.innerHTML = '';

  modules.forEach(m => {
    const li = document.createElement('li');
    li.className = 'module-item open';
    li.id = `mod-item-${m.id}`;

    let lessonButtonsHtml = '';
    m.lessons.forEach(l => {
      lessonButtonsHtml += `
        <li>
          <button class="lesson-nav-btn" id="nav-btn-${l.num}" onclick="navigateToLesson(${l.num})">
            <span class="lesson-nav-num">#${l.num < 10 ? '0' + l.num : l.num}</span>
            <span class="lesson-nav-title">${escapeHtml(l.title_tr)}</span>
          </button>
        </li>
      `;
    });

    li.innerHTML = `
      <div class="module-header" onclick="toggleModule(${m.id})">
        <div class="module-title-group">
          <span class="module-badge">BÖLÜM ${m.id}</span>
          <span class="module-title-text">${escapeHtml(m.title_tr)}</span>
        </div>
        <span class="module-chevron">▶</span>
      </div>
      <ul class="lesson-sublist">
        ${lessonButtonsHtml}
      </ul>
    `;
    container.appendChild(li);
  });
}

function toggleModule(modId) {
  const item = document.getElementById(`mod-item-${modId}`);
  if (item) {
    item.classList.toggle('open');
  }
}

function navigateToLesson(num) {
  window.location.hash = `#lesson-${num}`;
}

// Select and Render Lesson
function selectLesson(num) {
  currentLessonNum = num;
  const item = allLessonsFlat.find(x => x.num === num);
  if (!item) return;

  // Update Sidebar active state
  document.querySelectorAll('.lesson-nav-btn').forEach(btn => btn.classList.remove('active'));
  const activeBtn = document.getElementById(`nav-btn-${num}`);
  if (activeBtn) {
    activeBtn.classList.add('active');
    activeBtn.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    const parentModule = activeBtn.closest('.module-item');
    if (parentModule && !parentModule.classList.contains('open')) {
      parentModule.classList.add('open');
    }
  }

  // Update Counter Badge
  const counterBadge = document.getElementById('lessonCounterBadge');
  if (counterBadge) {
    counterBadge.textContent = `Ders ${num} / 60`;
  }

  // Render Content
  renderLessonContent(item);
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function renderLessonContent(item) {
  const container = document.getElementById('mainContent');
  if (!container) return;

  const m = item.module;
  const prevNum = item.num > 1 ? item.num - 1 : null;
  const nextNum = item.num < 60 ? item.num + 1 : null;

  // Takeaways rendering
  let takeawaysHtml = '';
  const takeawaysList = item.takeaways || [];
  if (takeawaysList.length > 0) {
    takeawaysHtml = takeawaysList.map(pair => `
      <li class="takeaway-item">
        <div class="takeaway-tr"><strong>•</strong> ${escapeHtml(pair[0])}</div>
        <div class="takeaway-en"><strong>•</strong> ${escapeHtml(pair[1])}</div>
      </li>
    `).join('');
  } else if (item.takeaway_tr) {
    takeawaysHtml = `
      <li class="takeaway-item">
        <div class="takeaway-tr"><strong>•</strong> ${escapeHtml(item.takeaway_tr)}</div>
        <div class="takeaway-en"><strong>•</strong> ${escapeHtml(item.takeaway_en || '')}</div>
      </li>
    `;
  }

  container.innerHTML = `
    <article class="lesson-card">
      <!-- Lesson Hero Header -->
      <div class="lesson-hero">
        <div class="hero-meta">
          <span class="hero-module-badge">Bölüm ${m.id}: ${escapeHtml(m.title_tr)}</span>
          <span class="hero-lesson-badge">Ders #${item.num} / 60</span>
        </div>
        <h1 class="hero-title-tr">${escapeHtml(item.title_tr)}</h1>
        <h2 class="hero-title-en">${escapeHtml(item.title_en)}</h2>

        <div class="hero-quick-actions">
          <a href="#sec-diagram" class="nav-jump-btn">⚡ Şema</a>
          <a href="#sec-eli5" class="nav-jump-btn">💡 ELI5</a>
          <a href="#sec-deep" class="nav-jump-btn">🔍 Derinlemesine</a>
          <a href="#sec-code" class="nav-jump-btn">⚡ Java 25 Kodu</a>
          <a href="#sec-warning" class="nav-jump-btn">⚠️ Tuzaklar</a>
          <a href="../output/individual/lesson_${item.num < 10 ? '0' + item.num : item.num}.pdf" target="_blank" class="nav-jump-btn" style="color: var(--accent-orange); margin-left: auto;">
            📄 Bu Dersi PDF Aç
          </a>
        </div>
      </div>

      <!-- 1. Diagram Box -->
      <section id="sec-diagram" class="content-box box-diagram">
        <div class="box-header">
          <span class="box-title-tr">⚡ Bellek & Eşzamanlılık Akış Şeması</span>
          <span class="box-title-en">Concurrency & Memory Schematic</span>
        </div>
        <div class="box-body">
          <pre class="diagram-pre"><code>${escapeHtml(item.diagram)}</code></pre>
        </div>
      </section>

      <!-- 2. ELI5 Box -->
      <section id="sec-eli5" class="content-box box-eli5">
        <div class="box-header">
          <span class="box-title-tr">💡 Aptala Anlatım (ELI5 Metaforu)</span>
          <span class="box-title-en">ELI5 Metaphor</span>
        </div>
        <div class="box-body">
          <div class="split-content ${currentLanguage}">
            <div class="lang-column tr-text" style="${currentLanguage === 'en' ? 'display:none;' : ''}">
              <span class="lang-badge-tr">🇹🇷 TÜRKÇE</span>
              <p>${formatParagraphs(item.eli5_tr)}</p>
            </div>
            <div class="lang-column en-text" style="${currentLanguage === 'tr' ? 'display:none;' : ''}">
              <span class="lang-badge-en">🇬🇧 ENGLISH</span>
              <p>${formatParagraphs(item.eli5_en)}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 3. Deep Dive Box -->
      <section id="sec-deep" class="content-box box-deep">
        <div class="box-header">
          <span class="box-title-tr">🔍 MAANG Seviyesi Teknik Derinlik</span>
          <span class="box-title-en">MAANG-Level Technical Deep-Dive</span>
        </div>
        <div class="box-body">
          <div class="split-content ${currentLanguage}">
            <div class="lang-column tr-text" style="${currentLanguage === 'en' ? 'display:none;' : ''}">
              <span class="lang-badge-tr">🇹🇷 TEKNİK ANALİZ</span>
              <p>${formatParagraphs(item.deep_tr)}</p>
            </div>
            <div class="lang-column en-text" style="${currentLanguage === 'tr' ? 'display:none;' : ''}">
              <span class="lang-badge-en">🇬🇧 TECHNICAL DEEP-DIVE</span>
              <p>${formatParagraphs(item.deep_en)}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 4. Java 25 Code Box -->
      <section id="sec-code" class="content-box box-code">
        <div class="box-header">
          <span class="box-title-tr">⚡ Modern Java 25 LTS Kodu</span>
          <span class="box-title-en">Java 25 LTS Implementation</span>
        </div>
        <div class="box-body">
          <div class="code-pre-wrapper">
            <button class="btn-copy-code" onclick="copyCode(this)">📋 Kodu Kopyala</button>
            <pre class="code-pre"><code>${escapeHtml(item.java_code)}</code></pre>
          </div>
        </div>
      </section>

      <!-- 5. Warning / Hazard Box -->
      <section id="sec-warning" class="content-box box-warning">
        <div class="box-header">
          <span class="box-title-tr">⚠️ Deadlock, Race Condition & Mülakat Tuzağı</span>
          <span class="box-title-en">Concurrency Hazard & Interview Trap</span>
        </div>
        <div class="box-body">
          <div class="split-content ${currentLanguage}">
            <div class="lang-column tr-text" style="${currentLanguage === 'en' ? 'display:none;' : ''}">
              <span class="lang-badge-tr">🇹🇷 DİKKAT EDİLECEK TUZAK</span>
              <p>${formatParagraphs(item.warning_tr)}</p>
            </div>
            <div class="lang-column en-text" style="${currentLanguage === 'tr' ? 'display:none;' : ''}">
              <span class="lang-badge-en">🇬🇧 INTERVIEW TRAP</span>
              <p>${formatParagraphs(item.warning_en)}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 6. Takeaways Box -->
      <section id="sec-takeaways" class="content-box box-takeaways">
        <div class="box-header">
          <span class="box-title-tr">🎯 Mülakatta Hatırlanacak Altın Çıkarımlar</span>
          <span class="box-title-en">Key Takeaways</span>
        </div>
        <div class="box-body">
          <ul class="takeaway-list">
            ${takeawaysHtml}
          </ul>
        </div>
      </section>

      <!-- Pagination Footer -->
      <div class="lesson-pagination">
        ${prevNum ? `
          <button class="btn-secondary" onclick="navigateToLesson(${prevNum})">
            ← Önceki Ders (#${prevNum < 10 ? '0' + prevNum : prevNum})
          </button>
        ` : '<div></div>'}

        <a href="#sidebar" class="btn-secondary" style="font-size: 0.75rem;">
          ↑ Menüye Dön
        </a>

        ${nextNum ? `
          <button class="btn-primary" onclick="navigateToLesson(${nextNum})">
            Sonraki Ders (#${nextNum < 10 ? '0' + nextNum : nextNum}) →
          </button>
        ` : '<div></div>'}
      </div>
    </article>
  `;
}

// Language Switcher Setup
function setupLanguageSwitcher() {
  const buttons = document.querySelectorAll('.lang-btn');
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      buttons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentLanguage = btn.dataset.lang;

      // Re-apply language visibility
      document.querySelectorAll('.split-content').forEach(splitEl => {
        const trCol = splitEl.querySelector('.tr-text');
        const enCol = splitEl.querySelector('.en-text');

        if (currentLanguage === 'split') {
          splitEl.style.gridTemplateColumns = '1fr 1fr';
          if (trCol) trCol.style.display = 'block';
          if (enCol) enCol.style.display = 'block';
        } else if (currentLanguage === 'tr') {
          splitEl.style.gridTemplateColumns = '1fr';
          if (trCol) trCol.style.display = 'block';
          if (enCol) enCol.style.display = 'none';
        } else if (currentLanguage === 'en') {
          splitEl.style.gridTemplateColumns = '1fr';
          if (trCol) trCol.style.display = 'none';
          if (enCol) enCol.style.display = 'block';
        }
      });
    });
  });
}

// Live Search Setup
function setupSearch() {
  const searchInput = document.getElementById('searchInput');
  if (!searchInput) return;

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    if (!query) {
      // Reset all sidebar buttons visibility
      document.querySelectorAll('.lesson-nav-btn').forEach(btn => {
        btn.closest('li').style.display = 'block';
      });
      document.querySelectorAll('.module-item').forEach(m => {
        m.style.display = 'block';
      });
      return;
    }

    // Filter lessons
    appData.modules.forEach(m => {
      let moduleHasMatch = false;
      m.lessons.forEach(l => {
        const match = 
          l.title_tr.toLowerCase().includes(query) ||
          l.title_en.toLowerCase().includes(query) ||
          l.eli5_tr.toLowerCase().includes(query) ||
          l.deep_tr.toLowerCase().includes(query) ||
          l.java_code.toLowerCase().includes(query);

        const btn = document.getElementById(`nav-btn-${l.num}`);
        if (btn) {
          btn.closest('li').style.display = match ? 'block' : 'none';
          if (match) moduleHasMatch = true;
        }
      });

      const modItem = document.getElementById(`mod-item-${m.id}`);
      if (modItem) {
        modItem.style.display = moduleHasMatch ? 'block' : 'none';
        if (moduleHasMatch) {
          modItem.classList.add('open');
        }
      }
    });
  });
}

// PDF Library Modal Setup
function setupPdfModal() {
  const btnOpen = document.getElementById('btnOpenPdfModal');
  const btnClose = document.getElementById('btnClosePdfModal');
  const modal = document.getElementById('pdfModal');

  if (btnOpen && modal) {
    btnOpen.addEventListener('click', () => {
      populatePdfModal();
      modal.classList.add('open');
    });
  }

  if (btnClose && modal) {
    btnClose.addEventListener('click', () => {
      modal.classList.remove('open');
    });
  }

  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.classList.remove('open');
      }
    });
  }
}

function populatePdfModal() {
  const modContainer = document.getElementById('modalModulePdfList');
  const indivContainer = document.getElementById('modalIndividualPdfList');

  if (modContainer && modContainer.children.length === 0) {
    appData.modules.forEach(m => {
      const item = document.createElement('div');
      item.className = 'pdf-item';
      item.innerHTML = `
        <div>
          <div style="font-weight: 700; color: white; font-size: 0.88rem;">📦 Bölüm ${m.id}: ${escapeHtml(m.title_tr)}</div>
          <div style="font-size: 0.76rem; color: var(--text-muted);">${escapeHtml(m.title_en)} (6 Ders)</div>
        </div>
        <a href="../output/modules/module_${m.id < 10 ? '0' + m.id : m.id}.pdf" target="_blank" class="btn-secondary" style="font-size: 0.78rem;">
          ⬇️ İndir (PDF)
        </a>
      `;
      modContainer.appendChild(item);
    });
  }

  if (indivContainer && indivContainer.children.length === 0) {
    allLessonsFlat.forEach(l => {
      const a = document.createElement('a');
      a.className = 'pdf-lesson-btn';
      a.href = `../output/individual/lesson_${l.num < 10 ? '0' + l.num : l.num}.pdf`;
      a.target = '_blank';
      a.innerHTML = `
        <span>#${l.num < 10 ? '0' + l.num : l.num} ${escapeHtml(l.title_tr.substring(0, 26))}...</span>
        <span style="color: var(--accent-orange); font-size: 0.72rem;">PDF ↗</span>
      `;
      indivContainer.appendChild(a);
    });
  }
}

// Keyboard shortcuts (ArrowLeft: prev, ArrowRight: next)
function setupKeyboardShortcuts() {
  document.addEventListener('keydown', (e) => {
    // If typing in search box, ignore arrow shortcuts
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;

    if (e.key === 'ArrowRight' && currentLessonNum < 60) {
      navigateToLesson(currentLessonNum + 1);
    } else if (e.key === 'ArrowLeft' && currentLessonNum > 1) {
      navigateToLesson(currentLessonNum - 1);
    } else if (e.key === 'Escape') {
      const modal = document.getElementById('pdfModal');
      if (modal) modal.classList.remove('open');
    }
  });
}

// Copy Code to Clipboard
window.copyCode = function(button) {
  const codeEl = button.parentElement.querySelector('code');
  if (!codeEl) return;

  navigator.clipboard.writeText(codeEl.textContent).then(() => {
    const originalText = button.textContent;
    button.textContent = '✅ Kopyalandı!';
    button.style.borderColor = 'var(--accent-emerald)';
    button.style.color = 'var(--accent-emerald)';
    setTimeout(() => {
      button.textContent = originalText;
      button.style.borderColor = '';
      button.style.color = '';
    }, 2000);
  }).catch(err => {
    console.error("Kopyalama başarısız:", err);
  });
};

// Utilities
function escapeHtml(str) {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function formatParagraphs(text) {
  if (!text) return '';
  return escapeHtml(text).replace(/\n\n/g, '</p><p>').replace(/\n/g, '<br>');
}
