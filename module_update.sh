#!/usr/bin/env bash
# module_update.sh - helper for manual testing of module clone, validation, deploy and container restart.
# Usage: ./module_update.sh <repo-url> <mount-path> <container-name> <github-token (optional)>
set -euo pipefail
REPO_URL="${1:-}"
MOUNT_PATH="${2:-/mnt/extra-addons}"
CONTAINER_NAME="${3:-odoo16}"
GITHUB_TOKEN="${4:-}"
TMPDIR="$(mktemp -d)"
echo "Cloning ${REPO_URL} into ${TMPDIR} ..."
if [ -n "${GITHUB_TOKEN}" ]; then
  git clone "https://${GITHUB_TOKEN}@${REPO_URL#https://}" "${TMPDIR}"
else
  git clone "${REPO_URL}" "${TMPDIR}"
fi
echo "Running python syntax check..."
if find "${TMPDIR}" -name '*.py' | grep -q .; then
  find "${TMPDIR}" -name '*.py' -print0 | xargs -0 -n1 -P2 python -m py_compile || { echo 'PY_COMPILE_FAIL'; exit 2; }
fi
echo "Syncing to ${MOUNT_PATH}..."
mkdir -p "${MOUNT_PATH}/$(basename ${REPO_URL%.*})"
rsync -av --delete "${TMPDIR}/" "${MOUNT_PATH}/$(basename ${REPO_URL%.*})/"
echo "Restarting container ${CONTAINER_NAME}..."
docker restart "${CONTAINER_NAME}" || { echo 'Failed to restart container'; exit 3; }
echo "Done."
