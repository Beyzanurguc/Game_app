"""Yapboz görsellerini Firebase'e yüklenmeye hazırlar.

`puzzle_sources/` içindeki her görseli ortadan kare kırpar, küçültür ve
`seed/puzzles/` altına yazar. Kaynak dosyalara dokunulmaz.

Neden gerekli:
  * Yapboz ızgarası kare; kare olmayan görsel tahtada ortadan kırpılacağı için
    kırpmayı önceden ve görünür şekilde yapmak daha güvenli.
  * Kaynaklar 4000 piksele kadar çıkıyor. 1200 piksel yeterli (5x5 ızgarada
    parça başına 240 piksel) ve indirilecek boyut ~6 kat küçülüyor.
  * Çıktı uygulamaya paketlenmiyor: görseller Firebase Storage'a yükleniyor,
    bu klasör yalnızca yükleme kaynağı.

Kullanım (proje kökünden):
    python tools/prepare_puzzle_images.py

Yeni resim eklemek için:
    1. Serbest lisanslı görseli `puzzle_sources/` altına ASCII bir adla koy.
    2. Bu betiği çalıştır.
    3. `seed/puzzles.json` içine bir kayıt ekle (title, sourceAsset, accent,
       icon, order). `icon` değeri `lib/games/yapboz/puzzle_icons.dart`
       içindeki anahtarlardan biri olmalı.
    4. `node tools/seed_firestore.js` ile yükle.

`test/seed_test.dart` çıktının kare ve 1200 piksel olduğunu doğrular; betiği
çalıştırmayı unutursan test kırmızıya döner.
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow gerekli:  pip install Pillow")

SOURCE_DIR = Path("puzzle_sources")
OUTPUT_DIR = Path("seed/puzzles")

# Yüklenecek kenar uzunluğu (piksel).
TARGET = 1200
QUALITY = 88

SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


def center_square(image: Image.Image) -> Image.Image:
    """Görseli ortadan kare kırpar. Zaten kareyse dokunmaz."""
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return image.crop((left, top, left + side, top + side))


def main() -> int:
    if not SOURCE_DIR.is_dir():
        sys.exit(f"{SOURCE_DIR} bulunamadı. Betiği proje kökünden çalıştır.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    sources = sorted(
        p for p in SOURCE_DIR.iterdir() if p.suffix.lower() in SUFFIXES
    )
    if not sources:
        sys.exit(f"{SOURCE_DIR} içinde görsel yok.")

    problems: list[str] = []

    for source in sources:
        name = source.stem
        if not name.isascii():
            problems.append(
                f"{source.name}: dosya adında ASCII olmayan karakter var; "
                f"Storage yolları için ASCII kullan."
            )
            continue

        with Image.open(source) as image:
            image = image.convert("RGB")
            original = image.size
            squared = center_square(image)
            if squared.width < TARGET:
                problems.append(
                    f"{source.name}: kırpınca {squared.width}px kaldı, "
                    f"{TARGET}px'in altında; parçalar bulanık görünebilir."
                )
            resized = squared.resize((TARGET, TARGET), Image.LANCZOS)

            target = OUTPUT_DIR / f"{name}.jpg"
            resized.save(target, "JPEG", quality=QUALITY, optimize=True)

        crop = "kare" if original[0] == original[1] else "ortadan kırpıldı"
        size_kb = target.stat().st_size // 1024
        print(
            f"{source.name:22} {original[0]}x{original[1]:<5} -> "
            f"{TARGET}x{TARGET} ({crop}, {size_kb} KB)"
        )

    if problems:
        print("\nUyarılar:")
        for problem in problems:
            print(f"  - {problem}")

    print(f"\n{len(sources) - len(problems)} görsel hazır: {OUTPUT_DIR}")
    print("Yüklemek için: node tools/seed_firestore.js")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
