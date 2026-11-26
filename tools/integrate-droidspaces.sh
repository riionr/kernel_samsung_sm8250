#!/usr/bin/env bash

set -euo pipefail

BASE="77c136a74135"
VALIDATED="71ac694716f0"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <upstream-ref> <new-branch>"
    exit 1
fi

TARGET="$1"
BRANCH="$2"

cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: Working tree is not clean."
    exit 1
fi

git rev-parse --verify "${TARGET}^{commit}" >/dev/null
git rev-parse --verify "${VALIDATED}^{commit}" >/dev/null

if ! git merge-base --is-ancestor "$BASE" "$TARGET"; then
    echo "ERROR: Target does not descend from validated base."
    exit 1
fi

if git merge-base --is-ancestor 43275a1e3 "$TARGET"; then
    echo "ERROR: Target already contains DroidSpaces integration."
    exit 1
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "ERROR: Branch already exists."
    exit 1
fi

echo "=== Creating integration branch ==="

git switch -c "$BRANCH" "$TARGET"

echo "=== Applying validated integration commits ==="

if ! git cherry-pick "$BASE..$VALIDATED"; then
    echo "ERROR: Integration conflict detected."
    echo "Review conflicts before continuing."
    echo "Use git cherry-pick --abort to cancel."
    exit 1
fi

echo "=== Integration completed ==="
echo "Branch: $BRANCH"
echo "Review dependency versions before building."
echo "Compilation and device testing are required."
