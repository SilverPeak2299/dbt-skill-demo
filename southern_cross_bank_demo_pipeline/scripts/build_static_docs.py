#!/usr/bin/env python3
"""Build profile-free static documentation for the demo pipeline."""

from __future__ import annotations

import argparse
import html
import re
import shutil
from pathlib import Path


REQUIRED_FILES = [
    "dbt_project.yml",
    "docs/southern_cross_bank_demo_pipeline.mdx",
    "mappings/source_to_target.md",
    "design/design_document.md",
    "design/validation_report.md",
    "models/sources.yml",
    "models/schema.yml",
]


def inline_markup(text: str) -> str:
    escaped = html.escape(text)
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(
        r"\[([^\]]+)\]\(([^)]+)\)",
        lambda match: (
            f'<a href="{html.escape(match.group(2), quote=True)}">'
            f"{match.group(1)}</a>"
        ),
        escaped,
    )
    return escaped


def table_to_html(lines: list[str]) -> str:
    rows = []
    for line in lines:
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if cells and all(set(cell) <= {"-", ":", " "} for cell in cells):
            continue
        rows.append(cells)

    if not rows:
        return ""

    out = ["<table>"]
    for row_index, row in enumerate(rows):
        tag = "th" if row_index == 0 else "td"
        out.append("<tr>")
        for cell in row:
            out.append(f"<{tag}>{inline_markup(cell)}</{tag}>")
        out.append("</tr>")
    out.append("</table>")
    return "\n".join(out)


def markdown_to_html(markdown: str) -> str:
    output: list[str] = []
    paragraph: list[str] = []
    list_items: list[str] = []
    table_lines: list[str] = []
    in_code = False
    code_lang = ""
    code_lines: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            output.append(f"<p>{inline_markup(' '.join(paragraph))}</p>")
            paragraph.clear()

    def flush_list() -> None:
        if list_items:
            output.append("<ul>")
            output.extend(f"<li>{item}</li>" for item in list_items)
            output.append("</ul>")
            list_items.clear()

    def flush_table() -> None:
        if table_lines:
            output.append(table_to_html(table_lines))
            table_lines.clear()

    for raw_line in markdown.splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()

        if stripped.startswith("import "):
            continue
        if stripped in {"<Tabs>", "</Tabs>"}:
            continue
        if stripped.startswith("<TabItem") or stripped == "</TabItem>":
            continue

        if stripped.startswith("```"):
            if in_code:
                code = chr(10).join(code_lines)
                if code_lang == "mermaid":
                    output.append(f'<pre class="mermaid">{html.escape(code)}</pre>')
                else:
                    classes = (
                        f' class="language-{html.escape(code_lang)}"'
                        if code_lang
                        else ""
                    )
                    output.append(
                        f"<pre><code{classes}>{html.escape(code)}</code></pre>"
                    )
                in_code = False
                code_lang = ""
                code_lines.clear()
            else:
                flush_paragraph()
                flush_list()
                flush_table()
                in_code = True
                code_lang = stripped[3:].strip()
            continue

        if in_code:
            code_lines.append(line)
            continue

        if not stripped:
            flush_paragraph()
            flush_list()
            flush_table()
            continue

        if stripped.startswith("|") and stripped.endswith("|"):
            flush_paragraph()
            flush_list()
            table_lines.append(stripped)
            continue

        flush_table()

        heading = re.match(r"^(#{1,4})\s+(.+)$", stripped)
        if heading:
            flush_paragraph()
            flush_list()
            level = len(heading.group(1))
            output.append(f"<h{level}>{inline_markup(heading.group(2))}</h{level}>")
            continue

        bullet = re.match(r"^[-*]\s+(.+)$", stripped)
        if bullet:
            flush_paragraph()
            list_items.append(inline_markup(bullet.group(1)))
            continue

        paragraph.append(stripped)

    flush_paragraph()
    flush_list()
    flush_table()
    return "\n".join(part for part in output if part)


def load_sections(project_dir: Path) -> list[tuple[str, str]]:
    files = [
        ("Overview", project_dir / "docs" / "southern_cross_bank_demo_pipeline.mdx"),
        ("Design", project_dir / "design" / "design_document.md"),
        ("Source To Target", project_dir / "mappings" / "source_to_target.md"),
        ("Validation", project_dir / "design" / "validation_report.md"),
    ]
    return [(title, path.read_text(encoding="utf-8")) for title, path in files]


