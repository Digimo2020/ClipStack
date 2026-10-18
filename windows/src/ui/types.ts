export type ClipItem = {
  id: string;
  kind: 'text' | 'image';
  text?: string;
  imageData?: string;
  imageSize?: string;
  imageHash?: string;
  imageFile?: string;
  date: string;
  pinned: boolean;
};

export type ClipSettings = {
  maxItems: number;
  isPaused: boolean;
  shortcut: string;
  launchAtLogin: boolean;
};

export type AppState = {
  items: ClipItem[];
  settings: ClipSettings;
  shortcuts: string[];
  minItems: number;
  maxItemsCap: number;
};

export type ClipStackAPI = {
  getState: () => Promise<AppState>;
  onState: (callback: (state: AppState) => void) => () => void;
  togglePin: (id: string) => Promise<void>;
  deleteItem: (id: string) => Promise<void>;
  copyItem: (id: string) => Promise<boolean>;
  setSetting: (key: keyof ClipSettings, value: string | number | boolean) => Promise<{ok: boolean; error?: string}>;
  clearUnpinned: () => Promise<void>;
  showWindow: () => Promise<void>;
};

declare global {
  interface Window { clipStack?: ClipStackAPI }
}
