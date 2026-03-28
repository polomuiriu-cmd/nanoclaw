---
name: home-portal
description: Read and write household data (tasks, calendar events, noticeboard notes) stored in Firestore. Use when the user asks about chores, to-dos, upcoming events, or household notes.
---

# Home Portal

Access household data from Firestore (project: temple-park-ave-bf1a3).

**Collections:**
- `households/home/tasks` — household to-do/chore tasks
- `households/home/events` — calendar events
- `households/home/notes` — noticeboard notes

**Script location:** `/home/node/.claude/skills/home-portal/home-portal.cjs`

---

## READ operations

```bash
node /home/node/.claude/skills/home-portal/home-portal.cjs list tasks
node /home/node/.claude/skills/home-portal/home-portal.cjs list events
node /home/node/.claude/skills/home-portal/home-portal.cjs list notes
```

Run reads freely whenever the user asks to see, check, or review household data.

---

## WRITE operations

**STOP — confirmation gate:**

Before running any `create` command you MUST verify that the user's **current message** explicitly asked you to create, add, or save something. If the current message is ambiguous or only asked to read/list, do NOT write — ask the user to confirm first.

Once confirmed, create with:

```bash
# Task
node /home/node/.claude/skills/home-portal/home-portal.cjs create task \
  '{"title":"water plants","description":"All indoor plants","due":"2026-03-28","status":"todo"}'

# Event
node /home/node/.claude/skills/home-portal/home-portal.cjs create event \
  '{"title":"Doctor appointment","date":"2026-03-28T10:00:00","location":"City clinic","description":"Annual check-up"}'

# Note
node /home/node/.claude/skills/home-portal/home-portal.cjs create note \
  '{"title":"Shopping list","content":"milk, eggs, bread"}'
```

**Field reference:**

| Type  | Required | Optional |
|-------|----------|----------|
| task  | title    | description, due (ISO date string), status (todo/done) |
| event | title    | date (ISO datetime), location, description |
| note  | title    | content |

**Task ID format:** slugified-title-{timestamp}, e.g. `water-plants-1774544586276`

---

## Troubleshooting

If the script fails with a credentials error, check:
```bash
echo $GOOGLE_APPLICATION_CREDENTIALS
ls -la /run/secrets/firebase-home.json
```

If firebase-admin is missing:
```bash
ls /app/node_modules/firebase-admin/package.json
```
