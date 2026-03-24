alias nv='nvim'
alias la='ls -la'

alias git-fetch='git fetch'
alias git-switch-main='git-fetch && git branch -D main && git switch -c main --track origin/main'

# Windows環境でのみ実行
if [[ "$OSTYPE" == msys* || "$OSTYPE" == "cygwin" ]]; then
    # Rancher Desktop の docker CLI 互換
    # 「the input device is not a TTY..」対策で winpty をつける
    alias docker='winpty docker'
else
    # Linux環境のみ
    alias tm='tmux attach -t default || tmux new -s default'
fi
