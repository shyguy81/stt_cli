#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/create_and_push_tag.sh [TAG] [--push]
# If TAG is omitted, the script finds the latest tag matching v* and increments the patch.
# With --push, the tag is pushed to the 'origin' remote.

cd "$(dirname "$0")/.."

PUSH=false
TAG_ARG=""

for a in "$@"; do
  case "$a" in
    --push) PUSH=true ;;
    -h|--help) echo "Usage: $0 [TAG] [--push]"; exit 0 ;;
    *) TAG_ARG="$a" ;;
  esac
done

if [ -n "$TAG_ARG" ]; then
  TAG="$TAG_ARG"
  case "$TAG" in
    v*) ;;
    *) TAG="v$TAG" ;;
  esac
else
  git fetch --tags origin || true
  LATEST_TAG=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)

  if [ -z "$LATEST_TAG" ]; then
    TAG="v0.1.0"
  else
    # Strip leading 'v'
    V=${LATEST_TAG#v}
    IFS='.' read -r MAJ MIN PATCH <<< "$V"
    if [[ -z "$MAJ" || -z "$MIN" || -z "$PATCH" ]]; then
      echo "Latest tag ($LATEST_TAG) doesn't look like semver vMAJOR.MINOR.PATCH" >&2
      exit 1
    fi
    PATCH=$((PATCH + 1))
    TAG="v${MAJ}.${MIN}.${PATCH}"
  fi
fi

echo "Creating tag: $TAG"
git tag -a "$TAG" -m "Release $TAG"

# Persist version in VERSION (without leading 'v') and commit the change if any
NEW_VERSION="${TAG#v}"
echo "$NEW_VERSION" > VERSION
git add VERSION
# Commit may fail if there are no changes; allow that without exiting
git commit -m "Bump version to ${NEW_VERSION}" || true

if [ "$PUSH" = true ]; then
  if git remote | grep -q '^origin$'; then
    echo "Pushing tag $TAG to origin..."
    # Push branch (if not detached) and tag so VERSION change is pushed as well
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$BRANCH" != "HEAD" ]; then
      echo "Pushing branch $BRANCH to origin..."
      git push origin "$BRANCH"
    else
      echo "Detached HEAD; skipping branch push."
    fi
    git push origin "$TAG"
    echo "Tag pushed."
  else
    echo "No 'origin' remote found. Skipping push." >&2
    exit 1
  fi
else
  echo "Tag created locally (not pushed). Use --push to push to origin." 
fi
