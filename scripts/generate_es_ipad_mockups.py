from pathlib import Path
from typing import List
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "AppStore-Mockups-iPad"
DESKTOP = Path.home() / "Desktop"

SCREEN_X = 231
SCREEN_Y = 463
SCREEN_W = 1602
SCREEN_H = 2136
SCREEN_RADIUS = 56

TITLE_CLEAR_BOTTOM = 380
TITLE_TOP = 32
TITLE_MAX_W = 1820
TITLE_COLOR = (35, 42, 52)
TITLE_SIZE = 68


def load_font(size: int):
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for font_path in candidates:
        path = Path(font_path)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> List[str]:
    words = text.split()
    lines: List[str] = []
    current: List[str] = []

    for word in words:
        trial = " ".join(current + [word])
        left, top, right, bottom = draw.textbbox((0, 0), trial, font=font)
        width = right - left
        if width <= max_width or not current:
            current.append(word)
        else:
            lines.append(" ".join(current))
            current = [word]

    if current:
        lines.append(" ".join(current))

    return lines


def clear_title_area(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    for y in range(TITLE_CLEAR_BOTTOM):
        color = image.getpixel((10, y))
        draw.line((0, y, image.width, y), fill=color)


def draw_title(image: Image.Image, text: str) -> None:
    draw = ImageDraw.Draw(image)
    font = load_font(TITLE_SIZE)
    lines = wrap_text(draw, text, font, TITLE_MAX_W)

    line_heights: List[int] = []
    max_width = 0
    for line in lines:
        left, top, right, bottom = draw.textbbox((0, 0), line, font=font)
        line_heights.append(bottom - top)
        max_width = max(max_width, right - left)

    line_spacing = 8
    total_height = sum(line_heights) + line_spacing * (len(lines) - 1)
    y = TITLE_TOP + (300 - total_height) // 2

    for i, line in enumerate(lines):
        lw = draw.textbbox((0, 0), line, font=font)[2]
        line_x = (image.width - lw) // 2
        draw.text((line_x, y), line, fill=TITLE_COLOR, font=font)
        y += line_heights[i] + line_spacing


def paste_screenshot(image: Image.Image, screenshot_path: Path) -> None:
    screenshot = Image.open(screenshot_path).convert("RGB")
    screenshot = screenshot.resize((SCREEN_W, SCREEN_H), Image.Resampling.LANCZOS)

    mask = Image.new("L", (SCREEN_W, SCREEN_H), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        (0, 0, SCREEN_W - 1, SCREEN_H - 1),
        radius=SCREEN_RADIUS,
        fill=255,
    )

    image.paste(screenshot, (SCREEN_X, SCREEN_Y), mask)


def render_one(base_name: str, screenshot_name: str, headline: str, out_name: str) -> None:
    base_path = OUT_DIR / base_name
    screenshot_path = DESKTOP / screenshot_name
    out_path = OUT_DIR / out_name

    if not base_path.exists():
        raise FileNotFoundError(f"Missing base mockup: {base_path}")
    if not screenshot_path.exists():
        raise FileNotFoundError(f"Missing screenshot: {screenshot_path}")

    image = Image.open(base_path).convert("RGB")

    clear_title_area(image)
    paste_screenshot(image, screenshot_path)
    draw_title(image, headline)

    image.save(out_path, format="PNG", dpi=(144, 144), optimize=True, compress_level=9)
    print(f"Created {out_path}")


def main() -> None:
    jobs = [
        {
            "base": "StartScreenExposed.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.01.32.png",
            "headline": "Empieza al instante en modo solo o multijugador.",
            "out": "StartScreenExposed-ES.png",
        },
        {
            "base": "CreateLobbyEXPOSED.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.02.03.png",
            "headline": "Personaliza tu partida en segundos antes de empezar.",
            "out": "CreateLobbyEXPOSED-ES.png",
        },
        {
            "base": "IngameSafeEXPOSED.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.02.19.png",
            "headline": "Mantén las rondas en marcha con votación grupal rápida.",
            "out": "IngameSafeEXPOSED-ES.png",
        },
        {
            "base": "IngameDeeperEXPOSED.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.02.36.png",
            "headline": "Desbloquea preguntas más profundas a medida que sube el nivel.",
            "out": "IngameDeeperEXPOSED-ES.png",
        },
        {
            "base": "IngameSecretiveEXPOSED.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.02.42.png",
            "headline": "Lleva preguntas secretive atrevidas a tu próxima ronda.",
            "out": "IngameSecretiveEXPOSED-ES.png",
        },
        {
            "base": "IngameFreakyEXPOSED.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.02.52.png",
            "headline": "Sube la energía con el divertido modo freaky.",
            "out": "IngameFreakyEXPOSED-ES.png",
        },
        {
            "base": "SettingsEXPOSED.png",
            "shot": "Simulator Screenshot - iPad Pro 13-inch (M5) - 2026-02-26 at 22.02.59.png",
            "headline": "Cambia el idioma y los ajustes legales con un toque.",
            "out": "SettingsEXPOSED-ES.png",
        },
    ]

    for job in jobs:
        render_one(job["base"], job["shot"], job["headline"], job["out"])


if __name__ == "__main__":
    main()
