'use strict';
const fs=require('node:fs');
const providers=['OpenAI','Gemini','Claude'];
function validateProvider(provider){if(!providers.includes(provider))throw new Error('Invalid provider')}
function buildRequest(provider,model,prompt,key){
 validateProvider(provider);if(typeof model!=='string'||!/^[a-zA-Z0-9._:-]{1,100}$/.test(model)||typeof prompt!=='string'||!prompt.trim()||prompt.length>20000)throw new Error('Check model and prompt (max 20,000 characters)');
 const headers={'Content-Type':'application/json'};let url,body;
 if(provider==='OpenAI'){url='https://api.openai.com/v1/responses';headers.Authorization='Bearer '+key;body={model,input:prompt,store:false,max_output_tokens:2048}}
 else if(provider==='Gemini'){url=`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;headers['x-goog-api-key']=key;body={contents:[{parts:[{text:prompt}]}],generationConfig:{maxOutputTokens:2048}}}
 else{url='https://api.anthropic.com/v1/messages';headers['x-api-key']=key;headers['anthropic-version']='2023-06-01';body={model,max_tokens:2048,messages:[{role:'user',content:prompt}]}}
 return {url,options:{method:'POST',headers,body:JSON.stringify(body),redirect:'error'}};
}
function parseResponse(data,provider){const parts=provider==='OpenAI'?(data.output||[]).flatMap(o=>o.content||[]):provider==='Gemini'?(data.candidates||[]).slice(0,1).flatMap(o=>o.content?.parts||[]):data.content||[];const text=parts.map(p=>p.text).filter(x=>typeof x==='string').join('\n');if(!text)throw new Error('No text response');return text}
function createStore(file,safeStorage){
 function read(){try{return JSON.parse(fs.readFileSync(file,'utf8'))}catch(error){if(error.code==='ENOENT')return {};throw new Error('Could not read secure API storage')}}
 function write(data){const temp=file+'.tmp';fs.writeFileSync(temp,JSON.stringify(data),{mode:0o600});fs.renameSync(temp,file)}
 function save(provider,key){validateProvider(provider);if(typeof key!=='string'||key.length<10||key.length>512||/\s/.test(key))throw new Error('Invalid key');if(!safeStorage.isEncryptionAvailable())throw new Error('OS encryption unavailable');const data=read();data[provider]=safeStorage.encryptString(key).toString('base64');write(data);return true}
 function remove(provider){validateProvider(provider);const data=read();delete data[provider];write(data);return true}
 function key(provider){validateProvider(provider);if(!safeStorage.isEncryptionAvailable())throw new Error('OS encryption unavailable');const value=read()[provider];if(!value)throw new Error('Save your API key first');try{return safeStorage.decryptString(Buffer.from(value,'base64'))}catch{throw new Error('Could not unlock API key')}}
 let busy=false;
 async function send(provider,model,prompt,consent){if(consent!==true)throw new Error('Explicit confirmation required');if(busy)throw new Error('A request is already running');const r=buildRequest(provider,model,prompt,key(provider));busy=true;try{const response=await fetch(r.url,{...r.options,signal:AbortSignal.timeout(60000)});if(!response.ok)throw new Error(`HTTP ${response.status}: check key, model, balance and limits`);const raw=await response.text();if(raw.length>2000000)throw new Error('Response too large');return parseResponse(JSON.parse(raw),provider)}catch(error){if(/^HTTP |^No text|^Response too/.test(error.message))throw error;throw new Error('Request failed. Check connection and provider settings. No automatic retry.')}finally{busy=false}}
 return {save,remove,send};
}
module.exports={buildRequest,parseResponse,createStore};
