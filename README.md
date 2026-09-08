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
5. Headroom starts automatically on `127.0.0.1:8787` and is enabled in Token Saver settings

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
| Upstream version | 0.5.69 |
| License | MIT |
| Port | 20128 |
| Data | `/app/data` (SQLite, backed up) |
| Memory | 1 GB |

## Publishing

To publish as a Cloudron community app:

1. Update `CloudronVersions.json` with your git URL
2. Submit via `cloudron appstore submit`

See [Cloudron publishing docs](https://docs.cloudron.io/packaging/publishing/) for details.
