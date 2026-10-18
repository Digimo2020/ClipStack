const { app, BrowserWindow, clipboard, globalShortcut, ipcMain, nativeImage, screen, Tray, Menu } = require('electron');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { MIN_ITEMS, MAX_ITEMS, clampLimit, addRecord, pruneRecords } = require('./history-core.cjs');

app.setName('ClipStack');
const hasSingleInstanceLock = app.requestSingleInstanceLock();
const SHORTCUTS = ['Control+Shift+V', 'Control+Alt+V', 'Alt+V'];
const DEFAULT_SETTINGS = { maxItems: 50, isPaused: false, shortcut: SHORTCUTS[0], launchAtLogin: false };
let win;
let tray;
let pollTimer;
let history = [];
let settings = { ...DEFAULT_SETTINGS };
let lastClipboardFingerprint = '';
let settingsPath;
let historyPath;
let imagesPath;

function readJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return fallback; }
}

function saveJson(file, value) {
  const temp = `${file}.tmp`;
  fs.writeFileSync(temp, JSON.stringify(value, null, 2));
  fs.renameSync(temp, file);
}

function publishState() {
  if (win && !win.isDestroyed()) win.webContents.send('state', getState());
  if (tray) {
    tray.setToolTip(`ClipStack · ${history.length} saved items`);
    tray.setContextMenu(Menu.buildFromTemplate([
      { label: 'Open ClipStack', click: showWindow },
      { label: 'Pause capturing', type: 'checkbox', checked: settings.isPaused, click: (menuItem) => { settings.isPaused = menuItem.checked; persist(); } },
      { type: 'separator' },
      { label: 'Quit ClipStack', click: () => { app.isQuitting = true; app.quit(); } },
    ]));
  }
}

function getState() {
  const items = history.map((item) => {
    let imageData;
    if (item.imageFile) {
      const file = path.join(imagesPath, path.basename(item.imageFile));
      if (fs.existsSync(file)) {
        const preview = nativeImage.createFromPath(file).resize({ width: 440, height: 280, quality: 'good' }).toPNG();
        imageData = `data:image/png;base64,${preview.toString('base64')}`;
      }
    }
    return { ...item, imageData };
  });
  return { items, settings, shortcuts: SHORTCUTS, minItems: MIN_ITEMS, maxItemsCap: MAX_ITEMS };
}

function persist() {
  saveJson(historyPath, history);
  saveJson(settingsPath, settings);
  const usedImages = new Set(history.map((item) => item.imageFile).filter(Boolean));
  for (const file of fs.readdirSync(imagesPath)) {
    if (!usedImages.has(file)) { try { fs.unlinkSync(path.join(imagesPath, file)); } catch { /* the file may already be gone */ } }
  }
  publishState();
}

function makeWindow() {
  win = new BrowserWindow({
    width: 500, height: 650, minWidth: 430, minHeight: 500,
    show: false, title: 'ClipStack', backgroundColor: '#11111b',
    autoHideMenuBar: true,
    webPreferences: { preload: path.join(__dirname, 'preload.cjs'), contextIsolation: true, nodeIntegration: false, sandbox: true },
  });
  if (app.isPackaged) win.loadFile(path.join(__dirname, '..', 'renderer-dist', 'index.html'));
  else win.loadURL('http://127.0.0.1:5173');
  win.on('close', (event) => { if (!app.isQuitting) { event.preventDefault(); win.hide(); } });
  win.webContents.on('before-input-event', (event, input) => {
    if (input.key === 'Escape' && input.type === 'keyDown') win.hide();
  });
}

function showWindow() {
  if (!win) makeWindow();
  const point = screen.getCursorScreenPoint();
  const display = screen.getDisplayNearestPoint(point);
  const [width, height] = win.getSize();
  const x = Math.min(display.workArea.x + display.workArea.width - width - 20, Math.max(display.workArea.x + 20, point.x - width / 2));
  const y = Math.min(display.workArea.y + display.workArea.height - height - 20, Math.max(display.workArea.y + 20, point.y - 24));
  win.setPosition(x, y);
  win.show();
  win.focus();
}

function registerShortcut(value) {
  const previous = settings.shortcut;
  globalShortcut.unregisterAll();
  const shortcut = SHORTCUTS.includes(value) ? value : SHORTCUTS[0];
  const ok = globalShortcut.register(shortcut, () => win?.isVisible() ? win.hide() : showWindow());
  if (!ok) {
    if (previous && previous !== shortcut) globalShortcut.register(previous, () => win?.isVisible() ? win.hide() : showWindow());
    return false;
  }
  settings.shortcut = shortcut;
  return true;
}

function fingerprint(text, image) {
  return crypto.createHash('sha256').update(text || '').update(image || Buffer.alloc(0)).digest('hex');
}

function readClipboardSnapshot() {
  const formats = clipboard.availableFormats().map((value) => value.toLowerCase());
  const text = clipboard.readText();
  const image = clipboard.readImage();
  const png = image.isEmpty() ? null : image.toPNG();
  return { text, image, png, hash: fingerprint(text, png), excluded: formats.some((value) => value.includes('excludeclipboardcontentfrommonitorprocessing')) };
}

