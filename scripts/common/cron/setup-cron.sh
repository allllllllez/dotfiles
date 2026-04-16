#!/usr/bin/env bash
#
# setup-cron.sh — 日次 git pull の cron エントリを管理する
#
# 使い方:
#   ./setup-cron.sh              # cron ジョブを登録
#   ./setup-cron.sh --remove     # cron ジョブを削除
#   ./setup-cron.sh --status     # 登録状態を表示
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRON_SCRIPT="${SCRIPT_DIR}/daily-git-pull.sh"
CRON_MARKER="# dotfiles:daily-git-pull"
CRON_SCHEDULE="0 6 * * *"
CRON_ENTRY="${CRON_SCHEDULE} bash ${CRON_SCRIPT} ${CRON_MARKER}"

usage() {
    echo "Usage: $0 [--remove] [--status]"
    echo "  (引数なし)  日次 git pull の cron ジョブを登録"
    echo "  --remove    cron ジョブを削除"
    echo "  --status    登録状態を表示"
}

remove_entry() {
    local current
    current=$(crontab -l 2>/dev/null || true)
    if echo "${current}" | grep -qF "${CRON_MARKER}"; then
        echo "${current}" | grep -vF "${CRON_MARKER}" | crontab -
        echo "日次 git pull の cron ジョブを削除しました。"
    else
        echo "日次 git pull の cron ジョブは登録されていません。"
    fi
}

install_entry() {
    local current
    current=$(crontab -l 2>/dev/null || true)

    # 冪等: 既存エントリを除去してから追加
    if echo "${current}" | grep -qF "${CRON_MARKER}"; then
        echo "既存の cron ジョブを更新します..."
        current=$(echo "${current}" | grep -vF "${CRON_MARKER}")
    fi

    printf '%s\n%s\n' "${current}" "${CRON_ENTRY}" | crontab -
    echo "日次 git pull の cron ジョブを登録しました:"
    echo "  ${CRON_ENTRY}"

    # WSL2 で cron が再起動後も動くか確認
    if grep -qs "systemd=true" /etc/wsl.conf 2>/dev/null && systemctl is-enabled cron &>/dev/null; then
        echo "cron は systemd 経由で自動起動します（追加設定不要）。"
    else
        echo ""
        echo "WARNING: WSL2 では再起動後に cron が停止する可能性があります。"
        echo "以下のいずれかで永続化してください:"
        echo "  1) /etc/wsl.conf に systemd=true を設定（推奨）"
        echo "  2) /etc/wsl.conf の [boot] に command = \"service cron start\" を追加"
    fi
}

show_status() {
    local current
    current=$(crontab -l 2>/dev/null || true)
    if echo "${current}" | grep -qF "${CRON_MARKER}"; then
        echo "INSTALLED:"
        echo "${current}" | grep -F "${CRON_MARKER}"
    else
        echo "NOT installed."
    fi
}

case "${1:-}" in
    --remove) remove_entry ;;
    --status) show_status ;;
    -h|--help) usage ;;
    "") install_entry ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
esac
