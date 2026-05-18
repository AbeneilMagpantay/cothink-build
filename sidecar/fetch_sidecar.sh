#!/usr/bin/env bash
#
# Fetch the cothink-serve sidecar binary for the current OS+arch from the
# AbeneilMagpantay/cothink GitHub Release matching $COTHINK_SIDECAR_VERSION
# (default v0.1.0), and drop it into $VSCODE_OUTPUT_DIR/resources/ so the
# Electron packager (Inno Setup on Windows, etc) includes it in the
# installer payload.
#
# Required env:
#   OS_NAME              linux | osx | windows
#   VSCODE_ARCH          x64 | arm64 (Linux/Win) | arm64 (macOS)
#   VSCODE_OUTPUT_DIR    e.g. ./VSCode-win32-x64  or  ./VSCode-darwin-arm64
#                         (auto-derived from OS_NAME+VSCODE_ARCH if unset)
#
# Optional env:
#   COTHINK_SIDECAR_VERSION   Release tag (default: v0.1.0)
#   GITHUB_TOKEN              For private-repo or rate-limit lift

set -euo pipefail

COTHINK_SIDECAR_VERSION="${COTHINK_SIDECAR_VERSION:-v0.1.0}"
COTHINK_REPO="${COTHINK_REPO:-AbeneilMagpantay/cothink}"

# Map OS_NAME + VSCODE_ARCH to the release asset name + the target path.
# Unsupported arches (e.g. Linux LOONG64, RISCV64, PPC64, S390X) get a
# skip-with-notice rather than a hard fail — the fork build for those arches
# still produces a usable IDE, just without the bundled AI sidecar.  Users on
# those arches would need to install Python + cothink themselves to use the
# extension's dev-mode fallback.
case "${OS_NAME}:${VSCODE_ARCH}" in
  windows:x64)
    ASSET="cothink-serve-windows-x64.exe"
    : "${VSCODE_OUTPUT_DIR:=./VSCode-win32-${VSCODE_ARCH}}"
    TARGET="${VSCODE_OUTPUT_DIR}/resources/cothink-serve.exe"
    ;;
  linux:x64)
    ASSET="cothink-serve-linux-x64"
    : "${VSCODE_OUTPUT_DIR:=./VSCode-linux-${VSCODE_ARCH}}"
    TARGET="${VSCODE_OUTPUT_DIR}/resources/cothink-serve"
    ;;
  osx:arm64|osx:x64)
    # cothink only publishes a macOS arm64 binary in v0.1.0; we use it for
    # both Apple Silicon and Intel until we add a separate macos-x64 build.
    # On Intel Macs the arm64 binary runs under Rosetta 2 (slow but works).
    ASSET="cothink-serve-macos-arm64"
    : "${VSCODE_OUTPUT_DIR:=./VSCode-darwin-${VSCODE_ARCH}}"
    TARGET="${VSCODE_OUTPUT_DIR}/cothink.app/Contents/Resources/cothink-serve"
    ;;
  windows:arm64|linux:arm64|linux:armhf|linux:ppc64le|linux:loong64|linux:riscv64|linux:s390x)
    echo "fetch_sidecar.sh: NOTICE no sidecar binary published for ${OS_NAME}:${VSCODE_ARCH}, skipping."
    echo "fetch_sidecar.sh: NOTICE the fork build will succeed without the bundled sidecar; users will need dev-mode Python."
    exit 0
    ;;
  *)
    echo "fetch_sidecar.sh: WARN unrecognized OS_NAME:VSCODE_ARCH='${OS_NAME}:${VSCODE_ARCH}', skipping fetch." >&2
    exit 0
    ;;
esac

if [[ ! -d "${VSCODE_OUTPUT_DIR}" ]]; then
  echo "fetch_sidecar.sh: VSCODE_OUTPUT_DIR '${VSCODE_OUTPUT_DIR}' does not exist." >&2
  echo "Run after the VSCode build completes and before prepare_assets packs the installer." >&2
  exit 1
fi

mkdir -p "$(dirname "${TARGET}")"

echo "fetch_sidecar.sh: downloading ${ASSET} from ${COTHINK_REPO}@${COTHINK_SIDECAR_VERSION}"
echo "fetch_sidecar.sh:   -> ${TARGET}"

# Use the unauthenticated download URL pattern.  Works for public repos
# without a token.  Switch to `gh release download` if we make the repo
# private later.
DOWNLOAD_URL="https://github.com/${COTHINK_REPO}/releases/download/${COTHINK_SIDECAR_VERSION}/${ASSET}"

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 5 --retry-delay 5 -o "${TARGET}" "${DOWNLOAD_URL}"
elif command -v wget >/dev/null 2>&1; then
  wget --tries=5 -O "${TARGET}" "${DOWNLOAD_URL}"
else
  echo "fetch_sidecar.sh: neither curl nor wget available." >&2
  exit 1
fi

# On Unix targets, make sure the binary is executable.
if [[ "${OS_NAME}" != "windows" ]]; then
  chmod +x "${TARGET}"
fi

SIZE_MB=$(du -m "${TARGET}" | cut -f1)
echo "fetch_sidecar.sh: ok (${SIZE_MB} MB)"
