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

## UPDATE operations

**STOP — confirmation gate:** Same as write operations — confirm with the user before running any update.

```bash
# Update arbitrary task fields
node /home/node/.claude/skills/home-portal/home-portal.cjs update task <taskId> \
  '{"status":"done"}'

# Mark a task complete (appends to completions array via arrayUnion)
node /home/node/.claude/skills/home-portal/home-portal.cjs update task <taskId> \
  '{"completions":[{"by":"polomuiriu@gmail.com","date":"2026-03-31"}]}'
```

The `completions` field uses `FieldValue.arrayUnion` — entries are appended, never overwritten. Each completion entry has the shape `{ "by": "<email>", "date": "YYYY-MM-DD" }`.

Only `task` is supported as the subcommand for update.

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
