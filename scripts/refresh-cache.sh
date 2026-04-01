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

function slugDate(d){ return d.toISOString().slice(0,10); }
function pad(n){ return String(n).padStart(2,'0'); }
function fmt(h,m){ const ap=h>=12?'pm':'am'; return (h%12||12)+':'+pad(m)+ap; }

const today=new Date();
const tomorrow=new Date(today); tomorrow.setDate(today.getDate()+1);
const todayStr=slugDate(today);
const tomorrowStr=slugDate(tomorrow);

Promise.all([
  db.collection('households/home/tasks').get(),
  db.collection('households/home/events').get(),
  db.collection('households/home/notes').get()
]).then(([tSnap,eSnap,nSnap])=>{
  const tasks=tSnap.docs.map(d=>({id:d.id,...d.data()}));
  const events=eSnap.docs.map(d=>({id:d.id,...d.data()}));
  const notes=nSnap.docs.map(d=>({id:d.id,...d.data()}));

  const todayMs=today.setHours(0,0,0,0);
  const tomorrowMs=new Date(tomorrowStr).getTime();

  function nextDue(t){
    const completions=(t.completions||[]).length;
    return t.createdAt+(completions*t.frequencyDays*86400000);
  }

  const dueTodayOrOver=tasks.filter(t=>nextDue(t)<=todayMs);
  const dueTomorrow=tasks.filter(t=>{
    const nd=nextDue(t);
    return nd>=tomorrowMs && nd<tomorrowMs+86400000;
  });
  const todayEvents=events.filter(e=>e.date===todayStr);
  const tomorrowEvents=events.filter(e=>e.date===tomorrowStr);
  const pinned=notes.filter(n=>n.pinned);

  const lines=[
    '\u{1F305} *Good morning! Here is your daily briefing*',
    '',
    '\u{1F4CB} *Tasks due today / overdue*',
    dueTodayOrOver.length?dueTodayOrOver.map(t=>'• '+t.name).join('\n'):'None',
    '',
    '\u{1F4CB} *Tasks due tomorrow*',
    dueTomorrow.length?dueTomorrow.map(t=>'• '+t.name).join('\n'):'None',
    '',
    '\u{1F4C5} *Today events*',
    todayEvents.length?todayEvents.map(e=>'• '+e.title+' — '+fmt(e.startHour,e.startMin)).join('\n'):'None',
    '',
    '\u{1F4C5} *Tomorrow events*',
    tomorrowEvents.length?tomorrowEvents.map(e=>'• '+e.title+' — '+fmt(e.startHour,e.startMin)).join('\n'):'None',
    '',
    '\u{1F4CC} *Pinned notes*',
    pinned.length?pinned.map(n=>'• '+n.text.replace(/\n/g,', ')).join('\n'):'None',
  ];

  const cache={
    updatedAt:new Date().toISOString(),
    tasks,events,notes,
    briefing:lines.join('\n')
  };
  fs.writeFileSync('/workspace/group/home-portal-cache.json',JSON.stringify(cache));
  process.exit(0);
}).catch(e=>{console.error(e.message);process.exit(1);});
"
