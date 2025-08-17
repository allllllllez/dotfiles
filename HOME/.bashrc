#!/usr/bin/bash

###############################################################################
# 
# Ubuntu デフォの .bashrc から拝借したいつものやつ
# 
############################################################################### 

# ~/.bashrc: 非ログインシェルでbash(1)によって実行される。
# 例については /usr/share/doc/bash/examples/startup-files (bash-docパッケージ内)
# を参照してください

# 対話的に実行されていない場合は、何もしない
case $- in
    *i*) ;;
      *) return;;
esac

# 履歴に重複行やスペースで始まる行を入れない。
# 詳細なオプションについては bash(1) を参照
HISTCONTROL=ignoreboth

# 履歴ファイルに追加し、上書きしない
shopt -s histappend

# 履歴の長さを設定する。bash(1) の HISTSIZE と HISTFILESIZE を参照
HISTSIZE=1000
HISTFILESIZE=2000

# 各コマンドの後にウィンドウサイズをチェックし、必要に応じて
# LINES と COLUMNS の値を更新する。
shopt -s checkwinsize

# 設定されている場合、パス名展開コンテキストで使用される "**" パターンは
# すべてのファイルと0個以上のディレクトリとサブディレクトリにマッチする。
#shopt -s globstar

# 非テキスト入力ファイルに対してlessをより使いやすくする、lesspipe(1)を参照
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 作業中のchrootを識別する変数を設定する（以下のプロンプトで使用）
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ファンシープロンプトを設定する(non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# ターミナルが対応している場合、カラープロンプトの場合はコメントを外す；デフォルトでは
# オフにしてユーザーを混乱させない：ターミナルウィンドウの焦点は
# プロンプトではなく、コマンドの出力にあるべき
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# 色のサポートがある；Ecma-48 (ISO/IEC-6429) に準拠しているとみなす
	# （このようなサポートの欠如は非常にまれで、そのような
	# 場合は setaf ではなく setf をサポートする傾向がある。）
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# xtermの場合はタイトルを user@host:dir に設定する
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# lsの色サポートを有効にし、便利なエイリアスも追加する
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# GCCの警告とエラーに色を付ける
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# さらにいくつかのlsエイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 長時間実行されるコマンド用の "alert" エイリアスを追加する。使用例：
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# エイリアス定義。
# すべての追加をここに直接追加するのではなく、~/.bash_aliases のような
# 別のファイルに入れることをお勧めします。
# bash-docパッケージの /usr/share/doc/bash-doc/examples を参照してください。

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# プログラマブル補完機能を有効にする（/etc/bash.bashrc と /etc/profile が
# /etc/bash.bashrc をソースしていて、すでに有効になっている場合は
# これを有効にする必要はありません）。
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export PATH="~/bin:$PATH"

# 
# いつものやつ ここまで
# 

# Windows環境でのみ実行
if [[ "$OSTYPE" == msys* || "$OSTYPE" == "cygwin" ]]; then
    # aws cli
    export PATH=/c/Program\ Files/Amazon/AWSCLIV2/:${PATH}

    # npm
    export PATH=${HOME}/AppData/Local/nvm:${PATH}
else # Linux環境のみ
    # starship
    eval "$(starship init bash)"

    # ssh-add
    eval `ssh-agent`
    ssh-add /home/you/.ssh/github # 必要に応じてuncomment、パスは自身の環境に合わせて変更
fi

# starship
eval "$(starship init bash)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# もしも direnv を使うなら uncomment
# export EDITOR=vi
# eval "$(direnv hook bash)"

# もしも pyenv を使うなら uncomment
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# aws sandbox login
# USAGE: $ aws_login 123456 > .env
function aws_login() {
    local session=`aws sts get-session-token --serial-number arn:aws:iam::123456789012:mfa/your_mfa --token-code $1 --profile default`
    local AccessKeyId=`echo $session | jq -r '.Credentials.AccessKeyId'`
    local SecretAccessKey=`echo $session | jq -r '.Credentials.SecretAccessKey'`
    local SessionToken=`echo $session | jq -r '.Credentials.SessionToken'`
    echo "export AWS_ACCESS_KEY_ID=$AccessKeyId"
    echo "export AWS_SECRET_ACCESS_KEY=$SecretAccessKey"
    echo "export AWS_SESSION_TOKEN=$SessionToken"
}

# ollama
function ollama_serve_obsidian() {
    OLLAMA_ORIGINS=app://obsidian.md* ollama serve
}

function ollama_serve() {
    ollama serve
}
