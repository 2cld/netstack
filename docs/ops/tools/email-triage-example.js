#!/usr/bin/env node
// email-triage.js — Generic email triage script (netstack pattern)
//
// Classifies unread email by sender/subject rules, applies labels, archives noise.
// Designed for any Google Workspace or personal Gmail account.
//
// Pattern: https://netstack.org/docs/ops/tools/email-triage-automation-pattern/
//
// Setup:
//   1. Create OAuth2 credentials with gmail.modify scope
//   2. Create labels in Gmail: PREFIX/action, PREFIX/dev, PREFIX/financial,
//      PREFIX/notification, PREFIX/noise, PREFIX/capture
//   3. Configure RULES below for your projects/contacts
//   4. Run: node email-triage.js --apply
//
// Usage:
//   node email-triage.js              → preview (show classifications)
//   node email-triage.js --apply      → classify + label + archive
//   node email-triage.js --status     → show label counts

// --- CONFIGURATION ---
// Modify these for your setup:

const LABEL_PREFIX = 'wip';  // Your label namespace (wip/, ops/, admin/)

// Routing rules — first match wins
// Derive these from your contract-map or project contacts
const RULES = [
  // Dev notifications (skip inbox — informational)
  { match: { from: '@github.com' }, label: `${LABEL_PREFIX}/dev`, action: 'skip-inbox' },
  { match: { from: 'notifications@github.com' }, label: `${LABEL_PREFIX}/dev`, action: 'skip-inbox' },

  // Calendar responses (archive — no action needed)
  { match: { from: 'calendar-notification@google.com' }, label: `${LABEL_PREFIX}/notification`, action: 'archive' },
  { match: { subject: 'accepted:' }, label: `${LABEL_PREFIX}/notification`, action: 'archive' },
  { match: { subject: 'declined:' }, label: `${LABEL_PREFIX}/notification`, action: 'archive' },

  // Project contacts (keep in inbox — needs action)
  // Add your own contract contacts here:
  // { match: { from: '@client-domain.com' }, label: `${LABEL_PREFIX}/action`, action: 'inbox', project: 'project-code' },

  // Financial (keep in inbox — track)
  { match: { subject: 'invoice' }, label: `${LABEL_PREFIX}/financial`, action: 'inbox' },
  { match: { subject: 'payment' }, label: `${LABEL_PREFIX}/financial`, action: 'inbox' },

  // Known noise (archive immediately)
  { match: { from: 'noreply@' }, label: `${LABEL_PREFIX}/noise`, action: 'archive' },
  { match: { from: 'no-reply@' }, label: `${LABEL_PREFIX}/noise`, action: 'archive' },
  { match: { from: 'marketing@' }, label: `${LABEL_PREFIX}/noise`, action: 'archive' },
  { match: { from: 'newsletter@' }, label: `${LABEL_PREFIX}/noise`, action: 'archive' },
];

// Default: anything unmatched goes to capture (human review)
const DEFAULT_CLASSIFICATION = { label: `${LABEL_PREFIX}/capture`, action: 'inbox', project: null };

// --- AUTH SETUP ---
// Replace with your OAuth2 setup:
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Load your OAuth2 credentials and tokens
// Adjust paths to match your project structure
const CREDENTIALS_PATH = process.env.GOOGLE_CREDENTIALS || './credentials.json';
const TOKEN_PATH = process.env.GOOGLE_TOKEN || './token.json';

let gmail;
try {
  const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_PATH));
  const tokens = JSON.parse(fs.readFileSync(TOKEN_PATH));
  const oauth2 = new google.auth.OAuth2(
    credentials.client_id || process.env.GOOGLE_CLIENT_ID,
    credentials.client_secret || process.env.GOOGLE_CLIENT_SECRET,
    credentials.redirect_uri || process.env.GOOGLE_REDIRECT_URI
  );
  oauth2.setCredentials(tokens);
  gmail = google.gmail({ version: 'v1', auth: oauth2 });
} catch (e) {
  console.error('Auth setup failed:', e.message);
  console.error('Set GOOGLE_CREDENTIALS and GOOGLE_TOKEN env vars, or place credentials.json + token.json in cwd.');
  process.exit(1);
}

// --- SCRIPT LOGIC (generic — don't modify below this line) ---

const APPLY = process.argv.includes('--apply');
const STATUS = process.argv.includes('--status');

let labelCache = null;
async function getLabelId(labelName) {
  if (!labelCache) {
    const res = await gmail.users.labels.list({ userId: 'me' });
    labelCache = {};
    for (const l of res.data.labels || []) { labelCache[l.name] = l.id; }
  }
  return labelCache[labelName] || null;
}

