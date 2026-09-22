// Offline desktop startup checks: node tests/native.mjs.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import vm from 'node:vm';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../apps/desktop/', import.meta.url));
for (const scenario of ['success', 'offline', 'cancel']) {
  const windows = [];
  let settle;
  class BrowserWindow extends EventEmitter {
    constructor(options) { super(); this.options = options; this.visible = options.show !== false; windows.push(this); }
    async loadFile(file, options) { assert(readFileSync(file).length); this.file = file; this.query = options?.query; }
    loadURL(url) { assert.equal(url, 'https://rainjack.heyitsmejosh.com/play.html'); return new Promise((resolve, reject) => { settle = scenario === 'offline' ? () => reject(Error('offline')) : resolve; }); }
    isDestroyed() { return !!this.destroyed; }
    isVisible() { return this.visible; }
    show() { this.visible = true; }
    close() { this.destroy(); }
    destroy() { this.destroyed = true; this.emit('closed'); }
  }
  let startup;
  const app = new EventEmitter();
  app.whenReady = () => ({ then: callback => { startup = callback(); } });
  app.quit = () => {};
  vm.runInNewContext(readFileSync(path.join(root, 'main.js'), 'utf8'), {
    __dirname: root,
    require: name => name === 'electron' ? { app, BrowserWindow } : path,
  });
  await new Promise(resolve => setImmediate(resolve));
  const [splash, game] = windows;
  assert.equal(game.isVisible(), false, 'game stays hidden during loading');
  for (const window of windows) {
    assert.equal(window.options.webPreferences.nodeIntegration, false);
    assert.equal(window.options.webPreferences.sandbox, true);
    assert(readFileSync(window.options.icon).length);
  }
  if (scenario === 'cancel') splash.close();
  settle();
  await startup;
  if (scenario === 'success') {
    assert(game.isVisible());
    assert(splash.isDestroyed());
  } else if (scenario === 'offline') {
    assert(game.isDestroyed());
    assert.equal(splash.query.error, '1');
    assert(!splash.isDestroyed());
  } else assert(game.isDestroyed());
  console.log('PASS desktop', scenario);
}
