## Code change rules
- Make only the specific change requested — nothing else
- Never refactor, rename, or "improve" surrounding code
- Never rewrite a function when a field name change will do
- Always show the diff and wait for approval before applying
- If unsure about scope, ask before writing any code
- One change per instruction — if multiple changes needed, list them and confirm before starting

## Scheduled tasks
Prefer cron scripts over NanoClaw scheduled tasks for predictable, well-defined outputs. NanoClaw scheduled tasks should only be used when the task genuinely requires LLM reasoning. When implementing a scheduled task, ask: does this need intelligence or just code?
