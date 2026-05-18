#!/usr/bin/env bash
#
# Fetch the cothink VSCode extension tarball from the matching GitHub
# Release on AbeneilMagpantay/cothink (default v0.1.0) and extract it into
# vscode/extensions/cothink/ so the gulp build packages it as a built-in.
#
# Built-in extensions are picked up automatically by VSCode's standard
# extension discovery — no patch to product.json needed for activation,
# only an entry in product.json's `builtInExtensions` list to flag it as
# bundled (which prepare_vscode.sh handles separately).
#
# Required env:
#   (none — script runs from the cothink-build repo root)
#
# Optional env:
#   COTHINK_EXTENSION_VERSION   Release tag (default: v0.1.0)
#   COTHINK_REPO                Source repo (default: AbeneilMagpantay/cothink)

set -euo pipefail

COTHINK_EXTENSION_VERSION="${COTHINK_EXTENSION_VERSION:-v0.5.0}"
COTHINK_REPO="${COTHINK_REPO:-AbeneilMagpantay/cothink}"
ASSET="cothink-extension.tar.gz"

if [[ ! -d "./vscode" ]]; then
  echo "fetch_extension.sh: ./vscode not found.  Run after get_repo.sh." >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/${COTHINK_REPO}/releases/download/${COTHINK_EXTENSION_VERSION}/${ASSET}"
TMP_TARBALL="$(mktemp -t cothink-ext-XXXXXX.tar.gz)"

echo "fetch_extension.sh: downloading ${ASSET} from ${COTHINK_REPO}@${COTHINK_EXTENSION_VERSION}"
echo "fetch_extension.sh:   -> vscode/extensions/cothink/"

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 5 --retry-delay 5 -o "${TMP_TARBALL}" "${DOWNLOAD_URL}"
elif command -v wget >/dev/null 2>&1; then
  wget --tries=5 -O "${TMP_TARBALL}" "${DOWNLOAD_URL}"
else
  echo "fetch_extension.sh: neither curl nor wget available." >&2
  exit 1
fi

# Tarball top-level is `cothink/`, so extract into vscode/extensions/.
# Wipe any prior copy first so stale files from older versions don't linger.
rm -rf "./vscode/extensions/cothink"
mkdir -p "./vscode/extensions"
tar -xzf "${TMP_TARBALL}" -C "./vscode/extensions/"
rm -f "${TMP_TARBALL}"

SIZE_KB=$(du -k "./vscode/extensions/cothink" | tail -1 | cut -f1)
FILES=$(find "./vscode/extensions/cothink" -type f | wc -l)
echo "fetch_extension.sh: ok (${FILES} files, ${SIZE_KB} KB)"
