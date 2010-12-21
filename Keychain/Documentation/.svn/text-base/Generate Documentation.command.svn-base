#!/bin/tcsh

cd ..
xcodebuild -project Keychain.xcodeproj -target Keychain -configuration Release build
cd -

# Public documentation
echo "Generating public documentation"
mkdir -p Public
find '../build/Release/Keychain.framework/Headers/' -name '*.h' | xargs headerdoc2html -o Public Keychain.hdoc
gatherheaderdoc Public

# Private documentation
echo "Generating internal documentation"
mkdir -p Private
find .. \( \( -name '*.m' \) -or \( -name '*.h' \) -or \( -name '*.mm' \) -or \( -name '*.c' \) \) -and \( \! -path '../build/*' \) | xargs headerdoc2html -o Private KeychainInternal.hdoc
gatherheaderdoc Private
