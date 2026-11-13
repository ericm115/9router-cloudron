# 0.4.15 release state

## Scope and authority

User confirmed on 2026-11-08: build `9router-cloudron:0.4.15` from this project; use only test container `9router-cloudron-test`, port `20128:20128`, volume `9router-cloudron-test-data:/app/data`; remove these resources after checks. Publish the tested image to `docker.io/emoralesjw/9router:0.4.15`; commit intended files and push `origin main` (`https://github.com/ericm115/9router-cloudron.git`). Keep existing source/image/catalog visibility. No live Cloudron deployment authorized.

Upstream remains 0.5.116, commit `1339107e624d1ab150c6a0c2c2ee22caa7e9db2f`. Scope is the Responses-to-Chat assistant-role override, not the separate DONE proposal. Previous local image 0.4.14: `sha256:05c22510e6c6713b05c42ff9b892753f481fd66bd4c0f78112455b9312bfe0b0`, 2863485521 bytes. Preserve the previous release and all catalog history.

## Evidence and limits

Source regression checks passed against the pinned translator and real stream filter. Ponytail check, JS/shell syntax, JSON metadata/history checks and diff check passed. Node host 24.13.0; image uses 22.23.4. Independent source review found no remaining blockers after focused test updates. Image runtime checks and live LibreChat behavior are separate. Both local services and the image check passed before publication. On 2026-11-08, after release, the user reported that LibreChat tool calls were working. This is user-confirmed production behavior, not an independently observed deployment or live test.

## Investigation and resolution

- Reported setup: LibreChat 0.8.8 on Cloudron, custom `/v1` endpoint, model aliases routed through 9Router's Codex provider. Tool requests appeared to hang; other clients worked.
- Meilisearch logs showed successful indexing, not a tool execution failure. Disabling Ponytail did not resolve the issue.
- LibreChat's browser event capture finalized with empty assistant text/content and no tool events. The `aux1` request was the actual chat request, not necessarily background title generation.
- A direct request through the public 9Router endpoint returned a tool-call ID/name, valid argument fragments, and `finish_reason: "tool_calls"`. It lacked both an assistant-role declaration and the terminal `[DONE]` marker. No credentials or private conversation payloads are retained here.
- Upstream issue https://github.com/decolua/9router/issues/4356 and PR https://github.com/decolua/9router/pull/4437 discuss missing `[DONE]`. At review on 2026-11-08, the PR was open and unmerged. Its format selection used the provider format rather than the client format; isolated checks showed incorrect behavior on other routes. It was not applied.
- LibreChat v0.8.8's lockfile selects `@librechat/agents` 4.0.1, nested `@langchain/openai` 1.5.8 and `openai` 6.49.0. The OpenAI stream reader accepts clean EOF without `[DONE]`. The LangChain converter retains tool calls only when the current or remembered role is assistant. An isolated check of the actual converter confirmed that a roleless first tool delta loses tool-call fields.
- Fix: `overrides/apply-responses-role.mjs` patches only `openaiResponsesToOpenAIResponse` before Next builds. It declares `role: "assistant"` on the first returned delta per stream. Existing argument fragments, finish reasons and other translators remain unchanged. The patch rejects a missing/duplicate entry point or repeat application. The stream filter retains the role-bearing chunk.
- Different clients can tolerate a missing role or use a different API path. That explains why other clients could work; their individual implementations were not traced.

Sources retrieved 2026-11-08:
- https://github.com/danny-avila/LibreChat/blob/v0.8.8/package-lock.json
- https://unpkg.com/@langchain/openai@1.5.8/dist/converters/completions.js
- https://unpkg.com/openai@6.49.0/core/streaming.js

## Build failures and corrections

The initial production build passed, but the new image check directly imported the translator, loading the unbundled provider registry and failing on missing `uuid`. The corrected check evaluates the copied translator and chunk builder with unrelated imports stubbed; no runtime dependency was added. This verifies the copied translator, not the full HTTP model route.

The initial Headroom probe failed with connection refused. A diagnostic run showed successful startup and HTTP 200 after initialization. `tests/check-health.py` now waits up to 90 seconds per service and requires HTTP 200 without following redirects. Three unit checks cover delayed startup, timeout and redirect refusal. No change to `start.sh` was needed.

