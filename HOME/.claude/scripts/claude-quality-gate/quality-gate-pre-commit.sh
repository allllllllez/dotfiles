#!/bin/bash
# cf. https://github.com/takahirom/claude-code-quality-gate-example

# Source common configuration
source "$(dirname "$0")/common-config.sh"
check_dependencies

input_json=$(cat)
command=$(echo "$input_json" | jq -r '.tool_input.command')

if [[ "$command" =~ (^|[[:space:];&|])git[[:space:]]+.*commit([[:space:]]|$) ]]; then
    transcript_path=$(echo "$input_json" | jq -r '.transcript_path')
    
    # Use common function to get quality result
    get_quality_result "$transcript_path"
    result_status=$?
    
    case $result_status in
        0)  # APPROVED
            echo "✅ Quality gate approved - allowing commit" >&2
            exit 0
            ;;
        1)  # REJECTED
            echo "⚠️ Quality gate REJECTED - critical issues were found, but commit is allowed to proceed" >&2
            echo "Consider running /quality-gate to review and fix issues before committing" >&2
            exit 0
            ;;
        2)  # No verdict found
            echo "🔍 Quality check has not been run yet - commit is allowed to proceed" >&2
            echo "Consider running /quality-gate to perform quality inspection before committing" >&2
            exit 0
            ;;
        3)  # No edits made
            echo "✅ No edits detected - allowing commit" >&2
            exit 0
            ;;
    esac
fi

exit 0
