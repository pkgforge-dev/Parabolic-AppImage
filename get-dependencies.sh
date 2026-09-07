#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm yt-dlp lttng-ust2.12

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

echo "Building quickjs..."
echo "---------------------------------------------------------------"
git clone https://github.com/bellard/quickjs ./quickjs && (
	cd ./quickjs
	make -s
	make -s install PREFIX=/usr
)

# yt-dlp gives a warning that only deno is supported by default
sed -i -e "s|default=\['deno'\]|default=['quickjs']|" /usr/lib/python*/site-packages/yt_dlp/options.py

# build self contained binary
export PRE_BUILD_CMDS="sed -i -e 's|SelfContained=false|SelfContained=true|g' ./PKGBUILD"
make-aur-package parabolic
pacman -Rdd --noconfirm dotnet-runtime


# If the application needs to be manually built that has to be done down here

# if you also have to make nightly releases check for DEVEL_RELEASE = 1
#
# if [ "${DEVEL_RELEASE-}" = 1 ]; then
# 	nightly build steps
# else
# 	regular build steps
# fi
