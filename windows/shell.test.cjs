const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {size, clampBounds, writeData, readData, validateData} = require('./shell.cjs');
test('drag and resize clamp pet into negative-coordinate secondary monitor', () => {
  assert.deepEqual(clampBounds({x: -2200, y: 999, width: 280, height: 460}, {x: -1920, y: 0, width:1920, height:1080}), {x:-1920,y:620,width:280,height:460});
  assert.equal(size(5000),480); assert.equal(size(-10),160);
});
test('Korean planner persists, malformed payload does not overwrite', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'rabbit-test-'));
  try {const file = path.join(dir, 'planner.json'); writeData(file,{goal:'이번 달 목표',entries:[{done:true}]}); assert.equal(readData(file).goal,'이번 달 목표'); assert.throws(()=>writeData(file,null)); assert.equal(readData(file).entries[0].done,true); assert.throws(()=>validateData({huge:'x'.repeat(5*1024*1024)}));} finally {fs.rmSync(dir,{recursive:true});}
});
