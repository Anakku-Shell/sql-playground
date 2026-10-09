import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, writeFileSync, unlinkSync, mkdtempSync, mkdirSync } from 'node:fs';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { SLUGS, LANGS, parseGuide, renderAll, writeFiles, checkFiles } from './split-guide.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (name) => readFileSync(path.join(ROOT, name), 'utf8');

// Section titles of the real English guide, reused so synthetic guides pass
// the title checks.
const REAL_TITLES = parseGuide(read('sql-guide.md'), 'sql-guide.md').sections.map((s) => s.title);

// Minimal guide with the same shape as the real ones: intro, `count` sections,
// a group H1 before section 14 and a cheat sheet as the last heading.
function makeGuide({ count = 25, extra = {} } = {}) {
  const lines = ['# Title', '', '## How to read this guide', '', '1. First · 🟢', '', '---', ''];
  for (let i = 1; i <= count; i++) {
    if (i === 14) lines.push('# Going further', '', '---', '');
    const title = i === count ? 'Cheat sheet' : REAL_TITLES[i - 1] ?? `${i}. Section ${i}`;
    lines.push(`## ${extra[i]?.title ?? title}`, '', `Body of ${i}.`, '', '### Sub', '', 'More.');
    if (extra[i]?.body) lines.push(...extra[i].body);
    lines.push('', '---', '');
  }
  return lines.join('\n');
}

