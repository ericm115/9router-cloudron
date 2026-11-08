#!/bin/bash
# Run inside the candidate image: docker run --rm -i --entrypoint /bin/bash IMAGE < tests/check-image.sh
set -euo pipefail
cd /app/code
[[ "$(node --version)" == v22.23.4 ]]
[[ "$(id -u cloudron):$(id -g cloudron)" == 1000:1000 ]]
for tool in git make g++ gcc npm npx; do
    if command -v "$tool" >/dev/null; then
        echo "Unexpected runtime build tool: $tool" >&2
        exit 1
    fi
done
for path in custom-server.js public .next/static src/mitm/server.js open-sse node_modules/sql.js/dist/sql-wasm.wasm; do
    test -e "$path"
done
test -s open-sse/rtk/ponytail.LICENSE
test ! -e .git
test ! -e .next/cache
test ! -e /root/.npm
test -x /opt/headroom/bin/headroom
/opt/headroom/bin/python -c 'import headroom, ssl'
node --input-type=module <<'JS'
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { loadRuntimeDep } from './open-sse/services/lazyRuntime.js';
import { PONYTAIL_VERSION, PONYTAIL_PROMPTS } from './open-sse/rtk/ponytailPrompt.js';
import { injectPonytail } from './open-sse/rtk/ponytail.js';
import { readFile } from 'node:fs/promises';
import { runInNewContext } from 'node:vm';
// Check the copied translator without loading the unbundled provider registry.
const translator = await readFile('./open-sse/translator/response/openai-responses.js', 'utf8');
const chunkBuilder = await readFile('./open-sse/translator/concerns/chunk.js', 'utf8');
const openaiResponsesToOpenAIResponse = runInNewContext(
    chunkBuilder.replace(/^export /gm, '') + '\n' +
    translator.replace(/^import .*;\r?\n/gm, '').replace(/^export /gm, '') +
    '\nopenaiResponsesToOpenAIResponse;', {
        register() {}, FORMATS: {}, ROLE: { ASSISTANT: 'assistant' },
        RESPONSES_ITEM: { FUNCTION_CALL: 'function_call' }, OPENAI_BLOCK: { FUNCTION: 'function' },
        OPENAI_FINISH: { TOOL_CALLS: 'tool_calls', STOP: 'stop' }, MODEL_FALLBACK: 'unknown',
    });
const roleState = {};
const toolStart = openaiResponsesToOpenAIResponse({
    type: 'response.output_item.added',
    item: { type: 'function_call', id: 'fc_test', call_id: 'call_test', name: 'get_weather' },
}, roleState);
assert.equal(toolStart.choices[0].delta.role, 'assistant');
assert.equal(toolStart.choices[0].delta.tool_calls[0].function.name, 'get_weather');
const toolEnd = openaiResponsesToOpenAIResponse({ type: 'response.completed', response: {} }, roleState);
assert.equal(toolEnd.choices[0].finish_reason, 'tool_calls');
assert.equal(toolEnd.choices[0].delta.role, undefined);
assert.equal(PONYTAIL_VERSION, '5.3.3');
for (const level of ['lite', 'full', 'ultra']) {
    const body = { messages: [{ role: 'user', content: 'test' }] };
    injectPonytail(body, 'openai', level);
    assert.equal(body.messages[0].content, PONYTAIL_PROMPTS[level]);
    injectPonytail(body, 'openai', level);
    assert.equal(body.messages.length, 2);
    assert.equal(body.messages[0].content, PONYTAIL_PROMPTS[level]);
}
assert.doesNotThrow(() => injectPonytail(null, 'openai', 'full'));
assert.doesNotThrow(() => injectPonytail(Object.freeze({}), 'openai', 'full'));
const invalidLevel = { messages: [] };
injectPonytail(invalidLevel, 'openai', 'invalid');
assert.deepEqual(invalidLevel.messages, []);
const require = createRequire(import.meta.url);
// Exercise the app's real loader without npm or a populated runtime fallback.
const wreq = await loadRuntimeDep('wreq-js');
assert.ok(wreq.getProfiles().length > 0); // Calls the native binding without network I/O.
const transport = await wreq.createTransport();
await transport.close();
const playwright = await loadRuntimeDep('playwright-core');
assert.equal(typeof playwright.chromium.launch, 'function');
for (const name of ['next', 'node-forge', 'sql.js', 'node-machine-id', 'wreq-js', 'playwright-core']) {
    assert.ok(require.resolve(name), name);
}
const Database = require('better-sqlite3');
const db = new Database(':memory:');
assert.equal(db.prepare('SELECT 1 AS ok').get().ok, 1);
db.close();
JS
printf 'Image packaging checks OK\n'
