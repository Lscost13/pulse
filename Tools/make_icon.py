"""Генерация иконки PULSE: тёмный премиальный фон + светящийся пульс.

Запуск:  python Tools/make_icon.py
Результат: Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Sources", "Resources", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png",
)

TOP = (13, 13, 22)
BOTTOM = (26, 16, 46)
VIOLET = (124, 92, 255)
MINT = (94, 234, 212)
BLUSH = (255, 138, 190)


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))  # type: ignore[return-value]


def gradient(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), TOP)
    px = img.load()
    for y in range(size):
        for x in range(size):
            dy = y / (size - 1)
            dx = x / (size - 1)
            base = lerp(TOP, BOTTOM, dy * 0.95)
            # мягкое свечение слева-сверху
            glow = max(0.0, 1.0 - math.hypot(dx - 0.28, dy - 0.18) / 0.95) ** 2
            t = min(1.0, glow * 0.55)
            px[x, y] = lerp(base, VIOLET, t * 0.55)
    return img


def pulse_points(size: int) -> list[tuple[float, float]]:
    """EKG-линия по сетке 0..1."""
    pts = [
        (0.06, 0.52), (0.20, 0.52), (0.28, 0.52),
        (0.33, 0.52), (0.375, 0.30), (0.425, 0.74),
        (0.47, 0.52), (0.56, 0.52), (0.615, 0.52),
        (0.66, 0.52), (0.705, 0.36), (0.75, 0.66),
        (0.79, 0.52), (0.94, 0.52),
    ]
    # компрессия по X: линия не должна касаться маски скругления
    return [((0.11 + x * 0.78) * size, y * size) for x, y in pts]


def main() -> None:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)

    base = gradient(SIZE).convert("RGBA")

    # свечение за линией
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    line = pulse_points(SIZE)
    width = int(SIZE * 0.030)
    for i in range(len(line) - 1):
        t = i / max(1, len(line) - 2)
        col = lerp(MINT, VIOLET, t * 0.85)
        gd.line([line[i], line[i + 1]], fill=col + (255,), width=width, joint="curve")
    glow = glow.filter(ImageFilter.GaussianBlur(SIZE * 0.045))
    glow = glow.point(lambda v: int(v * 1.15))
    base = Image.alpha_composite(base, glow)
    base = Image.alpha_composite(base, glow)

    # сама линия
    stroke = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stroke)
    for i in range(len(line) - 1):
        t = i / max(1, len(line) - 2)
        col = lerp(MINT, BLUSH, t * 1.0) if t > 0.55 else lerp(MINT, VIOLET, t / 0.55)
        sd.line([line[i], line[i + 1]], fill=col + (255,), width=max(8, int(SIZE * 0.018)), joint="curve")
    stroke = stroke.filter(ImageFilter.GaussianBlur(SIZE * 0.004))
    base = Image.alpha_composite(base, stroke)

    # точка-ядро в начале
    dot_r = SIZE * 0.030
    cx, cy = line[0]
    dot = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dot)
    dd.ellipse([cx - dot_r * 2.4, cy - dot_r * 2.4, cx + dot_r * 2.4, cy + dot_r * 2.4],
               fill=MINT + (90,))
    dd = dot.filter(ImageFilter.GaussianBlur(SIZE * 0.018))
    base = Image.alpha_composite(base, dd)

    # аккуратная внутренняя рамка (премиальная деталь)
    frame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    inset = int(SIZE * 0.055)
    fd.rounded_rectangle(
        [inset, inset, SIZE - inset, SIZE - inset],
        radius=int(SIZE * 0.235),
        outline=(255, 255, 255, 18),
        width=max(2, int(SIZE * 0.003)),
    )
    base = Image.alpha_composite(base, frame)

    # виньетка: края темнее, центр «светится»
    vignette = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    for i in range(96):
        t = i / 95
        pad = int(SIZE * 0.5 * t)
        alpha = int(46 * (1 - t) ** 2.2)
        vd.rectangle([pad, pad, SIZE - pad, SIZE - pad], outline=(0, 0, 0, alpha),
                     width=max(2, int(SIZE * 0.012)))
    vignette = vignette.filter(ImageFilter.GaussianBlur(SIZE * 0.02))
    base = Image.alpha_composite(base, vignette)

    # без альфа-канала: App Store не принимает прозрачность
    base.convert("RGB").save(OUT, "PNG", optimize=True)
    print("saved", OUT, os.path.getsize(OUT), "bytes")


if __name__ == "__main__":
    main()
