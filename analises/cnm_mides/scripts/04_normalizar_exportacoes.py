from __future__ import annotations

import re
from pathlib import Path


PROJECT = Path(__file__).resolve().parents[3]
ANALYSIS = PROJECT / "analises" / "cnm_mides"
UNICODE_TOKEN = re.compile(r"<U\+([0-9A-Fa-f]{4,6})>")


def decode_unicode_tokens(text: str) -> str:
    return UNICODE_TOKEN.sub(lambda match: chr(int(match.group(1), 16)), text)


def normalize_file(path: Path) -> None:
    text = path.read_text(encoding="utf-8-sig")
    normalized = decode_unicode_tokens(text)
    path.write_text(normalized, encoding="utf-8-sig" if path.suffix == ".csv" else "utf-8")


def main() -> None:
    files = [
        *sorted((ANALYSIS / "outputs").glob("*.csv")),
        *sorted((ANALYSIS / "checks").glob("*.md")),
    ]
    for path in files:
        normalize_file(path)
    print(f"Exportacoes normalizadas: {len(files)}")


if __name__ == "__main__":
    main()
