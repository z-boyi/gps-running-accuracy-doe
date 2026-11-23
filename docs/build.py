"""Build docs/index.html, the bilingual study guide published with GitHub Pages.

Usage (from the repository root):  python3 docs/build.py
Needs pandoc. Edit docs/src/guide_en.md or docs/src/guide_zh.md, then rebuild.
"""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent.parent
SRC = Path(__file__).parent / "src"
OUT = Path(__file__).parent / "index.html"
REPO = "https://github.com/z-boyi/gps-running-accuracy-doe/blob/main/"

# A line "<!-- r: code/02_analysis.R 3 -->" in a guide is replaced by that part
# of the script: "3" = section "# ---- 3. ...", "1-4" = sections 1 to 4,
# "all" = the whole file. The code is read from the script at build time, so
# the page always shows the current code.
CODE_TAG = re.compile(r"^<!-- r: (\S+) (\S+) -->$", re.M)
SECTION = re.compile(r"^# ---- (\d+)\.")
LABELS = {
    "en": ("R code", "lines", "View on GitHub"),
    "zh": ("R 代码", "行", "在 GitHub 上查看"),
}


def code_block(path, part, lang):
    """Return a collapsible block with the requested part of an R script."""
    lines = (ROOT / path).read_text(encoding="utf-8").rstrip("\n").split("\n")
    if part == "all":
        start, end = 0, len(lines)
    else:
        first, _, last = part.partition("-")
        last = last or first
        heads = [(int(m.group(1)), i) for i, l in enumerate(lines) if (m := SECTION.match(l))]
        nums = [n for n, _ in heads]
        start = heads[nums.index(int(first))][1]
        k = nums.index(int(last)) + 1
        end = heads[k][1] if k < len(heads) else len(lines)
    while end > start and not lines[end - 1].strip():
        end -= 1
    code = "\n".join(lines[start:end])
    title, word, link = LABELS[lang]
    where = f"{start + 1}–{end}"
    summary = (f"{title} · <code>{path}</code>, {word} {where}" if lang == "en"
               else f"{title} · <code>{path}</code> 第 {where} {word}")
    url = f"{REPO}{path}#L{start + 1}-L{end}"
    return (f'<details class="rcode">\n<summary>{summary}</summary>\n\n'
            f"```r\n{code}\n```\n\n"
            f'<p class="rcode-link"><a href="{url}">{link}</a></p>\n</details>')

TITLES = {
    "en": "How Accurate Is Your Running App? Design, Analysis and Results of a GPS Distance Experiment",
    "zh": "跑步 app 测距有多准？GPS 距离误差实验的设计、分析与结论",
}


def render(lang):
    """Convert one guide to HTML; return (code highlighting CSS, contents, body)."""
    text = (SRC / f"guide_{lang}.md").read_text(encoding="utf-8")
    text = CODE_TAG.sub(lambda m: code_block(m.group(1), m.group(2), lang), text)
    html = subprocess.run(
        ["pandoc", "-",
         "--from", "markdown", "--to", "html5", "--mathml",
         "--toc", "--toc-depth=3", "--id-prefix", f"{lang}-",
         "--highlight-style", "tango",
         "--template", str(SRC / "fragment.html")],
        input=text, check=True, capture_output=True, text=True,
    ).stdout
    css, toc, body = html.split("<!--SPLIT-->")
    return css.strip(), toc.strip(), body.strip()


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
        css, toc, body = render(lang)
        parts["{{CODE_CSS}}"] = css
        parts[f"{{{{TOC_{lang.upper()}}}}}"] = toc
        parts[f"{{{{BODY_{lang.upper()}}}}}"] = body
    for key, value in parts.items():
        page = page.replace(key, value)
    OUT.write_text(page, encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
