#!/usr/bin/env python3
"""Cắt một màn (timeline / camera / share) từ bảng thiết kế persona và phóng to để đọc chi tiết.

    python3 crop.py 2 timeline            # persona 2, màn timeline
    python3 crop.py quietTransformer all  # cả 3 màn của persona 1
    python3 crop.py --list                # bảng persona → thứ tự 3 màn trong ảnh
    python3 crop.py 3 camera --out DIR    # ghi ảnh vào DIR (mặc định: thư mục tạm)

In ra đường dẫn ảnh PNG đã cắt, mỗi dòng một ảnh. Thiếu Pillow thì in đường dẫn cả bảng và exit 0,
để vẫn đọc được bảng gốc.
"""

import argparse
import os
import sys
import tempfile

BOARD_DIR = os.path.join("apps", "mobile", "assets", "design_personas")

# Mỗi bảng 1376x768 có 3 điện thoại xếp ngang; thứ tự màn khác nhau giữa các bảng.
PERSONAS = {
    1: ("quietTransformer", "weightLoss", "persona_1_quiet_transformer.jpg", ("camera", "timeline", "share")),
    2: ("accountabilitySquad", "englishDaily", "persona_2_accountability_squad.jpg", ("timeline", "camera", "share")),
    3: ("memoryCollectors", "travel", "persona_3_memory_collectors.jpg", ("timeline", "camera", "share")),
    4: ("coupleRituals", "custom (2 người / 💞)", "persona_4_couple_rituals.jpg", ("timeline", "camera", "share")),
    5: ("aestheticFlexer", "workout30", "persona_5_aesthetic_flexers.jpg", ("timeline", "camera", "share")),
    6: ("minimalistHabit", "custom", "persona_6_minimalist_habit.jpg", ("camera", "timeline", "share")),
}

SCREEN_ALIASES = {
    "timeline": "timeline",
    "camera": "camera",
    "hud": "camera",
    "share": "share",
    "squad": "share",
    "poster": "share",
    "archive": "share",
}

SCALE = 2


def repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    root = here
    while root != os.path.dirname(root):
        if os.path.isdir(os.path.join(root, BOARD_DIR)):
            return root
        root = os.path.dirname(root)
    return os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())


def snake(name):
    return "".join("_" + c.lower() if c.isupper() else c for c in name)


def resolve_persona(arg):
    key = arg.strip().lower().replace("-", "_")
    if key.startswith("persona_"):
        key = key[len("persona_"):]
    if key.isdigit() and int(key) in PERSONAS:
        return int(key)
    for num, (skin, *_rest) in PERSONAS.items():
        if key in (skin.lower(), snake(skin)):
            return num
    raise SystemExit(f"Không rõ persona '{arg}'. Dùng 1-6 hoặc PersonaSkinId (vd. quietTransformer). Xem --list.")


def print_list():
    print("# | PersonaSkinId | TemplateId | Trái | Giữa | Phải")
    for num, (skin, template, _file, order) in PERSONAS.items():
        print(f"{num} | {skin} | {template} | {order[0]} | {order[1]} | {order[2]}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("persona", nargs="?", help="1-6, persona_N hoặc PersonaSkinId")
    parser.add_argument("screen", nargs="?", default="all", help="timeline | camera | share (squad) | all")
    parser.add_argument("--out", help="thư mục ghi ảnh đã cắt")
    parser.add_argument("--list", action="store_true", help="in bảng persona và thứ tự màn")
    args = parser.parse_args()

    if args.list or not args.persona:
        print_list()
        return

    num = resolve_persona(args.persona)
    skin, _template, filename, order = PERSONAS[num]
    board = os.path.join(repo_root(), BOARD_DIR, filename)
    if not os.path.isfile(board):
        raise SystemExit(f"Không thấy bảng thiết kế: {board}")

    screen = args.screen.lower()
    if screen == "all":
        screens = list(order)
    elif screen in SCREEN_ALIASES:
        screens = [SCREEN_ALIASES[screen]]
    else:
        raise SystemExit(f"Không rõ màn '{args.screen}'. Dùng timeline, camera, share hoặc all.")

    try:
        from PIL import Image
    except ImportError:
        print(board)
        print("Pillow chưa cài (pip install pillow): đọc cả bảng ở trên.", file=sys.stderr)
        return

    out_dir = args.out or os.path.join(tempfile.gettempdir(), "ourney-design-ref")
    os.makedirs(out_dir, exist_ok=True)

    with Image.open(board) as img:
        width, height = img.size
        third = width / 3
        margin = int(third * 0.03)
        for name in screens:
            index = order.index(name)
            left = max(0, int(index * third) - margin)
            right = min(width, int((index + 1) * third) + margin)
            panel = img.crop((left, 0, right, height))
            panel = panel.resize((panel.width * SCALE, panel.height * SCALE), Image.LANCZOS)
            path = os.path.join(out_dir, f"persona_{num}_{skin}_{name}.png")
            panel.save(path)
            print(path)


if __name__ == "__main__":
    main()
