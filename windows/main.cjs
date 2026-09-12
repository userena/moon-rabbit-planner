'use strict';
const {app, BrowserWindow, ipcMain, screen, Menu, shell, session, safeStorage} = require('electron');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const fs = require('node:fs');
const os = require('node:os');
const {ACTIONS, size, clampBounds, writeData, readData} = require('./shell.cjs');
const smoke = process.argv.includes('--smoke-test');
if (!smoke && !app.requestSingleInstanceLock()) app.quit();
app.on('second-instance', () => { if (app.isReady()) openPlanner(); });
if (smoke) setTimeout(() => { console.error('Electron smoke timed out'); app.exit(1); }, 45000).unref();
if (smoke) app.setPath('userData', fs.mkdtempSync(path.join(os.tmpdir(), 'moonrabbit-smoke-')));
const web = app.isPackaged ? path.join(process.resourcesPath, 'web') : path.join(__dirname, '../web');
const allowedURLs = new Set(['index.html', 'pet.html'].map(file => pathToFileURL(path.join(web, file)).href));
const file = () => path.join(app.getPath('userData'), 'planner.json');
let planner, pet, wander = false, target = null, pauseUntil = 0;
const externalHosts = new Set(['platform.openai.com', 'aistudio.google.com', 'platform.claude.com', 'gemini.google.com', 'claude.ai', 'chatgpt.com', 'open-meteo.com', 'www.openstreetmap.org', 'photon.komoot.io']);
function external(url) { try { const u = new URL(url); if (u.protocol === 'https:' && externalHosts.has(u.hostname)) void shell.openExternal(url); } catch {} }
function trusted(event) { return [planner, pet].some(w => w && !w.isDestroyed() && w.webContents === event.sender) && event.senderFrame === event.sender.mainFrame && allowedURLs.has(event.senderFrame.url); }
function handle(channel, fn, plannerOnly = false) { ipcMain.handle(channel, (event, ...args) => { if (!trusted(event) || (plannerOnly && event.sender !== planner?.webContents)) throw new Error('Untrusted sender'); return fn(...args); }); }
function broadcast(channel, payload) { for (const w of [planner, pet]) if (w && !w.isDestroyed()) w.webContents.send(channel, payload); }
function makeWindow(options, page) {
  const win = new BrowserWindow({...options, webPreferences: {preload: path.join(__dirname, 'preload.cjs'), contextIsolation: true, sandbox: true, nodeIntegration: false, webSecurity: true}});
  win.webContents.setWindowOpenHandler(({url}) => { external(url); return {action: 'deny'}; });
  win.webContents.on('will-navigate', (event, url) => { if (!allowedURLs.has(url)) { event.preventDefault(); external(url); } });
  win.renderErrors = [];
  win.webContents.on('console-message', (_event, details) => { if (details && details.level === 'error') win.renderErrors.push(details.message); });
  win.webContents.on('render-process-gone', (_event, details) => win.renderErrors.push('Renderer exited: ' + details.reason));
  win.loadFile(path.join(web, page));
  return win;
}
function openPlanner() {
  if (!planner || planner.isDestroyed()) {
    planner = makeWindow({width: 1080, height: 820, minWidth: 600, minHeight: 440, title: '달토끼 플래너', backgroundColor: '#faf7f2', show: !smoke}, 'index.html');
    planner.on('closed', () => { planner = null; });
  } else { planner.show(); planner.focus(); }
}
function setSize(value) {
  if (!Number.isFinite(value)) throw new Error('Invalid pet size');
  const old = pet.getBounds(), area = screen.getDisplayMatching(old).workArea;
  const s = Math.max(100, Math.min(280, Math.round(value)));
  const bounds = {...old, width: Math.min(area.width, Math.max(280, s + 40)), height: Math.min(area.height, s + 200)};
  pet.setBounds(clampBounds(bounds, area));
  return s;
}
function tick() {
  if (!wander || !pet || pet.isDestroyed() || Date.now() < pauseUntil) return;
  const bounds = pet.getBounds(), area = screen.getDisplayMatching(bounds).workArea;
  if (!target) {
    target = {x: area.x + Math.random() * Math.max(0, area.width - bounds.width), y: Math.max(area.y, area.y + area.height - bounds.height - Math.random() * 90)};
    broadcast('pet:action', {type: 'movement', direction: target.x < bounds.x ? 'left' : 'right', moving: true});
  }
  const dx = target.x - bounds.x, dy = target.y - bounds.y, length = Math.hypot(dx, dy);
  if (length < 4) { target = null; pauseUntil = Date.now() + 3000 + Math.random() * 5000; broadcast('pet:action', {type: 'movement', direction: 'right', moving: false}); return; }
  pet.setBounds(clampBounds({...bounds, x: Math.round(bounds.x + dx / length * 2), y: Math.round(bounds.y + dy / length * 2)}, area));
}
app.whenReady().then(async () => {
  Menu.setApplicationMenu(Menu.buildFromTemplate([{label: '달토끼', submenu: [{label: '플래너 열기', click: openPlanner}, {label: '종료', role: 'quit'}]}]));
  session.defaultSession.setPermissionRequestHandler((_wc, _permission, callback) => callback(false));
  session.defaultSession.setPermissionCheckHandler(() => false);
  const area = screen.getPrimaryDisplay().workArea;
  pet = makeWindow({width: 280, height: 460, x: area.x + area.width - 300, y: area.y + Math.max(0, area.height - 480), frame: false, transparent: true, alwaysOnTop: true, resizable: false, skipTaskbar: false, hasShadow: false, show: !smoke}, 'pet.html');
  pet.on('will-move', () => { target = null; pauseUntil = Date.now() + 5000; });
  pet.on('closed', () => app.quit());
  openPlanner();
  try { const saved = readData(file()); wander = saved.wander === true; setSize(Number.isFinite(saved.size) ? saved.size : 180); }
  catch (error) { console.error('Could not restore planner preferences:', error.message); }
  const personalAPI = require('./personal-api.cjs').createStore(path.join(app.getPath('userData'), 'personal-api-keys.json'), safeStorage);
  handle('api:save', (provider,key) => personalAPI.save(provider,key), true);
  handle('api:delete', provider => personalAPI.remove(provider), true);
  handle('api:send', (provider,model,prompt,consent) => personalAPI.send(provider,model,prompt,consent), true);
  handle('planner:open', section => { if(section!==undefined&&!['planner','alarms','roulette'].includes(section))throw new Error('Invalid section');openPlanner();if(section&&section!=='planner'){const send=()=>planner.webContents.send('planner:section',section);if(planner.webContents.isLoading())planner.webContents.once('did-finish-load',send);else send()}return true; });
  handle('pet:size', setSize);
  handle('pet:wander', value => { if (typeof value !== 'boolean') throw new Error('Invalid wander value'); const saved = readData(file()); saved.wander = value; writeData(file(), saved); wander = value; target = null; broadcast('shared:update', saved); if (!value) broadcast('pet:action', {type: 'movement', direction: 'right', moving: false}); return value; });
  handle('pet:action', value => {
    if (value && typeof value === 'object' && value.type === 'message') {
      if (typeof value.text !== 'string' || value.text.length > 1000 || (value.duration !== undefined && !Number.isFinite(value.duration)) || (value.weather !== undefined && typeof value.weather !== 'boolean')) throw new Error('Invalid message');
      broadcast('pet:action', {type: 'message', text: value.text, duration: Math.max(1000, Math.min(30000, value.duration ?? 7000)), weather: value.weather === true});
    } else { if (!ACTIONS.has(value)) throw new Error('Invalid action'); pauseUntil = Date.now() + 8000; broadcast('pet:action', value); }
    return true;
  });
  handle('shared:load', () => readData(file()));
  handle('shared:save', data => { writeData(file(), data); broadcast('shared:update', data); return true; }, true);
  const timer = setInterval(tick, 33);
  app.on('before-quit', () => clearInterval(timer));
  screen.on('display-metrics-changed', () => { if (pet && !pet.isDestroyed()) pet.setBounds(clampBounds(pet.getBounds(), screen.getDisplayMatching(pet.getBounds()).workArea)); });
  if (smoke) {
    try { await require('./smoke.cjs')({planner, pet, file: file(), tick, screen}); app.exit(0); }
    catch (error) { console.error(error); app.exit(1); }
  }
});
app.on('window-all-closed', () => app.quit());
