import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import {
  extractSqlBlocks, guideHash, readCaseSections, caseEngines,
  exerciseCase, formatSnapshot, parseSnapshot, normalize,
} from './verify-sql.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (name) => readFileSync(path.join(ROOT, name), 'utf8');

const GUIDE = [
  '# Guide', '', '## 1. One · 🟢', '', '```sql', 'SELECT 1;', '```', '', 'Text.', '',
  '```', 'not sql', '```', '', '```sql', 'SELECT 2;', '```', '',
  '## 2. Two · 🟢', '', '```sql', 'SELECT 3;', '```', '',
].join('\n');

test('extracts only the sql blocks of the requested section', () => {
  assert.deepEqual(extractSqlBlocks(GUIDE, 1), ['SELECT 1;\n', 'SELECT 2;\n']);
  assert.deepEqual(extractSqlBlocks(GUIDE, 2), ['SELECT 3;\n']);
});

test('extracts the same blocks from CRLF input', () => {
  assert.deepEqual(extractSqlBlocks(GUIDE.replaceAll('\n', '\r\n'), 1), extractSqlBlocks(GUIDE, 1));
});

test('throws for a section that does not exist', () => {
  assert.throws(() => extractSqlBlocks(GUIDE, 9), /Section 9 not found/);
});

test('guide hash changes only when the sections it covers change', () => {
  const edited = GUIDE.replace('SELECT 3;', 'SELECT 33;');
  assert.equal(guideHash([GUIDE], [1]), guideHash([edited], [1]));
  assert.notEqual(guideHash([GUIDE], [2]), guideHash([edited], [2]));
  assert.match(guideHash([GUIDE], [1]), /^[0-9a-f]{12}$/);
});

test('reads the guide sections a case covers from its header', () => {
  assert.deepEqual(readCaseSections('-- guide-sections: 7\nSELECT 1;'), [7]);
  assert.deepEqual(readCaseSections('-- Joins\n-- guide-sections: 8, 9, 12\n'), [8, 9, 12]);
  assert.throws(() => readCaseSections('SELECT 1;'), /guide-sections/);
});

test('picks engines from the case file name', () => {
  assert.deepEqual(caseEngines('07-joins.sql'), ['mysql', 'postgres']);
  assert.deepEqual(caseEngines('13-procedures.mysql.sql'), ['mysql']);
  assert.deepEqual(caseEngines('13-procedures.postgres.sql'), ['postgres']);
});

test('builds the exercises case from the real guides', () => {
  for (const name of ['sql-guide.md', 'sql-guide-es.md']) {
    const sql = exerciseCase(read(name));
    assert.match(sql, /^-- guide-sections: 24\n/);
    assert.match(sql, /DROP TABLE IF EXISTS/);
    assert.equal(sql.match(/^SELECT 'EXERCISE \d+' AS exercise;$/gm).length, 13, name);
  }
});

test('snapshot round-trips hash and output', () => {
  const text = formatSnapshot({ hash: 'abc123abc123', stdout: 'rows\n', stderr: 'ERROR x\n' });
  assert.deepEqual(parseSnapshot(text), { hash: 'abc123abc123', body: text.slice(text.indexOf('\n') + 1) });
  assert.match(text, /^# guide-sql-hash: abc123abc123\n/);
  assert.match(text, /\n--- stderr ---\nERROR x\n$/);
});

test('normalize ignores CRLF and trailing spaces', () => {
  assert.equal(normalize('a  \r\nb\t\r\n\r\n'), 'a\nb');
});
