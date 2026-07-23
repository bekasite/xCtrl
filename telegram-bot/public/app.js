let commands = [];
const API_BASE = window.location.origin;

let tg = null;
try {
  if (window.Telegram && window.Telegram.WebApp) {
    tg = window.Telegram.WebApp;
    tg.ready();
    tg.expand();
  }
} catch (e) {}

function switchTab(name) {
  document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  const tab = document.getElementById('tab-' + name);
  if (tab) tab.classList.add('active');
  const nav = document.querySelector(`.nav-item[data-tab="${name}"]`);
  if (nav) nav.classList.add('active');
}

function filterCommands() {
  const q = document.getElementById('command-search').value.toLowerCase();
  document.querySelectorAll('.command-item').forEach(el => {
    el.classList.toggle('hidden', q && !el.textContent.toLowerCase().includes(q));
  });
}

async function loadCommands() {
  try {
    const res = await fetch(API_BASE + '/api/commands');
    const data = await res.json();
    commands = data.commands || [];
    const list = document.getElementById('commands-list');
    list.innerHTML = commands.map(c =>
      `<div class="command-item">
        <div class="command-name">${c.name}</div>
        <div class="command-desc">${c.desc}</div>
      </div>`
    ).join('');
  } catch (e) {
    document.getElementById('commands-list').innerHTML =
      '<p style="color:var(--text-secondary);font-size:13px;text-align:center;padding:20px;">Failed to load commands</p>';
  }
}

async function loadDownloadUrl() {
  try {
    const res = await fetch(API_BASE + '/api/config');
    const data = await res.json();
    const btn = document.getElementById('download-btn');
    if (data.apkUrl) {
      btn.href = data.apkUrl;
    } else {
      btn.textContent = 'APK not yet available';
      btn.style.pointerEvents = 'none';
      btn.style.opacity = '0.5';
    }
  } catch (e) {}
}

function showLinkResult(text, type) {
  const status = document.getElementById('link-status');
  status.textContent = text;
  status.className = type || '';
}

async function submitCode(code) {
  const btn = document.getElementById('link-btn');
  btn.disabled = true;
  showLinkResult('Linking...', '');

  try {
    const res = await fetch(API_BASE + '/api/link', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code }),
    });
    const data = await res.json();
    if (data.ok) {
      showLinkResult('Linked as ' + data.linkedInfo, 'success');
      document.getElementById('link-code').value = '';
      return true;
    } else {
      showLinkResult(data.error || 'Link failed', 'error');
      return false;
    }
  } catch (e) {
    showLinkResult('Connection error', 'error');
    return false;
  } finally {
    btn.disabled = false;
  }
}

async function linkDevice() {
  const code = document.getElementById('link-code').value.trim();
  if (!code) {
    showLinkResult('Enter a linking code', 'error');
    return;
  }
  await submitCode(code);
}

async function handleAutoLink() {
  const params = new URLSearchParams(window.location.search);
  const code = params.get('code');
  if (!code) return;

  const status = document.getElementById('link-status');
  status.textContent = 'Linking your device...';
  status.className = '';
  switchTab('link');

  const ok = await submitCode(code);
  if (ok) {
    setTimeout(() => switchTab('home'), 1500);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  loadCommands();
  loadDownloadUrl();
  handleAutoLink();
});
