# draw.io の CLI の場所

`which drawio` で見つからないときに、OS ごとの既定の場所を探す。

| 環境 | 呼び方 |
|---|---|
| macOS | `/Applications/draw.io.app/Contents/MacOS/draw.io` |
| Linux（deb、rpm、snap） | `drawio` |
| Linux（flatpak） | `flatpak run com.jgraph.drawio.desktop` |
| Linux（AppImage） | 落とした `.AppImage` ファイルのパス |
| Windows（インストーラー版） | `C:\Program Files\draw.io\draw.io.exe` |
| Windows（MSI 版、ユーザー単位） | `%LOCALAPPDATA%\Programs\draw.io\draw.io.exe` |
| WSL2 | `/mnt/c/Program Files/draw.io/draw.io.exe`（`/proc/version` に `microsoft` が含まれていれば WSL2） |

画面の無い Linux（サーバーやコンテナ）では、draw.io はブラウザの部品で描くので、そのままでは動かない。`xvfb-run -a drawio -x ...` のように仮想のディスプレイで包む。WSL2 から Windows の draw.io を呼ぶとき、ファイルが見つからないと言われたら、パスを `wslpath -w` で Windows の形にして渡す。

## 書き出しが止まったとき

書き出しは止まることがあるので、`timeout 120 xvfb-run -a drawio -x ...` のように `timeout` を付けて実行する。時間切れになれば、`timeout` が起動したプロセスを止める。

止まったプロセスを `pkill -f drawio` や `pkill -f Xvfb` のように名前で止めない。同じ機械で動いている別の作業の draw.io や Xvfb まで止まる。止める必要があるときは、自分が起動したプロセスの PID だけを `kill` する。

2回続けて止まったら書き出しを諦め、XML の検査だけを済ませて、目で確かめていないことを最後に伝える。
