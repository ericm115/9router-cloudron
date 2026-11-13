# 0.4.16 release state

## Scope and authority

User confirmed all named operations on 2026-11-13: build `9router-cloudron:0.4.16` from this project root; create only container `9router-cloudron-test`, port `20128:20128`, volume `9router-cloudron-test-data:/app/data`; remove only these owned resources after tests. Publish the tested image to `docker.io/emoralesjw/9router:0.4.16`; commit intended update files including existing `RELEASE_0.4.15.md` documentation and push `origin main` (`https://github.com/ericm115/9router-cloudron.git`), including catalog. Preserve existing source/image/catalog visibility. No live Cloudron deployment authorized.

## Source and design

Package 0.4.16 selects upstream tag v0.5.119, verified via tags API and `git ls-remote` to `1855aa44473e88feac9d3f131b9c0c5fc9706b68`. Upstream package.json still says 0.5.116. Dockerfile explicitly separates selected `UPSTREAM_VERSION=0.5.119` from verified `UPSTREAM_PACKAGE_VERSION=0.5.116`, preserving exact commit and manifest checks. Upstream manifest is not rewritten; dashboard may still report 0.5.116.

Preserve assistant-role patch, Ponytail v5.3.3, lint dependency override, Headroom, OIDC, MITM, multi-stage runtime and pinned Node. No database migration files appeared in upstream comparison; no production data/upgrade or live LibreChat test is claimed.

## Evidence and blocker

Passed before freeze: metadata/version checks, semantic preservation of every historical catalog entry against HEAD, start.sh LF, `node tests/check-responses-role.mjs upstream/release-0.4.16-check/open-sse` using exact selected upstream source files, `node tests/check-ponytail.mjs`, `python -B tests/check-health-test.py` (3 tests), `bash -n start.sh tests/check-image.sh`, `node --check overrides/apply-responses-role.mjs`, and `git diff --check`.

Independent source review and focused catalog/runbook follow-up cleared the packaging changes with no blocking code/catalog findings. The low-severity stale-state note was corrected before freeze. Docker was initially unavailable; user started it and `docker info` reports server 29.9.2. Named test container and volume are absent. `docker manifest inspect docker.io/emoralesjw/9router:0.4.16` returned no such manifest. No build, commit, push or deployment has occurred at this source checkpoint.

One run-scoped ignored source-check set exists at `upstream/release-0.4.16-check`; retain for evidence/resumption, do not accumulate duplicates. Test container and volume were not created. Previous release runtime config digest is `sha256:0618457c43cec6d46d7a41371e40929f064f73f291431d8a38ab236e15a53745`, size 2863484658 bytes; preserve previous registry image/catalog.

## Next actions / approved execution order

Working directory: project root. Stop on required failures. Do not overwrite a differing registry tag. Do not remove existing resources of unknown ownership. Docker Desktop is now running.

1. Integrate independent review, inspect final intended diff/status/history and secrets; run affected checks. Commit intended source with normal hooks and freeze exact source commit before building.
2. Confirm named test container and volume absent and registry tag absent. Record frozen commit.
3. `docker build --tag 9router-cloudron:0.4.16 .` (production build includes npm audit and lint-dependency check).
4. `docker image inspect 9router-cloudron:0.4.16 --format '{{.Id}} {{.Size}} {{.Architecture}}'`; `docker history 9router-cloudron:0.4.16`; compare size with previous release.
5. `docker volume create 9router-cloudron-test-data`
6. `MSYS_NO_PATHCONV=1 docker run --detach --name 9router-cloudron-test --publish 20128:20128 --volume 9router-cloudron-test-data:/app/data 9router-cloudron:0.4.16`
7. `MSYS_NO_PATHCONV=1 docker exec -i 9router-cloudron-test /bin/bash < tests/check-image.sh`
8. `MSYS_NO_PATHCONV=1 docker exec -i 9router-cloudron-test /opt/headroom/bin/python - < tests/check-health.py` (requires both HTTP 200).
9. Record exact tested image ID, architecture, size, build/audit and health evidence. Only then publisher may tag that exact ID with `docker tag IMAGE_ID docker.io/emoralesjw/9router:0.4.16` and `docker push docker.io/emoralesjw/9router:0.4.16`.
10. Verify registry digest; pull by digest and compare image ID. Push frozen source with `git push origin main`. Fetch raw public catalog and compare full content/history.
11. Remove only this run's named test resources: `docker rm --force 9router-cloudron-test`, `docker volume rm 9router-cloudron-test-data`. Record completed effects and final status.

Publisher must receive exact frozen commit and tested immutable image ID plus check/review evidence before execution; never rebuild or repair source during publication. No live deployment. Production update requires separately authorized named target and backup/recovery prerequisites; image rollback does not restore data.
