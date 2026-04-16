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
DOTFILES_DIR="${HOME}/git/dotfiles"
MANAGE_REPOS="${DOTFILES_DIR}/scripts/common/manage-repos/manage-repos.sh"
GIT_PULL_ALL="${DOTFILES_DIR}/scripts/common/manage-repos/git_pull_all.sh"
REFER_DIR="${HOME}/git/refer"

# --- ログ準備 ---
mkdir -p "${LOG_DIR}"

# 30日超のログを削除
if [[ -f "${LOG_FILE}" ]]; then
    find "${LOG_DIR}" -name "git-pull-cron.log" -mtime +30 -delete 2>/dev/null || true
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
