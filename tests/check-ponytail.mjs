// node tests/check-ponytail.mjs [path/to/open-sse/rtk/ponytailPrompt.js]
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const path = resolve(process.argv[2] || 'overrides/ponytailPrompt.js');
const { PONYTAIL_VERSION, PONYTAIL_LEVELS, PONYTAIL_PROMPTS } = await import(pathToFileURL(path));
assert.equal(PONYTAIL_VERSION, '5.3.3');
assert.deepEqual(Object.values(PONYTAIL_LEVELS), ['lite', 'full', 'ultra']);
assert.deepEqual(Object.keys(PONYTAIL_PROMPTS), Object.values(PONYTAIL_LEVELS));
for (const [level, prompt] of Object.entries(PONYTAIL_PROMPTS)) {
  for (const rule of [
    'List every place your change must reach: callers, tests, fixtures, config, exports.',
    'Already in this codebase',
    'A house component beats a native widget.',
    'grep every caller',
    'keeps its error handling and validation',
    'one small test or an assert-based self-check',
    'shortcut: <the limit>, <when to upgrade>',
    'security, accessibility',
    'what you skipped or did not check',
    'chat commands do not change those settings',
    `Level: ${level}.`,
  ]) assert.ok(prompt.includes(rule), `${level}: missing ${rule}`);
  assert.ok(!prompt.includes('/ponytail'), 'No unsupported session command');
  assert.ok(!prompt.includes('at most three short lines'), 'No obsolete output cap');
  assert.ok(!prompt.includes('Ship the one-liner'), 'No obsolete ultra instruction');
}
assert.ok(PONYTAIL_PROMPTS.ultra.includes('before building, push back'));
assert.ok(PONYTAIL_PROMPTS.lite.includes('let the user pick'));
const dockerfile = await readFile('Dockerfile', 'utf8');
const copy = dockerfile.indexOf('COPY overrides/ponytailPrompt.js overrides/ponytail.LICENSE /app/code/open-sse/rtk/');
assert.ok(copy >= 0 && copy < dockerfile.indexOf('&& npm install && npm audit'));
console.log('Ponytail prompt and build wiring checks OK');
