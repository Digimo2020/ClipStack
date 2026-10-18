const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('clipStack', {
  getState: () => ipcRenderer.invoke('get-state'),
  onState: (callback) => {
    const listener = (_, state) => callback(state);
    ipcRenderer.on('state', listener);
    return () => ipcRenderer.removeListener('state', listener);
  },
  togglePin: (id) => ipcRenderer.invoke('toggle-pin', id),
  deleteItem: (id) => ipcRenderer.invoke('delete-item', id),
  copyItem: (id) => ipcRenderer.invoke('copy-item', id),
  setSetting: (key, value) => ipcRenderer.invoke('set-setting', key, value),
  clearUnpinned: () => ipcRenderer.invoke('clear-unpinned'),
  showWindow: () => ipcRenderer.invoke('show-window'),
});
