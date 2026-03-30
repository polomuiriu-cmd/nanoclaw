#!/bin/bash
docker run --rm \
  -v /home/polomuiriu/nanoclaw/credentials:/run/secrets \
  -v /home/polomuiriu/nanoclaw/groups/telegram_main:/workspace/group \
  -e GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/firebase-home.json \
  --entrypoint node \
  nanoclaw-agent:latest \
  -e "
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.applicationDefault(),projectId:'temple-park-ave-bf1a3'});
const db=admin.firestore();
const fs=require('fs');
Promise.all([
  db.collection('households/home/tasks').get(),
  db.collection('households/home/events').get(),
  db.collection('households/home/notes').get()
]).then(([t,e,n])=>{
  const cache={
    updatedAt:new Date().toISOString(),
    tasks:t.docs.map(d=>({id:d.id,...d.data()})),
    events:e.docs.map(d=>({id:d.id,...d.data()})),
    notes:n.docs.map(d=>({id:d.id,...d.data()}))
  };
  fs.writeFileSync('/workspace/group/home-portal-cache.json',JSON.stringify(cache));
  process.exit(0);
}).catch(e=>{console.error(e.message);process.exit(1);});
"
