const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_PATH = process.env.DATA_PATH || path.join(__dirname, 'data', 'bot.json');

let data;

function read() {
  try {
    return JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
  } catch {
    return { linkCodes: {}, linkedChats: {} };
  }
}

function write() {
  const dir = path.dirname(DATA_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(DATA_PATH, JSON.stringify(data, null, 2));
}

function init() {
  data = read();
  setInterval(cleanupExpired, 60000);
}

function cleanupExpired() {
  const now = Math.floor(Date.now() / 1000);
  let changed = false;
  for (const [code, entry] of Object.entries(data.linkCodes)) {
    if (!entry.used && entry.expires_at < now) {
      delete data.linkCodes[code];
      changed = true;
    }
  }
  if (changed) write();
}

function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}

function createLinkCode(chatId, username, firstName) {
  const code = generateCode();
  const now = Math.floor(Date.now() / 1000);
  data.linkCodes[code] = {
    chatId,
    chatUsername: username || '',
    chatFirstName: firstName || '',
    createdAt: now,
    expiresAt: now + 300,
    used: false,
  };
  write();
  return code;
}

function consumeLinkCode(code) {
  const entry = data.linkCodes[code];
  if (!entry || entry.used) return null;

  const now = Math.floor(Date.now() / 1000);
  if (entry.expires_at < now) return null;

  entry.used = true;
  const displayName = entry.chatFirstName || entry.chatUsername || `Chat ${entry.chatId}`;
  data.linkedChats[entry.chatId] = {
    linkedInfo: displayName,
    linkedAt: now,
  };
  write();
  return { chatId: entry.chatId, linkedInfo: displayName };
}

function isChatLinked(chatId) {
  return !!data.linkedChats[chatId];
}

module.exports = { init, createLinkCode, consumeLinkCode, isChatLinked };
