"""Uygulama ikonunun kaynak gorsellerini uretir.

Kullanim:
    python tools/build_icon_sources.py
    dart run flutter_launcher_icons

Elde "assets/icon/Foxy logo.png" (saydam zeminli tilki) varken calisir ve
flutter_launcher_icons'in bekledigi iki dosyayi yazar. Olculer bilerek
farkli; aciklamasi pubspec.yaml icindeki flutter_launcher_icons blogunda.
"""

from PIL import Image

SOURCE = "assets/icon/Foxy logo.png"
FOREGROUND = "assets/icon/foxium_foreground.png"
LEGACY = "assets/icon/foxium_icon.png"

CANVAS = 1024
CREAM = (255, 245, 235, 255)

# Adaptive ikonda guvenli alan tuvalin %66,7'si (108dp icinde 72dp). Tilki
# tam o sinira oturtulursa kulak ucu maskeye deger; biraz altinda kaliyor.
FOREGROUND_RATIO = 0.62
# iOS/eski ikonda maske yok; kenarda biraz nefes payi birakiyoruz.
LEGACY_RATIO = 0.80


def place(art, ratio, background=None):
    """Tilkiyi tuvalin ortasina, uzun kenari `ratio` oraninda koyar."""
    scale = (CANVAS * ratio) / max(art.size)
    size = (max(1, round(art.width * scale)), max(1, round(art.height * scale)))
    resized = art.resize(size, Image.LANCZOS)

    base = Image.new("RGBA", (CANVAS, CANVAS), background or (0, 0, 0, 0))
    base.alpha_composite(
        resized,
        ((CANVAS - size[0]) // 2, (CANVAS - size[1]) // 2),
    )
    return base


def main():
    source = Image.open(SOURCE).convert("RGBA")
    # Saydam kenarlar atilmazsa oranlar kaynaktaki bosluga gore hesaplanir.
    art = source.crop(source.getchannel("A").getbbox())

    place(art, FOREGROUND_RATIO).save(FOREGROUND)
    place(art, LEGACY_RATIO, background=CREAM).convert("RGB").save(LEGACY)

    print("yazildi:", FOREGROUND)
    print("yazildi:", LEGACY)


if __name__ == "__main__":
    main()
