#!/usr/bin/env bash
# shellcheck disable=SC1091

set -e

APP_NAME_LC="$( echo "${APP_NAME}" | awk '{print tolower($0)}' )"

mkdir -p assets

# cothink v0.1 — fetch the PyInstaller-built cothink-serve sidecar from the
# matching GitHub Release on AbeneilMagpantay/cothink and drop it into the
# VSCode build output's resources/ directory.  When Inno Setup (Windows) /
# create-dmg (macOS) / tar+AppImage (Linux) packs the installer, the binary
# rides along.  At runtime the built-in extension's resolveSidecarBinary()
# finds it at process.resourcesPath and spawns it without needing Python.
if [[ -x "./sidecar/fetch_sidecar.sh" || -f "./sidecar/fetch_sidecar.sh" ]]; then
  echo "fetching cothink-serve sidecar..."
  bash ./sidecar/fetch_sidecar.sh
fi

if [[ "${OS_NAME}" == "osx" ]]; then
  . ./build/osx/prepare_assets.sh

  VSCODE_PLATFORM="darwin"
elif [[ "${OS_NAME}" == "windows" ]]; then
  . ./build/windows/prepare_assets.sh

  VSCODE_PLATFORM="win32"
else
  . ./build/linux/prepare_assets.sh

  VSCODE_PLATFORM="linux"
fi

if [[ "${SHOULD_BUILD_REH}" != "no" ]]; then
  echo "Building and moving REH"
  cd "vscode-reh-${VSCODE_PLATFORM}-${VSCODE_ARCH}"
  tar czf "../assets/${APP_NAME_LC}-reh-${VSCODE_PLATFORM}-${VSCODE_ARCH}-${RELEASE_VERSION}.tar.gz" .
  cd ..
fi

if [[ "${SHOULD_BUILD_REH_WEB}" != "no" ]]; then
  echo "Building and moving REH-web"
  cd "vscode-reh-web-${VSCODE_PLATFORM}-${VSCODE_ARCH}"
  tar czf "../assets/${APP_NAME_LC}-reh-web-${VSCODE_PLATFORM}-${VSCODE_ARCH}-${RELEASE_VERSION}.tar.gz" .
  cd ..
fi

set -ex

if [[ "${SHOULD_BUILD_CLI}" != "no" ]]; then
  echo "Building and moving CLI"

  APPLICATION_NAME="$( node -p "require(\"./vscode/product.json\").applicationName" )"
  NAME_SHORT="$( node -p "require(\"./vscode/product.json\").nameShort" )"
  TUNNEL_APPLICATION_NAME="$( node -p "require(\"./vscode/product.json\").tunnelApplicationName" )"

  mkdir -p "vscode-cli"

  cd "vscode-cli"

  if [[ "${OS_NAME}" == "osx" ]]; then
    cp "../VSCode-${VSCODE_PLATFORM}-${VSCODE_ARCH}/${NAME_SHORT}.app/Contents/Resources/app/bin/${TUNNEL_APPLICATION_NAME}" "${APPLICATION_NAME}"
  elif [[ "${OS_NAME}" == "windows" ]]; then
    cp "../VSCode-${VSCODE_PLATFORM}-${VSCODE_ARCH}/bin/${TUNNEL_APPLICATION_NAME}.exe" "${APPLICATION_NAME}.exe"
  else
    cp "../VSCode-${VSCODE_PLATFORM}-${VSCODE_ARCH}/bin/${TUNNEL_APPLICATION_NAME}" "${APPLICATION_NAME}"
  fi

  tar czf "../assets/${APP_NAME_LC}-cli-${VSCODE_PLATFORM}-${VSCODE_ARCH}-${RELEASE_VERSION}.tar.gz" .

  cd ..
fi

if [[ "${OS_NAME}" != "windows" ]]; then
  ./prepare_checksums.sh
fi
