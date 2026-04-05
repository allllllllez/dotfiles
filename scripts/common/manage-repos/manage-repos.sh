#!/usr/bin/env bash
#
# manage-repos.sh — repos.json に基づき外部リポジトリの clone/pull とシンボリックリンク作成を行う
#
# 使い方:
#   ./manage-repos.sh              # clone/pull + symlink
#   ./manage-repos.sh --dry-run    # 実行内容の表示のみ（変更なし）
#   ./manage-repos.sh --pull-only  # pull のみ（symlink 作成しない）
#
# 依存: git, jq
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="${SCRIPT_DIR}/repos.json"
DRY_RUN=false
PULL_ONLY=false
BAKDIR="${HOME}/.repos-links.bak"

# --- 引数パース ---
for arg in "$@"; do
    case "$arg" in
        --dry-run)  DRY_RUN=true ;;
        --pull-only) PULL_ONLY=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--pull-only]"
            echo "  --dry-run    実行内容を表示するのみ"
            echo "  --pull-only  git pull のみ（symlink 作成しない）"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

# --- 前提チェック ---
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq が見つかりません。先にインストールしてください。" >&2
    exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: マニフェストが見つかりません: $MANIFEST" >&2
    exit 1
fi

# --- リポジトリ数を取得 ---
REPO_COUNT=$(jq '.repos | length' "$MANIFEST")

if [[ "$REPO_COUNT" -eq 0 ]]; then
    echo "repos.json にリポジトリが定義されていません。"
    exit 0
fi

echo "=== manage-repos: ${REPO_COUNT} リポジトリを処理 ==="
[[ "$DRY_RUN" == true ]] && echo "(dry-run モード: 変更は行いません)"
echo ""

# --- チルダ展開 ---
expand_tilde() {
    local path="$1"
    echo "${path/#\~/$HOME}"
}

# --- メイン処理 ---
for i in $(seq 0 $((REPO_COUNT - 1))); do
    URL=$(jq -r ".repos[$i].url" "$MANIFEST")
    CLONE_PATH=$(expand_tilde "$(jq -r ".repos[$i].path" "$MANIFEST")")
    BRANCH=$(jq -r ".repos[$i].branch // \"\"" "$MANIFEST")

    echo "--- [$((i + 1))/${REPO_COUNT}] ${URL} ---"
    echo "    clone先: ${CLONE_PATH}"

    # --- Clone or Pull ---
    if [[ -d "$CLONE_PATH/.git" ]]; then
        echo "    状態: 既存リポジトリ → fetch + pull"
        if [[ "$DRY_RUN" == false ]]; then
            git -C "$CLONE_PATH" fetch --prune
            if [[ -n "$BRANCH" ]]; then
                git -C "$CLONE_PATH" pull origin "$BRANCH"
            else
                git -C "$CLONE_PATH" pull
            fi
        fi
    else
        echo "    状態: 新規 → clone"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$(dirname "$CLONE_PATH")"
            if [[ -n "$BRANCH" ]]; then
                git clone --branch "$BRANCH" "$URL" "$CLONE_PATH"
            else
                git clone "$URL" "$CLONE_PATH"
            fi
        fi
    fi

    # --- Symlink 作成 ---
    if [[ "$PULL_ONLY" == true ]]; then
        echo "    symlink: スキップ (--pull-only)"
        echo ""
        continue
    fi

    LINK_COUNT=$(jq ".repos[$i].links | length" "$MANIFEST")

    if [[ "$LINK_COUNT" -eq 0 ]]; then
        echo "    symlink: 定義なし"
        echo ""
        continue
    fi

    for j in $(seq 0 $((LINK_COUNT - 1))); do
        SRC_REL=$(jq -r ".repos[$i].links[$j].src" "$MANIFEST")
        DEST=$(expand_tilde "$(jq -r ".repos[$i].links[$j].dest" "$MANIFEST")")
        SRC="${CLONE_PATH}/${SRC_REL}"

        # ソースの存在確認
        if [[ ! -e "$SRC" ]]; then
            echo "    WARNING: ソースが存在しません: ${SRC}" >&2
            continue
        fi

        # 既にリンク済みで正しい場合はスキップ
        if [[ -L "$DEST" ]]; then
            CURRENT_TARGET=$(readlink -f "$DEST")
            EXPECTED_TARGET=$(readlink -f "$SRC")
            if [[ "$CURRENT_TARGET" == "$EXPECTED_TARGET" ]]; then
                echo "    symlink: ${DEST} → 既にリンク済み（スキップ）"
                continue
            fi
        fi

        echo "    symlink: ${DEST} → ${SRC}"

        if [[ "$DRY_RUN" == false ]]; then
            # 既存ファイル/ディレクトリのバックアップ
            if [[ -e "$DEST" || -L "$DEST" ]]; then
                mkdir -p "$BAKDIR"
                BAKNAME="$(basename "$DEST").$(date +%Y%m%d%H%M%S)"
                echo "    backup: ${DEST} → ${BAKDIR}/${BAKNAME}"
                mv "$DEST" "${BAKDIR}/${BAKNAME}"
            fi

            # 親ディレクトリ作成
            mkdir -p "$(dirname "$DEST")"

            # シンボリックリンク作成
            ln -s "$SRC" "$DEST"
        fi
    done

    echo ""
done

echo "=== manage-repos: 完了 ==="
