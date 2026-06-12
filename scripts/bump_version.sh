#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Usage: scripts/bump_version.sh [patch|minor|major|VERSION]

Bump the package version in Cargo.toml.

Examples:
  scripts/bump_version.sh patch
  scripts/bump_version.sh minor
  scripts/bump_version.sh major
  scripts/bump_version.sh 1.2.3
EOF
}

TARGET="${1:-patch}"

if [ "$TARGET" = "-h" ] || [ "$TARGET" = "--help" ]; then
  usage
  exit 0
fi

CURRENT="$(
  sed -n '0,/^version = /s/^version = "\([^"]*\)"/\1/p' Cargo.toml
)"

if [ -z "$CURRENT" ]; then
  echo "Could not find package version in Cargo.toml" >&2
  exit 1
fi

if [[ ! "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Current version is not supported by this script: $CURRENT" >&2
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

case "$TARGET" in
  patch)
    PATCH=$((PATCH + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  *)
    if [[ ! "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "Invalid target version or bump type: $TARGET" >&2
      usage >&2
      exit 2
    fi
    MAJOR="${TARGET%%.*}"
    REST="${TARGET#*.}"
    MINOR="${REST%%.*}"
    PATCH="${REST#*.}"
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

sed -i "0,/^version = \".*\"/s//version = \"${NEW_VERSION}\"/" Cargo.toml
echo "$NEW_VERSION" > VERSION

echo "Bumped version: $CURRENT -> $NEW_VERSION"
echo "Cargo.toml and VERSION updated."
