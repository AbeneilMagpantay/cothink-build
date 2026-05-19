#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

rm -rf extensions/copilot

{ set +x; } 2>/dev/null

# {{{ product.json
cp product.json{,.bak}

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'value' "${3}" "setpath(path(.${2}); \$value)" "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --argjson 'value' "${3}" "setpath(path(.${2}); \$value)" "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath "product" "checksumFailMoreInfoUrl" "https://github.com/AbeneilMagpantay/cothink-build/blob/main/docs/checksum.md"
setpath "product" "documentationUrl" "https://github.com/AbeneilMagpantay/cothink-build#readme"
setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item", "latestUrlTemplate": "https://open-vsx.org/vscode/gallery/{publisher}/{name}/latest", "controlUrl": "https://raw.githubusercontent.com/EclipseFdn/publish-extensions/refs/heads/master/extension-control/extensions.json"}'

# cothink v0.8 — kill literally every VSCode-chrome surface so the first
# launch looks like Cursor/Codex: one composer, full window, no menu bar,
# no tab strip, no explorer, no top search box, no breadcrumbs, no
# outline.  VSCode reads product.json's configurationDefaults during the
# configuration service bootstrap — applied BEFORE any UI renders, so we
# win the race against welcome/sidebar/menubar.  Users can override any
# of these in Settings (Ctrl+,) or via the View menu (Alt+ to reveal).
setpath_json "product" "configurationDefaults" '{
  "workbench.startupEditor": "none",
  "workbench.activityBar.location": "hidden",
  "workbench.statusBar.visible": true,
  "workbench.colorTheme": "cothink Dark",
  "workbench.editor.empty.hint": "hidden",
  "workbench.editor.enablePreview": false,
  "workbench.editor.showTabs": "none",
  "workbench.editor.tabActionLocation": "right",
  "workbench.editor.tabCloseButton": "off",
  "workbench.editor.titleScrollbarSizing": "default",
  "workbench.layoutControl.enabled": false,
  "workbench.tips.enabled": false,
  "workbench.tree.indent": 12,
  "workbench.welcomePage.walkthroughs.openOnInstall": false,
  "window.menuBarVisibility": "compact",
  "window.commandCenter": false,
  "window.customTitleBarVisibility": "auto",
  "breadcrumbs.enabled": false,
  "outline.collapseItems": "alwaysCollapse",
  "timeline.excludeSources": ["git-history", "extension-timeline.source"],
  "explorer.openEditors.visible": 0,
  "scm.alwaysShowProviders": false,
  "telemetry.telemetryLevel": "off",
  "update.showReleaseNotes": false,
  "update.mode": "manual",
  "extensions.ignoreRecommendations": true,
  "extensions.autoUpdate": false,
  "git.openRepositoryInParentFolders": "never",
  "editor.minimap.enabled": false,
  "editor.glyphMargin": false,
  "editor.folding": true,
  "editor.lineNumbers": "on",
  "editor.renderLineHighlight": "none",
  "editor.overviewRulerBorder": false,
  "editor.hideCursorInOverviewRuler": true,
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true,
    "**/__pycache__": true,
    "**/.pytest_cache": true,
    "**/node_modules": true
  }
}'

