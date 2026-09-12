'use strict';
const fs = require('node:fs');
const MAX_BYTES = 4 * 1024 * 1024;
const ACTIONS = new Set(['idle','walk','snack','smile','dance','stretch','flower','coffee','work','weather']);
function size(value) { return Number.isFinite(value) ? Math.max(160, Math.min(480, Math.round(value))) : 280; }
function clampBounds(bounds, area) {
  return {...bounds, x: Math.max(area.x, Math.min(area.x + area.width - bounds.width, bounds.x)), y: Math.max(area.y, Math.min(area.y + area.height - bounds.height, bounds.y))};
}
function validateData(data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Expected planner object');
  const json = JSON.stringify(data);
  if (Buffer.byteLength(json) > MAX_BYTES) throw new Error('Planner exceeds 4 MB');
  return json;
}
function writeData(file, data) {
  const json = validateData(data);
  fs.writeFileSync(file + '.tmp', json, {mode: 0o600});
  fs.renameSync(file + '.tmp', file);
}
function readData(file) {
  if (!fs.existsSync(file)) return {};
  if (fs.statSync(file).size > MAX_BYTES) throw new Error('Planner exceeds 4 MB');
  const value = JSON.parse(fs.readFileSync(file, 'utf8'));
  validateData(value);
  return value;
}
module.exports = {ACTIONS, size, clampBounds, validateData, writeData, readData};
