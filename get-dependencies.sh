#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm yt-dlp aria2 dotnet-sdk blueprint-compiler gtk4 libadwaita

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

# If the application needs to be manually built that has to be done down here
echo "Building quickjs..."
echo "---------------------------------------------------------------"
git clone https://github.com/bellard/quickjs ./quickjs && (
	cd ./quickjs
	make -s
	make -s install PREFIX=/usr
)

# yt-dlp gives a warning that only deno is supported by default
sed -i -e "s|default=\['deno'\]|default=['quickjs']|" /usr/lib/python*/site-packages/yt_dlp/options.py

echo "Building parabolic as a self-contained .NET binary..."
echo "---------------------------------------------------------------"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
case "$ARCH" in
	x86_64)  farch=linux-x64;;
	aarch64) farch=linux-arm64;;
esac

git clone https://github.com/NickvisionApps/Parabolic.git ./parabolic && (
	cd ./parabolic

	TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|preview\|alpha\|beta' | head -1)
	git checkout "$TAG"
	echo "$TAG" > ~/version

	dotnet publish ./Nickvision.Parabolic.GNOME/Nickvision.Parabolic.GNOME.csproj \
		-c Release                \
		-r "$farch"               \
		--self-contained true     \
		-p:PublishAot=false       \
		-p:PublishTrimmed=true    \
		-p:TrimMode=partial       \
		-p:DebugSymbols=false     \
		-p:DebugType=None         \
		-p:JsonSerializerIsReflectionEnabledByDefault=true
)

_icon_dst=/usr/share/icons/hicolor/scalable/apps
mkdir -p ./AppDir/bin "$_icon_dst"
cp -v ./parabolic/resources/org.nickvision.tubeconverter.svg          "$_icon_dst"
cp -v ./parabolic/resources/org.nickvision.tubeconverter-devel.svg    "$_icon_dst"
cp -v ./parabolic/resources/org.nickvision.tubeconverter-symbolic.svg "$_icon_dst"

cp -r ./parabolic/Nickvision.Parabolic.GNOME/bin/Release/net*/"$farch"/publish/. ./AppDir/bin

# keep the original binary name, symlink a short alias for the .desktop Exec
# who types /Nickvision.Parabolic.GNOME to run a binary???
ln -s ./Nickvision.Parabolic.GNOME ./AppDir/bin/parabolic

# dlopen'd lazily only when tracing, would drag in liblttng-ust
rm -f ./AppDir/bin/libcoreclrtraceptprovider.so

cp -v ./parabolic/resources/linux/org.nickvision.tubeconverter.desktop.in ./AppDir/tubeconverter.desktop
sed -i -e "s|@APP_ID@|org.nickvision.tubeconverter|g" \
	-e "s|@OUTPUT_NAME@|parabolic|g" \
	-e "s|^Exec=[^ ]*|Exec=parabolic|g" \
	./AppDir/tubeconverter.desktop
