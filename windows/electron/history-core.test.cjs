const test = require('node:test');
const assert = require('node:assert/strict');
const { clampLimit, addRecord, pruneRecords } = require('./history-core.cjs');

test('history limit stays between 20 and 200', () => {
  assert.equal(clampLimit(1), 20);
  assert.equal(clampLimit(500), 200);
  assert.equal(clampLimit('80'), 80);
});

test('duplicate copies move to the top and retain their pin', () => {
  const old = { id: 'old', kind: 'text', text: 'hello', pinned: true };
  const next = { id: 'new', kind: 'text', text: 'hello', pinned: false };
  const result = addRecord([old], next, 50);
  assert.equal(result.length, 1);
  assert.equal(result[0].id, 'new');
  assert.equal(result[0].pinned, true);
});

test('pruning preserves pins while limiting unpinned records', () => {
  const records = Array.from({ length: 25 }, (_, i) => ({ id: String(i), pinned: i === 24 }));
  const result = pruneRecords(records, 20);
  assert.equal(result.length, 21);
  assert.equal(result.at(-1).id, '24');
});
