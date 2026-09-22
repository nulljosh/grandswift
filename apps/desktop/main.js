// Desktop shell with a local splash while the hosted game loads.
const { app, BrowserWindow } = require('electron');
const path = require('node:path');
app.whenReady().then(async () => {
  const icon = path.join(__dirname, 'assets/icon.png');
  const splash = new BrowserWindow({ width: 400, height: 300, frame: false, resizable: false, backgroundColor: '#111111', title: 'Vancouver Vice', icon, webPreferences: { sandbox: true, contextIsolation: true, nodeIntegration: false } });
  await splash.loadFile(path.join(__dirname, 'splash.html'));
  const game = new BrowserWindow({ width: 1280, height: 800, fullscreen: true, show: false, autoHideMenuBar: true, backgroundColor: '#111111', title: 'Vancouver Vice', icon, webPreferences: { sandbox: true, contextIsolation: true, nodeIntegration: false } });
  // Closing the splash cancels startup, including a stalled network request.
  splash.on('closed', () => { if (!game.isDestroyed() && !game.isVisible()) game.destroy(); });
  try {
    await game.loadURL('https://vancouvervice.heyitsmejosh.com/play.html');
    if (game.isDestroyed()) return;
    game.show();
    splash.close();
  } catch {
    if (!game.isDestroyed()) game.destroy();
    if (!splash.isDestroyed()) await splash.loadFile(path.join(__dirname, 'splash.html'), { query: { error: '1' } });
  }
});
app.on('window-all-closed', () => app.quit());
