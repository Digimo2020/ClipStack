const MIN_ITEMS = 20;
const MAX_ITEMS = 200;

function clampLimit(value) {
  const number = Number.isFinite(Number(value)) ? Math.trunc(Number(value)) : 50;
  return Math.min(MAX_ITEMS, Math.max(MIN_ITEMS, number));
}

function sameContent(a, b) {
  if (!a || !b || a.kind !== b.kind) return false;
  return a.kind === 'text' ? a.text === b.text : a.imageHash === b.imageHash;
}

function addRecord(items, incoming, maxItems) {
  const previous = items.find((item) => sameContent(item, incoming));
  const next = { ...incoming, pinned: previous?.pinned ?? Boolean(incoming.pinned) };
  const ordered = [next, ...items.filter((item) => !sameContent(item, incoming))];
  let unpinned = 0;
  return ordered.filter((item) => item.pinned || ++unpinned <= clampLimit(maxItems));
}

function pruneRecords(items, maxItems) {
  let unpinned = 0;
  return items.filter((item) => item.pinned || ++unpinned <= clampLimit(maxItems));
}

module.exports = { MIN_ITEMS, MAX_ITEMS, clampLimit, sameContent, addRecord, pruneRecords };
