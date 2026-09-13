# 9router Cloudron Update Guide

## Project

- Fork: `https://github.com/ericm115/9router-cloudron`
- Original package: `https://github.com/vRobM/9router-cloudron`
- Upstream app: `https://github.com/decolua/9router`
- Docker Hub: `docker.io/emoralesjw/9router`
- Cloudron app ID: `com.toldyouso.9router`
- Package worktree: `C:\Users\donkr\Documents\randomProj\9router-cloudron`

## Current setup

- `Dockerfile` clones upstream tag `v${UPSTREAM_VERSION}` during image build.
- `Dockerfile` installs `headroom-ai[proxy,code]` in `/opt/headroom`.
- `start.sh` starts Headroom on `127.0.0.1:8787`.
- `start.sh` enables Headroom in 9Router SQLite settings.
- Headroom data lives in `/app/data/headroom`.
- `CloudronVersions.json` points to the Docker Hub image.
- `.dockerignore` excludes local `upstream/`; do not rely on that directory for builds.
- `start.sh` must use LF line endings. CRLF causes `/app/code/start.sh: no such file or directory` in Linux containers.

## Update workflow

1. Find latest upstream release:

```powershell
Invoke-RestMethod 'https://api.github.com/repos/decolua/9router/releases/latest'
```

2. Confirm tag exists:

```powershell
git ls-remote --tags https://github.com/decolua/9router.git "refs/tags/vVERSION"
```

3. Update `Dockerfile`:

```text
ARG UPSTREAM_VERSION=VERSION
```

4. Bump Cloudron package version in both:

- `CloudronManifest.json`: `version`
- `CloudronVersions.json`: version key and nested manifest `version`

Use next package version, not upstream version. Example: upstream `0.5.70` becomes package `0.5.0`.

5. Update `upstreamVersion` in both manifest files.

6. Tag image metadata in `CloudronVersions.json`:

```text
"dockerImage": "docker.io/emoralesjw/9router:PACKAGE_VERSION"
```

7. Update README upstream version and `CHANGELOG`.

8. Refresh current `CloudronVersions.json` entry `creationDate` and `ts` using current UTC date. Keep historical entries unchanged.

9. Build image:

```powershell
docker build --tag 9router-cloudron:PACKAGE_VERSION .
```

10. Runtime-test image:

```powershell
docker volume create 9router-cloudron-test-data

docker run --detach --name 9router-cloudron-test `
  --publish 20128:20128 `
  --volume 9router-cloudron-test-data:/app/data `
  9router-cloudron:PACKAGE_VERSION

Start-Sleep -Seconds 15
Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:20128/api/health'
docker exec 9router-cloudron-test /opt/headroom/bin/python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8787/health').status)"

docker rm --force 9router-cloudron-test
docker volume rm 9router-cloudron-test-data
```

Expected status: `200` for both services.

11. Normalize `start.sh` line endings before building if needed:

```powershell
$path = 'start.sh'
$bytes = [System.IO.File]::ReadAllBytes($path)
$text = [System.Text.Encoding]::UTF8.GetString($bytes).Replace("`r`n", "`n")
[System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
```

12. Push image:

```powershell
docker tag 9router-cloudron:PACKAGE_VERSION docker.io/emoralesjw/9router:PACKAGE_VERSION
docker push docker.io/emoralesjw/9router:PACKAGE_VERSION
```

13. Validate files:

```powershell
python -c "import json; json.load(open('CloudronManifest.json')); json.load(open('CloudronVersions.json')); print('JSON OK')"
git diff --check
git status --short
```

14. Commit and push only intended files:

```powershell
git add Dockerfile CloudronManifest.json CloudronVersions.json README.md CHANGELOG start.sh AGENTS.md
git commit -m "feat: update upstream to VERSION"
git push origin main
```

15. Verify raw catalog URL:

`https://raw.githubusercontent.com/ericm115/9router-cloudron/main/CloudronVersions.json`

Confirm current entry has new package version, upstream version, Docker image, date, and changelog.

## Cloudron notes

- Community app updates require a new package version. Changing an existing image without bumping version is not enough.
- Users must add the raw `CloudronVersions.json` URL as a Community App source.
- `cloudron build` on Windows may fail with `process.stdin.setRawMode is not a function`; Docker build plus pushed registry image remains usable.
- `dockerImage` must exist before Cloudron can install/update from the catalog.
- Keep original attribution to `vRobM/9router-cloudron` and Robi. Keep fork attribution as `ericm115`; do not add personal full names.
- Never commit credentials, API keys, tokens, Docker config, or local runtime data.
