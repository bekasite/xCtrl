let commands = [];
const API_BASE = window.location.origin;

let tg = null;
try {
  if (window.Telegram && window.Telegram.WebApp) {
    tg = window.Telegram.WebApp;
    tg.ready();
    tg.expand();
  }
} catch (e) {
  // not in Telegram
}

function switchTab(name) {
  document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  document.getElementById('tab-' + name).classList.add('active');
  document.querySelector(`.nav-item[data-tab="${name}"]`).classList.add('active');
}

function filterCommands() {
  const q = document.getElementById('command-search').value.toLowerCase();
  document.querySelectorAll('.command-item').forEach(el => {
    const text = el.textContent.toLowerCase();
    el.classList.toggle('hidden', q && !text.includes(q));
  });
}

async function loadCommands() {
  try {
    const res = await fetch(API_BASE + '/api/commands');
    const data = await res.json();
    commands = data.commands || [];
    document.getElementById('command-count').textContent = commands.length + '+';
    renderCommands(commands);
  } catch (e) {
    document.getElementById('commands-list').innerHTML =
      '<p style="color:var(--text-secondary);font-size:13px;text-align:center;padding:20px;">Failed to load commands</p>';
  }
}

function renderCommands(cmds) {
  const list = document.getElementById('commands-list');
  list.innerHTML = cmds.map(c =>
    `<div class="command-item">
      <span class="command-name">${c.name}</span>
      <span class="command-desc">${c.desc}</span>
    </div>`
  ).join('');
}

async function loadDownloadUrl() {
  try {
    const res = await fetch(API_BASE + '/api/config');
    const data = await res.json();
    const btn = document.getElementById('download-btn');
    if (data.apkUrl) {
      btn.href = data.apkUrl;
    } else {
      btn.textContent = 'APK not available';
      btn.style.pointerEvents = 'none';
      btn.style.opacity = '0.5';
    }
  } catch (e) {
    // use default
  }
}

async function linkDevice() {
  const code = document.getElementById('link-code').value.trim();
  const status = document.getElementById('link-status');
  const btn = document.getElementById('link-btn');

  if (!code) {
    status.textContent = 'Enter a linking code';
    status.className = 'error';
    return;
  }

  btn.disabled = true;
  status.textContent = 'Linking...';
  status.className = '';

  try {
    const res = await fetch(API_BASE + '/api/link', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code }),
    });
    const data = await res.json();
    if (data.ok) {
      status.textContent = 'Device linked as ' + data.linkedInfo;
      status.className = 'success';
      document.getElementById('link-code').value = '';
    } else {
      status.textContent = data.error || 'Link failed';
      status.className = 'error';
    }
  } catch (e) {
    status.textContent = 'Connection error';
    status.className = 'error';
  } finally {
    btn.disabled = false;
  }
}

document.addEventListener('DOMContentLoaded', () => {
  loadCommands();
  loadDownloadUrl();
});
