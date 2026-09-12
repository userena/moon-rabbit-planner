(function(global){
'use strict';
const sequences={idle:['rabbit','blink','rabbit'],smile:['smile'],snack:['snack','snackB'],dance:['dance','danceB'],stretch:['stretch','stretchB'],flower:['flower','flowerB'],coffee:['coffee','coffeeB'],walk:['walkCycle0','walkCycle1','walkCycle2','walkCycle3']};
class RabbitPet {
 constructor(element,options={}){this.element=element;this.options=options;this.action='idle';this.until=0;this.frame=0;this.messageUntil=0;this.left=false;this.timer=setInterval(()=>this.tick(),260);this.lastImage='';element.addEventListener('pointerenter',()=>{this.perform('smile',2400);this.say(options.t?.('반가워요! 잠깐 웃고 갈까요?','Hello! A little smile for you?')||'Hello!',2400)});element.addEventListener('click',()=>options.click?.());this.tick();}
 perform(action,duration=6500){this.action=action;this.until=Date.now()+duration;this.frame=0;}
 say(message,duration=7000,weather=false){this.message=message;this.messageUntil=Date.now()+duration;this.weather=weather;this.tick();}
 tick(){const state=this.options.state?.()||{},now=Date.now();if(now>this.until){this.action=(this.options.desktop?this.moving:state.wander)?'walk':'idle';if(Math.random()<.015){this.action=['smile','stretch','flower'][Math.floor(Math.random()*3)];this.until=now+3000}}let frames=this.action==='work'?[`${global.RabbitModel?.roles[state.role]?.[2]||'workLaptop'}0`,`${global.RabbitModel?.roles[state.role]?.[2]||'workLaptop'}1`]:sequences[this.action]||sequences.idle;let index=this.action==='idle'?(this.frame%24===0?1:0):Math.floor(this.frame/2)%frames.length;const source=`assets/${frames[index]}.png`;const img=this.element.querySelector('img');if(img&&source!==this.lastImage){img.src=source;this.lastImage=source;}if(img){img.style.scale=this.left?'-1 1':'1 1';}this.element.style.setProperty('--pet-size',`${state.size||180}px`);this.element.classList.toggle('active',['dance','stretch','smile'].includes(this.action));this.element.classList.toggle('roam',!!state.wander&&!this.options.desktop);const upper=this.element.querySelector('.bubble-goal');if(upper){let text=[];if(state.showDDay&&state.dday)text.push(global.RabbitModel.ddayLabel(state.dday,global.RabbitModel.dayKey(new Date()),state.ddayPrefix)+' '+state.ddayName);if(state.showGoal&&state.goal)text.push(state.goal);upper.textContent=text.join(' · ');upper.hidden=!text.length;}const message=this.element.querySelector('.bubble-message');if(message){if(now>this.messageUntil){const ko=state.lang!=='en';const messages=ko?['곁에서 응원하고 있어요 🌿','어깨를 펴고 천천히 해봐요.','작은 한 걸음도 소중해요.','물 한 모금, 잠깐 쉬어 갈까요?','오늘도 나만의 속도로.']:['Here, cheering you on 🌿','Relax your shoulders.','Small steps count.','A sip of water and a short break?','Keep your own pace today.'];this.message=messages[Math.floor(now/14000)%messages.length];this.weather=false;}message.textContent=this.message||'';}const link=this.element.querySelector('.weather-source');if(link)link.hidden=!this.weather;this.frame++;}
 destroy(){clearInterval(this.timer)}
}
global.RabbitPet=RabbitPet;
if(document.body?.classList.contains('desktop-pet')){
 let state=global.RabbitModel.defaults();const t=(ko,en)=>state.lang==='en'?en:ko;
 const element=document.querySelector('.rabbit-pet');const menu=document.getElementById('pet-menu');
 const pet=new RabbitPet(element,{desktop:true,state:()=>state,t,click:()=>{menu.hidden=!menu.hidden;}});
 function update(data){state=global.RabbitModel.normalize(data);document.documentElement.style.setProperty('--bubble',state.bubble);pet.tick();}
 global.moonRabbit?.loadShared?.().then(data=>{if(data)update(data)}).catch(()=>{});
 global.moonRabbit?.onSharedUpdate?.(update);
 global.moonRabbit?.onPetAction?.(event=>{if(typeof event==='string')pet.perform(event);else if(event?.type==='movement'){pet.left=event.direction==='left';pet.moving=event.moving;if(event.moving)pet.perform('walk',700);else pet.perform('idle',700)}else if(event?.type==='message')pet.say(event.text,event.duration,event.weather)});
 document.querySelectorAll('[data-action]').forEach(button=>button.addEventListener('click',()=>{const action=button.dataset.action;if(action==='planner')global.moonRabbit?.openPlanner?.();else if(action==='wander'){state.wander=!state.wander;global.moonRabbit?.setWander?.(state.wander);}else pet.perform(action);menu.hidden=true;}));
}
})(window);
