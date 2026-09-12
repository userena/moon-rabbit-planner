/* Local planner model. No cloud sync or generated content at runtime. */
(function (global) {
'use strict';
const roles = {
 developer:['개발자','Developer','workLaptop',['재현 방법과 기대 결과','원인과 해결 아이디어','다음에 이어 할 작업'],['Reproduction & expected result','Cause & solution','Next step']],
 designer:['디자이너','Designer','workDesign',['디자인 목적과 사용자','참고 자료와 링크','피드백과 수정 방향'],['Design goal & audience','References','Feedback & revisions']],
 planner:['기획자','Planner','workPlan',['해결할 문제와 성공 기준','결정 사항과 근거','위험 요소와 다음 행동'],['Problem & success criteria','Decisions & reasons','Risks & next actions']],
 soloStartup:['1인 스타트업','Solo startup','workLaptop',['고객 문제와 이번 주 가설','검증 실험과 성공 지표','매출 · 비용 · 다음 행동'],['Customer problem & hypothesis','Experiment & metrics','Revenue, costs & next actions']],
 student:['학생','Student','workStudy',['오늘 공부할 범위','틀린 이유와 핵심 개념','다시 복습할 내용'],['Study scope','Mistakes & key concepts','Review next']],
 office:['회사원','Office','workLaptop',['회의 안건과 메모','결정 사항','후속 업무 · 담당자 · 기한'],['Meeting agenda & notes','Decisions','Follow-up, owner & deadline']],
 startupTeam:['스타트업 팀','Startup team','workPlan',['이번 스프린트 목표','팀 결정과 의존 작업','막힌 일과 지원 요청'],['Sprint goal','Decisions & dependencies','Blockers & support']]
};
const defaults = () => ({version:1,studio:null,calendarPeriods:[],routine:{},weeklyGoals:{},progress:{day:{target:3,color:'#ee68c0'},week:{target:15,color:'#ee68c0'},month:{target:60,color:'#ee68c0'}},zoom:100,logo:'original',meals:['','',''],reminderKeys:[],title:'',lang:'ko',role:'developer',goal:'',showGoal:true,showDDay:false,dday:'',ddayName:'',ddayPrefix:'D',period:'month',periodStart:dayKey(new Date()),step:10,bg:'#f5f2f7',card:'#ffffff',accent:'#ee68c0',bubble:'#fff4e0',size:180,wander:false,days:{},months:{},alarms:[],weatherPlace:null,workSeconds:0,timerMinutes:25,timerRemaining:1500});
function dayKey(date) { return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`; }
function dateFor(key) { const [y,m,d]=key.split('-').map(Number); return new Date(y,m-1,d); }
function addDays(key,n) { const d=dateFor(key); d.setDate(d.getDate()+n); return dayKey(d); }
function periodEnd(start,period) {
 const d=dateFor(start);
 if(['week','100','200'].includes(period)) return addDays(start,period==='week'?6:Number(period)-1);
 const amount=period==='year'?12:1, original=d.getDate(); d.setDate(1); d.setMonth(d.getMonth()+amount); const last=new Date(d.getFullYear(),d.getMonth()+1,0).getDate(); d.setDate(Math.min(original,last)); d.setDate(d.getDate()-1); return dayKey(d);
}
function ddayLabel(target,today,prefix='D') { if(!target)return ''; const a=dateFor(target),b=dateFor(today); const diff=Math.round((Date.UTC(a.getFullYear(),a.getMonth(),a.getDate())-Date.UTC(b.getFullYear(),b.getMonth(),b.getDate()))/86400000); return diff===0?(prefix==='D'?'D-DAY':`${prefix} 0`):`${prefix}${diff>0?'−':'+'}${Math.abs(diff)}`; }
function clock(n) { return `${String(Math.floor(n/60)).padStart(2,'0')}:${String(n%60).padStart(2,'0')}`; }
function elapsed(n) { n=Math.max(0,Math.floor(n)); return `${String(Math.floor(n/3600)).padStart(2,'0')}:${clock(n%3600)}`; }
function uid() { return global.crypto?.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`; }
function task(start=540,minutes=30,color='#ee68c0') { return {id:uid(),start,minutes,color,title:'',category:'',owner:'',done:false,priority:'normal'}; }
function normalize(raw) { const d=defaults(); if(!raw || typeof raw!=='object' || Array.isArray(raw))return d; for(const key of Object.keys(d))if(Object.prototype.hasOwnProperty.call(raw,key))d[key]=raw[key]; if(!roles[d.role])d.role='developer'; if(!['ko','en'].includes(d.lang))d.lang='ko'; if(![10,30].includes(d.step))d.step=10; for(const k of ['days','months'])if(!d[k]||typeof d[k]!=='object'||Array.isArray(d[k]))d[k]={}; if(!Array.isArray(d.alarms))d.alarms=[]; for(const k of ['bg','card','accent','bubble'])if(!/^#[0-9a-f]{6}$/i.test(d[k]))d[k]=defaults()[k]; d.zoom=Math.min(140,Math.max(75,Number(d.zoom)||100)); d.size=Math.min(280,Math.max(100,Number(d.size)||180)); return d; }
function priorityRank(task) { return task.priority==='high'?0:task.priority==='low'?2:1; }
function upcoming(state,now=new Date()) {
 const rows=[]; for(let offset=0;offset<=1;offset++){const key=addDays(dayKey(now),offset);for(const task of state.days[key+':'+state.role]?.tasks||[]){if(task.done||!task.title?.trim())continue;const start=dateFor(key);start.setMinutes(task.start);if(start>now)rows.push({task,start,key});}}
 return rows.sort((a,b)=>priorityRank(a.task)-priorityRank(b.task)||a.start-b.start);
}
function reminders(state,now=new Date()) {
 const due=[];state.reminderKeys=Array.isArray(state.reminderKeys)?state.reminderKeys:[];
 for(const row of upcoming(state,now))for(const lead of [60,30,10]){const when=row.start.getTime()-lead*60000,key=`${row.key}:${state.role}:${row.task.id}:${row.task.start}:${lead}`;if(now.getTime()>=when&&now.getTime()-when<60000&&!state.reminderKeys.includes(key)){due.push({...row,lead});state.reminderKeys.push(key);}}
 state.reminderKeys=state.reminderKeys.slice(-512);return due;
}
function progressCount(state,date,period){let start=dateFor(date),end=new Date(start);if(period==='week'){start.setDate(start.getDate()-((start.getDay()+6)%7));end=new Date(start);end.setDate(end.getDate()+7)}else if(period==='month'){start.setDate(1);end=new Date(start);end.setMonth(end.getMonth()+1)}else end.setDate(end.getDate()+1);let count=0;for(let d=new Date(start);d<end;d.setDate(d.getDate()+1)){count+=(state.days[dayKey(d)+':'+state.role]?.tasks||[]).filter(t=>t.done&&t.title?.trim()).length;}if(period==='month')count+=(state.months?.[date.slice(0,7)+':'+state.role]?.tasks||[]).filter(t=>t.done&&t.title?.trim()).length;return count;}
const api={progressCount,priorityRank,upcoming,reminders,roles,defaults,dayKey,dateFor,addDays,periodEnd,ddayLabel,clock,elapsed,uid,task,normalize};
if(typeof module!=='undefined')module.exports=api;
global.RabbitModel=api;
})(typeof window!=='undefined'?window:globalThis);
