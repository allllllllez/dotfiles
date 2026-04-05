#!/usr/bin/env python3
"""
Generate ASCII art from Japanese text for Neovim/Vim startup screens.

Rendering styles:
  - outline: edge-detected half-block characters (▀/▄/█)
  - shadow: outline + offset solid shadow for 3D effect
  - Pre-made AA: loaded from premade_ascii_art.txt (hand-crafted)
"""

import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent

LUA_OUTPUT = PROJECT_ROOT / "HOME" / ".config" / "nvim" / "lua" / "data" / "ascii_art.lua"
VIM_OUTPUT = PROJECT_ROOT / "HOME" / ".vim" / "startup" / "ascii_art_data.vim"

# Messages to render with Pillow
MESSAGES = [
    "今北産業",
    "そんなことより\nおうどんたべたい",
    "日本語でおｋ",
    "ググレカス",
    "まるで成長\nしていない",
    "ぬるぽ",
    "ガッ",
    "半年ROMれ",
    "逝ってよし",
    "通報しますた",
]

# Rendering styles for each message
STYLES = ["outline", "shadow"]

# Pre-made AA file: sections separated by "--- label" lines
PREMADE_ART_FILE = SCRIPT_DIR / "premade_ascii_art.txt"

# Japanese font search paths
FONT_CANDIDATES = [
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf",
    "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf",
    "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
]

# Half-block rendering: each pixel = 1 column (▀/▄/█), 2 rows per char
MAX_COLS = 120
MAX_PIXEL_WIDTH = MAX_COLS  # 120 pixels (1 char per pixel)


def find_font() -> str:
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return path
    import subprocess
    try:
        result = subprocess.run(
            ["fc-match", "-f", "%{file}", ":lang=ja:style=Bold"],
            capture_output=True, text=True, check=True,
        )
        if result.stdout and os.path.exists(result.stdout.strip()):
            return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    print("ERROR: No Japanese font found. Install noto-cjk or specify font path.", file=sys.stderr)
    sys.exit(1)


def find_font_size(font_path: str, text: str) -> int:
    """Find the largest font size that fits within MAX_PIXEL_WIDTH."""
    lines = text.split("\n")
    for size in range(48, 5, -1):
        font = ImageFont.truetype(font_path, size)
        max_pixel_width = 0
        for line in lines:
            bbox = font.getbbox(line)
            w = bbox[2] - bbox[0]
            max_pixel_width = max(max_pixel_width, w)
        if max_pixel_width <= MAX_PIXEL_WIDTH:
            return size
    return 6


def render_bitmap(text: str, font_path: str) -> tuple[list[list[bool]], int, int]:
    """Render text to a boolean pixel grid."""
    font_size = find_font_size(font_path, text)
    font = ImageFont.truetype(font_path, font_size)

    lines = text.split("\n")

    line_metrics = []
    total_width = 0
    for line in lines:
        bbox = font.getbbox(line)
        w = bbox[2] - bbox[0]
        line_metrics.append(bbox)
        total_width = max(total_width, w)

    ascent, descent = font.getmetrics()
    line_height = ascent + descent
    total_height = line_height * len(lines)

    img = Image.new("L", (total_width, total_height), 0)
    draw = ImageDraw.Draw(img)

    y_offset = 0
    for i, line in enumerate(lines):
        bbox = line_metrics[i]
        x_offset = -bbox[0]
        draw.text((x_offset, y_offset - bbox[1]), line, fill=255, font=font)
        y_offset += line_height

    pixels = img.load()
    threshold = 80
    grid = [[pixels[x, y] >= threshold for x in range(total_width)]
            for y in range(total_height)]

    return grid, total_width, total_height


def detect_edges(grid: list[list[bool]], w: int, h: int) -> list[list[bool]]:
    """Edge detection: mark boundary pixels only."""
    edge = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if grid[y][x]:
                for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    ny, nx = y + dy, x + dx
                    if ny < 0 or ny >= h or nx < 0 or nx >= w or not grid[ny][nx]:
                        edge[y][x] = True
                        break
    return edge


def apply_outline(grid: list[list[bool]], w: int, h: int) -> tuple[list[list[bool]], int, int]:
    """Outline style: edge-detected pixels only."""
    return detect_edges(grid, w, h), w, h


def apply_shadow(grid: list[list[bool]], w: int, h: int,
                 shadow_dx: int = 2, shadow_dy: int = 1) -> tuple[list[list[bool]], int, int]:
    """Shadow style: outline in front + solid filled shadow offset behind."""
    edge = detect_edges(grid, w, h)
    new_w = w + shadow_dx
    new_h = h + shadow_dy

    composite = [[False] * new_w for _ in range(new_h)]

    # Shadow layer: shifted filled grid
    for y in range(h):
        for x in range(w):
            if grid[y][x]:
                composite[y + shadow_dy][x + shadow_dx] = True

    # Outline layer on top (unshifted)
    for y in range(h):
        for x in range(w):
            if edge[y][x]:
                composite[y][x] = True

    return composite, new_w, new_h


