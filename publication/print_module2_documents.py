"""Check source excerpts, or rebuild the canonical retrospective PDFs from Markdown."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import textwrap

REPO = Path(__file__).resolve().parents[1]
MODULE = next(REPO.glob("Module_2*/v1.0"))
SQL_DIGEST = "833c075d8194a46cb0dc7a92acf32ab2eeddba9238569d57919c7f943d8e39ec"
DOCUMENTS = (
    MODULE / "docs/MODULE_2_BUSINESS_REQUIREMENTS.md",
    MODULE / "tests/MODULE_2_VALIDATION_SUMMARY.md",
)
PRINT_CSS = """
@page { size: Letter; margin: .65in .62in .68in; }
body { max-width: none; margin: 0; font: 10pt/1.42 Arial, sans-serif; color: #21393e; }
h1,h2,h3 { color: #113c40; line-height:1.17; break-after: avoid; }
h1 { font: bold 26pt/1.15 Georgia, serif; border-bottom:2pt solid #2d6967; padding-bottom: 8pt; margin:0 0 8pt; }
h2 { font: bold 17pt/1.15 Georgia, serif; margin:19pt 0 7pt; }
h3 { font-size: 12pt; margin:14pt 0 5pt; }
p { margin: 5pt 0 8pt; }
a { color: #135d66; text-decoration: underline; }
table { width:100%; border-collapse:collapse; font-size:9pt; line-height:1.33; margin:8pt 0; }
th,td { text-align:left; padding:4pt; border-bottom:.55pt solid #b5c7c5; vertical-align:top; overflow-wrap:anywhere; }
th { background:#e4f0ed; color: #173d40; }
thead { display:table-header-group; }
tr { break-inside:avoid; }
code { overflow-wrap:anywhere; font-family:"Liberation Mono",monospace; font-size:.9em; }
pre { white-space:pre-wrap; overflow-wrap:anywhere; font:8pt/1.35 "Liberation Mono",monospace; padding:5pt 7pt; color:#173940; background:#f1f5f4; border-left:2pt solid #4c7a76; margin:3pt 0 6pt; }
pre code { font:inherit; }
p:has(+ pre),p:has(>strong:only-child) { break-after:avoid; }
th.short-label { min-width:3.4em; white-space:nowrap; }
#source-excerpts { break-before:page; }
"""


def verify_excerpts(document, source_lines):
    text = document.read_text(encoding="utf-8")
    links = set(re.findall(r"#sql-(\d+)", text))
    anchors = re.findall(r"^### SQL (\d+)$", text, flags=re.M)
    if set(anchors) != links or len(anchors) != len(links):
        raise ValueError(f"{document.name}: SQL links and headings disagree")
    snippets = re.findall(r"Lines (\d+)–(\d+)\.\n\n```text\n(.*?)\n```", text, flags=re.S)
    for first, last, snippet in snippets:
        original = "\n".join(source_lines[int(first)-1:int(last)])
        if snippet != textwrap.dedent(original):
            raise ValueError(f"{document.name}: SQL differs at lines {first}–{last}")
    if len(snippets) < len(links) or not links:
        raise ValueError(f"{document.name}: missing source excerpts")
    print(f"{document.name}: {len(links)} local SQL destinations, {len(snippets)} excerpts")
    return links


def render_pdf(document, anchors, chromium, temp):
    from playwright.sync_api import sync_playwright
    import fitz

    html = subprocess.check_output(
        ["pandoc", "--from=gfm", "--to=html5", "--wrap=none", str(document)], encoding="utf-8"
    )
    webpage = temp / (document.stem + ".html")
    webpage.write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8"><title>'
        + document.stem.replace("_", " ").title()
        + "</title><style>" + PRINT_CSS + "</style><body>" + html + "</body></html>",
        encoding="utf-8",
    )
    with sync_playwright() as pw:
        browser = pw.chromium.launch(executable_path=chromium)
        page = browser.new_page()
        page.goto(webpage.as_uri())
        page.evaluate("""() => document.querySelectorAll('th').forEach(th => {
            if (['ID', 'Count'].includes(th.textContent.trim())) th.classList.add('short-label');
        })""")
        for line in anchors:
            if page.locator("#sql-" + line).count() != 1:
                raise ValueError(f"{document.name}: missing printed anchor {line}")
        page.pdf(path=temp / "printed.pdf", prefer_css_page_size=True, print_background=True,
                 display_header_footer=True, header_template="<span></span>",
                 footer_template='<div style="width:100%;text-align:center;font:8px Arial;color:#576e6c;">Credit Decisioning Strategy Simulator &nbsp; · &nbsp; Module 2 v1.0 &nbsp; · &nbsp; <span class="pageNumber"></span></div>')
        browser.close()
    dest = document.with_suffix(".pdf")
    with fitz.open(temp / "printed.pdf") as pdf:
        metadata = pdf.metadata
        for field in ("creationDate", "modDate"):
            metadata[field] = ""
        pdf.set_metadata(metadata)
        named = pdf.resolve_names()
        if any("sql-" + line not in named for line in anchors):
            raise ValueError(f"{document.name}: printed PDF is missing a SQL destination")
        pdf.save(dest, garbage=4, deflate=True, no_new_id=True)
        print(f"  {dest.name}: {len(pdf)} pages")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", action="store_true", help="render with Pandoc, Playwright, Chromium and PyMuPDF")
    parser.add_argument("--chromium", default=os.environ.get("CHROMIUM_PATH") or shutil.which("chromium"))
    args = parser.parse_args()
    source = next((MODULE / "src").glob("*.sql")).read_bytes().replace(b"\r\n", b"\n")
    if hashlib.sha256(source).hexdigest() != SQL_DIGEST:
        raise ValueError("The historical Module 2 SQL source differs from the reviewed edition.")
    with tempfile.TemporaryDirectory() as temp:
        for doc in DOCUMENTS:
            anchors = verify_excerpts(doc, source.decode("utf-8").splitlines())
            if args.pdf:
                render_pdf(doc, anchors, args.chromium, Path(temp))


if __name__ == "__main__":
    main()