// Non-empty lines that are not headings or separators, in order.
const contentLines = (text) =>
  text.split('\n').filter((l) => l.trim() && !/^#{1,6} /.test(l) && l !== '---');

test('splits the real English guide into 25 sections with fixed slugs', () => {
  const { sections } = parseGuide(read('sql-guide.md'), 'sql-guide.md');
  assert.equal(sections.length, 25);
  assert.deepEqual(sections.map((s) => s.slug), SLUGS);
  assert.ok(sections[6].title.startsWith('7. JOINs'));
  assert.equal(sections[24].title, 'Cheat sheet');
});

test('splits the real Spanish guide with the same slugs', () => {
  const { sections } = parseGuide(read('sql-guide-es.md'), 'sql-guide-es.md');
  assert.deepEqual(sections.map((s) => s.slug), SLUGS);
  assert.equal(sections[24].title, 'Chuleta final');
});

test('ignores headings inside code fences', () => {
  const guide = makeGuide({ extra: { 3: { body: ['', '```', '## not a heading', '# nor this', '```'] } } });
  const { sections } = parseGuide(guide, 'x.md');
  assert.equal(sections.length, 25);
  assert.match(sections[2].body, /\n## not a heading\n/);
});

test('throws when section count is wrong', () => {
  assert.throws(() => parseGuide(makeGuide({ count: 26 }), 'x.md'), /Expected 25 sections in x\.md, found 26/);
});

test('slugs depend on position, not title', () => {
  const guide = makeGuide({ extra: { 7: { title: '7. Joining tables · 🟡' } } });
  const { sections } = parseGuide(guide, 'x.md');
  assert.equal(sections[6].slug, '07-joins');
  assert.equal(sections[6].title, '7. Joining tables · 🟡');
});

test('promotes headings one level outside fences only', () => {
  const { sections } = parseGuide(read('sql-guide.md'), 'sql-guide.md');
  const joins = sections[6].body;
  assert.ok(joins.startsWith('# 7. JOINs'));
  assert.match(joins, /^## INNER JOIN/m);
  assert.doesNotMatch(joins, /^### /m);

  const guide = makeGuide({ extra: { 3: { body: ['', '```', '## kept', '```'] } } });
  assert.match(parseGuide(guide, 'x.md').sections[2].body, /```\n## kept\n```/);
});

test('keeps every non-heading line of the original section in order', () => {
  for (const name of ['sql-guide.md', 'sql-guide-es.md']) {
    const text = read(name).replaceAll('\r\n', '\n');
    const { sections } = parseGuide(text, name);
    const starts = sections.map((s) => text.indexOf(`\n## ${s.title}\n`));
    sections.forEach((s, i) => {
      const slice = text.slice(starts[i], starts[i + 1] ?? text.length)
        .split('\n').filter((l) => l !== '# Going further' && l !== '# Ampliación').join('\n');
      assert.deepEqual(contentLines(s.body), contentLines(slice), `${name} ${s.slug}`);
    });
  }
});

test('normalizes CRLF input', () => {
  const text = read('sql-guide.md').replaceAll('\r\n', '\n');
  assert.deepEqual(parseGuide(text.replaceAll('\n', '\r\n'), 'x.md'), parseGuide(text, 'x.md'));
});

test('drops group H1 lines', () => {
  for (const name of ['sql-guide.md', 'sql-guide-es.md']) {
    for (const s of parseGuide(read(name), name).sections) {
      assert.doesNotMatch(s.body, /^# (Going further|Ampliación)$/m, `${name} ${s.slug}`);
    }
  }
});

const guides = () => ({ en: read('sql-guide.md'), es: read('sql-guide-es.md') });

test('renders 26 files per language', () => {
  const files = renderAll(guides());
  assert.equal(files.size, 52);
  assert.ok(files.has('sections/en/README.md'));
  assert.ok(files.has('sections/es/25-cheat-sheet.md'));
});

test('section file starts with generated header and has nav at top and bottom', () => {
  const joins = renderAll(guides()).get('sections/en/07-joins.md');
  assert.ok(joins.startsWith('<!-- Generated by scripts/split-guide.mjs from sql-guide.md. Do not edit by hand. -->'));
  for (const link of ['](06-group-by.md)', '[Index](README.md)', '](08-subqueries.md)', '](../es/07-joins.md)']) {
    assert.equal(joins.split(link).length - 1, 2, link);
  }
  assert.match(joins, /^# 7\. JOINs/m);
});

test('first and last sections omit missing prev/next', () => {
  const files = renderAll(guides());
  assert.ok(!files.get('sections/en/01-ddl.md').includes('←'));
  assert.ok(!files.get('sections/es/25-cheat-sheet.md').includes('→'));
});

test('index links every numbered section', () => {
  const index = renderAll(guides()).get('sections/es/README.md');
  assert.ok(index.includes('7. [JOINs · 🟡 ⭐⭐⭐](07-joins.md)'));
  assert.ok(index.includes('24. [Ejercicios con solución · 🟢🟡🔴](24-exercises.md)'));
  assert.ok(index.includes('](25-cheat-sheet.md)'));
  assert.ok(index.includes('](../en/README.md)'));
});

test('every relative link resolves', () => {
  const files = renderAll(guides());
  for (const [file, content] of files) {
    for (const [, target] of content.matchAll(/\]\(([^)\s]+)\)/g)) {
      if (/^(https?:|#)/.test(target)) continue;
      const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(file), target));
      assert.ok(files.has(resolved) || existsSync(path.join(ROOT, resolved)), `${file} → ${target}`);
    }
  }
});

test('output is identical for CRLF and LF input', () => {
  const lf = { en: guides().en.replaceAll('\r\n', '\n'), es: guides().es.replaceAll('\r\n', '\n') };
  const crlf = { en: lf.en.replaceAll('\n', '\r\n'), es: lf.es.replaceAll('\n', '\r\n') };
  assert.deepEqual(renderAll(crlf), renderAll(lf));
});

const tmpRoot = () => mkdtempSync(path.join(os.tmpdir(), 'split-guide-'));

test('check passes right after write', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  assert.deepEqual(checkFiles(files, root), { stale: [], missing: [], extra: [] });
});

test('check reports stale file', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  writeFileSync(path.join(root, 'sections/en/07-joins.md'), 'edited by hand\n');
  assert.deepEqual(checkFiles(files, root).stale, ['sections/en/07-joins.md']);
});

test('check reports missing file', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  unlinkSync(path.join(root, 'sections/es/03-select.md'));
  assert.deepEqual(checkFiles(files, root).missing, ['sections/es/03-select.md']);
});

test('check reports extra files', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  writeFileSync(path.join(root, 'sections/en/99-old.md'), 'old\n');
  assert.deepEqual(checkFiles(files, root).extra, ['sections/en/99-old.md']);
});