STYLE_FUNCS = {
    "outline": apply_outline,
    "shadow": apply_shadow,
}


def to_halfblock(grid: list[list[bool]], w: int, h: int) -> list[str]:
    """Convert boolean grid to half-block characters (▀/▄/█)."""
    if h % 2 != 0:
        grid.append([False] * w)
        h += 1

    result = []
    for y in range(0, h, 2):
        row = []
        for x in range(w):
            upper = grid[y][x]
            lower = grid[y + 1][x]
            if upper and lower:
                row.append("\u2588")   # █
            elif upper:
                row.append("\u2580")   # ▀
            elif lower:
                row.append("\u2584")   # ▄
            else:
                row.append(" ")
        result.append("".join(row).rstrip())

    while result and not result[0].strip():
        result.pop(0)
    while result and not result[-1].strip():
        result.pop()

    return result


def load_premade_arts() -> list[tuple[str, list[str]]]:
    """Load pre-made ASCII arts from external text file.

    Format: sections separated by '--- label' lines.
    """
    if not PREMADE_ART_FILE.exists():
        return []

    arts = []
    current_label = None
    current_lines = []

    for line in PREMADE_ART_FILE.read_text(encoding="utf-8").splitlines():
        if line.startswith("--- "):
            if current_label is not None:
                # Trim trailing empty lines
                while current_lines and not current_lines[-1].strip():
                    current_lines.pop()
                arts.append((current_label, current_lines))
            current_label = line[4:].strip()
            current_lines = []
        elif current_label is not None:
            current_lines.append(line.rstrip())

    if current_label is not None:
        while current_lines and not current_lines[-1].strip():
            current_lines.pop()
        arts.append((current_label, current_lines))

    return arts


def generate_lua(all_arts: list[tuple[str, list[str]]]) -> str:
    """Generate Lua module with ascii art data."""
    lines = []
    lines.append("-- Auto-generated by scripts/common/generate_ascii_art/generate_ascii_art.py")
    lines.append("-- Do not edit manually")
    lines.append("")
    lines.append("local M = {}")
    lines.append("")
    lines.append("M.arts = {")

    for label, art in all_arts:
        lines.append(f"  -- {label}")
        lines.append('"",')
        lines.append("  {")
        for row in art:
            escaped = row.replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'    "{escaped}",')
        lines.append('"",')
        lines.append("  },")

    lines.append("}")
    lines.append("")
    lines.append("function M.random()")
    lines.append("  return table.concat(M.arts[math.random(#M.arts)], '\\n')")
    lines.append("end")
    lines.append("")
    lines.append("return M")
    lines.append("")
    return "\n".join(lines)


def generate_vim(all_arts: list[tuple[str, list[str]]]) -> str:
    """Generate Vimscript with ascii art data."""
    lines = []
    lines.append('" Auto-generated by scripts/common/generate_ascii_art/generate_ascii_art.py')
    lines.append('" Do not edit manually')
    lines.append("")
    lines.append("let g:ascii_arts = []")
    lines.append("")

    for label, art in all_arts:
        lines.append(f'" {label}')
        lines.append("call add(g:ascii_arts, [")
        lines.append("      \\ '',")
        for row in art:
            escaped = row.replace("\\", "\\\\").replace("'", "''")
            lines.append(f"      \\ '{escaped}',")
        lines.append("      \\ '',")
        lines.append("      \\ ])")
        lines.append("")

    return "\n".join(lines)


def main():
    font_path = find_font()
    print(f"Using font: {font_path}")

    all_arts = []

    # Load pre-made ASCII arts
    premade = load_premade_arts()
    for label, art in premade:
        print(f"  Pre-made: {label}")
        for row in art:
            print(f"    {row}")
        print()
        all_arts.append((label, art))

    # Generate pixel-art from text (all styles × all messages)
    for msg in MESSAGES:
        label = msg.replace("\n", " ")
        grid, w, h = render_bitmap(msg, font_path)
        for style in STYLES:
            style_label = f"{label} [{style}]"
            print(f"  Rendering: {style_label}")
            styled, sw, sh = STYLE_FUNCS[style](
                [row[:] for row in grid], w, h,
            )
            art = to_halfblock(styled, sw, sh)
            all_arts.append((style_label, art))
            for row in art:
                print(f"    {row}")
            print()

    # Write Lua output
    LUA_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    lua_content = generate_lua(all_arts)
    LUA_OUTPUT.write_text(lua_content, encoding="utf-8")
    print(f"Written: {LUA_OUTPUT}")

    # Write Vim output
    VIM_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    vim_content = generate_vim(all_arts)
    VIM_OUTPUT.write_text(vim_content, encoding="utf-8")
    print(f"Written: {VIM_OUTPUT}")


if __name__ == "__main__":
    main()
