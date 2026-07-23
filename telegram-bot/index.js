require('dotenv').config();

const express = require('express');
const path = require('path');
const db = require('./db');

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const WEBHOOK_URL = process.env.WEBHOOK_URL;
const APK_DOWNLOAD_URL = process.env.APK_DOWNLOAD_URL;
const PORT = process.env.PORT || 3000;
const API_BASE = `https://api.telegram.org/bot${BOT_TOKEN}`;

if (!BOT_TOKEN) {
  console.error('TELEGRAM_BOT_TOKEN is required');
  process.exit(1);
}

db.init();

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const MINI_APP_URL = WEBHOOK_URL
  ? WEBHOOK_URL.replace(/\/+$/, '').replace(/\/webhook\/?$/, '')
  : `http://localhost:${PORT}`;

const COMMANDS = [
  { name: 'LOCK', desc: 'Lock device screen' },
  { name: 'LOCATION', desc: 'Get GPS location' },
  { name: 'STATUS', desc: 'Device status info' },
  { name: 'SMS', desc: 'Send SMS: xctl SMS +1234567890 message' },
  { name: 'CALL', desc: 'Make call: xctl CALL +1234567890' },
  { name: 'WIPE', desc: 'Factory reset (needs Device Admin)' },
  { name: 'PASSWORD', desc: 'Set lock password: xctl PASSWORD 1234' },
  { name: 'CLEARPASSWORD', desc: 'Remove device password' },
  { name: 'MESSAGE', desc: 'Show notification: xctl MESSAGE text' },
  { name: 'WIFI', desc: 'WiFi on/off/toggle' },
  { name: 'BLUETOOTH', desc: 'Bluetooth on/off/toggle' },
  { name: 'DATA', desc: 'Mobile data on/off/toggle' },
  { name: 'HOTSPOT', desc: 'Hotspot on/off/toggle' },
  { name: 'BRIGHTNESS', desc: 'Set brightness 0-255' },
  { name: 'TIMEOUT', desc: 'Set screen timeout seconds' },
  { name: 'SCREEN', desc: 'Screen on/off' },
  { name: 'VOLUME', desc: 'Set volume 0-15' },
  { name: 'MUTE', desc: 'Silence device' },
  { name: 'AIRPLANE', desc: 'Airplane mode on/off/toggle' },
  { name: 'REBOOT', desc: 'Reboot device' },
  { name: 'SHUTDOWN', desc: 'Shutdown device' },
  { name: 'CAMERA', desc: 'Take photo front/back' },
  { name: 'AUDIO', desc: 'Record audio: xctl AUDIO seconds' },
  { name: 'VIDEO', desc: 'Record video: xctl VIDEO seconds' },
  { name: 'CONTACTS', desc: 'List contacts' },
  { name: 'CALLS', desc: 'Recent call log' },
  { name: 'SMSREAD', desc: 'Read SMS: xctl SMSREAD count' },
  { name: 'SMSDELETE', desc: 'Delete SMS by index' },
  { name: 'FILES', desc: 'List files: xctl FILES /path' },
  { name: 'READ', desc: 'Read file: xctl READ /path/to/file' },
  { name: 'DELETE', desc: 'Delete file: xctl DELETE /path' },
  { name: 'LISTAPPS', desc: 'List installed apps' },
  { name: 'LAUNCH', desc: 'Launch app: xctl LAUNCH pkg.name' },
  { name: 'STOP', desc: 'Stop app: xctl STOP pkg.name' },
  { name: 'UNINSTALL', desc: 'Uninstall app: xctl UNINSTALL pkg' },
  { name: 'INSTALL', desc: 'Install from URL: xctl INSTALL url' },
  { name: 'SCREENSHOT', desc: 'Take screenshot' },
  { name: 'CLIPBOARD', desc: 'Clipboard get/set' },
  { name: 'NOTIFICATION', desc: 'Send notification' },
  { name: 'FLASH', desc: 'Flashlight on/off/toggle' },
  { name: 'SHELL', desc: 'Execute shell command' },
  { name: 'RING', desc: 'Ring mode normal/silent/vibrate' },
  { name: 'STORAGE', desc: 'Storage usage info' },
  { name: 'IP', desc: 'Network IP and WiFi info' },
  { name: 'SIM', desc: 'SIM and network operator info' },
  { name: 'BATTERY', desc: 'Battery health and details' },
  { name: 'DND', desc: 'Do Not Disturb on/off' },
  { name: 'RUNNING', desc: 'Running processes list' },
];

