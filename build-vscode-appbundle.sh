#!/bin/bash
set -e

APP="VSCode"
ARCH="x86_64"
APPDIR="code.AppDir"

WORKDIR=$(mktemp -d)
trap 'echo "--> Cleaning up temporary directory..."; rm -r "$WORKDIR"' EXIT
cd "$WORKDIR"

echo "✅ Downloading necessary files..."
curl -L -s "https://github.com/xplshn/pelf/releases/latest/download/pelf_x86_64" -o pelf
chmod +x pelf
wget -q "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O vscode.deb

echo "📦 Extracting package..."
ar x vscode.deb
tar xf data.tar.xz

echo "🏗️ Assembling the AppDir..."
mv ./usr/share/code ./"$APPDIR"

echo "🚀 Creating the AppRun entrypoint..."
cat <<'EOF' > ./"$APPDIR"/AppRun
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/code" "$@"
EOF
chmod +x ./"$APPDIR"/AppRun

echo "🎨 Setting up icons and desktop entry..."
cp ./"$APPDIR"/resources/app/resources/linux/code.png ./"$APPDIR"/.DirIcon
cat <<EOF > ./"$APPDIR"/vscode.desktop
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=AppRun
Icon=.DirIcon
Type=Application
Categories=Utility;TextEditor;Development;IDE;
EOF

echo "🔎 Determining application version..."
VERSION=$(dpkg-deb -f vscode.deb Version)
APPBUNDLE_NAME="$APP-$VERSION-$ARCH.sqfs.AppBundle"
echo "Building $APPBUNDLE_NAME..."

./pelf --add-appdir "$APPDIR" --appbundle-id "com.microsoft.vscode.portable" --output-to "$APPBUNDLE_NAME"

echo "🎉 Build complete!"
mv "$APPBUNDLE_NAME" "$OLDPWD"
echo "AppBundle created at: $(realpath "$OLDPWD/$APPBUNDLE_NAME")"

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "appbundle_name=$APPBUNDLE_NAME" >> "$GITHUB_OUTPUT"
