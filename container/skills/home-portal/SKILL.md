---
name: home-portal
description: Read and write household tasks, calendar events, and notes. Use for anything related to chores, schedule, reminders, or household notes.
---
## Commands
node /home/node/.claude/skills/home-portal/home-portal.cjs list tasks
node /home/node/.claude/skills/home-portal/home-portal.cjs list events
node /home/node/.claude/skills/home-portal/home-portal.cjs list notes
node /home/node/.claude/skills/home-portal/home-portal.cjs create task '{"name":"title","scheduleType":"interval","frequencyDays":7,"scheduledDay":6,"icon":"clean","subtasks":[],"completions":[],"forSean":false}'
node /home/node/.claude/skills/home-portal/home-portal.cjs create event '{"title":"title","date":"YYYY-MM-DD","startHour":9,"startMin":0,"endHour":10,"endMin":0,"allDay":false,"colorIdx":0,"notes":""}'
node /home/node/.claude/skills/home-portal/home-portal.cjs create note '{"text":"content","pinned":false,"colorIdx":0}'
node /home/node/.claude/skills/home-portal/home-portal.cjs update task <taskId> '{"completions":[{"by":"polomuiriu@gmail.com","date":"YYYY-MM-DD"}]}'
## Rules
Reads: always available
Writes: describe what you will create and confirm before running
Completions format: {"by":"polomuiriu@gmail.com","date":"YYYY-MM-DD"}
