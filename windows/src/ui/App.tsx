import { useEffect, useMemo, useState } from 'react';
import { AlignLeft, ArrowDownUp, Check, ChevronDown, Clipboard, Copy, Image as ImageIcon, Link2, Pause, Play, Search, Settings, Star, Trash2, X } from 'lucide-react';
import type { AppState, ClipItem } from './types';

const previewItems: ClipItem[] = [
  { id: '1', kind: 'text', text: 'Welcome to ClipStack — your clipboard history, ready when you are.', date: new Date(Date.now() - 40_000).toISOString(), pinned: true },
  { id: '2', kind: 'text', text: 'https://github.com/Digimo2020/ClipStack', date: new Date(Date.now() - 3 * 60_000).toISOString(), pinned: false },
  { id: '3', kind: 'text', text: 'Windows shortcut: Ctrl + Shift + V', date: new Date(Date.now() - 8 * 60_000).toISOString(), pinned: false },
  { id: '4', kind: 'image', imageData: `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 320"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#493a83"/><stop offset="1" stop-color="#b779e8"/></linearGradient></defs><rect width="640" height="320" fill="url(#g)"/><circle cx="500" cy="85" r="54" fill="#f4d3a0"/><path d="M0 250 150 130l128 116 108-100 254 174H0Z" fill="#282541"/><path d="m0 280 170-92 126 74 120-68 224 96v30H0Z" fill="#171625"/></svg>')}`, imageSize: '640 × 320', date: new Date(Date.now() - 19 * 60_000).toISOString(), pinned: false },
];

const previewState: AppState = { items: previewItems, settings: { maxItems: 50, isPaused: false, shortcut: 'Control+Shift+V', launchAtLogin: false }, shortcuts: ['Control+Shift+V', 'Control+Alt+V', 'Alt+V'], minItems: 20, maxItemsCap: 200 };
const previewMode = new URLSearchParams(location.search).has('preview');
const previewApi = {
  getState: async () => previewState,
  onState: () => () => undefined,
  togglePin: async () => undefined,
  deleteItem: async () => undefined,
  copyItem: async () => true,
  setSetting: async () => ({ ok: true, error: undefined }),
  clearUnpinned: async () => undefined,
  showWindow: async () => undefined,
};
const api: NonNullable<Window['clipStack']> | undefined = window.clipStack ?? (previewMode ? previewApi as NonNullable<Window['clipStack']> : undefined);

function readableShortcut(value: string) {
  return value.replaceAll('Control', 'Ctrl').replaceAll('+', ' + ');
}

