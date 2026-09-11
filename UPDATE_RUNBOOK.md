# 9Router Cloudron Update Runbook

When asked `Update to latest`, update this project end to end. Do not stop after changing source metadata.

## Project

- Worktree: `C:\Users\donkr\Documents\randomProj\9router-cloudron`
- Fork: `https://github.com/ericm115/9router-cloudron`
- Upstream: `https://github.com/decolua/9router`
- Docker Hub: `docker.io/emoralesjw/9router`
- Cloudron app ID: `com.toldyouso.9router`
- Catalog URL: `https://raw.githubusercontent.com/ericm115/9router-cloudron/main/CloudronVersions.json`

## Required behavior

- Find latest upstream tagged release, not merely `master`.
- Keep Headroom integration.
- Keep `INITIAL_PASSWORD=123456` unless user requests another value.
- Preserve existing `CloudronVersions.json` entries.
- Add new version entry; never replace or delete old versions.
- Mark every catalog version `publishState: "published"`; do not use `testing` for normal updates.
- Bump Cloudron package version separately from upstream version.
- Keep original attribution to `vRobM/9router-cloudron` and Robi.
- Use `ericm115` only; never add full personal names.
- Never commit credentials, tokens, Docker config, local data, or secrets.

## Workflow

1. Find latest upstream tag:

```powershell
Invoke-RestMethod 'https://api.github.com/repos/decolua/9router/tags?per_page=5'
```

2. Confirm selected tag exists:

```powershell
git ls-remote --tags https://github.com/decolua/9router.git "refs/tags/vVERSION"
```

3. Inspect current package version from `CloudronManifest.json`. Bump patch version. Example: `0.4.2` becomes `0.4.3`.

4. Update `Dockerfile`:

```text
ARG UPSTREAM_VERSION=VERSION
```

5. Update `CloudronManifest.json`:

- `version`: new Cloudron package version
- `upstreamVersion`: selected upstream version

6. Update `README.md` upstream version.

7. Add a new first entry to `CHANGELOG`.

8. Add a new entry to `CloudronVersions.json`. Preserve every existing entry. New entry must contain:

- key matching new package version
- embedded manifest version matching key
- new upstream version
- new Docker image `docker.io/emoralesjw/9router:PACKAGE_VERSION`
- current `creationDate` and `ts`
- `publishState: "published"`

Cloudron version rules: version key must equal embedded manifest version; old versions remain in catalog; updates use highest non-revoked semver.

9. Validate JSON:

```powershell
python -c "import json; json.load(open('CloudronManifest.json')); json.load(open('CloudronVersions.json')); print('JSON OK')"
git diff --check
```

10. Normalize `start.sh` to LF if Windows changed line endings:

```powershell
$path = 'start.sh'
$bytes = [System.IO.File]::ReadAllBytes($path)
$text = [System.Text.Encoding]::UTF8.GetString($bytes).Replace("`r`n", "`n")
[System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
```

11. Build image:

```powershell
docker build --tag 9router-cloudron:PACKAGE_VERSION .
```

12. Fresh-container test:

```powershell
$volume='9router-cloudron-test-data'
docker volume create $volume
docker rm --force 9router-cloudron-test 2>$null
docker run --detach --name 9router-cloudron-test --publish 20128:20128 --volume "$volume`:/app/data" 9router-cloudron:PACKAGE_VERSION
Start-Sleep -Seconds 15
Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:20128/api/health'
docker exec 9router-cloudron-test /opt/headroom/bin/python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8787/health').status)"
docker rm --force 9router-cloudron-test
docker volume rm $volume
```

Expected: 9Router HTTP `200`; Headroom HTTP `200`.

13. Push Docker image:

```powershell
docker tag 9router-cloudron:PACKAGE_VERSION docker.io/emoralesjw/9router:PACKAGE_VERSION
docker push docker.io/emoralesjw/9router:PACKAGE_VERSION
```

14. Validate catalog preserves old versions:

```powershell
python -c "import json; d=json.load(open('CloudronVersions.json')); print(list(d['versions']))"
```

15. Inspect status and diff. Stage only intended project files. Include `AGENTS.md` or this runbook only when changed intentionally:

```powershell
git status --short
git diff --stat
git diff --check
git add Dockerfile CloudronManifest.json CloudronVersions.json README.md CHANGELOG start.sh
 git commit -m "feat: update upstream to VERSION"
git push origin main
```

16. Verify raw catalog after push:

```text
https://raw.githubusercontent.com/ericm115/9router-cloudron/main/CloudronVersions.json
```

Confirm new version, image tag, upstream version, date, and preserved older entries.

## Do not use

- Do not delete old `CloudronVersions.json` entries.
- Do not reuse an existing Cloudron package version for changed content.
- Do not point catalog image at `robius/9router`.
- Do not publish a Docker image before building and runtime-testing it.
- Do not use `cloudron build` as the only validation on Windows; local Cloudron CLI can fail due TTY handling.
