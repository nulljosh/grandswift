// Windows / Linux / Mac desktop shell around the web build.
const { app, BrowserWindow } = require("electron");
app.whenReady().then(() => {
  const w = new BrowserWindow({ width: 1280, height: 800, fullscreen: true, autoHideMenuBar: true, backgroundColor: "#111111", title: "Rainjack" });
  w.loadURL("https://rainjack.heyitsmejosh.com/play.html");
});
app.on("window-all-closed", () => app.quit());