## Completed release and verification

- Source commits pushed to `origin main`: `65bd1f1b762f1a8f5d9b9423e264cc1643169453` (role fix/release) and `7f6dc41de8d45668130e213c597135b52ebd6b15` (check corrections).
- Published image: `docker.io/emoralesjw/9router:0.4.15`.
- Tested and published manifest-list digest: `sha256:14f2e9713d6f11c13cfb95b84e6ac011e6ee9e3f94ec809dcebcf26e78802742`. Pulled by digest after push and compared with the tested local image identity.
- Runtime config digest: `sha256:0618457c43cec6d46d7a41371e40929f064f73f291431d8a38ab236e15a53745`; architecture amd64. Final image size 2863484658 bytes, 863 bytes smaller than 0.4.14. History inspected.
- Production build passed; npm audit reported zero vulnerabilities. Cached rebuild retained the same runtime config; attestation changed the manifest-list digest, so exact-artifact image/health checks were repeated on the final identity above.
- Passed: `node tests/check-responses-role.mjs PATH_TO_PINNED_OPEN_SSE`, `node tests/check-ponytail.mjs`, JS/shell syntax, `python -B tests/check-health-test.py`, JSON/version/catalog-history consistency, and `git diff --check`.
- Final candidate: `tests/check-image.sh` passed; `tests/check-health.py` reported HTTP 200 from both 9Router `/api/health` and Headroom `/health`.
- Independent review cleared source, release metadata and check corrections. The runtime image check emitted a non-fatal upstream module-type warning.
- Docker Hub tag was absent before publication. The public raw catalog was fetched after source push and matched the local catalog, including all historical entries: https://raw.githubusercontent.com/ericm115/9router-cloudron/main/CloudronVersions.json
- Only the authorized test container and volume were created and removed. No live Cloudron deployment was performed by the assistant. The user subsequently reported the fix working on 2026-11-08; exact deployed digest and deployment procedure were not independently checked.

Changed release paths: `Dockerfile`, `CloudronManifest.json`, `CloudronVersions.json`, `CHANGELOG`, `README.md`, `overrides/apply-responses-role.mjs`, `tests/check-responses-role.mjs`, `tests/check-image.sh`, `tests/check-health.py`, `tests/check-health-test.py`, and this record. Ponytail and Headroom behavior were preserved. The separate `[DONE]` issue remains outside this fix.

## Execution order

Working directory: project root. Stop on failed required commands. Do not overwrite an existing differing registry tag. Confirm test resources absent before creation. Source must be committed/frozen before build. Record the resulting commit and image ID/digest in the release handoff, not in a self-referential commit.

1. `docker build --tag 9router-cloudron:0.4.15 .`
2. `docker image inspect 9router-cloudron:0.4.15 --format '{{.Id}} {{.Size}}'`
3. `docker history 9router-cloudron:0.4.15`
4. `docker volume create 9router-cloudron-test-data`
5. `MSYS_NO_PATHCONV=1 docker run --detach --name 9router-cloudron-test --publish 20128:20128 --volume 9router-cloudron-test-data:/app/data 9router-cloudron:0.4.15`
6. After service startup, `MSYS_NO_PATHCONV=1 docker exec -i 9router-cloudron-test /bin/bash < tests/check-image.sh`
7. `MSYS_NO_PATHCONV=1 docker exec -i 9router-cloudron-test /opt/headroom/bin/python - < tests/check-health.py` (waits up to 90 seconds per service and requires HTTP 200).
8. Confirm both health results passed; stop publication on failure.
9. After checks, remove only owned test resources: `docker rm --force 9router-cloudron-test`, then `docker volume rm 9router-cloudron-test-data`.
10. Only after exact-image verification, tag that image ID as `docker.io/emoralesjw/9router:0.4.15` and push. Do not rebuild in publication.
11. Push frozen reviewed source with `git push origin main`. Verify the raw catalog URL and registry digest; pull by digest and compare local image ID.

On failure preserve useful diagnostics and report completed effects. No automatic deployment. Production update requires separate named-target authority and backup/recovery prerequisites. A package rollback does not restore persistent data.
