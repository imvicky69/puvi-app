/**
 * Puvi — Public Sanctuary & App Downloader
 * Handles live GitHub Releases API fetch, interactive love showers, and melody playback.
 */

const GITHUB_REPO = 'imvicky69/puvi-app';
const GITHUB_API_URL = `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`;
const FALLBACK_VERSION = '1.0.0';

// DOM Elements
const versionBanner = document.getElementById('version-banner');
const versionText = document.getElementById('version-text');
const primaryBtn = document.getElementById('primary-download-btn');
const primaryBtnTitle = document.getElementById('primary-btn-title');
const primaryBtnSub = document.getElementById('primary-btn-sub');

const toggleVariantsBtn = document.getElementById('toggle-variants-btn');
const variantsList = document.getElementById('variants-list');
const chevronIcon = toggleVariantsBtn.querySelector('.chevron-icon');

const linkUniversal = document.getElementById('link-universal');
const linkArm32 = document.getElementById('link-arm32');
const linkX86 = document.getElementById('link-x86');
const sizeUniversal = document.getElementById('size-universal');
const sizeArm32 = document.getElementById('size-arm32');
const sizeX86 = document.getElementById('size-x86');
const releaseNotesContent = document.getElementById('release-notes-content');

const musicBtn = document.getElementById('music-btn');
const themeAudio = document.getElementById('theme-audio');

const loveHoldBtn = document.getElementById('love-hold-btn');
const holdRing = document.getElementById('hold-ring');
const holdBtnText = document.getElementById('hold-btn-text');
const explosionContainer = document.getElementById('love-explosion-container');
const heartsBg = document.getElementById('hearts-bg');
const qrCodeContainer = document.getElementById('qr-code');

// 1. Fetch Latest Release from GitHub API
async function fetchLatestRelease() {
  try {
    const res = await fetch(GITHUB_API_URL);
    if (!res.ok) {
      throw new Error(`GitHub API returned status ${res.status}`);
    }
    const data = await res.json();
    populateReleaseData(data);
  } catch (err) {
    console.warn('[Puvi] Using fallback release metadata:', err.message);
    populateFallbackReleaseData();
  }
}

function formatBytes(bytes) {
  if (!bytes || bytes === 0) return '';
  const mb = bytes / (1024 * 1024);
  return `~${mb.toFixed(1)} MB`;
}

function populateReleaseData(data) {
  const version = data.tag_name || `v${FALLBACK_VERSION}`;
  const pubDate = data.published_at
    ? new Date(data.published_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    : 'Latest Release';

  versionText.textContent = `${version} • Released ${pubDate}`;

  const assets = data.assets || [];
  let arm64Asset = null;
  let universalAsset = null;
  let arm32Asset = null;
  let x86Asset = null;

  for (const asset of assets) {
    const name = asset.name.toLowerCase();
    if (name.includes('arm64-v8a')) arm64Asset = asset;
    else if (name.includes('universal') || name === 'app-release.apk') universalAsset = asset;
    else if (name.includes('armeabi-v7a')) arm32Asset = asset;
    else if (name.includes('x86_64')) x86Asset = asset;
  }

  // Fallback to first available apk if specific not found
  const primaryAsset = arm64Asset || universalAsset || assets[0];

  if (primaryAsset) {
    primaryBtn.href = primaryAsset.browser_download_url;
    primaryBtnTitle.textContent = `Download Puvi for Android (${version})`;
    const sizeStr = formatBytes(primaryAsset.size);
    primaryBtnSub.textContent = `ARM64-v8a • ${sizeStr || '~22.7 MB'} • Recommended`;
    renderQrCode(primaryAsset.browser_download_url);
  }

  if (universalAsset) {
    linkUniversal.href = universalAsset.browser_download_url;
    sizeUniversal.textContent = formatBytes(universalAsset.size) || '~59.8 MB';
  } else {
    linkUniversal.href = `https://github.com/${GITHUB_REPO}/releases/latest`;
  }

  if (arm32Asset) {
    linkArm32.href = arm32Asset.browser_download_url;
    sizeArm32.textContent = formatBytes(arm32Asset.size) || '~20.3 MB';
  } else {
    linkArm32.href = `https://github.com/${GITHUB_REPO}/releases/latest`;
  }

  if (x86Asset) {
    linkX86.href = x86Asset.browser_download_url;
    sizeX86.textContent = formatBytes(x86Asset.size) || '~24.2 MB';
  } else {
    linkX86.href = `https://github.com/${GITHUB_REPO}/releases/latest`;
  }

  // Release Notes
  if (data.body && data.body.trim().length > 0) {
    formatReleaseNotes(data.body);
  }
}

function populateFallbackReleaseData() {
  const version = `v${FALLBACK_VERSION}`;
  versionText.textContent = `${version} • Latest Edition`;

  const baseUrl = `https://github.com/${GITHUB_REPO}/releases/download/${version}`;
  const directArm64 = `${baseUrl}/puvi-${version}-arm64-v8a.apk`;

  primaryBtn.href = directArm64;
  primaryBtnTitle.textContent = `Download Puvi for Android (${version})`;
  primaryBtnSub.textContent = `ARM64-v8a • ~22.7 MB • Recommended`;

  linkUniversal.href = `${baseUrl}/puvi-${version}-universal.apk`;
  linkArm32.href = `${baseUrl}/puvi-${version}-armeabi-v7a.apk`;
  linkX86.href = `${baseUrl}/puvi-${version}-x86_64.apk`;

  renderQrCode(directArm64);
}

function formatReleaseNotes(markdown) {
  const lines = markdown.split('\n');
  const items = [];

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      const text = trimmed.substring(2).trim();
      items.push(`<div class="notes-item">💕 ${escapeHtml(text)}</div>`);
    }
  }

  if (items.length > 0) {
    releaseNotesContent.innerHTML = items.join('');
  }
}

