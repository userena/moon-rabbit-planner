'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(win, expression) {
  for (let i = 0; i < 100; i++) {
    if (await win.webContents.executeJavaScript(expression)) return;
    await delay(100);
  }
  throw new Error('UI did not become ready: ' + expression);
}
module.exports = async ({planner, pet, file, tick, screen}) => {
  for (const win of [planner, pet]) {
    if (win.webContents.isLoading()) await new Promise((resolve, reject) => {win.webContents.once('did-finish-load', resolve); win.webContents.once('did-fail-load', (_e, code, text) => reject(new Error(`${code}: ${text}`)));});
    const isolated = await win.webContents.executeJavaScript("typeof require === 'undefined' && typeof process === 'undefined' && window.moonRabbit.platform === 'windows'");
    assert.equal(isolated, true);
    assert.equal(win.webContents.getLastWebPreferences().sandbox, true);
    await until(win, "document.querySelectorAll('.rabbit-pet img').length > 0 && [...document.querySelectorAll('.rabbit-pet img')].every(img => img.complete && img.naturalWidth > 0)");
  }
  await until(planner, "document.querySelector('h1')?.textContent.includes('달토끼')");
  await planner.webContents.executeJavaScript(`document.querySelector('#rename').click(); document.querySelector('#new-title').value = 'Windows 실제 테스트'; document.querySelector('#rename-form').requestSubmit(); document.querySelector('#add-task').click(); const input=document.querySelector('[data-field="title"]'); input.value='실제 일정 저장'; input.dispatchEvent(new Event('change',{bubbles:true}));`);
  await until(planner, "window.moonRabbit.loadShared().then(s => s.title === 'Windows 실제 테스트' && Object.values(s.days).some(d=>d.tasks.some(t=>t.title==='실제 일정 저장')))");
  planner.reload();
  await delay(300);
  await until(planner, "document.querySelector('h1')?.textContent === 'Windows 실제 테스트' && document.querySelector('[data-field=title]')?.value === '실제 일정 저장'");
  await planner.webContents.executeJavaScript("document.querySelector('[data-delete]').click()");
  await until(planner, "window.moonRabbit.loadShared().then(s => Object.values(s.days).every(d=>d.tasks.length===0))");
  await planner.webContents.executeJavaScript(`document.querySelector('[data-view="studio"]').click(); const project=document.querySelector('[data-studio-field="project"]'); project.value='Agent smoke'; project.dispatchEvent(new Event('input',{bubbles:true})); document.querySelector('[data-preview]').click();`);
  assert.equal(await planner.webContents.executeJavaScript("document.querySelector('#studio-prompt').value.includes('Agent smoke')"), true);
  await until(planner, "window.moonRabbit.loadShared().then(s=>s.studio?.project==='Agent smoke')");
  await planner.webContents.executeJavaScript("document.querySelector('#close-dialog').click(); document.querySelector('[data-view=week]').click()");
  assert.equal(await planner.webContents.executeJavaScript("document.querySelectorAll('[data-date]').length"), 7);
  assert.equal(JSON.parse(fs.readFileSync(file, 'utf8')).title, 'Windows 실제 테스트');
  assert.equal(pet.isAlwaysOnTop(), true);
  assert.equal(await planner.webContents.executeJavaScript('window.moonRabbit.setPetSize(280)'), 280);
  assert.ok(pet.getSize()[0] >= 280);
  assert.equal(await planner.webContents.executeJavaScript("window.moonRabbit.performAction('not-valid').then(() => false, () => true)"), true);
  assert.equal(await planner.webContents.executeJavaScript("window.moonRabbit.saveShared(null).then(() => false, () => true)"), true);
  assert.equal(await pet.webContents.executeJavaScript("window.moonRabbit.saveShared({}).then(() => false, () => true)"), true);
  assert.equal(await planner.webContents.executeJavaScript("window.moonRabbit.performAction({type:'message',text:'x'.repeat(1001)}).then(() => false, () => true)"), true);
  await planner.webContents.executeJavaScript("window.moonRabbit.performAction({type:'message',text:'서울 날씨 테스트',duration:3000,weather:true})");
  await until(pet, "document.querySelector('.bubble-message').textContent === '서울 날씨 테스트'");
  await pet.webContents.executeJavaScript('window.moonRabbit.setWander(true)');
  assert.equal(JSON.parse(fs.readFileSync(file, 'utf8')).wander, true);
  assert.equal(JSON.parse(fs.readFileSync(file, 'utf8')).title, 'Windows 실제 테스트');
  const before = pet.getBounds();
  for (let i = 0; i < 40; i++) tick();
  const after = pet.getBounds(), area = screen.getDisplayMatching(after).workArea;
  assert.ok(after.x !== before.x || after.y !== before.y, 'autonomous movement must change location');
  assert.ok(after.x >= area.x && after.y >= area.y);
  assert.ok(after.x + after.width <= area.x + area.width && after.y + after.height <= area.y + area.height);
  await pet.webContents.executeJavaScript('window.moonRabbit.setWander(false)');
  const stopped = pet.getBounds();
  tick();
  assert.deepEqual(pet.getBounds(), stopped);
  assert.deepEqual(planner.renderErrors, []);
  assert.deepEqual(pet.renderErrors, []);
  console.log('Electron smoke passed: real document/images, DOM rename/add/delete and reload persistence, two sandboxed windows, validated IPC/messages, size, autonomous movement, stop, bounds. Host:', process.platform);
};
