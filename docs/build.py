"""Build docs/index.html, the bilingual study guide published with GitHub Pages.

Usage (from the repository root):  python3 docs/build.py
Needs pandoc. Edit docs/src/guide_en.md or docs/src/guide_zh.md, then rebuild.
"""
import json
import subprocess
from pathlib import Path

SRC = Path(__file__).parent / "src"
OUT = Path(__file__).parent / "index.html"

TITLES = {
    "en": "How Accurate Is Your Running App? Design, Analysis and Results of a GPS Distance Experiment",
    "zh": "跑步 app 测距有多准？GPS 距离误差实验的设计、分析与结论",
}


def render(lang):
    """Convert one guide to HTML; return (table of contents, body)."""
    html = subprocess.run(
        ["pandoc", str(SRC / f"guide_{lang}.md"),
         "--from", "markdown", "--to", "html5", "--mathml",
         "--toc", "--toc-depth=3", "--id-prefix", f"{lang}-",
         "--template", str(SRC / "fragment.html")],
        check=True, capture_output=True, text=True,
    ).stdout
    toc, body = html.split("<!--SPLIT-->")
    return toc.strip(), body.strip()


def main():
    page = (SRC / "page.html").read_text(encoding="utf-8")
    parts = {
        "{{CSS}}": (SRC / "style.css").read_text(encoding="utf-8").strip(),
        "{{TITLE_EN_JS}}": json.dumps(TITLES["en"], ensure_ascii=False),
        "{{TITLE_ZH_JS}}": json.dumps(TITLES["zh"], ensure_ascii=False),
        "{{TITLE_EN}}": TITLES["en"],
        "{{TITLE_ZH}}": TITLES["zh"],
    }
    for lang in ("en", "zh"):
        toc, body = render(lang)
        parts[f"{{{{TOC_{lang.upper()}}}}}"] = toc
        parts[f"{{{{BODY_{lang.upper()}}}}}"] = body
    for key, value in parts.items():
        page = page.replace(key, value)
    OUT.write_text(page, encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
