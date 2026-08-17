# CI Build Guide (No DevEco Studio)

> This repo builds HAPs in the cloud via GitHub Actions — **no DevEco Studio install required**.
> This file mirrors [CI_Guide.md](CI_Guide.md) (Bilingual: 中文 / English).

## 1. Overview

Three workflows under `.github/workflows/`:

| Workflow | Trigger | Purpose |
|---|---|---|
| `docker-image.yml` | moved to the [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) repo | central build of API 23/26 CI images (this repo only consumes) |
| `build.yml` | push `main`/`master`, PR, manual | Build unsigned debug HAP → upload artifact → **auto-publish rolling `nightly` Release on push** |
| `sign-and-release.yml` | push `v*` tag, manual | Build → sign with hap-sign-tool → publish a versioned release |

Trigger matrix:

| Action | Result |
|---|---|
| Push to `main`/`master` (files changed) | Auto build + auto publish/update rolling `nightly` Release |
| Open/update a PR | Build only (no Release, keeps things clean) |
| Push a `v*` tag | Build + sign (if secrets configured) + publish a versioned Release |

## 2. Prerequisites

- Image `ghcr.io/dalongzhuazi/harmonyos-ci:api26` is already built and public.
- Image build & maintenance is centralized in the **[harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) repo** (Dockerfile + build workflow + multi-API tags); rebuild or add new API versions (e.g. api23, api24) there — this repo only consumes the image.

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
| `CLT_ZIP_URL` | (moved to the harmonyos-ci repo along with the image build) |

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
| Build fails because image is missing | The image is built centrally in [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci); verify the tag exists |
| `entry-default-unsigned.hap` won't install | Unsigned HAPs must be signed first (DevEco Studio or hap-sign-tool) |

## 8. File index

- `.github/workflows/build.yml` — build + artifact + auto rolling Release
- `.github/workflows/sign-and-release.yml` — tag signing & release
- (image build moved to the [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) repo)
- `.github/scripts/strip_signing.py` — strip local signing config (unsigned output)