---
name: home-portal
description: Read and write household tasks, calendar events, and notes. Use for anything related to chores, schedule, reminders, or household notes.
---
## Commands
node /home/node/.claude/skills/home-portal/home-portal.cjs list tasks
node /home/node/.claude/skills/home-portal/home-portal.cjs list events
node /home/node/.claude/skills/home-portal/home-portal.cjs list notes
node /home/node/.claude/skills/home-portal/home-portal.cjs queue create task '{"name":"title","scheduleType":"interval","frequencyDays":7,"scheduledDay":6,"icon":"clean","subtasks":[],"completions":[],"forSean":false}'
node /home/node/.claude/skills/home-portal/home-portal.cjs queue create event '{"title":"title","date":"YYYY-MM-DD","startHour":9,"startMin":0,"endHour":10,"endMin":0,"allDay":false,"colorIdx":0,"notes":""}'
node /home/node/.claude/skills/home-portal/home-portal.cjs queue create note '{"text":"content","pinned":false,"colorIdx":0}'
node /home/node/.claude/skills/home-portal/home-portal.cjs queue update task '{"id":"<taskId>","completions":[{"by":"polomuiriu@gmail.com","date":"YYYY-MM-DD"}]}'
node /home/node/.claude/skills/home-portal/home-portal.cjs queue delete task '{"id":"<id>"}'
node /home/node/.claude/skills/home-portal/home-portal.cjs queue delete event '{"id":"<id>"}'
node /home/node/.claude/skills/home-portal/home-portal.cjs queue delete note '{"id":"<id>"}'
## Rules
Reads: always available
Writes: go through the queue for instant response, processed every 5 minutes — describe what you will write and confirm before running
Deletes: CONFIRMATION GATE — state the id and type being deleted and wait for explicit user approval before running delete
Completions format: {"by":"polomuiriu@gmail.com","date":"YYYY-MM-DD"}
