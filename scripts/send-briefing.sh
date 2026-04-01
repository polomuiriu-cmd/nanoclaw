#!/bin/bash

CACHE_FILE="/home/polomuiriu/nanoclaw/groups/telegram_main/home-portal-cache.json"
ENV_FILE="/home/polomuiriu/nanoclaw/data/env/env"
BOT_TOKEN=$(grep TELEGRAM_BOT_TOKEN "$ENV_FILE" | cut -d= -f2)
CHAT_ID="8696469478"

BRIEFING=$(node -e "
const fs=require('fs');
const cache=JSON.parse(fs.readFileSync('$CACHE_FILE','utf8'));
process.stdout.write(cache.briefing||'No briefing available');
")

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\":\"${CHAT_ID}\",\"text\":$(node -e "process.stdout.write(JSON.stringify(process.argv[1]))" "$BRIEFING"),\"parse_mode\":\"Markdown\"}"

echo "Done"
