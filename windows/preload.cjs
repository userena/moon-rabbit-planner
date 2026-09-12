'use strict';
const {contextBridge, ipcRenderer} = require('electron');
function subscribe(channel, callback) {
  if (typeof callback !== 'function') return () => {};
  const listener = (_event, payload) => callback(payload);
  ipcRenderer.on(channel, listener);
  return () => ipcRenderer.removeListener(channel, listener);
}
contextBridge.exposeInMainWorld('moonRabbit', {
  platform: 'windows',
  openPlanner: () => ipcRenderer.invoke('planner:open'),
  setPetSize: value => ipcRenderer.invoke('pet:size', value),
  setWander: value => ipcRenderer.invoke('pet:wander', value),
  performAction: value => ipcRenderer.invoke('pet:action', value),
  onPetAction: callback => subscribe('pet:action', callback),
  saveShared: data => ipcRenderer.invoke('shared:save', data),
  loadShared: () => ipcRenderer.invoke('shared:load'),
  onSharedUpdate: callback => subscribe('shared:update', callback)
});