setpath "product" "introductoryVideosUrl" "https://github.com/AbeneilMagpantay/cothink-build#readme"
setpath "product" "keyboardShortcutsUrlLinux" "https://github.com/AbeneilMagpantay/cothink-build/blob/main/docs/keybindings-linux.md"
setpath "product" "keyboardShortcutsUrlMac" "https://github.com/AbeneilMagpantay/cothink-build/blob/main/docs/keybindings-macos.md"
setpath "product" "keyboardShortcutsUrlWin" "https://github.com/AbeneilMagpantay/cothink-build/blob/main/docs/keybindings-windows.md"
setpath "product" "licenseUrl" "https://github.com/AbeneilMagpantay/cothink-build/blob/main/LICENSE"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://github.com/AbeneilMagpantay/cothink-build/releases"
setpath "product" "reportIssueUrl" "https://github.com/AbeneilMagpantay/cothink-build/issues/new"
setpath "product" "requestFeatureUrl" "https://github.com/AbeneilMagpantay/cothink-build/issues/new?labels=enhancement"
setpath "product" "tipsAndTricksUrl" "https://github.com/AbeneilMagpantay/cothink-build#readme"
setpath "product" "twitterUrl" ""

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  # cothink v0.1: we don't have a versions tracking repo yet. Replace with a
  # real versions feed (mirror of VSCodium/versions structure) once we cut v0.2.
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/AbeneilMagpantay/cothink-versions/refs/heads/main"

  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    setpath "product" "downloadUrl" "https://github.com/AbeneilMagpantay/cothink-build-insiders/releases"
  else
    setpath "product" "downloadUrl" "https://github.com/AbeneilMagpantay/cothink-build/releases"
  fi

  # if [[ "${OS_NAME}" == "windows" ]]; then
  #   setpath_json "product" "win32VersionedUpdate" "true"
  # fi
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "VSCodium - Insiders"
  setpath "product" "nameLong" "VSCodium - Insiders"
  setpath "product" "applicationName" "codium-insiders"
  setpath "product" "dataFolderName" ".vscodium-insiders"
  setpath "product" "linuxIconName" "vscodium-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "vscodium-insiders"
  setpath "product" "serverApplicationName" "codium-server-insiders"
  setpath "product" "serverDataFolderName" ".vscodium-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.vscodium.VSCodiumInsiders"
  setpath "product" "win32AppUserModelId" "VSCodium.VSCodiumInsiders"
  setpath "product" "win32DirName" "VSCodium Insiders"
  setpath "product" "win32MutexName" "vscodiuminsiders"
  setpath "product" "win32NameVersion" "VSCodium Insiders"
  setpath "product" "win32RegValueName" "VSCodiumInsiders"
  setpath "product" "win32ShellNameShort" "VSCodium Insiders"
  setpath "product" "win32AppId" "{{EF35BB36-FA7E-4BB9-B7DA-D1E09F2DA9C9}"
  setpath "product" "win32x64AppId" "{{B2E0DDB2-120E-4D34-9F7E-8C688FF839A2}"
  setpath "product" "win32arm64AppId" "{{44721278-64C6-4513-BC45-D48E07830599}"
  setpath "product" "win32UserAppId" "{{ED2E5618-3E7E-4888-BF3C-A6CCC84F586F}"
  setpath "product" "win32x64UserAppId" "{{20F79D0D-A9AC-4220-9A81-CE675FFB6B41}"
  setpath "product" "win32arm64UserAppId" "{{2E362F92-14EA-455A-9ABD-3E656BBBFE71}"
  setpath "product" "tunnelApplicationName" "codium-insiders-tunnel"
  setpath "product" "win32TunnelServiceMutex" "vscodiuminsiders-tunnelservice"
  setpath "product" "win32TunnelMutex" "vscodiuminsiders-tunnel"
  setpath "product" "win32ContextMenu.x64.clsid" "90AAD229-85FD-43A3-B82D-8598A88829CF"
  setpath "product" "win32ContextMenu.arm64.clsid" "7544C31C-BDBF-4DDF-B15E-F73A46D6723D"
else
  # cothink stable build identity. GUIDs below are fresh — generated 2026-05-16
  # for cothink-build/main. NEVER re-use VSCodium GUIDs: those identify the
  # VSCodium installer on Windows; collision would let our installer overwrite
  # their install (and vice versa).
  setpath "product" "nameShort" "cothink"
  setpath "product" "nameLong" "cothink"
  setpath "product" "applicationName" "cothink"
  setpath "product" "dataFolderName" ".cothink"
  setpath "product" "linuxIconName" "cothink"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "cothink"
  setpath "product" "serverApplicationName" "cothink-server"
  setpath "product" "serverDataFolderName" ".cothink-server"
  setpath "product" "darwinBundleIdentifier" "com.cothink.cothink"
  setpath "product" "win32AppUserModelId" "cothink.cothink"
  setpath "product" "win32DirName" "cothink"
  setpath "product" "win32MutexName" "cothink"
  setpath "product" "win32NameVersion" "cothink"
  setpath "product" "win32RegValueName" "cothink"
  setpath "product" "win32ShellNameShort" "cothink"
  setpath "product" "win32AppId"          "{{8FCD10BF-E579-4A32-A814-761DBB3F6374}"
  setpath "product" "win32x64AppId"       "{{7F0857C2-3FD0-4E1B-9F2F-5287FB6172BC}"
  setpath "product" "win32arm64AppId"     "{{2956D8C0-53E0-4877-B7AA-F7E2BEC82FC8}"
  setpath "product" "win32UserAppId"      "{{588CAED5-C59E-4E3F-9BE8-7CE1C9AA5F7E}"
  setpath "product" "win32x64UserAppId"   "{{5F7BF9A7-9705-4F03-B666-025081506F59}"
  setpath "product" "win32arm64UserAppId" "{{309CE6EB-9BFA-46EC-A549-E719F62E8F77}"
  setpath "product" "tunnelApplicationName" "cothink-tunnel"
  setpath "product" "win32TunnelServiceMutex" "cothink-tunnelservice"
  setpath "product" "win32TunnelMutex" "cothink-tunnel"
  setpath "product" "win32ContextMenu.x64.clsid"   "47A02ACE-BA88-4F2F-A9BD-D65A4E87EB4E"
  setpath "product" "win32ContextMenu.arm64.clsid" "CFAB04E1-A415-4F8B-8942-800B3213BBC1"
