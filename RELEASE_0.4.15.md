# 0.4.15 release state

## Scope and authority

User confirmed on 2026-11-08: build `9router-cloudron:0.4.15` from this project; use only test container `9router-cloudron-test`, port `20128:20128`, volume `9router-cloudron-test-data:/app/data`; remove these resources after checks. Publish the tested image to `docker.io/emoralesjw/9router:0.4.15`; commit intended files and push `origin main` (`https://github.com/ericm115/9router-cloudron.git`). Keep existing source/image/catalog visibility. No live Cloudron deployment authorized.

Upstream remains 0.5.116, commit `1339107e624d1ab150c6a0c2c2ee22caa7e9db2f`. Scope is the Responses-to-Chat assistant-role override, not the separate DONE proposal. Previous local image 0.4.14: `sha256:05c22510e6c6713b05c42ff9b892753f481fd66bd4c0f78112455b9312bfe0b0`, 2863485521 bytes. Preserve the previous release and all catalog history.

## Evidence and limits

Source regression checks passed against the pinned translator and real stream filter. Ponytail check, JS/shell syntax, JSON metadata/history checks and diff check passed. Node host 24.13.0; image uses 22.23.4. Independent source review found no remaining blockers after focused test updates. Image runtime checks and live LibreChat behavior are separate: no live LibreChat instance is available here, so the release is a source-supported compatibility correction, not confirmed production resolution.

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