function timeAgo(date: string) {
  const minutes = Math.max(0, Math.floor((Date.now() - new Date(date).getTime()) / 60_000));
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h ago` : `${Math.floor(hours / 24)}d ago`;
}

export default function App() {
  const [state, setState] = useState<AppState>(previewMode ? previewState : { ...previewState, items: [] });
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState('All');
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [notice, setNotice] = useState('');
  const [selected, setSelected] = useState(0);

  useEffect(() => {
    if (!api) return;
    api.getState().then(setState);
    return api.onState(setState);
  }, []);

  const visibleItems = useMemo(() => state.items.filter((item) => {
    const matchesFilter = filter === 'All' || (filter === 'Text' && item.kind === 'text') || (filter === 'Images' && item.kind === 'image') || (filter === 'Links' && item.kind === 'text' && /^https?:\/\//i.test(item.text ?? '')) || (filter === 'Pinned' && item.pinned);
    return matchesFilter && (!query || (item.text ?? '').toLowerCase().includes(query.toLowerCase()));
  }), [filter, query, state.items]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') { if (settingsOpen) setSettingsOpen(false); return; }
      if (settingsOpen || !visibleItems.length || ['INPUT', 'SELECT', 'TEXTAREA'].includes((event.target as HTMLElement)?.tagName)) return;
      if (event.key === 'ArrowDown') { event.preventDefault(); setSelected((index) => Math.min(index + 1, visibleItems.length - 1)); }
      if (event.key === 'ArrowUp') { event.preventDefault(); setSelected((index) => Math.max(index - 1, 0)); }
      if (event.key === 'Enter') { event.preventDefault(); void api?.copyItem(visibleItems[selected]?.id); }
      if (event.key.toLowerCase() === 'f' && (event.ctrlKey || event.metaKey)) { event.preventDefault(); document.querySelector<HTMLInputElement>('.search-wrap input')?.focus(); }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [selected, settingsOpen, visibleItems]);

  async function setSetting(key: 'maxItems' | 'isPaused' | 'shortcut' | 'launchAtLogin', value: string | number | boolean) {
    const result = await api?.setSetting(key, value);
    if (result && !result.ok) { setNotice(result.error ?? 'Could not save this setting.'); setTimeout(() => setNotice(''), 3000); }
  }

  return <main className="app-shell">
    <header className="topbar">
      <div className="brand-mark"><Clipboard size={19} strokeWidth={2.3} /></div>
      <div className="brand-copy"><strong>ClipStack</strong><span>Your clipboard, remembered.</span></div>
      <div className="top-actions">
        <span className={`capture-state ${state.settings.isPaused ? 'paused' : ''}`}><i />{state.settings.isPaused ? 'Paused' : 'Recording'}</span>
        <button className="icon-button" title="Settings" aria-label="Settings" onClick={() => setSettingsOpen(!settingsOpen)}><Settings size={18} /></button>
      </div>
    </header>

    {settingsOpen ? <section className="settings-view">
      <div className="section-heading"><div><span className="eyebrow">PREFERENCES</span><h1>Settings</h1></div><button className="icon-button" onClick={() => setSettingsOpen(false)} aria-label="Close settings"><X size={18} /></button></div>
      <div className="setting-card">
        <label htmlFor="shortcut">Open history shortcut</label>
        <span className="field-note">Choose a shortcut that is free in other apps.</span>
        <div className="select-wrap"><select id="shortcut" value={state.settings.shortcut} onChange={(event) => void setSetting('shortcut', event.target.value)}>{state.shortcuts.map((key) => <option value={key} key={key}>{readableShortcut(key)}</option>)}</select><ChevronDown size={15} /></div>
      </div>
      <div className="setting-card">
        <div className="setting-row"><div><label htmlFor="limit">History size</label><span className="field-note">Keep up to {state.settings.maxItems} unpinned items.</span></div><strong className="value-chip">{state.settings.maxItems}</strong></div>
        <input id="limit" type="range" min={state.minItems} max={state.maxItemsCap} step="10" value={state.settings.maxItems} onChange={(event) => void setSetting('maxItems', Number(event.target.value))} />
      </div>
      <button className="setting-card setting-row action-card" onClick={() => void setSetting('isPaused', !state.settings.isPaused)}><div><strong className="setting-name">{state.settings.isPaused ? 'Resume capturing' : 'Pause capturing'}</strong><span className="field-note">Control whether new clipboard items are saved.</span></div>{state.settings.isPaused ? <Play size={18} /> : <Pause size={18} />}</button>
      <button className="setting-card setting-row action-card" onClick={() => void setSetting('launchAtLogin', !state.settings.launchAtLogin)}><div><strong className="setting-name">Launch at sign in</strong><span className="field-note">Start ClipStack when you sign in to Windows.</span></div><span className={`switch ${state.settings.launchAtLogin ? 'on' : ''}`}><i /></span></button>
      <div className="settings-footer"><span>History stays on this PC.</span><button className="text-danger" onClick={() => void api?.clearUnpinned()}>Clear unpinned items</button></div>
    </section> : <>
      <div className="search-wrap"><Search size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search your clipboard" aria-label="Search clipboard history" /><kbd>Ctrl F</kbd></div>
      <nav className="filters" aria-label="History filters">{['All', 'Text', 'Images', 'Links', 'Pinned'].map((item) => <button key={item} className={filter === item ? 'selected' : ''} onClick={() => setFilter(item)}>{item}</button>)}</nav>
      <section className="history-head"><span>{filter === 'All' ? 'RECENT COPIES' : filter.toUpperCase()}</span><span>{visibleItems.length} <ArrowDownUp size={13} /></span></section>
      <section className="history-list">
        {visibleItems.map((item, index) => <article className={`clip-card ${selected === index ? 'keyboard-selected' : ''}`} key={item.id} onMouseEnter={() => setSelected(index)}>
          <button className="clip-main" onClick={() => void api?.copyItem(item.id)} title="Copy item to clipboard">
            <div className={`clip-icon ${item.kind}`}>{item.kind === 'image' ? <ImageIcon size={18} /> : /^https?:\/\//i.test(item.text ?? '') ? <Link2 size={18} /> : <AlignLeft size={18} />}</div>
            <div className="clip-content">{item.imageData ? <img className="clip-image" src={item.imageData} alt="Copied image" /> : <span className="clip-text">{item.text}</span>}<span className="clip-meta">{item.kind === 'image' ? item.imageSize ?? 'Image' : 'Text'} <i /> {timeAgo(item.date)}</span></div>
          </button>
          <div className="clip-actions"><button title="Copy" aria-label="Copy" onClick={() => void api?.copyItem(item.id)}><Copy size={15} /></button><button className={item.pinned ? 'pinned' : ''} title={item.pinned ? 'Unpin' : 'Pin'} aria-label={item.pinned ? 'Unpin' : 'Pin'} onClick={() => void api?.togglePin(item.id)}><Star size={15} fill={item.pinned ? 'currentColor' : 'none'} /></button><button className="delete-button" title="Delete" aria-label="Delete" onClick={() => void api?.deleteItem(item.id)}><Trash2 size={15} /></button></div>
        </article>)}
        {!visibleItems.length && <div className="empty-state"><div className="empty-icon"><Clipboard size={22} /></div><strong>{state.items.length ? 'No matching copies' : 'Your history starts here'}</strong><span>{state.items.length ? 'Try another search or filter.' : 'Copy text or an image and it will show up here.'}</span></div>}
      </section>
      <footer className="bottom-bar"><span><kbd>{readableShortcut(state.settings.shortcut)}</kbd><span>Open history</span></span><span><kbd>Enter</kbd><span>Copy item</span></span><span><kbd>Esc</kbd><span>Close</span></span><span className="private-label"><Check size={13} /> Local only</span></footer>
    </>}
    {notice && <div className="toast"><X size={14} />{notice}</div>}
  </main>;
}
