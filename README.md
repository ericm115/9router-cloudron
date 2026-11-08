# 9Router — Cloudron App

> Updated fork of [vRobM/9router-cloudron](https://github.com/vRobM/9router-cloudron), originally packaged by Robi. Maintained here by [ericm115](https://github.com/ericm115).
>
> This fork updates the upstream 9Router release, bundles Headroom, enables Headroom by default, and raises the memory limit. It is not the original package.

Cloudron community package for [9Router](https://github.com/decolua/9router), a free open-source AI router and token saver for coding tools.

## What is 9Router?

9Router acts as a smart proxy between AI coding tools (Claude Code, Codex, Cursor, Cline, Copilot, etc.) and 40+ AI providers. Key features:

- **RTK Token Saver** — auto-compresses tool_result content to save 20-40% of tokens
- **Headroom Token Saver** — local proxy compression for additional context savings
- **3-tier fallback** — Subscription → Cheap → Free
- **Multi-account round-robin** with quota tracking
- **MITM proxy** for transparent tool routing
- **OpenAI-compatible API** — drop-in replacement for any tool

## After Installation

1. Open the dashboard at `https://<your-domain>/dashboard`
2. Default password: `123456` — change it immediately
3. Add your AI provider API keys in Providers
4. Point your coding tools to `https://<your-domain>/v1`
5. Headroom starts automatically on `127.0.0.1:8787`, includes code-aware compression, and stores its persistent data under `/app/data/headroom`

## Installation on Cloudron

```bash
cloudron install
```

Or build locally first:

```bash
cloudron build
cloudron install
```

## Packaging Details

| Component | Detail |
|-----------|--------|
| Upstream | https://github.com/decolua/9router |
| Upstream version | 0.5.116 (commit `1339107e624d1ab150c6a0c2c2ee22caa7e9db2f`) |
| Base image | Official Node 22.23.4, Debian bookworm-slim (linux/amd64) |
| License | MIT |
| Port | 20128 |
| Data | `/app/data` (SQLite, backed up) |
| Memory | 2 GB |

## Ponytail

This package replaces 9Router's older embedded prompt with an adaptation of
[Ponytail v5.3.3](https://github.com/DietrichGebert/ponytail/tree/v5.3.3)
(commit `7801d061243d7b753bad0e0b3c057cd250b11755`). The tracked override in
`overrides/ponytailPrompt.js` is applied before the upstream build. Its MIT notice
is included alongside the runtime module.

Lite/Full/Ultra and the existing dashboard toggle remain unchanged. Session commands
are replaced with 9Router settings guidance: use the dashboard to disable it, or
send `x-9router-token-saver: off` to bypass all token savers for one request.
This is prompt-only integration, not the official plugin's hooks, commands or task board.

Run `node tests/check-ponytail.mjs` for the source regression check.

## LibreChat tool-call compatibility

`overrides/apply-responses-role.mjs` patches the pinned upstream Responses-to-Chat
translator before Next builds. The first emitted delta declares the assistant
role, so role-sensitive clients such as LibreChat can retain tool calls. Other
translators and stream termination are unchanged. The build stops if the patch
entry point is missing or the patch is already applied.

Run `node tests/check-responses-role.mjs PATH_TO_PINNED_OPEN_SSE` against the
`open-sse` directory from `UPSTREAM_COMMIT` in the Dockerfile. The local
`upstream/` checkout can be older and is not a build input. The check covers
text, reasoning, parallel tool calls, errors, and duplicate patch rejection.
A live LibreChat tool-call check is still required to confirm the fix for a deployed instance.

Package 0.4.14 also overrides only the lint tooling's transitive `minimatch` to
11.0.1 for [GHSA-g3hv-75wg-m249](https://github.com/advisories/GHSA-g3hv-75wg-m249).
The build runs `npm audit --audit-level=moderate` before compiling; upstream
9Router remains pinned to 0.5.116.

## Build policy

Prefer multi-stage Docker builds. Keep compilers, source checkouts, package caches and build intermediates out of the final runtime image; preserve upstream's explicit runtime assets and lazy dependencies.

Before publishing, compare `docker image inspect IMAGE --format '{{.Size}}'` and `docker history IMAGE` with the previous release. In the named test container, run `MSYS_NO_PATHCONV=1 docker exec -i 9router-cloudron-test /bin/bash < tests/check-image.sh` from Git Bash, then verify both 9Router and Headroom health endpoints return HTTP 200.

## Publishing

To publish as a Cloudron community app:

1. Update `CloudronVersions.json` with your git URL
2. Submit via `cloudron appstore submit`

See [Cloudron publishing docs](https://docs.cloudron.io/packaging/publishing/) for details.
