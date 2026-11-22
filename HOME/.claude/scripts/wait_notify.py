#!/usr/bin/env python3
"""Claude Code のセッションが応答待ちのまま放置されたら、Windows のトーストと beep で知らせる。

hook から次のように呼ぶ。
  wait_notify.py start <kind>  応答待ちに入った（kind: stop / permission）
  wait_notify.py pretool       PreToolUse。AskUserQuestion なら応答待ちに入り、それ以外なら解く
  wait_notify.py clear         応答待ちが解けた

start のたびに新しいトークンを状態ファイルへ書き、監視プロセスを切り離して起動する。
監視プロセスは、起動直後に1回通知し、その後は状態ファイルのトークンが自分のものである間だけ再通知する。
再通知は同じ応答待ちにつき最大 MAX_COUNT 回で打ち切る。
"""

import base64
import json
import os
import re
import subprocess
import sys
import time
import uuid
from pathlib import Path

STATE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "claude-wait-notify"
FIRST_DELAY = int(os.environ.get("CLAUDE_WAIT_NOTIFY_FIRST", "180"))
INTERVAL = int(os.environ.get("CLAUDE_WAIT_NOTIFY_INTERVAL", "180"))
MAX_COUNT = int(os.environ.get("CLAUDE_WAIT_NOTIFY_MAX", "10"))

KIND_LABEL = {"stop": "入力待ち", "permission": "権限の確認待ち", "question": "質問への回答待ち"}
POWERSHELL_AUMID = r"{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"


def state_path(session_id: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9_-]", "_", session_id)
    return STATE_DIR / safe


def read_token(path: Path) -> str | None:
    try:
        return json.loads(path.read_text()).get("token")
    except (OSError, ValueError):
        return None


def xml_escape(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def notify(title: str, body: str) -> None:
    toast_xml = (
        "<toast><visual><binding template='ToastGeneric'>"
        f"<text>{xml_escape(title)}</text><text>{xml_escape(body)}</text>"
        "</binding></visual></toast>"
    )
    script = f"""
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml(@'
{toast_xml}
'@)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('{POWERSHELL_AUMID}').Show([Windows.UI.Notifications.ToastNotification]::new($xml))
[System.Media.SystemSounds]::Beep.Play()
"""
    encoded = base64.b64encode(script.encode("utf-16-le")).decode("ascii")
    subprocess.run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=30,
        check=False,
    )


def watch(session_id: str, token: str) -> None:
    path = state_path(session_id)
    if read_token(path) != token:
        return
    state = json.loads(path.read_text())
    project = Path(state.get("cwd") or "").name or "(unknown)"
    notify(f"Claude Code {KIND_LABEL.get(state['kind'], '応答待ち')}", f"{project}（session {session_id[:8]}）")
    for count in range(1, MAX_COUNT + 1):
        time.sleep(FIRST_DELAY if count == 1 else INTERVAL)
        if read_token(path) != token:
            return
        waited_min = int((time.time() - state["since"]) // 60)
        notify(
            f"Claude Code {KIND_LABEL.get(state['kind'], '応答待ち')} ({count}/{MAX_COUNT})",
            f"{project} が {waited_min} 分待っています（session {session_id[:8]}）",
        )
    if read_token(path) == token:
        path.unlink(missing_ok=True)


def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] == "watch":
        watch(sys.argv[2], sys.argv[3])
        return 0

    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0
    session_id = payload.get("session_id")
    if not session_id or len(sys.argv) < 2:
        return 0
    path = state_path(session_id)

    command = sys.argv[1]
    if command == "pretool":
        command = "start" if payload.get("tool_name") == "AskUserQuestion" else "clear"
        sys.argv[2:] = ["question"]

    if command == "clear":
        path.unlink(missing_ok=True)
        return 0

    if command == "start":
        kind = sys.argv[2] if len(sys.argv) >= 3 else "stop"
        token = uuid.uuid4().hex
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({"token": token, "kind": kind, "since": time.time(), "cwd": payload.get("cwd")}))
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "watch", session_id, token],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
