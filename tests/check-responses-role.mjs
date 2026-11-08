// node tests/check-responses-role.mjs path/to/pinned/open-sse
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { runInNewContext } from 'node:vm';
import { patchResponsesRole } from '../overrides/apply-responses-role.mjs';

const root = process.argv[2];
assert.ok(root, 'Supply the pinned upstream open-sse directory (not the stale local upstream checkout)');
const source = await readFile(resolve(root, 'translator/response/openai-responses.js'), 'utf8');
const chunkSource = await readFile(resolve(root, 'translator/concerns/chunk.js'), 'utf8');
const helpers = await readFile(resolve(root, 'utils/streamHelpers.js'), 'utf8');
const hasValuableContent = runInNewContext(
  helpers.replace(/^import .*;\r?\n/gm, '').replace(/^export /gm, '') + '\nhasValuableContent;',
  { FORMATS: { OPENAI: 'openai' }, TextEncoder });
const patched = patchResponsesRole(source);
assert.throws(() => patchResponsesRole(''), /exactly one/);
assert.throws(() => patchResponsesRole(patched), /exactly one|already applied/);

function load(text) {
  // Run the real translator and chunk builder; stub only unrelated imports.
  const context = {
    register() {}, FORMATS: {}, ROLE: { ASSISTANT: 'assistant' },
    RESPONSES_ITEM: { FUNCTION_CALL: 'function_call' },
    OPENAI_BLOCK: { FUNCTION: 'function' }, OPENAI_FINISH: { TOOL_CALLS: 'tool_calls', STOP: 'stop' },
    MODEL_FALLBACK: 'unknown',
    fallbackToolCallId: () => 'call_fallback',
    buildUsage: (usage) => usage,
    reasoningDelta: (text) => ({ reasoning_content: text }),
  };
  return runInNewContext(
    chunkSource.replace(/^export /gm, '') + '\n' +
    text.replace(/^import .*;\r?\n/gm, '').replace(/^export /gm, '') +
    '\nopenaiResponsesToOpenAIResponse;', context);
}
const added = (id, name) => ({ type: 'response.output_item.added', item: { type: 'function_call', id, call_id: `call_${id}`, name } });
const delta = (id, args) => ({ type: 'response.function_call_arguments.delta', item_id: id, delta: args });
const completed = { type: 'response.completed', response: {} };
const baseline = load(source);
const convert = load(patched);
assert.equal(baseline(added('a', 'weather'), {}).choices[0].delta.role, undefined);

for (const events of [
  [added('a', 'weather'), delta('a', '{"city":"Paris"}'), completed, null],
  [{ type: 'response.created' }, { type: 'response.reasoning_summary_text.delta', delta: 'Thinking' }, added('a', 'weather'), delta('a', '{}'), completed],
  [{ type: 'response.output_text.delta', delta: 'Hello' }, completed],
  [added('a', 'weather'), added('b', 'clock'), delta('b', '{}'), delta('a', '{}'), completed],
  [{ type: 'error', error: { message: 'Rejected' } }, null],
]) {
  const state = {};
  const beforeState = {};
  let count = 0;
  let defaultRole;
  for (const event of events) {
    const result = convert(event, state);
    const original = baseline(event, beforeState);
    assert.equal(Boolean(result), Boolean(original));
    if (!result) continue;
    assert.ok(hasValuableContent(result, 'openai'), 'The real stream filter must retain each translated chunk');
    const output = result.choices[0].delta;
    if (count++ === 0) assert.equal(output.role, 'assistant');
    else assert.equal(output.role, undefined, 'Only the first emitted delta needs a role');
    defaultRole = output.role ?? defaultRole;
    if (output.tool_calls) assert.equal(defaultRole, 'assistant', 'Role-sensitive clients must retain calls');
    // Apart from the role and time-generated metadata, preserve translator output.
    const { role, ...rest } = output;
    assert.equal(JSON.stringify(rest), JSON.stringify(original.choices[0].delta));
    assert.equal(result.choices[0].finish_reason, original.choices[0].finish_reason);
  }
  assert.ok(count > 0);
}
assert.ok(hasValuableContent({ choices: [{ delta: { role: 'assistant' } }] }, 'openai'),
  'The real stream filter must also retain role-only opening chunks');
const dockerfile = await readFile('Dockerfile', 'utf8');
assert.ok(dockerfile.indexOf('RUN node /opt/apply-responses-role.mjs') < dockerfile.indexOf('&& npm install && npm audit'));
console.log('Responses assistant-role regression checks OK');
