import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, existsSync, mkdirSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

// Runs the guide's SQL against MySQL and PostgreSQL (docker-compose.yml) and
// compares the output with the reviewed snapshots in verify/expected/.
// Cases live in verify/cases/; the exercises are taken straight from the guides.

const GUIDES = ['sql-guide.md', 'sql-guide-es.md'];
const ENGINES = ['mysql', 'postgres'];

export const normalize = (text) =>
  text.replaceAll('\r\n', '\n').split('\n').map((l) => l.trimEnd()).join('\n').trimEnd();

// The ```sql blocks of section N ("## N. ...") of a guide, in order.
export function extractSqlBlocks(markdown, section) {
  const text = markdown.replaceAll('\r\n', '\n');
  const start = text.search(new RegExp(`^## ${section}\\. `, 'm'));
  if (start < 0) throw new Error(`Section ${section} not found`);
  const next = text.slice(start + 3).search(/^## /m);
  const body = next < 0 ? text.slice(start) : text.slice(start, start + 3 + next);
  return [...body.matchAll(/^```sql\n([\s\S]*?)^```/gm)].map((m) => m[1]);
}

// Fingerprint of the SQL a case covers, so a snapshot knows when the guide moved on.
export function guideHash(guides, sections) {
  const hash = createHash('sha256');
  for (const guide of guides) {
    for (const section of sections) hash.update(extractSqlBlocks(guide, section).join('\0'));
  }
  return hash.digest('hex').slice(0, 12);
}

export function readCaseSections(sql) {
  const match = sql.match(/^-- guide-sections: ([\d, ]+)$/m);
  if (!match) throw new Error('Case files must have a "-- guide-sections: N[, N...]" line');
  return match[1].split(',').map((n) => Number(n.trim()));
}

export function caseEngines(fileName) {
  const engine = ENGINES.find((e) => fileName.endsWith(`.${e}.sql`));
  return engine ? [engine] : [...ENGINES];
}

// Section 24 of a guide as one script: the data setup, then each solution
// preceded by a marker row so the output shows which exercise it belongs to.
export function exerciseCase(markdown) {
  const [setup, ...solutions] = extractSqlBlocks(markdown, 24);
  const parts = solutions.map((sql, i) => `SELECT 'EXERCISE ${i + 1}' AS exercise;\n${sql}`);
  return ['-- guide-sections: 24', setup, ...parts].join('\n');
}

export const formatSnapshot = ({ hash, stdout, stderr }) =>
  `# guide-sql-hash: ${hash}\n${normalize(stdout)}\n--- stderr ---\n${normalize(stderr)}\n`;

export function parseSnapshot(text) {
  const normalized = text.replaceAll('\r\n', '\n');
  const firstLine = normalized.slice(0, normalized.indexOf('\n'));
  return { hash: firstLine.replace('# guide-sql-hash: ', ''), body: normalized.slice(firstLine.length + 1) };
}

// --- Talking to the databases (docker compose) ---------------------------------

function compose(root, args, input) {
  const result = spawnSync('docker', ['compose', ...args], { cwd: root, input, encoding: 'utf8' });
  if (result.error) throw result.error;
  return result;
}

const CLIENTS = {
  mysql: (db) => ['exec', '-T', '-e', 'MYSQL_PWD=playground', 'mysql', 'mysql', '-uroot', db, '--table', '--force'],
  postgres: (db) => ['exec', '-T', '-e', 'PGOPTIONS=-c client_min_messages=warning',
    'postgres', 'psql', '-U', 'postgres', '-d', db, '-X', '-q', '-P', 'pager=off', '-v', 'ON_ERROR_STOP=0'],
};

// Each case runs in a fresh "verify" database.
function resetDatabase(root, engine) {
  const sql = engine === 'mysql'
    ? 'DROP DATABASE IF EXISTS verify; CREATE DATABASE verify;'
    : 'DROP DATABASE IF EXISTS verify WITH (FORCE);\nCREATE DATABASE verify;';
  const result = compose(root, CLIENTS[engine](engine === 'mysql' ? 'playground' : 'postgres'), sql);
  if (result.status !== 0) throw new Error(`Could not reset the ${engine} database:\n${result.stderr}`);
}

function runSql(root, engine, db, sql) {
  const { stdout, stderr } = compose(root, CLIENTS[engine](db), sql);
  return { stdout, stderr };
}

function requireDatabases(root) {
  const running = compose(root, ['ps', '--status', 'running', '--services']).stdout.split('\n');
  const missing = ENGINES.filter((e) => !running.includes(e));
  if (missing.length) throw new Error(`Not running: ${missing.join(', ')}. Start them with: npm run db:up`);
}

// --- CLI -------------------------------------------------------------------------

function loadCases(root, guides) {
  const dir = path.join(root, 'verify', 'cases');
  const cases = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort().map((file) => {
    const sql = readFileSync(path.join(dir, file), 'utf8');
    const name = file.replace(/(\.(mysql|postgres))?\.sql$/, '');
    return { name, file: `verify/cases/${file}`, sql, engines: caseEngines(file), sections: readCaseSections(sql) };
  });
  GUIDES.forEach((guide, i) => {
    const lang = i === 0 ? 'en' : 'es';
    cases.push({ name: `24-exercises-${lang}`, file: `${guide} (section 24)`, sql: exerciseCase(guides[i]),
      engines: [...ENGINES], sections: [24] });
  });
  return cases;
}

function firstDifference(expected, actual) {
  const a = expected.split('\n');
  const b = actual.split('\n');
  const i = a.findIndex((line, n) => line !== b[n]);
  const at = i < 0 ? a.length : i;
  return `line ${at + 1}:\n      expected: ${a[at] ?? '(end)'}\n      actual:   ${b[at] ?? '(end)'}`;
}

function verify(root, { update }) {
  requireDatabases(root);
  const guides = GUIDES.map((g) => readFileSync(path.join(root, g), 'utf8'));
  const expectedDir = path.join(root, 'verify', 'expected');
  mkdirSync(expectedDir, { recursive: true });
  const problems = [];

  for (const c of loadCases(root, guides)) {
    const hash = guideHash(guides, c.sections);
    for (const engine of c.engines) {
      resetDatabase(root, engine);
      const actual = formatSnapshot({ hash, ...runSql(root, engine, 'verify', c.sql) });
      const snapshotFile = path.join(expectedDir, `${c.name}.${engine}.txt`);
      const label = `${c.name} (${engine})`;

      if (update) {
        writeFileSync(snapshotFile, actual);
        console.log(`updated  ${label}`);
        continue;
      }
      if (!existsSync(snapshotFile)) {
        problems.push(`${label}: no snapshot yet. Review the output, then run: npm run verify:sql -- --update`);
        continue;
      }
      const expected = parseSnapshot(readFileSync(snapshotFile, 'utf8'));
      const current = parseSnapshot(actual);
      if (expected.body !== current.body) {
        problems.push(`${label}: output changed at ${firstDifference(expected.body, current.body)}`);
      } else if (expected.hash !== current.hash) {
        problems.push(`${label}: the guide's SQL for section ${c.sections.join(', ')} changed. ` +
          `Check that ${c.file} still matches it, then run: npm run verify:sql -- --update`);
      } else {
        console.log(`ok       ${label}`);
      }
    }
  }

  if (problems.length) {
    console.error(`\n${problems.length} problem(s):\n- ${problems.join('\n- ')}`);
    process.exit(1);
  }
  if (!update) console.log('\nAll SQL output matches the snapshots.');
}

// Loads the example tables of section 24 (both languages) into the
// "playground" database of both engines, for practice.
function load(root) {
  requireDatabases(root);
  const setup = GUIDES.map((g) => extractSqlBlocks(readFileSync(path.join(root, g), 'utf8'), 24)[0]).join('\n');
  for (const engine of ENGINES) {
    const { stderr } = runSql(root, engine, 'playground', setup);
    if (/ERROR/.test(stderr)) throw new Error(`Loading data into ${engine} failed:\n${stderr}`);
    console.log(`Loaded customers/orders and clientes/pedidos into ${engine} (database "playground")`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const args = process.argv.slice(2);
  try {
    if (args.includes('--load')) load(root);
    else verify(root, { update: args.includes('--update') });
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
