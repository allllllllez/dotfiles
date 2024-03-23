-- ==============================================================================
-- Settings
-- ==============================================================================

local opt = vim.opt

-- スワップファイル/バックアップファイルを作らない
opt.swapfile = false
opt.backup = false
-- 編集中のファイルが変更されたら自動で読み直す
opt.autoread = true
-- バッファが編集中（未保存状態）で他ファイルを開くとき警告を出さない
opt.hidden = true
-- 入力中のコマンドをステータスに表示する
opt.showcmd = true

--
-- Appearance
--
-- カラースキーム（ベース。後の設定でちょっと改造する）
-- colorscheme slate
-- 行番号を表示
opt.number = true
-- opt.relativenumber = false
-- opt.signcolumn = "number"
-- 現在の行を強調表示
opt.cursorline = true
-- 現在の行を強調表示（縦）
-- opt.cursorcolumn
-- インデントはスマートインデント
opt.smartindent = true
-- ビープ音を可視化
opt.visualbell = true
-- 括弧入力時の対応する括弧を表示
opt.showmatch = true
-- ステータスラインを常に表示
opt.laststatus = 2
-- -- コマンドラインの補完
-- opt.wildmode = list:longest

-- シンタックスハイライトの有効化
-- syntax enable

--
-- Tab
--
-- 不可視文字を可視化(タブを「▸ 」、スペースを「⋅」で表示)
opt.list = true
opt.listchars = { tab = "▸ ", trail = "⋅", nbsp = "␣" }
-- 改行の色を変える
-- hi NonText ctermfg=59
-- タブの色を変える
-- hi SpecialKey ctermfg=59
-- Tab文字を半角スペースにする
-- opt.expandtab

-- タブ, インデント
-- 行頭以外のTab文字の表示幅（スペースいくつ分）
opt.tabstop = 4
opt.expandtab = true
-- 行頭でのTab文字の表示幅
opt.shiftwidth = 4
opt.smartindent = true

--
-- Search
--
-- 検索文字列が小文字の場合は大文字小文字を区別なく検索する
opt.ignorecase = true
-- 検索文字列に大文字が含まれている場合は区別して検索する
opt.smartcase = true
-- 検索文字列入力時に順次対象文字列にヒットさせる
opt.incsearch = true
-- 検索時に最後まで行ったら最初に戻る
opt.wrapscan = true
-- 検索語をハイライト表示
opt.hlsearch = true
