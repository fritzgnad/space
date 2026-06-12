#!/usr/bin/env python3
"""Generates the DMG background (1x and 2x) into assets/.

Run with a venv that has Pillow:  python3 scripts/make-dmg-background.py
Layout must match the icon coordinates in scripts/make-dmg.sh
(icons at y=200: app at x=165, Applications folder at x=495).
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 660, 400
TEXT = "Drag Space into the Applications folder"
FONT = "/System/Library/Fonts/Helvetica.ttc"


def render(scale: int, path: str) -> None:
    img = Image.new("RGB", (W * scale, H * scale), "#f5f5f7")
    d = ImageDraw.Draw(img)

    font = ImageFont.truetype(FONT, 22 * scale)
    box = d.textbbox((0, 0), TEXT, font=font)
    d.text(((W * scale - (box[2] - box[0])) // 2, 64 * scale),
           TEXT, font=font, fill="#6e6e73")

    # Arrow between the two icon positions (icons centered at y=200).
    y = 200 * scale
    x0, x1 = 255 * scale, 390 * scale
    lw = 6 * scale
    d.line([(x0, y), (x1, y)], fill="#a1a1a6", width=lw)
    head = 16 * scale
    d.polygon([(x1 + head, y), (x1 - head // 2, y - head),
               (x1 - head // 2, y + head)], fill="#a1a1a6")

    img.save(path)
    print(f"wrote {path}")


render(1, "assets/dmg-background.png")
render(2, "assets/dmg-background@2x.png")