async function callTelegram(method, payload) {
  const url = `${API_BASE}/${method}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return response.json();
}

async function sendMessage(chatId, text, extra) {
  return callTelegram('sendMessage', { chat_id: chatId, text, ...extra });
}

async function setWebhook() {
  if (!WEBHOOK_URL) {
    console.log('No WEBHOOK_URL set, skipping webhook registration');
    return;
  }
  const webhookUrl = `${WEBHOOK_URL.replace(/\/+$/, '')}/webhook`;
  const result = await callTelegram('setWebhook', { url: webhookUrl });
  console.log('Webhook registration:', result.ok ? 'OK' : 'FAILED', result.description || '');
}

function handleStart(chatId, username, firstName) {
  const code = db.createLinkCode(chatId, username, firstName);

  const message = [
    'Welcome to xCtl Bot!',
    '',
    'xCtl lets you remotely control your Android device by sending SMS commands from authorized phone numbers -- no internet required.',
    '',
    'Commands include: LOCATION, CAMERA, LOCK, WIPE, SMS, CALL, WiFi, clipboard, files, and 50+ more.',
    '',
    `Your linking code: ${code}`,
    'Enter this in the Mini App or in xCtl Settings > Telegram. Expires in 5 minutes.',
    '',
    'More info: x-prime.dev',
  ].join('\n');

  return sendMessage(chatId, message, {
    reply_markup: {
      inline_keyboard: [[
        {
          text: 'Open xCtl Mini App',
          web_app: { url: MINI_APP_URL },
        },
      ]],
    },
  });
}

function handleLink(chatId, username, firstName) {
  const code = db.createLinkCode(chatId, username, firstName);
  return sendMessage(chatId, `Your linking code: ${code}\n\nEnter this in the Mini App or in xCtl Settings > Telegram. Expires in 5 minutes.`, {
    reply_markup: {
      inline_keyboard: [[
        {
          text: 'Open xCtl Mini App',
          web_app: { url: MINI_APP_URL },
        },
      ]],
    },
  });
}

function handleHelp(chatId) {
  return sendMessage(chatId, [
    'xCtl Bot commands:',
    '/start - Welcome message and linking code',
    '/link - Get a new linking code',
    '/help - Show this message',
    '',
    'Visit x-prime.dev for more information.',
  ].join('\n'));
}

async function handleUpdate(update) {
  const msg = update.message;
  if (!msg || !msg.text) return;

  const chatId = msg.chat.id;
  const username = msg.chat.username || '';
  const firstName = msg.chat.first_name || '';
  const text = msg.text.trim().toLowerCase();

  if (text === '/start') {
    await handleStart(chatId, username, firstName);
  } else if (text === '/link') {
    await handleLink(chatId, username, firstName);
  } else if (text === '/help') {
    await handleHelp(chatId);
  }
}

app.post('/webhook', async (req, res) => {
  res.sendStatus(200);
  try {
    await handleUpdate(req.body);
  } catch (err) {
    console.error('Error handling update:', err);
  }
});

app.get('/api/commands', (req, res) => {
  res.json({ commands: COMMANDS });
});

app.get('/api/config', (req, res) => {
  res.json({
    version: '1.0.0',
    packageName: 'dev.xprime.xctl',
    domain: 'x-prime.dev',
    apkUrl: APK_DOWNLOAD_URL || null,
  });
});

app.post('/api/link', async (req, res) => {
  try {
    const { code } = req.body;
    if (!code || typeof code !== 'string') {
      return res.json({ ok: false, error: 'Missing or invalid code' });
    }

    const result = db.consumeLinkCode(code.trim().toUpperCase());
    if (!result) {
      return res.json({ ok: false, error: 'Invalid or expired code' });
    }

    try {
      await sendMessage(result.chatId, 'Your device is now linked to xCtl Bot!');
    } catch (e) {
      console.error('Failed to send confirmation:', e.message);
    }

    res.json({
      ok: true,
      chatId: result.chatId,
      linkedInfo: result.linkedInfo,
    });
  } catch (err) {
    console.error('Link error:', err);
    res.json({ ok: false, error: 'Server error' });
  }
});

app.get('/api/health', (req, res) => {
  res.json({ ok: true, uptime: process.uptime() });
});

app.listen(PORT, () => {
  console.log(`xCtl bot server listening on port ${PORT}`);
  setWebhook();
});