def validate(project_dir: Path) -> list[str]:
    errors: list[str] = []
    for relative_path in REQUIRED_FILES:
        if not (project_dir / relative_path).is_file():
            errors.append(f"Missing required file: {relative_path}")

    sql_models = sorted((project_dir / "models").glob("**/*.sql"))
    tests = sorted((project_dir / "tests").glob("*.sql"))
    if not sql_models:
        errors.append("No SQL model files found under models/")
    if not tests:
        errors.append("No singular test files found under tests/")

    forbidden_dirs = [
        project_dir / "target",
        project_dir / "site",
    ]
    for directory in forbidden_dirs:
        if directory.exists() and not directory.is_dir():
            errors.append(f"Expected directory path is not a directory: {directory}")

    return errors


def build_site(project_dir: Path, output_dir: Path) -> None:
    errors = validate(project_dir)
    if errors:
        raise SystemExit("\n".join(errors))
    if output_dir == project_dir:
        raise SystemExit("Output directory must not be the project directory.")
    try:
        output_dir.relative_to(project_dir)
    except ValueError as exc:
        raise SystemExit("Output directory must be inside the project directory.") from exc

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    sections = load_sections(project_dir)
    nav = "\n".join(
        f'<a href="#section-{index}">{html.escape(title)}</a>'
        for index, (title, _) in enumerate(sections, start=1)
    )
    body = "\n".join(
        (
            f'<section id="section-{index}">'
            f"<h2>{html.escape(title)}</h2>"
            f"{markdown_to_html(markdown)}"
            "</section>"
        )
        for index, (title, markdown) in enumerate(sections, start=1)
    )

    index_html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Southern Cross Bank Demo Pipeline</title>
  <style>
    :root {{
      color: #171717;
      background: #ffffff;
      font-family: Arial, Helvetica, sans-serif;
      line-height: 1.55;
    }}
    body {{
      margin: 0;
      background: #ffffff;
    }}
    header {{
      border-bottom: 1px solid #d4d4d4;
      padding: 32px max(20px, calc((100vw - 1120px) / 2));
    }}
    main {{
      max-width: 1120px;
      margin: 0 auto;
      padding: 24px 20px 48px;
    }}
    h1, h2, h3, h4 {{
      line-height: 1.2;
      margin: 0 0 14px;
    }}
    h1 {{
      font-size: 2rem;
    }}
    h2 {{
      border-top: 1px solid #d4d4d4;
      margin-top: 32px;
      padding-top: 28px;
    }}
    p, ul {{
      max-width: 86ch;
    }}
    nav {{
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 20px;
    }}
    nav a {{
      border: 1px solid #737373;
      border-radius: 8px;
      color: #171717;
      padding: 6px 10px;
      text-decoration: none;
    }}
    a {{
      color: #0f766e;
    }}
    code {{
      background: #f5f5f5;
      border-radius: 4px;
      padding: 0.1em 0.3em;
    }}
    pre {{
      background: #171717;
      border-radius: 8px;
      color: #f5f5f5;
      overflow-x: auto;
      padding: 16px;
    }}
    pre code {{
      background: transparent;
      color: inherit;
      padding: 0;
    }}
    .mermaid {{
      background: #ffffff;
      border: 1px solid #d4d4d4;
      border-radius: 8px;
      color: #171717;
      margin: 18px 0;
      overflow-x: auto;
      padding: 16px;
    }}
    table {{
      border-collapse: collapse;
      display: block;
      margin: 18px 0;
      max-width: 100%;
      overflow-x: auto;
    }}
    th, td {{
      border: 1px solid #d4d4d4;
      padding: 8px 10px;
      text-align: left;
      vertical-align: top;
    }}
    th {{
      background: #f5f5f5;
    }}
  </style>
</head>
<body>
  <header>
    <h1>Southern Cross Bank Demo Pipeline</h1>
    <p>Governed retail banking analytics package for review without publishing runtime profiles, local credentials, or DuckDB data files.</p>
    <nav>{nav}</nav>
  </header>
  <main>
    {body}
  </main>
  <script type="module">
    import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
    mermaid.initialize({{ startOnLoad: true, theme: "default", securityLevel: "strict" }});
  </script>
</body>
</html>
"""
    (output_dir / "index.html").write_text(index_html, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("project_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    project_dir = args.project_dir.resolve()
    output_dir = args.output_dir.resolve()

    errors = validate(project_dir)
    if errors:
        raise SystemExit("\n".join(errors))
    if args.check:
        return

    build_site(project_dir, output_dir)


if __name__ == "__main__":
    main()
