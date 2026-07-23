const Database = require('better-sqlite3');
const path = require('path');

const DB_PATH = process.env.DATABASE_URL || path.join(__dirname, 'data', 'bot.db');

let db;

function init() {
  const fs = require('fs');
  const dir = path.dirname(DB_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  db = new Database(DB_PATH);
  db.pragma('journal_mode = WAL');

  db.exec(`
    CREATE TABLE IF NOT EXISTS link_codes (
      code TEXT PRIMARY KEY,
      chat_id INTEGER NOT NULL,
      chat_username TEXT DEFAULT '',
      chat_first_name TEXT DEFAULT '',
      created_at INTEGER NOT NULL,
      expires_at INTEGER NOT NULL,
      used INTEGER NOT NULL DEFAULT 0
    )
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS linked_chats (
      chat_id INTEGER PRIMARY KEY,
      linked_info TEXT DEFAULT '',
      linked_at INTEGER NOT NULL
    )
  `);

  setInterval(cleanupExpired, 60000);
}

function cleanupExpired() {
  if (!db) return;
  const now = Math.floor(Date.now() / 1000);
  db.prepare('DELETE FROM link_codes WHERE expires_at < ? AND used = 0').run(now);
}

function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  const bytes = require('crypto').randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}

function createLinkCode(chatId, username, firstName) {
  const code = generateCode();
  const now = Math.floor(Date.now() / 1000);
  const expiresAt = now + 300;
  db.prepare(`
    INSERT INTO link_codes (code, chat_id, chat_username, chat_first_name, created_at, expires_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(code, chatId, username || '', firstName || '', now, expiresAt);
  return code;
}

function consumeLinkCode(code) {
  const row = db.prepare('SELECT * FROM link_codes WHERE code = ? AND used = 0').get(code);
  if (!row) return null;
  const now = Math.floor(Date.now() / 1000);
  if (row.expires_at < now) return null;

  db.prepare('UPDATE link_codes SET used = 1 WHERE code = ?').run(code);

  const displayName = row.chat_first_name || row.chat_username || `Chat ${row.chat_id}`;

  db.prepare(`
    INSERT INTO linked_chats (chat_id, linked_info, linked_at)
    VALUES (?, ?, ?)
    ON CONFLICT(chat_id) DO UPDATE SET linked_info = excluded.linked_info, linked_at = excluded.linked_at
  `).run(row.chat_id, displayName, now);

  return { chatId: row.chat_id, linkedInfo: displayName };
}

function isChatLinked(chatId) {
  const row = db.prepare('SELECT * FROM linked_chats WHERE chat_id = ?').get(chatId);
  return !!row;
}

module.exports = { init, createLinkCode, consumeLinkCode, isChatLinked };
