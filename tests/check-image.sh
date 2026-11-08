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
test ! -e .git
test ! -e .next/cache
test ! -e /root/.npm
test -x /opt/headroom/bin/headroom
/opt/headroom/bin/python -c 'import headroom, ssl'
node --input-type=module <<'JS'
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { loadRuntimeDep } from './open-sse/services/lazyRuntime.js';
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
