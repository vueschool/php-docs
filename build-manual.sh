#!/usr/bin/env bash
set -euo pipefail

#
# Download the pre-built PHP manual and install it.
# Uses only standard Ubuntu tools: curl, tar, mkdir, md5sum.
#
# Safe to run multiple times — skips download if already up to date.
#
# Usage:
#   ./build-manual.sh              # Download English manual
#   ./build-manual.sh --lang=ja    # Download Japanese manual
#   ./build-manual.sh --force      # Force re-download even if up to date
#   ./build-manual.sh --clean      # Remove temp files
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG="en"
FORCE=false

for arg in "$@"; do
    case $arg in
        --lang=*)
            LANG="${arg#*=}"
            ;;
        --force)
            FORCE=true
            ;;
        --clean)
            echo "Cleaning temp files..."
            rm -f /tmp/php_manual_*.tar.gz
            rm -f "${SCRIPT_DIR}"/manual/.last_*
            echo "Done."
            exit 0
            ;;
        --help)
            echo "Usage: ./build-manual.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --lang=CODE   Language to download (default: en)"
            echo "                Examples: en, ja, de, fr, es, pt_BR, ru, zh, tr"
            echo "  --force       Force re-download even if up to date"
            echo "  --clean       Remove state and temp files"
            echo "  --help        Show this help message"
            exit 0
            ;;
    esac
done

TARBALL_URL="https://www.php.net/distributions/manual/php_manual_${LANG}.tar.gz"
TARBALL="/tmp/php_manual_${LANG}.tar.gz"
MANUAL_DEST="${SCRIPT_DIR}/manual/${LANG}"
ETAG_FILE="${SCRIPT_DIR}/manual/.last_etag_${LANG}"

# Check remote ETag to see if the manual has been updated
echo "==> Checking for updates (lang: ${LANG})..."
REMOTE_ETAG=$(curl -sfI "${TARBALL_URL}" | grep -i '^etag:' | tr -d '\r' || true)

if [ "${FORCE}" = false ] && [ -f "${ETAG_FILE}" ] && [ -n "${REMOTE_ETAG}" ]; then
    LOCAL_ETAG=$(cat "${ETAG_FILE}")
    if [ "${REMOTE_ETAG}" = "${LOCAL_ETAG}" ]; then
        echo "    Manual is already up to date. Use --force to re-download."
        exit 0
    fi
fi

echo "==> Downloading PHP manual (lang: ${LANG})"
echo "    URL: ${TARBALL_URL}"
curl -fSL -o "${TARBALL}" "${TARBALL_URL}"

echo "==> Extracting to ${MANUAL_DEST}"
mkdir -p "${MANUAL_DEST}"
tar -xzf "${TARBALL}" -C "${MANUAL_DEST}" --strip-components=1

rm -f "${TARBALL}"

# Save ETag so next run can skip if unchanged
mkdir -p "${SCRIPT_DIR}/manual"
if [ -n "${REMOTE_ETAG}" ]; then
    echo "${REMOTE_ETAG}" > "${ETAG_FILE}"
fi

TOTAL_FILES=$(find "${MANUAL_DEST}" -type f | wc -l | tr -d ' ')
echo ""
echo "==> Done!"
echo "    Files: ${TOTAL_FILES}"
echo "    Path:  ${MANUAL_DEST}"
echo ""
echo "    To serve locally:"
echo "      php -S localhost:8080 .router.php"