test('build removes extra files', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  writeFileSync(path.join(root, 'sections/en/99-old.md'), 'old\n');
  const { removed } = writeFiles(files, root);
  assert.deepEqual(removed, ['sections/en/99-old.md']);
  assert.ok(!existsSync(path.join(root, 'sections/en/99-old.md')));
});

test('check ignores CRLF differences', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  const file = path.join(root, 'sections/en/07-joins.md');
  writeFileSync(file, readFileSync(file, 'utf8').replaceAll('\n', '\r\n'));
  assert.deepEqual(checkFiles(files, root).stale, []);
});

test('index does not link to itself', () => {
  const files = renderAll(guides());
  assert.ok(!files.get('sections/en/README.md').includes('one file per section'));
  assert.ok(!files.get('sections/es/README.md').includes('un fichero por sección'));
});

test('throws when sections were reordered', () => {
  const swapped = makeGuide({ extra: { 17: { title: REAL_TITLES[17] }, 18: { title: REAL_TITLES[16] } } });
  assert.throws(() => parseGuide(swapped, 'x.md'), /Section 17 in x.md is "18. UPSERT.*", which doesn't look like 17-window-functions/);
});

test('accepts the real titles in both languages', () => {
  for (const name of ['sql-guide.md', 'sql-guide-es.md']) {
    assert.doesNotThrow(() => parseGuide(read(name), name), name);
  }
});

test('throws on an unexpected H1 inside a section', () => {
  const guide = makeGuide({ extra: { 5: { body: ['', '# Stray heading'] } } });
  assert.throws(() => parseGuide(guide, 'x.md'), /Unexpected H1 "# Stray heading" in x.md, section 5/);
});

test('index only links numbered lines that carry level tags', () => {
  const en = read('sql-guide.md').replace(/## How to read this guide\r?\n/, '## How to read this guide\n\n1. Read the core first\n');
  const index = renderAll({ en, es: read('sql-guide-es.md') }).get('sections/en/README.md');
  assert.match(index, /^1\. Read the core first$/m);
  assert.match(index, /^1\. \[Creating and altering tables/m);
});

test('section pages point to the example tables, except exercises and cheat sheet', () => {
  const files = renderAll(guides());
  assert.match(files.get('sections/en/07-joins.md'), /Examples use the `customers` and `orders` tables described in the \[index\]\(README\.md\)/);
  assert.match(files.get('sections/es/07-joins.md'), /Los ejemplos usan las tablas `clientes` y `pedidos` descritas en el \[índice\]\(README\.md\)/);
  assert.doesNotMatch(files.get('sections/en/24-exercises.md'), /Examples use the/);
  assert.doesNotMatch(files.get('sections/en/25-cheat-sheet.md'), /Examples use the/);
});

test('cheat sheet link follows the last table of contents entry', () => {
  for (const lang of ['en', 'es']) {
    const lines = renderAll(guides()).get(`sections/${lang}/README.md`).split('\n');
    const last = lines.findIndex((l) => l.startsWith('24. ['));
    assert.match(lines[last + 2], /^\[.+\]\(25-cheat-sheet\.md\)$/, lang);
    assert.equal(lines.filter((l) => l.includes('](25-cheat-sheet.md)')).length, 1, lang);
  }
});

test('check reports extra files of any type and unknown folders', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  writeFileSync(path.join(root, 'sections/en/img.png'), 'x');
  mkdirSync(path.join(root, 'sections/en/old'));
  mkdirSync(path.join(root, 'sections/fr'));
  assert.deepEqual(checkFiles(files, root).extra, ['sections/en/img.png', 'sections/en/old/', 'sections/fr/']);
});

test('build removes extra files but only reports folders', () => {
  const root = tmpRoot();
  const files = renderAll(guides());
  writeFiles(files, root);
  writeFileSync(path.join(root, 'sections/en/img.png'), 'x');
  mkdirSync(path.join(root, 'sections/fr'));
  const { removed, kept } = writeFiles(files, root);
  assert.deepEqual(removed, ['sections/en/img.png']);
  assert.deepEqual(kept, ['sections/fr/']);
  assert.ok(existsSync(path.join(root, 'sections/fr')));
});
