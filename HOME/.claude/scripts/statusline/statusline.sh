#!/bin/bash

# Read JSON from stdin
input=$(cat)

# Extract basic info
SESSION_ID=$(echo "$input" | jq -r '.session_id // "N/A"')
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# Calculate context window usage
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

TOKEN_INFO="0%"
if [ "$USAGE" != "null" ] && [ "$CONTEXT_SIZE" -gt 0 ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq -r '.input_tokens // 0')
    CACHE_CREATE=$(echo "$USAGE" | jq -r '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq -r '.cache_read_input_tokens // 0')
    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    TOKEN_INFO="${PERCENT_USED}%"
fi

# Get Git branch
GIT_BRANCH="N/A"
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH="$BRANCH"
    fi
fi

# Get PR info with caching
CACHE_FILE="$HOME/.claude/pr-cache.json"
CACHE_TTL=60
PR_INFO=""

get_pr_info() {
    if command -v gh &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
        PR_DATA=$(gh pr view --json url,state,statusCheckRollup 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$PR_DATA" ]; then
            echo "$PR_DATA" > "$CACHE_FILE"
            echo "$(date +%s)" > "${CACHE_FILE}.timestamp"
            echo "$PR_DATA"
        fi
    fi
}

# Check cache
if [ -f "$CACHE_FILE" ] && [ -f "${CACHE_FILE}.timestamp" ]; then
    CACHE_TIME=$(cat "${CACHE_FILE}.timestamp")
    CURRENT_TIME=$(date +%s)
    AGE=$((CURRENT_TIME - CACHE_TIME))

    if [ $AGE -lt $CACHE_TTL ]; then
        PR_DATA=$(cat "$CACHE_FILE")
    else
        PR_DATA=$(get_pr_info)
    fi
else
    PR_DATA=$(get_pr_info)
fi

# Parse PR info
if [ -n "$PR_DATA" ]; then
    PR_URL=$(echo "$PR_DATA" | jq -r '.url // ""')
    PR_STATE=$(echo "$PR_DATA" | jq -r '.state // ""')

    # Check status checks
    STATUS_ROLLUP=$(echo "$PR_DATA" | jq -r '.statusCheckRollup[0].state // "NONE"')

    case "$STATUS_ROLLUP" in
        SUCCESS) STATUS_ICON="✅" ;;
        FAILURE) STATUS_ICON="❌" ;;
        PENDING) STATUS_ICON="🔄" ;;
        *) STATUS_ICON="⚪" ;;
    esac

    if [ -n "$PR_URL" ]; then
        PR_INFO=" | PR: $PR_URL ($STATUS_ICON)"
    fi
fi

# Build status line
echo "Session: $SESSION_ID | Model: $MODEL | Tokens: $TOKEN_INFO | Branch: $GIT_BRANCH$PR_INFO"
