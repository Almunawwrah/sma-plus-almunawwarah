(function () {
  'use strict';

  /* ─── a) Duplicate injection guard ─── */
  if (window.__smaFooterLoaded) return;

  /* ─── b) Path detection ─── */
  var isPages =
    window.location.pathname.includes('/pages/') ||
    window.location.pathname.includes('/admincms/');

  var homeUrl = isPages ? '../index.html' : 'index.html';

  function pages(name) {
    return isPages ? './' + name : 'pages/' + name;
  }

  var imgLogo = isPages ? '../assets/logo.png' : 'assets/logo.png';

  /* ─── c) Footer CSS ─── */
  var footerCSS = document.createElement('style');
  footerCSS.id = 'sma-footer-css';
  footerCSS.textContent = [
    '.site-footer {',
    '  background: linear-gradient(135deg, #064e3b 0%, #065f46 60%, #047857 100%);',
    '  color: rgba(255,255,255,0.9);',
    '  padding: 72px 0 0;',
    '  position: relative;',
    '  overflow: hidden;',
    '}',
    '',
    '.site-footer::before {',
    '  content: "";',
    '  position: absolute;',
    '  top: 0; left: 0; right: 0;',
    '  height: 5px;',
    '  background: linear-gradient(to right, var(--primary), var(--accent), var(--secondary), var(--primary));',
    '  background-size: 200% 100%;',
    '  animation: footerGradient 8s ease infinite;',
    '}',
    '@keyframes footerGradient {',
    '  0% { background-position: 0% 50%; }',
    '  50% { background-position: 100% 50%; }',
    '  100% { background-position: 0% 50%; }',
    '}',
    '.site-footer::after {',
    '  content: "";',
    '  position: absolute;',
    '  top: -120px; right: -120px;',
    '  width: 320px; height: 320px;',
    '  border-radius: 50%;',
    '  background: radial-gradient(circle, rgba(245,158,11,0.10), transparent 70%);',
    '  pointer-events: none;',
    '}',
    '',
    '.footer-grid {',
    '  display: grid;',
    '  grid-template-columns: 1.6fr 1fr 1.2fr 0.8fr;',
    '  gap: 44px;',
    '  max-width: 1240px;',
    '  margin: 0 auto;',
    '  padding: 0 28px;',
    '  position: relative;',
    '  z-index: 1;',
    '}',
    '',
    '.footer-brand { margin-bottom: 0; }',
    '',
    '.footer-brand .brand-name {',
    "  font-family: 'Plus Jakarta Sans', sans-serif;",
    '  font-size: 1.35rem;',
    '  font-weight: 800;',
    '  color: white;',
    '  margin-bottom: 12px;',
    '  letter-spacing: -0.015em;',
    '}',
    '',
    '.footer-brand .brand-name i { font-size: 1.4rem; color: var(--accent); }',
    '',
    '.footer-brand p {',
    '  font-size: 0.9rem;',
    '  line-height: 1.75;',
    '  color: rgba(255,255,255,0.75);',
    '  margin-bottom: 20px;',
    '}',
    '',
    '.footer-col h4 {',
    "  font-family: 'Plus Jakarta Sans', sans-serif;",
    '  font-size: 1rem;',
    '  font-weight: 700;',
    '  color: white;',
    '  margin-bottom: 20px;',
    '  position: relative;',
    '  padding-bottom: 10px;',
    '  letter-spacing: -0.01em;',
    '}',
    '',
    '.footer-col h4::after {',
    '  content: "";',
    '  position: absolute;',
    '  bottom: 0; left: 0;',
    '  width: 32px; height: 3px;',
    '  background: linear-gradient(90deg, var(--accent), var(--primary-light));',
    '  border-radius: 2px;',
    '}',
    '',
    '.footer-col ul { list-style: none; padding: 0; }',
    '.footer-col ul li { margin-bottom: 10px; }',
    '',
    '.footer-col ul li a {',
    '  color: rgba(255,255,255,0.75);',
    '  font-size: 0.9rem;',
    '  transition: all 0.25s var(--ease);',
    '  display: flex; align-items: center; gap: 8px;',
    '}',
    '.footer-col ul li a:hover { color: white; padding-left: 6px; }',
    '.footer-col ul li a i { font-size: 0.7rem; color: var(--accent); }',
    '',
    '.footer-contact-item {',
    '  display: flex; align-items: flex-start; gap: 12px;',
    '  margin-bottom: 14px;',
    '}',
    '.footer-contact-item i {',
    '  color: var(--accent);',
    '  font-size: 1rem;',
    '  margin-top: 3px;',
    '  width: 18px;',
    '}',
    '.footer-contact-item span {',
    '  color: rgba(255,255,255,0.75);',
    '  font-size: 0.9rem;',
    '  line-height: 1.55;',
    '}',
    '',
    '.footer-social { display: flex; gap: 10px; margin-top: 16px; }',
    '.footer-social a {',
    '  width: 42px; height: 42px;',
    '  border-radius: 12px;',
    '  background: rgba(255,255,255,0.08);',
    '  backdrop-filter: blur(4px);',
    '  border: 1px solid rgba(255,255,255,0.1);',
    '  display: flex; align-items: center; justify-content: center;',
    '  color: white;',
    '  transition: all 0.3s var(--ease);',
    '  font-size: 1rem;',
    '}',
    '.footer-social a:hover {',
    '  background: linear-gradient(135deg, var(--accent), #d97706);',
    '  transform: translateY(-3px);',
    '  border-color: transparent;',
    '  box-shadow: 0 8px 16px -4px rgba(245,158,11,0.4);',
    '}',
    '',
    '.footer-bottom {',
    '  margin-top: 48px;',
    '  padding: 22px 28px;',
    '  border-top: 1px solid rgba(255,255,255,0.1);',
    '  text-align: center;',
    '  background: rgba(0,0,0,0.15);',
    '  backdrop-filter: blur(4px);',
    '}',
    '.footer-bottom p { font-size: 0.85rem; color: rgba(255,255,255,0.65); margin-bottom: 6px; }',
    '.footer-bottom p:last-child { margin-bottom: 0; }',
    '.footer-bottom a { color: rgba(255,255,255,0.75); text-decoration: none; transition: color 0.3s; }',
    '.footer-bottom a:hover { color: white; text-decoration: underline; }',
    '',
    '.whatsapp-float {',
    '  position: fixed;',
    '  bottom: 26px; right: 26px;',
    '  width: 58px; height: 58px;',
    '  background: linear-gradient(135deg, #25D366, #128C7E);',
    '  border-radius: 50%;',
    '  display: flex; align-items: center; justify-content: center;',
    '  color: white;',
    '  font-size: 1.6rem;',
    '  box-shadow: 0 8px 24px -4px rgba(37,211,102,0.45);',
    '  z-index: 900;',
    '  transition: all 0.3s var(--ease);',
    '  animation: whatsappPulse 2.5s ease-in-out infinite;',
    '}',
    '@keyframes whatsappPulse {',
    '  0%, 100% { box-shadow: 0 8px 24px -4px rgba(37,211,102,0.45), 0 0 0 0 rgba(37,211,102,0.4); }',
    '  50% { box-shadow: 0 8px 24px -4px rgba(37,211,102,0.45), 0 0 0 14px rgba(37,211,102,0); }',
    '}',
    '.whatsapp-float:hover { transform: scale(1.08); box-shadow: 0 12px 28px -4px rgba(37,211,102,0.55); }',
    '',
    '.back-to-top {',
    '  position: fixed;',
    '  bottom: 96px; right: 26px;',
    '  width: 46px; height: 46px;',
    '  background: linear-gradient(135deg, var(--primary), var(--primary-dark));',
    '  border-radius: 14px;',
    '  display: flex; align-items: center; justify-content: center;',
    '  color: white;',
    '  font-size: 1rem;',
    '  box-shadow: 0 8px 20px -6px rgba(5,150,105,0.45);',
    '  z-index: 900;',
    '  transition: all 0.3s var(--ease);',
    '  opacity: 0; visibility: hidden; transform: translateY(10px);',
    '  border: none; cursor: pointer;',
    '}',
    '.back-to-top.active { opacity: 1; visibility: visible; transform: translateY(0); }',
    '.back-to-top:hover { transform: translateY(-3px); box-shadow: 0 12px 26px -6px rgba(5,150,105,0.55); filter: brightness(1.05); }',
    '',
    '@media (max-width: 900px) {',
    '  .footer-grid { grid-template-columns: 1fr 1fr; gap: 32px; }',
    '}',
    '@media (max-width: 560px) {',
    '  .footer-grid { grid-template-columns: 1fr; gap: 28px; }',
    '  .site-footer { padding: 48px 0 0; }',
    '  .footer-bottom { padding: 18px 20px; }',
    '}'
  ].join('\n');
  document.head.appendChild(footerCSS);

  /* ─── d) Footer HTML (injected on DOM ready) ─── */
  function injectFooter() {
    var footerHTML = [
      '<footer class="site-footer">',
      '  <div class="footer-grid">',
      '',
      '    <!-- Brand -->',
      '    <div class="footer-brand">',
      '      <img src="' + imgLogo + '" alt="Logo SMA Plus Almunawwarah" style="height:56px;width:auto;object-fit:contain;border-radius:10px;margin-bottom:16px;">',
      '      <div class="brand-name">SMA Plus Almunawwarah</div>',
      '      <p>SMA Plus Almunawwarah adalah pesantren berbasis sekolah menengah atas yang berkomitmen pada keunggulan akademik dan pembentukan karakter Islami untuk mencetak generasi yang berilmu, berakhlak, dan berdaya saing.</p>',
      '    </div>',
      '',
      '    <!-- Tautan Cepat -->',
      '    <div class="footer-col">',
      '      <h4>Tautan Cepat</h4>',
      '      <ul>',
      '        <li><a href="' + homeUrl + '"><i class="fas fa-chevron-right"></i>Beranda</a></li>',
      '        <li><a href="' + pages('sejarah.html') + '"><i class="fas fa-chevron-right"></i>Sejarah</a></li>',
      '        <li><a href="' + pages('kurikulum.html') + '"><i class="fas fa-chevron-right"></i>Kurikulum</a></li>',
      '        <li><a href="' + ('https://smaplusalmunawwarahsmd.blogspot.com/') + '"><i class="fas fa-chevron-right"></i>Berita</a></li>',
      '        <li><a href="' + pages('galeri.html') + '"><i class="fas fa-chevron-right"></i>Galeri</a></li>',
      '        <li><a href="' + pages('info-psb.html') + '"><i class="fas fa-chevron-right"></i>Info PSB</a></li>',
      '      </ul>',
      '    </div>',
      '',
      '    <!-- Hubungi Kami -->',
      '    <div class="footer-col">',
      '      <h4>Hubungi Kami</h4>',
      '      <div class="footer-contact-item">',
      '        <i class="fas fa-map-marker-alt"></i>',
      '        <span>Gunungmanik, Kec. Tanjungsari, Kabupaten Sumedang, Jawa Barat 45362</span>',
      '      </div>',
      '      <div class="footer-contact-item">',
      '        <i class="fas fa-phone-alt"></i>',
      '        <span>+6283178710191</span>',
      '      </div>',
      '      <div class="footer-contact-item">',
      '        <i class="fas fa-envelope"></i>',
      '        <span>info@smaplusalmunawwarah.sch.id</span>',
      '      </div>',
      '    </div>',
      '',
      '    <!-- Media Sosial -->',
      '    <div class="footer-col">',
      '      <h4>Media Sosial</h4>',
      '      <div class="footer-social">',
      '        <a href="https://www.instagram.com/sma_plus_almunawwarah" target="_blank" rel="noopener" aria-label="Instagram"><i class="fab fa-instagram"></i></a>',
      '        <a href="https://www.youtube.com/@El-MunaTV" target="_blank" rel="noopener" aria-label="YouTube"><i class="fab fa-youtube"></i></a>',
      '        <a href="https://www.tiktok.com/@elmuna.tv" target="_blank" rel="noopener" aria-label="TikTok"><i class="fab fa-tiktok"></i></a>',
      '      </div>',
      '    </div>',
      '',
      '  </div>',
      '',
      '  <div class="footer-bottom">',
      '    <p>&copy; 2026 SMA Plus Almunawwarah. Seluruh hak cipta dilindungi.</p>',
      '    <p><a href="https://hulya-app.netlify.app" target="_blank" rel="noopener">In collaboration with Hulya Apps</a></p>',
      '  </div>',
      '</footer>',
      '',
      '<a href="https://wa.me/+6283178710191" target="_blank" class="whatsapp-float" aria-label="WhatsApp">',
      '  <i class="fab fa-whatsapp"></i>',
      '</a>',
      '',
      '<button class="back-to-top" aria-label="Kembali ke atas">',
      '  <i class="fas fa-arrow-up"></i>',
      '</button>'
    ].join('\n');

    var wrapper = document.querySelector('.page-wrapper');
    if (wrapper) {
      wrapper.insertAdjacentHTML('beforeend', footerHTML);
    } else {
      document.body.insertAdjacentHTML('beforeend', footerHTML);
    }
  }

  /* ─── e) JavaScript logic (back-to-top) ─── */
  function initBackToTop() {
    var btn = document.querySelector('.back-to-top');
    if (!btn) return;

    window.addEventListener('scroll', function () {
      if (window.scrollY > 300) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    }, { passive: true });

    btn.addEventListener('click', function () {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  /* ─── DOM-ready bootstrap ─── */
  function boot() {
    injectFooter();
    initBackToTop();
    window.__smaFooterLoaded = true;
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
