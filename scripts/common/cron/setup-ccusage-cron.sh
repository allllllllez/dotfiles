#!/usr/bin/env bash
#
# setup-ccusage-cron.sh — ccusage 日次通知の cron エントリを管理する
#
# 使い方:
#   ./setup-ccusage-cron.sh              # cron ジョブを登録
#   ./setup-ccusage-cron.sh --remove     # cron ジョブを削除
#   ./setup-ccusage-cron.sh --status     # 登録状態を表示
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRON_SCRIPT="${SCRIPT_DIR}/ccusage-daily/ccusage-daily-notify.sh"
CRON_MARKER="# dotfiles:ccusage-daily"
CRON_SCHEDULE="0 9 * * *"
CRON_ENTRY="${CRON_SCHEDULE} bash ${CRON_SCRIPT} ${CRON_MARKER}"

usage() {
    echo "Usage: $0 [--remove] [--status]"
    echo "  (引数なし)  ccusage 日次通知の cron ジョブを登録"
    echo "  --remove    cron ジョブを削除"
    echo "  --status    登録状態を表示"
}

remove_entry() {
    local current
    current=$(crontab -l 2>/dev/null || true)
    if echo "${current}" | grep -qF "${CRON_MARKER}"; then
        echo "${current}" | grep -vF "${CRON_MARKER}" | crontab -
        echo "ccusage 日次通知の cron ジョブを削除しました。"
    else
        echo "ccusage 日次通知の cron ジョブは登録されていません。"
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

    if [[ -n "${current}" ]]; then
        printf '%s\n%s\n' "${current}" "${CRON_ENTRY}" | crontab -
    else
        printf '%s\n' "${CRON_ENTRY}" | crontab -
    fi
    echo "ccusage 日次通知の cron ジョブを登録しました:"
    echo "  ${CRON_ENTRY}"

    # WSL2 で cron が再起動後も動くか確認
    if grep -qs "systemd=true" /etc/wsl.conf 2>/dev/null && systemctl is-enabled cron &>/dev/null; then
        echo "cron は systemd 経由で自動起動します（追加設定不要）。"
    else
        echo ""
        echo "WARNING: WSL2 では再起動後に cron が停止する可能性があります。"
        echo "  /etc/wsl.conf に systemd=true を設定してください。"
    fi
    echo "WSL が停止している時刻に当たった日の通知は、実行されず欠測になります。"
}

show_status() {
    local current line entry script log_file last_run webhook_file
    current=$(crontab -l 2>/dev/null || true)
    if ! echo "${current}" | grep -qF "${CRON_MARKER}"; then
        echo "NOT installed."
        return 1
    fi

    line=$(echo "${current}" | grep -F "${CRON_MARKER}")
    echo "INSTALLED:"
    echo "${line}"

    entry="${line% "${CRON_MARKER}"}"
    script="${entry#*bash }"

    log_file="${HOME}/.local/log/ccusage-daily.log"
    last_run=$(grep 'ccusage daily notify finished' "${log_file}" 2>/dev/null | tail -n 1 || true)
    echo "最終成功: ${last_run:-記録なし}"

    webhook_file="${HOME}/.config/ccusage-daily/webhook_url"
    if [[ ! -s "${webhook_file}" ]]; then
        echo "MISMATCH: Webhook URL が未保存です: ${webhook_file}" >&2
        return 1
    fi
    if [[ ! -f "${script}" ]]; then
        echo "MISMATCH: 登録されたスクリプトが存在しません: ${script}" >&2
        return 1
    fi
    if [[ "${script}" != "${CRON_SCRIPT}" ]]; then
        echo "MISMATCH: 登録パスがこのクローンと異なります (登録: ${script} / 期待: ${CRON_SCRIPT})" >&2
        return 1
    fi
}

case "${1:-}" in
    --remove) remove_entry ;;
    --status) show_status ;;
    -h|--help) usage ;;
    "") install_entry ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
esac
