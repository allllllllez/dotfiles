#!/usr/bin/env bash
#
# ccusage-daily-notify.sh — 前日分の ccusage 集計を Slack Incoming Webhook に投稿する
#
# 使い方:
#   bash ccusage-daily-notify.sh            # 前日分を集計して投稿
#   bash ccusage-daily-notify.sh --dry-run  # 投稿せず、本文を標準出力に表示
#
# Webhook URL: ~/.config/ccusage-daily/webhook_url（権限 600。リポジトリには入れない）
# ログ: ~/.local/log/ccusage-daily.log（10MB 超で自動削除）
#
# ccusage は同ディレクトリの package-lock.json で固定したバージョンを、
# `npm ci --ignore-scripts` で入れて実行する。
#
set -Eeuo pipefail

# --- 設定 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${HOME}/.local/log"
LOG_FILE="${LOG_DIR}/ccusage-daily.log"
MAX_LOG_SIZE=10485760  # 10MB
WEBHOOK_FILE="${CCUSAGE_WEBHOOK_FILE:-${HOME}/.config/ccusage-daily/webhook_url}"
REPORT_TZ="Asia/Tokyo"
CCUSAGE_BIN="${SCRIPT_DIR}/node_modules/.bin/ccusage"

DRY_RUN=0
case "${1:-}" in
    --dry-run) DRY_RUN=1 ;;
    "") ;;
    *) echo "Usage: $0 [--dry-run]" >&2; exit 1 ;;
esac

# --- ログ準備（dry-run は標準出力のまま） ---
if [[ ${DRY_RUN} -eq 0 ]]; then
    mkdir -p "${LOG_DIR}"
    if [[ -f "${LOG_FILE}" ]] && [[ "$(stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)" -gt ${MAX_LOG_SIZE} ]]; then
        rm -f "${LOG_FILE}"
    fi
    exec >> "${LOG_FILE}" 2>&1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - ccusage daily notify started"

# --- Slack 投稿 ---
post_to_slack() {
    local text="$1" payload
    payload="$(jq -n --arg text "${text}" '{text: $text}')"
    if [[ ${DRY_RUN} -eq 1 ]]; then
        echo "[dry-run] 投稿本文:"
        echo "${text}"
        return 0
    fi
    # URL を引数に出さないため、curl の設定を標準入力から渡す
    printf 'url = "%s"\n' "$(tr -d '\n' < "${WEBHOOK_FILE}")" \
        | curl -sS --fail --max-time 30 -K - \
            -H 'Content-Type: application/json' --data-binary "${payload}"
    echo ""
}

# 失敗した日に気づけるよう、失敗を Slack にも知らせる（投稿自体の失敗はログのみ）
on_error() {
    local code=$?
    trap - ERR
    echo "ERROR: exit=${code} line=${BASH_LINENO[0]}"
    if [[ ${DRY_RUN} -eq 0 && -r "${WEBHOOK_FILE}" ]]; then
        post_to_slack "ccusage 日次通知が失敗しました（exit=${code}）。ログ: ${LOG_FILE}" || true
    fi
    exit "${code}"
}
trap on_error ERR

# --- 前提の確認 ---
if [[ ${DRY_RUN} -eq 0 ]]; then
    if [[ ! -r "${WEBHOOK_FILE}" ]]; then
        echo "ERROR: ${WEBHOOK_FILE} が読めません"
        exit 1
    fi
    if ! grep -q '^https://hooks\.slack\.com/' "${WEBHOOK_FILE}"; then
        echo "ERROR: ${WEBHOOK_FILE} の内容が Webhook URL の形式ではありません（https://hooks.slack.com/ で始まる必要があります）"
        exit 1
    fi
fi
command -v jq >/dev/null || { echo "ERROR: jq がありません"; exit 1; }

# cron の PATH には nvm 配下の node がないため、nvm を読み込む
export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    set +u
    # shellcheck disable=SC1091
    . "${NVM_DIR}/nvm.sh"
    set -u
fi
command -v node >/dev/null || { echo "ERROR: node がありません"; exit 1; }

# --- 依存の導入（lockfile が node_modules より新しいとき、または未導入のとき） ---
if [[ ! -x "${CCUSAGE_BIN}" || "${SCRIPT_DIR}/package-lock.json" -nt "${SCRIPT_DIR}/node_modules/.package-lock.json" ]]; then
    echo "[npm ci]"
    npm ci --prefix "${SCRIPT_DIR}" --ignore-scripts --no-audit --no-fund
fi

# --- 前日分の集計 ---
TARGET_DATE="$(TZ="${REPORT_TZ}" date -d yesterday +%F)"
echo "target date: ${TARGET_DATE} (${REPORT_TZ})"
USAGE_JSON="$("${CCUSAGE_BIN}" daily --json --since "${TARGET_DATE}" --until "${TARGET_DATE}" --timezone "${REPORT_TZ}")"

# --- 本文の整形 ---
MESSAGE="$(jq -r --arg date "${TARGET_DATE}" '
    def usd: (. * 100 | round) as $c
        | "$\($c / 100 | floor).\(($c % 100) | tostring | if length < 2 then "0" + . else . end)";
    def mtok: "\(. / 1000000 * 10 | round / 10)M";
    if (.daily | length) == 0 then
        "ccusage \($date): 使用量なし"
    else
        .daily[0] as $d
        | ["ccusage \($date)",
           "合計: \($d.totalCost | usd)（\($d.totalTokens | mtok) tokens）"]
          + ($d.modelBreakdowns | sort_by(-.cost) | map("- \(.modelName): \(.cost | usd)"))
        | join("\n")
    end
' <<< "${USAGE_JSON}")"

post_to_slack "${MESSAGE}"

echo "$(date '+%Y-%m-%d %H:%M:%S') - ccusage daily notify finished"
