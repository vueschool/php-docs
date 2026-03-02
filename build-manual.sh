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

echo "==> Syncing PHP manual (lang: ${LANG})"
echo "    Source: ${RSYNC_SOURCE}"
echo "    Dest:   ${MANUAL_DEST}"
echo ""

mkdir -p "${MANUAL_DEST}"
rsync -avz --delete "${RSYNC_SOURCE}" "${MANUAL_DEST}"

TOTAL_FILES=$(find "${MANUAL_DEST}" -type f | wc -l | tr -d ' ')
echo ""
echo "==> Done!"
echo "    Files: ${TOTAL_FILES}"
echo "    Path:  ${MANUAL_DEST}"
echo ""
echo "    To serve locally:"
echo "      php -S localhost:8080 .router.php"
