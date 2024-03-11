#!/usr/bin/env bash

# Script to update Obsidian from the latest release on GitHub. Requires the `gh`
# cli and `jq`.

log() {
    1>&2 echo "$@"
}

set -e

if [ -z "$PREFIX" ]; then
    PREFIX=$HOME/.local
fi
GH_REPO=obsidianmd/obsidian-releases
OPTDIR=$PREFIX/opt/obsidian
DESTPATH=$PREFIX/share/applications/obsidian.desktop

# Find the latest release
tag=$(gh api -X GET --jq .tag_name "/repos/$GH_REPO/releases/latest")
if [ -z "$tag" ]; then
    log "Error: got empty tag name"
    exit 1
fi
version=${tag#v}
appimage_name=Obsidian-$version.AppImage
appimage_path=$OPTDIR/$appimage_name
if [ -e "$appimage_path" ]; then
    log "Obsidian is up-to-date ($tag)"
    exit 0
fi

current_version=$(find . -maxdepth 1 -name 'Obsidian-*.AppImage' | head -n1)
if [ -n "$current_version" ]; then
    current_version=${current_version#./Obsidian-}
    current_version=${current_version%*.AppImage}
    log "Updating $current_version -> $version"
fi

rm -f "$OPTDIR"/*.AppImage

log "Downloading $tag from GitHub..."
gh release -R "$GH_REPO" download -p "$appimage_name" -O "$appimage_path"
chmod +x "$appimage_path"

cat > "$OPTDIR/obsidian.desktop" << EOF
[Desktop Entry]
Name=Obsidian
Exec=$appimage_path %u
Terminal=false
Type=Application
Icon=$OPTDIR/obsidian-icon.svg
StartupWMClass=obsidian
X-AppImage-Version=$version
Comment=Obsidian
Categories=Office;
MimeType=text/html;x-scheme-handler/obsidian;
EOF

ln -sf "$OPTDIR/obsidian.desktop" "$DESTPATH"
log "Installed .desktop file to $DESTPATH"
