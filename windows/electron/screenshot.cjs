// Captures the React renderer's sample preview only. This harness has no preload
// and never reads the operating system clipboard.
const { app, BrowserWindow } = require('electron');
const fs = require('node:fs');
const path = require('node:path');

app.whenReady().then(async () => {
  const window = new BrowserWindow({ width: 500, height: 650, show: true, backgroundColor: '#11111b' });
  await window.loadURL('http://127.0.0.1:5173/?preview=1');
  await new Promise((resolve) => setTimeout(resolve, 800));
  const cardCount = await window.webContents.executeJavaScript('document.querySelectorAll(".clip-card").length');
  if (cardCount !== 4) throw new Error(`Expected four sample history cards, found ${cardCount}`);
  const screenshotDir = path.join(__dirname, '..', '..', 'docs');
  fs.mkdirSync(screenshotDir, { recursive: true });
  const history = await window.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotDir, 'windows-history.png'), history.toPNG());
  await window.webContents.executeJavaScript('document.querySelector(".icon-button").click()');
  await new Promise((resolve) => setTimeout(resolve, 250));
  const settings = await window.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotDir, 'windows-settings.png'), settings.toPNG());
  app.quit();
});
