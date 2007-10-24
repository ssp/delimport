# Public documentation
echo "Generating public documentation"
mkdir -p Documentation/Public
find . \( -name '*.h' \) -and \( \! -path './build/*' \) | xargs headerdoc2html -o Documentation/Public Keychain.hdoc
gatherheaderdoc Documentation/Public

# Private documentation
echo "Generating internal documentation"
mkdir -p Documentation/Private
find . \( -name '*.m' \) -and \( \! -path './build/*' \) | xargs headerdoc2html -o Documentation/Private KeychainInternal.hdoc
gatherheaderdoc Documentation/Private
