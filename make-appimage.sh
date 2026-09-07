#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/scalable/apps/org.nickvision.tubeconverter.svg
export STARTUPWMCLASS=org.nickvision.tubeconverter
export DEPLOY_PYTHON=1
export STRACE_TIME=3

# Deploy dependencies
quick-sharun \
	./AppDir/bin/*            \
	/usr/bin/qjs              \
	/usr/bin/yt-dlp           \
	/usr/bin/aria2c           \
	/usr/lib/libgtk-4.so*     \
	/usr/lib/libadwaita-1.so* \
	/usr/lib/libgirepository*.so*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
