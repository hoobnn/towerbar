#!/bin/zsh
# Rebrand the upstream CellDock sources as TowerBar.
#
# Only the identity that lands on a user's machine is renamed: bundle
# identifiers, executable / helper names, on-disk paths, Keychain services and
# user-visible text. Swift type names, SwiftPM target names and C symbols keep
# their upstream spelling so `git merge upstream/main` stays cheap. The script
# is idempotent: run it again after every upstream merge.
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

# Files sent to the module, vendored code and license texts stay untouched.
files=("${(@f)$(git ls-files -- \
  Resources Sources Tests docs script scripts .gitignore \
  ':!:Sources/CEuiccCore/Vendor/**' \
  ':!:Resources/ModuleVoice/**' \
  ':!:docs/COPYING-*' \
  ':!:scripts/rebrand.sh' |
  while read -r f; do [[ -f "$f" ]] && grep -Iq . "$f" && print -r -- "$f"; done)}")

perl -0pi -e '
  # Bundle identifier prefix first, so the generic rules never see it.
  s/\bapp\.celldock\.mac\b/com.hoobnn.towerbar/g;
  s/\bapp\.celldock\./com.hoobnn.towerbar./g;
  # Installed executables (product names, not SwiftPM target directories).
  s/(?<!Sources\/)(?<![A-Za-z_])CellDockNetworkHelper(?![A-Za-z_\/])/TowerBarNetworkHelper/g;
  s/(?<![A-Za-z_])CellDockVoWiFiRuntime(?![A-Za-z_])/TowerBarVoWiFiRuntime/g;
  # The ADB host banner is a protocol string shared with the module side.
  s/host::CellDock/host::\x00KEEP\x00/g;
  # Upstream attribution stays as written.
  s/Based on CellDock/Based on \x00KEEP\x00/g;
  s/CellDock contributors/\x00KEEP\x00 contributors/g;
  # Bare product name: UI text, paths, defaults keys. Skips CellDockFoo
  # identifiers and Sources/CellDock/ target directories.
  s/(?<!Sources\/)(?<![A-Za-z_])CellDock(?![A-Za-z_\/])/TowerBar/g;
  s/\x00KEEP\x00/CellDock/g;
  s#"Sources" / "TowerBar"#"Sources" / "CellDock"#g;
  # On-disk state must not collide with an installed CellDock.
  s#Application Support/CellDock/#Application Support/TowerBar/#g;
  s#/var/run/celldock-vowifi#/var/run/towerbar-vowifi#g;
' "${files[@]}"

# Sparkle feed is ours; the upstream appcast must never reach TowerBar users.
perl -pi -e 's#https://celldock\.app/#https://raw.githubusercontent.com/hoobnn/towerbar/main/appcast/#g' \
  Resources/Info.plist Sources/CellDock/UpdaterManager.swift
perl -pi -e 's#/\\\(rawValue\)/appcast\.xml#/\\(rawValue).xml#; s#appcast/stable/appcast\.xml#appcast/stable.xml#' \
  Resources/Info.plist Sources/CellDock/UpdaterManager.swift

for from to in \
  Resources/app.celldock.mac.network.helper.plist Resources/com.hoobnn.towerbar.network.helper.plist \
  Resources/CellDock.icns Resources/TowerBar.icns \
  Resources/CellDock.entitlements Resources/TowerBar.entitlements; do
  [[ -e "$from" ]] && git mv -f "$from" "$to"
done
print "Rebranded ${#files[@]} files."