fi

setpath_json "product" "tunnelApplicationConfig" '{}'

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json
# }}}

# include common functions
. ../utils.sh

# {{{ apply patches

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "ASSETS_REPOSITORY=\"${ASSETS_REPOSITORY}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "GLOBAL_DIRNAME=\"${GLOBAL_DIRNAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""
echo "TUNNEL_APP_NAME=\"${TUNNEL_APP_NAME}\""

if [[ "${DISABLE_UPDATE}" == "yes" ]]; then
  mv ../patches/00-update-disable.patch.yet ../patches/00-update-disable.patch
fi

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done
# }}}

set -x

# {{{ install dependencies
export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
else
  if [[ "${CI_BUILD}" != "no" ]]; then
    clang++ --version
  fi
fi

node build/npm/preinstall.ts

mv .npmrc .npmrc.bak
cp ../npmrc .npmrc

for i in {1..5}; do # try 5 times
  if [[ "${CI_BUILD}" != "no" && "${OS_NAME}" == "osx" ]]; then
    CXX=clang++ npm ci && break
  else
    npm ci && break
  fi

  if [[ $i == 5 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

mv .npmrc.bak .npmrc
# }}}

# package.json
cp package.json{,.bak}

setpath "package" "version" "${RELEASE_VERSION%-insider}"

replace 's|Microsoft Corporation|cothink|' package.json

cp resources/server/manifest.json{,.bak}

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "resources/server/manifest" "name" "cothink - Insiders"
  setpath "resources/server/manifest" "short_name" "cothink - Insiders"
else
  setpath "resources/server/manifest" "name" "cothink"
  setpath "resources/server/manifest" "short_name" "cothink"
fi

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|cothink|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 cothink|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # Microsoft adds their apt repo to sources unless the app name is code-oss.
  # We rename to cothink so we must edit a line in the post-install template.
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/cothink-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/cothink/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|cothink|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/AbeneilMagpantay/cothink-build#download-install|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://raw.githubusercontent.com/AbeneilMagpantay/cothink-build/main/icons/stable/cothink_cnl.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://github.com/AbeneilMagpantay/cothink-build|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|cothink <https://github.com/AbeneilMagpantay/cothink-build>|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|cothink|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/AbeneilMagpantay/cothink-build#download-install|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://github.com/AbeneilMagpantay/cothink-build|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|cothink|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|cothink <https://github.com/AbeneilMagpantay/cothink-build>|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|cothink|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/AbeneilMagpantay/cothink-build#download-install|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://github.com/AbeneilMagpantay/cothink-build|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml (upstream typo — references code.spec.template; kept verbatim, swapped name)
  sed -i 's|Visual Studio Code|cothink|' resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss — Windows Inno Setup installer template
  sed -i 's|https://code.visualstudio.com|https://github.com/AbeneilMagpantay/cothink-build|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|cothink|' build/win32/code.iss
fi


# cothink v0.8 — inject Cursor-shape chrome-hiding CSS into VSCode's workbench
# styles BEFORE the build packages them.  Same pattern as 00-ui-custom-font
# but applied via append rather than .patch (we don't need to hit specific
# line numbers).  Result: tab strip, menubar, sidebar, panel, breadcrumbs,
# command center, etc. are display:none from the very first frame — no
# flicker, no race conditions, no need for an extension retry loop.
#
# Users who want to re-enable any of these can do so via Settings (Ctrl+,)
# overriding the configurationDefaults set above; but more practically, the
# CSS classes can be re-enabled by editing the cothink-installed CSS file
# manually if a power user really wants to.
# v0.8 first attempt appended to src/vs/workbench/browser/style.css.  Build
# logs confirmed the append ran, but the rules never made it into runtime
# workbench.desktop.main.css — that file isn't in VSCode's bundled CSS
# module graph.  v0.9: append the same rules to actionbar.css (proven-
# bundled by the existing 00-ui-custom-font.patch which lands its rules at
# runtime via that same file) PLUS each workbench-part CSS file directly.
# At least one of these files reliably ships in workbench.desktop.main.css.
COTHINK_HIDE_CSS=$(cat <<'COTHINK_HIDE_INNER'

/* === cothink v0.8/v0.9 — hide ALL VSCode chrome (Cursor-shape) === */
.monaco-workbench .part.titlebar .menubar { display: none !important; }
.monaco-workbench .part.titlebar .menubar-main { display: none !important; }
.monaco-workbench .part.titlebar .command-center-center { display: none !important; }
.monaco-workbench .part.titlebar .command-center { display: none !important; }
.monaco-workbench .part.titlebar .action-toolbar-container { display: none !important; }
.monaco-workbench .part.titlebar .layout-controls-container { display: none !important; }
.monaco-workbench .part.editor .tabs-and-actions-container { display: none !important; }
.monaco-workbench .part.editor .title.tabs { display: none !important; }
.monaco-workbench .part.editor .title-actions { display: none !important; }
.monaco-workbench .part.editor > .content > .editor-group-container > .title { display: none !important; }
.monaco-workbench .part.sidebar { display: none !important; }
.monaco-workbench .part.auxiliarybar { display: none !important; }
.monaco-workbench .part.panel { display: none !important; }
.monaco-workbench .part.activitybar { display: none !important; }
.monaco-breadcrumbs { display: none !important; }
.monaco-workbench .part.editor .breadcrumbs-control { display: none !important; }
.monaco-workbench .part.editor { left: 0 !important; }
COTHINK_HIDE_INNER
)

# Try every plausible target — at least one is in the bundled CSS graph.
for css_target in \
  "src/vs/base/browser/ui/actionbar/actionbar.css" \
  "src/vs/workbench/browser/style.css" \
  "src/vs/workbench/browser/parts/titlebar/media/titlebarpart.css" \
  "src/vs/workbench/browser/parts/sidebar/media/sidebarpart.css" \
  "src/vs/workbench/browser/parts/auxiliarybar/media/auxiliarybarpart.css" \
  "src/vs/workbench/browser/parts/panel/media/panelpart.css" \
  "src/vs/workbench/browser/parts/activitybar/media/activitybar.css" \
  "src/vs/workbench/browser/parts/editor/media/editorpart.css" \
  "src/vs/workbench/browser/parts/editor/media/editor.css" ; do
  if [[ -f "${css_target}" ]]; then
    echo "${COTHINK_HIDE_CSS}" >> "${css_target}"
    echo "cothink: appended chrome-hide rules to ${css_target}"
  else
    echo "cothink: skipped (not found): ${css_target}"
  fi
done

# Keep the legacy block too so existing readers find the v0.8 marker.
cat >> src/vs/workbench/browser/style.css <<'COTHINK_HIDE_CHROME_EOF'

/* === cothink v0.8 — hide VSCode chrome to make the IDE look like Cursor/Codex === */

/* Title bar: kill the menu (File Edit Selection...), command center search,
   and the right-side toolbar (CHAT button, layout split icons, etc.). The
   draggable area + window controls stay so the window remains movable +
   closable. */
.monaco-workbench .part.titlebar .menubar { display: none !important; }
.monaco-workbench .part.titlebar .command-center-center { display: none !important; }
.monaco-workbench .part.titlebar .menubar-main { display: none !important; }
.monaco-workbench .part.titlebar .titlebar-right .action-toolbar-container > .actions-container > .action-item:not(.window-controls-container .action-item) { display: none !important; }

/* Editor area: kill the tab strip + tab actions. The composer is the only
   thing that should appear in the editor area. */
.monaco-workbench .part.editor .tabs-and-actions-container { display: none !important; }
.monaco-workbench .part.editor .title.tabs { display: none !important; }
.monaco-workbench .part.editor .title-actions { display: none !important; }

/* Sidebar (primary): hide entirely. Explorer + OUTLINE + TIMELINE all gone. */
.monaco-workbench .part.sidebar { display: none !important; }

/* Auxiliary bar (right): hide entirely. */
.monaco-workbench .part.auxiliarybar { display: none !important; }

/* Bottom panel: hide entirely (terminal/output/problems). User can re-show
   via Ctrl+J if they need it. */
.monaco-workbench .part.panel { display: none !important; }

/* Breadcrumbs above the editor: kill. */
.monaco-breadcrumbs { display: none !important; }
.monaco-workbench .part.editor .breadcrumbs-control { display: none !important; }

/* Activity bar (left icon strip): belt-and-suspenders alongside the
   workbench.activityBar.location=hidden setting. */
.monaco-workbench .part.activitybar { display: none !important; }

/* Status bar: keep visible — our cothink reachability indicator lives there.
   (configurationDefaults already has workbench.statusBar.visible=true.) */

/* Make the editor area fill the full window since side + bottom panels are gone. */
.monaco-workbench .part.editor { left: 0 !important; }

COTHINK_HIDE_CHROME_EOF

echo "cothink: injected chrome-hide CSS into vscode/src/vs/workbench/browser/style.css"

cd ..

# cothink v0.5 — fetch the built-in extension tarball from the cothink GitHub
# Release and extract it into vscode/extensions/cothink/ so the gulp build
# packages it as a bundled extension.  Pinned to COTHINK_EXTENSION_VERSION
# (default v0.1.0) so the fork's build is reproducible against a known
# extension version — bump that env var (or the script default) when we ship
# a new extension release.
if [[ -f "./sidecar/fetch_extension.sh" ]]; then
  echo "fetching cothink built-in extension..."
  bash ./sidecar/fetch_extension.sh
fi
