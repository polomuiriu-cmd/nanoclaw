#!/usr/bin/env node
/**
 * Home Portal CLI — Firestore interface for household data
 *
 * Usage:
 *   node home-portal.cjs list   tasks|events|notes
 *   node home-portal.cjs create task   '<json>'
 *   node home-portal.cjs create event  '<json>'
 *   node home-portal.cjs create note   '<json>'
 *
 * Credentials: GOOGLE_APPLICATION_CREDENTIALS env var (set by container runner)
 * Project: temple-park-ave-bf1a3
 */

'use strict';

const admin = require('firebase-admin');

const PROJECT_ID = 'temple-park-ave-bf1a3';
const HOUSEHOLD = 'home';

// ── Initialise Firebase ───────────────────────────────────────────────────────

let app;
try {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credPath) {
    console.error('GOOGLE_APPLICATION_CREDENTIALS is not set');
    process.exit(1);
  }
  const serviceAccount = require(credPath);
  app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: PROJECT_ID,
  });
} catch (err) {
  console.error('Failed to initialise Firebase:', err.message);
  process.exit(1);
}

const db = admin.firestore(app);

// ── Helpers ───────────────────────────────────────────────────────────────────

function slugify(title) {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function householdCol(type) {
  return db.collection('households').doc(HOUSEHOLD).collection(type);
}

function formatDate(val) {
  if (!val) return null;
  if (val && typeof val.toDate === 'function') return val.toDate().toISOString();
  return val;
}

// ── List ──────────────────────────────────────────────────────────────────────

async function listDocs(type) {
  const snap = await householdCol(type).orderBy('createdAt', 'desc').get();
  if (snap.empty) {
    console.log(`No ${type} found.`);
    return;
  }
  const rows = snap.docs.map((doc) => {
    const d = doc.data();
    return { id: doc.id, ...d, createdAt: formatDate(d.createdAt) };
  });

  if (type === 'tasks') {
    rows.forEach((r) => {
      const due = r.due ? ` | due: ${r.due}` : '';
      const status = r.status ? ` [${r.status}]` : '';
      console.log(`• ${r.id}${status}`);
      console.log(`  ${r.name}${due}`);
      if (r.description) console.log(`  ${r.description}`);
    });
  } else if (type === 'events') {
    rows.forEach((r) => {
      const date = r.date ? ` | ${r.date}` : '';
      const loc = r.location ? ` @ ${r.location}` : '';
      console.log(`• ${r.id}`);
      console.log(`  ${r.title}${date}${loc}`);
      if (r.description) console.log(`  ${r.description}`);
    });
  } else {
    rows.forEach((r) => {
      console.log(`• ${r.id}`);
      if (r.text) console.log(`  ${r.text}`);
    });
  }
}

// ── Create ────────────────────────────────────────────────────────────────────

async function createDoc(type, jsonArg) {
  let fields;
  try {
    fields = JSON.parse(jsonArg);
  } catch {
    console.error('Invalid JSON argument');
    process.exit(1);
  }

  const nameField = type === 'notes' ? 'text' : 'name';
  if (!fields[nameField] || typeof fields[nameField] !== 'string') {
    console.error(`"${nameField}" field is required`);
    process.exit(1);
  }

  const now = Date.now();
  const id = `${slugify(fields[nameField])}-${now}`;

  const doc = {
    ...fields,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (type === 'tasks' && !doc.status) {
    doc.status = 'todo';
  }

  await householdCol(type).doc(id).set(doc);
  console.log(`Created ${type.slice(0, -1)}: ${id}`);
  console.log(JSON.stringify({ id, ...fields }, null, 2));
}

// ── Update ────────────────────────────────────────────────────────────────────

async function updateDoc(type, taskId, jsonArg) {
  let fields;
  try {
    fields = JSON.parse(jsonArg);
  } catch {
    console.error('Invalid JSON argument');
    process.exit(1);
  }

  const update = { ...fields };

  if (update.completions !== undefined) {
    // Replace completions array with arrayUnion to append entries
    const entries = Array.isArray(update.completions) ? update.completions : [update.completions];
    update.completions = admin.firestore.FieldValue.arrayUnion(...entries);
  }

  const ref = householdCol(type).doc(taskId);
  await ref.update(update);
  console.log(`Updated ${type.slice(0, -1)}: ${taskId}`);
}

// ── Queue ─────────────────────────────────────────────────────────────────────

const fs = require('fs');
const QUEUE_PATH = '/workspace/group/portal-write-queue.json';

function appendToQueue(action, type, data) {
  let queue = [];
  if (fs.existsSync(QUEUE_PATH)) {
    queue = JSON.parse(fs.readFileSync(QUEUE_PATH, 'utf8'));
  }
  const entry = {
    id: `queue-${Date.now()}`,
    action,
    type,
    data,
    timestamp: new Date().toISOString(),
  };
  queue.push(entry);
  fs.writeFileSync(QUEUE_PATH, JSON.stringify(queue, null, 2));
  console.log(`Queued ${action} ${type}: ${entry.id}`);
}

// ── Delete ────────────────────────────────────────────────────────────────────

async function deleteDocById(type, id) {
  const ref = householdCol(type).doc(id);
  await ref.delete();
  console.log(`Deleted ${type.slice(0, -1)}: ${id}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const [, , command, subcommand, arg1, arg2] = process.argv;

  const VALID_TYPES = ['tasks', 'events', 'notes'];

  if (command === 'list') {
    if (!VALID_TYPES.includes(subcommand)) {
      console.error(`Usage: home-portal.cjs list tasks|events|notes`);
      process.exit(1);
    }
    await listDocs(subcommand);
  } else if (command === 'create') {
    if (!VALID_TYPES.includes(subcommand)) {
      console.error(`Usage: home-portal.cjs create task|event|note '<json>'`);
      process.exit(1);
    }
    // Normalise singular → plural collection name
    const colName = subcommand.endsWith('s') ? subcommand : subcommand + 's';
    if (!arg1) {
      console.error('JSON argument is required for create');
      process.exit(1);
    }
    await createDoc(colName, arg1);
  } else if (command === 'update') {
    if (subcommand !== 'task') {
      console.error(`Usage: home-portal.cjs update task <taskId> '<json>'`);
      process.exit(1);
    }
    const taskId = arg1;
    const jsonArg = arg2;
    if (!taskId || !jsonArg) {
      console.error(`Usage: home-portal.cjs update task <taskId> '<json>'`);
      process.exit(1);
    }
    await updateDoc('tasks', taskId, jsonArg);
  } else if (command === 'queue') {
    const VALID_ACTIONS = ['create', 'update', 'delete'];
    if (!VALID_ACTIONS.includes(subcommand)) {
      console.error(`Usage: home-portal.cjs queue create|update|delete <type> '<json>'`);
      process.exit(1);
    }
    const colName = arg1 && (arg1.endsWith('s') ? arg1 : arg1 + 's');
    if (!colName || !VALID_TYPES.includes(colName)) {
      console.error(`Usage: home-portal.cjs queue ${subcommand} task|event|note '<json>'`);
      process.exit(1);
    }
    if (!arg2) {
      console.error('JSON argument is required for queue');
      process.exit(1);
    }
    let data;
    try {
      data = JSON.parse(arg2);
    } catch {
      console.error('Invalid JSON argument');
      process.exit(1);
    }
    appendToQueue(subcommand, colName, data);
  } else if (command === 'delete') {
    const colName = subcommand && (subcommand.endsWith('s') ? subcommand : subcommand + 's');
    if (!colName || !VALID_TYPES.includes(colName)) {
      console.error(`Usage: home-portal.cjs delete task|event|note <id>`);
      process.exit(1);
    }
    if (!arg1) {
      console.error('ID argument is required for delete');
      process.exit(1);
    }
    await deleteDocById(colName, arg1);
  } else {
    console.error('Usage: home-portal.cjs <list|create|update|delete|queue> <type> [args]');
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error:', err.message);
    process.exit(1);
  });
