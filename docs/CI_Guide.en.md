# CI Build Guide (No DevEco Studio)

> This repo builds HAPs in the cloud via GitHub Actions — **no DevEco Studio install required**.
> This file mirrors [CI_Guide.md](CI_Guide.md) (Bilingual: 中文 / English).

## 1. Overview

Three workflows under `.github/workflows/`:

| Workflow | Trigger | Purpose |
|---|---|---|
| `docker-image.yml` | Manual (workflow_dispatch) | One-time build & push of the API 26 CI image to ghcr.io |
| `build.yml` | push `main`/`master`, PR, manual | Build unsigned debug HAP → upload artifact → **auto-publish rolling `nightly` Release on push** |
| `sign-and-release.yml` | push `v*` tag, manual | Build → sign with hap-sign-tool → publish a versioned release |

Trigger matrix:

| Action | Result |
|---|---|
| Push to `main`/`master` (files changed) | Auto build + auto publish/update rolling `nightly` Release |
| Open/update a PR | Build only (no Release, keeps things clean) |
| Push a `v*` tag | Build + sign (if secrets configured) + publish a versioned Release |

## 2. Prerequisites

- A GitHub repo (public repos expose release assets for direct download).
- One-time CI image build (below), after which everything is automatic.

## 3. First-time setup (one-time, ~15 minutes)

### 3.1 Get a command-line-tools Linux zip URL

You need a Linux (x86-64) command-line-tools zip matching API 26 — either source:

1. **Community mirror (recommended, stable public links)**: the `v26.0.0.461` release of [jerry-271828/harmonyos-commandline-tools](https://github.com/jerry-271828/harmonyos-commandline-tools) ships the zip split into `clt.zip.part00` / `clt.zip.part01`; pass both URLs space-separated and the Dockerfile concatenates them.
2. **Official**: download from the [Obtaining Command Line Tools](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-commandline-get) page (links are short-lived; re-host the zip first).

### 3.2 Configure and build the image

1. Add secret `CLT_ZIP_URL` (space-separated URLs) under Settings → Secrets and variables → Actions.
2. Run the **Build CI image** workflow once → produces `ghcr.io/<owner>/harmonyos-ci:api26`.
3. `build.yml` / `sign-and-release.yml` then reference that pinned tag, keeping builds reproducible.

> You can also pass the URL directly via the `clt_zip_url` workflow_dispatch input (no secret needed).

## 4. Three ways to build without DevEco Studio

### A. Cloud automatic (default, zero effort)
On push to `main`, Actions runs inside the ghcr image:
```bash
ohpm install --all
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon --stacktrace
```
Output: `entry/build/default/outputs/default/entry-default-unsigned.hap`, distributed via artifact and the `nightly` Release.

### B. Local Docker (no DevEco, mirrors the cloud env)
```bash
docker run --rm -v "$PWD":/workspace ghcr.io/dalongzhuazi/harmonyos-ci:api26 \\
  bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
```

### C. Local DevEco CLI (when DevEco is already installed)
Use the IDE's bundled hvigor (see `.local-rules/build-commands.local.md`):
```powershell
$env:DEVECO_SDK_HOME='G:\\DevEco Studio 26\\DevEco Studio\\sdk'; & 'G:\\DevEco Studio 26\\DevEco Studio\\tools\\hvigor\\bin\\hvigorw.bat' assembleHap --no-daemon --stacktrace
```
(That is a machine-local path; use your actual DevEco install directory.)

## 5. Signing & auto Release

### Rolling nightly Release (no signing needed, on by default)
On every push to `main`/`master`, the `release` job in `build.yml` uses `gh release` to move the `nightly` tag and refresh the same-named prerelease, attaching the unsigned HAP with bilingual notes.

### Versioned Release + signing (optional, requires secrets)
Push a `v*` tag to trigger `sign-and-release.yml`. Required secrets (cert/key files are base64-encoded, never committed; `.gitignore` already blocks them):

| Secret | Content |
|---|---|
| `SIGNING_CERT` | `.cer` certificate, base64 (`base64 -w 0`) |
| `SIGNING_PROFILE` | `.p7b` profile, base64 |
| `SIGNING_KEY` | `.p12` keystore, base64 |
| `SIGNING_KEY_ALIAS` | Key alias (plain) |
| `KEYSTORE_PASSWORD` / `KEY_PASSWORD` | Keystore / key passwords (plain) |
| `CLT_ZIP_URL` | (docker-image.yml only) zip direct URL |

> Without signing secrets, tag builds skip signing with a notice instead of failing red.

## 6. Verification

1. After push, confirm `Assemble HAP` and `Auto-publish rolling Release` are green on the Actions page.
2. Download `entry-default-unsigned.hap` from the Releases page or the artifact (`gh run download <id> -n hap-unsigned`), then re-sign in DevEco Studio to install.
3. Confirm the HAP is non-empty and a valid ZIP container (magic `50 4B 03 04` = `PK`).

## 7. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `libGL.so.1: cannot open shared object file` | Bare container lacks OpenGL; image ships `libgl1/libegl1/...` |
| `shopt: not found` | Runner default `sh` (dash) lacks `shopt`; workflows use `defaults.run.shell: bash` |
| hvigor version mismatch / unsupported model version | command-line-tools ≠ project `modelVersion 26.0.0`; rebuild with a 26.0.0.x zip |
| Build fails because image is missing | Run Build CI image once before pushing |
| `entry-default-unsigned.hap` won't install | Unsigned HAPs must be signed first (DevEco Studio or hap-sign-tool) |

## 8. File index

- `.github/workflows/build.yml` — build + artifact + auto rolling Release
- `.github/workflows/sign-and-release.yml` — tag signing & release
- `.github/workflows/docker-image.yml` — build & push the CI image
- `.github/scripts/strip_signing.py` — strip local signing config (unsigned output)
- `docker/harmonyos-ci.Dockerfile` / `docker/README.md` — CI image definition & docs