function classify(from, subject) {
  const f = (from || '').toLowerCase();
  const s = (subject || '').toLowerCase();
  for (const rule of RULES) {
    if (rule.match.from && f.includes(rule.match.from.toLowerCase())) return rule;
    if (rule.match.subject && s.includes(rule.match.subject.toLowerCase())) return rule;
  }
  return DEFAULT_CLASSIFICATION;
}

async function getHeaders(msgId) {
  const msg = await gmail.users.messages.get({ userId: 'me', id: msgId, format: 'metadata', metadataHeaders: ['From', 'Subject'] });
  const headers = msg.data.payload.headers || [];
  return {
    id: msgId,
    from: (headers.find(h => h.name === 'From') || {}).value || '',
    subject: (headers.find(h => h.name === 'Subject') || {}).value || '',
  };
}

async function showStatus() {
  console.log(`=== EMAIL STATUS (${LABEL_PREFIX}/) ===\n`);
  const labels = await gmail.users.labels.list({ userId: 'me' });
  const myLabels = (labels.data.labels || []).filter(l => l.name.startsWith(`${LABEL_PREFIX}/`));
  for (const label of myLabels) {
    const detail = await gmail.users.labels.get({ userId: 'me', id: label.id });
    const unread = detail.data.messagesUnread || 0;
    console.log(`  ${unread > 0 ? '📬' : '✅'} ${label.name}: ${unread} unread / ${detail.data.messagesTotal || 0} total`);
  }
  const inbox = await gmail.users.labels.get({ userId: 'me', id: 'INBOX' });
  console.log(`\n  📥 Inbox: ${inbox.data.messagesUnread || 0} unread / ${inbox.data.messagesTotal || 0} total`);
}

async function triage() {
  console.log(APPLY ? '=== EMAIL TRIAGE (APPLYING) ===' : '=== EMAIL TRIAGE (PREVIEW) ===');
  console.log('');

  // Build exclusion query (skip already-labeled messages)
  const excludeLabels = [`${LABEL_PREFIX}/action`, `${LABEL_PREFIX}/dev`, `${LABEL_PREFIX}/financial`, `${LABEL_PREFIX}/notification`, `${LABEL_PREFIX}/noise`, `${LABEL_PREFIX}/capture`];
  const excludeQuery = excludeLabels.map(l => `-label:${l}`).join(' ');
  const query = `is:unread in:inbox ${excludeQuery}`;

  const res = await gmail.users.messages.list({ userId: 'me', q: query, maxResults: 50 });
  const messages = res.data.messages || [];

  if (messages.length === 0) {
    console.log('No unclassified unread messages. Inbox is triaged.');
    return;
  }

  console.log(`Found ${messages.length} unclassified message(s)\n`);
  const buckets = {};

  for (const msg of messages) {
    const h = await getHeaders(msg.id);
    const result = classify(h.from, h.subject);
    const bucket = result.label;
    if (!buckets[bucket]) buckets[bucket] = [];
    buckets[bucket].push({ ...h, rule: result });

    const icon = bucket.includes('action') ? '🔴' : bucket.includes('capture') ? '❓' : bucket.includes('dev') ? '💻' : bucket.includes('financial') ? '💰' : bucket.includes('noise') ? '🗑️' : '📋';
    console.log(`  ${icon} ${bucket}${result.project ? ` [${result.project}]` : ''}`);
    console.log(`     From: ${h.from}`);
    console.log(`     Subj: ${h.subject}\n`);
  }

  console.log('--- SUMMARY ---');
  for (const [label, msgs] of Object.entries(buckets)) {
    console.log(`  ${label}: ${msgs.length}`);
  }

  if (!APPLY) { console.log('\n(Preview only. Run with --apply to label + archive.)'); return; }

  console.log('\nApplying...');
  for (const [label, msgs] of Object.entries(buckets)) {
    const labelId = await getLabelId(label);
    if (!labelId) { console.log(`  ⚠️  Label "${label}" not found — create it in Gmail first`); continue; }
    for (const msg of msgs) {
      const add = [labelId];
      const remove = (msg.rule.action === 'archive' || msg.rule.action === 'skip-inbox') ? ['INBOX'] : [];
      await gmail.users.messages.modify({ userId: 'me', id: msg.id, requestBody: { addLabelIds: add, removeLabelIds: remove } });
    }
    const archived = msgs.filter(m => m.rule.action === 'archive' || m.rule.action === 'skip-inbox').length;
    console.log(`  ✅ ${label}: ${msgs.length} labeled${archived > 0 ? `, ${archived} archived` : ''}`);
  }
  console.log('\nDone.');
}

if (STATUS) { showStatus().catch(e => console.error(e.message)); }
else { triage().catch(e => console.error(e.message)); }
