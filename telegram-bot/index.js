require('dotenv').config();

const express = require('express');
const db = require('./db');

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const WEBHOOK_URL = process.env.WEBHOOK_URL;
const PORT = process.env.PORT || 3000;
const API_BASE = `https://api.telegram.org/bot${BOT_TOKEN}`;

if (!BOT_TOKEN) {
  console.error('TELEGRAM_BOT_TOKEN is required');
  process.exit(1);
}

db.init();

const app = express();
app.use(express.json());

async function callTelegram(method, payload) {
  const url = `${API_BASE}/${method}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return response.json();
}

async function sendMessage(chatId, text) {
  return callTelegram('sendMessage', { chat_id: chatId, text });
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
    'To link your device:',
    '1. Install xCtl on your Android device',
    `2. Enter this code in xCtl Settings > Telegram: ${code}`,
    '3. The code expires in 5 minutes',
    '',
    'Once linked, media captured via CAMERA, AUDIO, VIDEO, SCREENSHOT commands will be auto-uploaded here.',
    '',
    'More info: x-prime.dev',
  ].join('\n');

  return sendMessage(chatId, message);
}

function handleLink(chatId, username, firstName) {
  const code = db.createLinkCode(chatId, username, firstName);
  return sendMessage(chatId, `Your linking code: ${code}\n\nEnter this in xCtl Settings > Telegram. Expires in 5 minutes.`);
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
