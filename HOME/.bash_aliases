alias nv='nvim'
alias la='ls -la'

# Windows環境でのみ実行
if [[ "$OSTYPE" == msys* || "$OSTYPE" == "cygwin" ]]; then
    # 「the input device is not a TTY..」対策で winpty をつける
    alias docker='winpty docker'
else
    # Linux環境のみ
    alias claude="/home/you/.claude/local/claude"
fi
