#!/bin/bash

# ---------------------------------------------------------
# SwiftFormat helper script
# ---------------------------------------------------------
# Usage:
#   ./format.sh            # formats the entire project
#   ./format.sh Sources/   # formats only the Sources folder
# ---------------------------------------------------------

set -e

# Path to format (default = current directory)
TARGET=${1:-"."}

echo "🧹 Running SwiftFormat on: $TARGET"

if ! command -v swiftformat &> /dev/null; then
    echo "❌ SwiftFormat is not installed."
    echo "👉 Install it via: brew install swiftformat"
    exit 1
fi

swiftformat "$TARGET"

echo "✅ SwiftFormat finished successfully!"
