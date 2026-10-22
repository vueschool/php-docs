#!/usr/bin/env bash
set -euo pipefail

#
# Sync the pre-built PHP manual (.php format) from rsync.php.net.
# Uses only standard Ubuntu tools: rsync.
#
# Safe to run multiple times — rsync only transfers changed files.
#
# Usage:
#   ./build-manual.sh              # Sync English manual
#   ./build-manual.sh --lang=ja    # Sync Japanese manual
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG="en"

for arg in "$@"; do
    case $arg in
        --lang=*)
            LANG="${arg#*=}"
            ;;
        --help)
            echo "Usage: ./build-manual.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --lang=CODE   Language to sync (default: en)"
            echo "                Examples: en, ja, de, fr, es, pt_BR, ru, zh, tr"
            echo "  --help        Show this help message"
            exit 0
            ;;
    esac
done

RSYNC_SOURCE="rsync://rsync.php.net/phpweb/manual/${LANG}/"
MANUAL_DEST="${SCRIPT_DIR}/manual/${LANG}/"
# Persistent copy that outlives releases (Forge keeps releases/<id> next to shared/).
MANUAL_CACHE="${MANUAL_CACHE:-${SCRIPT_DIR}/../../shared/manual/${LANG}}"

echo "==> Syncing PHP manual (lang: ${LANG})"
echo "    Source: ${RSYNC_SOURCE}"
echo "    Dest:   ${MANUAL_DEST}"
echo "    Cache:  ${MANUAL_CACHE}"
echo ""

mkdir -p "${MANUAL_DEST}"

# Start from the last good copy so a fresh release is never empty.
if [ -d "${MANUAL_CACHE}" ]; then
    rsync -a "${MANUAL_CACHE}/" "${MANUAL_DEST}"
fi

# php.net has moved or removed manual/<lang> from the rsync module before
# (Oct 2026), so an upstream failure must not fail the deploy while we hold
# a good copy.
if rsync -avz --delete "${RSYNC_SOURCE}" "${MANUAL_DEST}"; then
    mkdir -p "${MANUAL_CACHE}"
    rsync -a --delete "${MANUAL_DEST}" "${MANUAL_CACHE}/"
elif [ -d "${MANUAL_CACHE}" ]; then
    echo "!!  Upstream sync failed; keeping the cached manual from ${MANUAL_CACHE}" >&2
else
    echo "!!  Upstream sync failed and there is no cached manual to fall back to" >&2
    exit 1
fi

TOTAL_FILES=$(find "${MANUAL_DEST}" -type f | wc -l | tr -d ' ')
echo ""
echo "==> Done!"
echo "    Files: ${TOTAL_FILES}"
echo "    Path:  ${MANUAL_DEST}"
echo ""
echo "    To serve locally:"
echo "      php -S localhost:8080 .router.php"
