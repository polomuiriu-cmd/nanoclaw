#!/bin/bash
QUEUE_FILE="/home/polomuiriu/nanoclaw/groups/telegram_main/portal-write-queue.json"
LOG="/home/polomuiriu/nanoclaw/logs/portal-queue.log"

if [ ! -f "$QUEUE_FILE" ]; then exit 0; fi
COUNT=$(node -e "const q=JSON.parse(require('fs').readFileSync('$QUEUE_FILE'));console.log(q.length);")
if [ "$COUNT" = "0" ]; then exit 0; fi

echo "$(date) Processing $COUNT queue items" >> "$LOG"

docker run --rm \
  -v /home/polomuiriu/nanoclaw/credentials:/run/secrets \
  -v /home/polomuiriu/nanoclaw/groups/telegram_main:/workspace/group \
  -e GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/firebase-home.json \
  --entrypoint node \
  nanoclaw-agent:latest \
  -e "
const admin=require('firebase-admin');
const fs=require('fs');
const QUEUE='/workspace/group/portal-write-queue.json';

admin.initializeApp({credential:admin.credential.applicationDefault(),projectId:'temple-park-ave-bf1a3'});
const db=admin.firestore();

const queue=JSON.parse(fs.readFileSync(QUEUE,'utf8'));
if(!queue.length){process.exit(0);}

const col=type=>db.collection('households').doc('home').collection(type);

async function processItem(item){
  const {action,type,data}=item;
  const types={task:'tasks',event:'events',note:'notes',tasks:'tasks',events:'events',notes:'notes'};
  const colName=types[type];
  if(!colName)throw new Error('Unknown type: '+type);

  if(action==='create'){
    const id=data.id||(type.replace(/s$/,'')+'-'+Date.now());
    await col(colName).doc(id).set({...data,id,createdAt:data.createdAt||Date.now(),updatedAt:Date.now()});
    console.log('Created',colName,id);
  } else if(action==='update'){
    const id=data.id;
    if(!id)throw new Error('Update requires id in data');
    const {id:_,...rest}=data;
    await col(colName).doc(id).update({...rest,updatedAt:Date.now()});
    console.log('Updated',colName,id);
  } else if(action==='delete'){
    const id=data.id;
    if(!id)throw new Error('Delete requires id in data');
    await col(colName).doc(id).delete();
    console.log('Deleted',colName,id);
  }
}

(async()=>{
  const errors=[];
  for(const item of queue){
    try{ await processItem(item); }
    catch(e){ errors.push({item,error:e.message}); }
  }
  if(errors.length){
    fs.writeFileSync(QUEUE,JSON.stringify(errors.map(e=>e.item),null,2));
    console.error('Errors:',JSON.stringify(errors));
    process.exit(1);
  } else {
    fs.writeFileSync(QUEUE,'[]');
    process.exit(0);
  }
})();
" 2>> "$LOG"

echo "$(date) Queue processing complete" >> "$LOG"