function captureClipboard() {
  const snapshot = readClipboardSnapshot();
  if (snapshot.hash === lastClipboardFingerprint) return;
  lastClipboardFingerprint = snapshot.hash;
  if (settings.isPaused || snapshot.excluded) return;
  const { text, image, png } = snapshot;
  if ((!text || !text.trim()) && !png) return;
  const item = { id: crypto.randomUUID(), kind: text?.trim() ? 'text' : 'image', text: text?.trim() ? text : undefined,
    imageHash: png ? crypto.createHash('sha256').update(png).digest('hex') : undefined, date: new Date().toISOString(), pinned: false };
  if (png && item.kind === 'image') {
    const imageFile = `${item.id}.png`;
    fs.writeFileSync(path.join(imagesPath, imageFile), png);
    item.imageFile = imageFile;
    item.imageSize = `${image.getSize().width} × ${image.getSize().height}`;
  }
  history = addRecord(history, item, settings.maxItems);
  persist();
}

function deleteImageIfUnused(item) {
  if (!item?.imageFile || history.some((other) => other.imageFile === item.imageFile)) return;
  try { fs.unlinkSync(path.join(imagesPath, path.basename(item.imageFile))); } catch { /* stale files are harmless */ }
}

function initializeTray() {
  const iconPath = app.isPackaged
    ? path.join(process.resourcesPath, 'app-icon.png')
    : path.join(__dirname, '..', 'assets', 'app-icon.png');
  const icon = fs.existsSync(iconPath) ? nativeImage.createFromPath(iconPath) : nativeImage.createEmpty();
  tray = new Tray(icon);
  tray.setToolTip('ClipStack');
  publishState();
  tray.on('click', () => win?.isVisible() ? win.hide() : showWindow());
}

function registerIpc() {
  ipcMain.handle('get-state', () => getState());
  ipcMain.handle('toggle-pin', (_, id) => { const item = history.find((entry) => entry.id === id); if (item) item.pinned = !item.pinned; history = pruneRecords(history, settings.maxItems); persist(); return true; });
  ipcMain.handle('delete-item', (_, id) => { const item = history.find((entry) => entry.id === id); history = history.filter((entry) => entry.id !== id); deleteImageIfUnused(item); persist(); });
  ipcMain.handle('copy-item', (_, id) => {
    const item = history.find((entry) => entry.id === id);
    if (!item) return false;
    if (item.kind === 'text') clipboard.writeText(item.text || '');
    else if (item.imageFile) clipboard.writeImage(nativeImage.createFromPath(path.join(imagesPath, path.basename(item.imageFile))));
    lastClipboardFingerprint = readClipboardSnapshot().hash;
    history = history.filter((entry) => entry.id !== item.id);
    item.date = new Date().toISOString();
    history.unshift(item);
    persist();
    win?.hide();
    return true;
  });
  ipcMain.handle('set-setting', (_, key, value) => {
    if (key === 'maxItems') settings.maxItems = clampLimit(value);
    else if (key === 'isPaused' || key === 'launchAtLogin') settings[key] = Boolean(value);
    else if (key === 'shortcut') {
      if (!SHORTCUTS.includes(value) || !registerShortcut(value)) return { ok: false, error: 'That shortcut is already in use by another app.' };
    }
    history = pruneRecords(history, settings.maxItems);
    if (key === 'launchAtLogin') app.setLoginItemSettings({ openAtLogin: settings.launchAtLogin });
    persist();
    return { ok: true };
  });
  ipcMain.handle('clear-unpinned', () => {
    const removed = history.filter((item) => !item.pinned);
    history = history.filter((item) => item.pinned);
    removed.forEach(deleteImageIfUnused);
    persist();
  });
  ipcMain.handle('show-window', showWindow);
}

if (!hasSingleInstanceLock) {
  app.quit();
} else {
  app.on('second-instance', showWindow);
  app.whenReady().then(() => {
  const directory = app.getPath('userData');
  settingsPath = path.join(directory, 'settings.json');
  historyPath = path.join(directory, 'history.json');
  imagesPath = path.join(directory, 'images');
  fs.mkdirSync(imagesPath, { recursive: true });
  settings = { ...DEFAULT_SETTINGS, ...readJson(settingsPath, {}) };
  const loginSettings = app.getLoginItemSettings();
  if (typeof loginSettings.openAtLogin === 'boolean') settings.launchAtLogin = loginSettings.openAtLogin;
  settings.maxItems = clampLimit(settings.maxItems);
  if (!SHORTCUTS.includes(settings.shortcut)) settings.shortcut = DEFAULT_SETTINGS.shortcut;
  const savedItems = readJson(historyPath, []);
  history = (Array.isArray(savedItems) ? savedItems : []).filter((item) => item && item.id && ['text', 'image'].includes(item.kind));
  history = pruneRecords(history, settings.maxItems);
  makeWindow();
  initializeTray();
  registerIpc();
  registerShortcut(settings.shortcut);
  persist();
  lastClipboardFingerprint = readClipboardSnapshot().hash;
  pollTimer = setInterval(captureClipboard, 650);
  if (process.argv.includes('--show')) showWindow();
  });
}

app.on('will-quit', () => { clearInterval(pollTimer); globalShortcut.unregisterAll(); });
app.on('activate', showWindow);