function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
}

// 2. Toggle Variants Dropdown
toggleVariantsBtn.addEventListener('click', () => {
  const isHidden = variantsList.classList.contains('hidden');
  if (isHidden) {
    variantsList.classList.remove('hidden');
    chevronIcon.classList.add('rotated');
  } else {
    variantsList.classList.add('hidden');
    chevronIcon.classList.remove('rotated');
  }
});

// 3. Romantic Melody Audio Toggle
let isMusicPlaying = false;

musicBtn.addEventListener('click', toggleMusic);

function toggleMusic() {
  if (isMusicPlaying) {
    themeAudio.pause();
    isMusicPlaying = false;
    musicBtn.classList.remove('playing');
    musicBtn.querySelector('.music-label').textContent = 'Play Song';
  } else {
    themeAudio.play().then(() => {
      isMusicPlaying = true;
      musicBtn.classList.add('playing');
      musicBtn.querySelector('.music-label').textContent = 'Our Song 💕';
    }).catch(err => {
      console.warn('Playback error or blocked by autoplay policy:', err);
    });
  }
}

// 4. Interactive Hold-to-Love Simulation
let holdTimer = null;
let holdProgressInterval = null;
let holdStart = 0;
const HOLD_DURATION = 1200; // ms

function startHold(e) {
  e.preventDefault();
  holdStart = Date.now();
  holdBtnText.textContent = 'Charging Love...';

  if (navigator.vibrate) navigator.vibrate(25);

  holdProgressInterval = setInterval(() => {
    const elapsed = Date.now() - holdStart;
    const pct = Math.min(100, (elapsed / HOLD_DURATION) * 100);
    holdRing.style.width = `${pct}%`;

    if (elapsed >= HOLD_DURATION) {
      clearInterval(holdProgressInterval);
      completeHold();
    }
  }, 20);
}

function cancelHold() {
  if (holdProgressInterval) clearInterval(holdProgressInterval);
  holdRing.style.width = '0%';
  holdBtnText.textContent = 'Hold to Shower +1,000 ✨';
}

function completeHold() {
  holdRing.style.width = '100%';
  holdBtnText.textContent = '💖 Showered!';

  if (navigator.vibrate) navigator.vibrate([60, 40, 90]);

  // Play music if not already playing
  if (!isMusicPlaying) {
    toggleMusic();
  }

  triggerExplosion();

  setTimeout(() => {
    holdRing.style.width = '0%';
    holdBtnText.textContent = 'Hold to Shower +1,000 ✨';
  }, 1600);
}

// Attach Touch & Mouse Events
loveHoldBtn.addEventListener('mousedown', startHold);
window.addEventListener('mouseup', cancelHold);
loveHoldBtn.addEventListener('touchstart', startHold, { passive: false });
window.addEventListener('touchend', cancelHold);
window.addEventListener('touchcancel', cancelHold);

function triggerExplosion() {
  explosionContainer.innerHTML = '';
  const colors = ['#702D40', '#D9A6A1', '#E88B97', '#DFB15B', '#C45A72'];
  const symbols = ['💖', '💕', '❤️', '✨', '🌸', '💫'];

  for (let i = 0; i < 28; i++) {
    const el = document.createElement('span');
    el.className = 'particle-heart';
    el.textContent = symbols[i % symbols.length];

    const angle = (i * (2 * Math.PI / 28)) + (Math.random() * 0.4 - 0.2);
    const dist = 80 + Math.random() * 120;
    const dx = Math.cos(angle) * dist;
    const dy = Math.sin(angle) * dist - 50;
    const rot = `${(Math.random() * 360 - 180)}deg`;

    el.style.setProperty('--dx', `${dx}px`);
    el.style.setProperty('--dy', `${dy}px`);
    el.style.setProperty('--rot', rot);
    el.style.left = '50%';
    el.style.top = '50%';

    explosionContainer.appendChild(el);
  }

  // Center Pop Banner
  const banner = document.createElement('div');
  banner.className = 'mega-burst-banner';
  banner.innerHTML = '✨ +1,000 LOVE SHOWER 💕';
  explosionContainer.appendChild(banner);

  setTimeout(() => {
    explosionContainer.innerHTML = '';
  }, 2200);
}

// 5. Ambient Floating Hearts Generator
function generateAmbientHearts() {
  const symbols = ['❤️', '💕', '💖', '🌸', '✨'];
  for (let i = 0; i < 15; i++) {
    const heart = document.createElement('div');
    heart.className = 'floating-bg-heart';
    heart.textContent = symbols[i % symbols.length];
    heart.style.left = `${Math.random() * 95}vw`;
    heart.style.fontSize = `${16 + Math.random() * 20}px`;
    heart.style.animationDuration = `${14 + Math.random() * 16}s`;
    heart.style.animationDelay = `${Math.random() * 10}s`;
    heartsBg.appendChild(heart);
  }
}

// 6. Inline SVG QR Code Generator
function renderQrCode(url) {
  // Use a reliable lightweight QR SVG service or fallback image
  const encoded = encodeURIComponent(url);
  qrCodeContainer.innerHTML = `<img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encoded}&color=70-45-64" alt="Download QR Code" style="width:100%; height:100%; object-fit:contain; border-radius:4px;">`;
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  fetchLatestRelease();
  generateAmbientHearts();
});
