#!/usr/bin/env bash
#
# daily-git-pull.sh — cron から呼ばれる日次 git pull ラッパー
#
# ログ: ~/.local/log/git-pull-cron.log（30日超で自動削除）
#
set -euo pipefail

# --- 設定 ---
LOG_DIR="${HOME}/.local/log"
LOG_FILE="${LOG_DIR}/git-pull-cron.log"
MAX_LOG_SIZE=10485760  # 10MB
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MANAGE_REPOS="${DOTFILES_DIR}/scripts/common/manage-repos/manage-repos.sh"
GIT_PULL_ALL="${DOTFILES_DIR}/scripts/common/manage-repos/git_pull_all.sh"
REFER_DIR="${HOME}/git/refer"

# --- ログ準備 ---
mkdir -p "${LOG_DIR}"

# 10MB超のログを削除（次回実行時に再作成される）
if [[ -f "${LOG_FILE}" ]] && [[ "$(stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)" -gt ${MAX_LOG_SIZE} ]]; then
    rm -f "${LOG_FILE}"
fi

exec >> "${LOG_FILE}" 2>&1

echo "========================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Daily git pull started"
echo "========================================"

# --- repos.json 定義リポジトリの pull ---
echo "[manage-repos.sh --pull-only]"
bash "${MANAGE_REPOS}" --pull-only || echo "WARNING: manage-repos.sh failed ($?)"

# --- ~/git/refer/ 配下の全リポジトリを pull ---
echo ""
echo "[git_pull_all.sh ${REFER_DIR}]"
bash "${GIT_PULL_ALL}" "${REFER_DIR}" || echo "WARNING: git_pull_all.sh failed ($?)"

echo ""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Daily git pull finished"
echo ""
