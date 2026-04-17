---
name: gws-docs-to-markdown
description: >
  Generate a Markdown file from a Google Docs URL and extract embedded images as local files.
  Use for requests like "read this Google Doc" or "load this document."
  Runs a Bash script to generate the Markdown and image files, then reads them with the Read tool.
---

# Google Docs to Markdown

Given a Google Docs URL, generate a lightweight Markdown file and image files.

## Usage

```bash
${SKILL_DIR}/scripts/read_gdoc.sh "GOOGLE_DOCS_URL_OR_DOC_ID" "OUTPUT_DIR"
```

- `GOOGLE_DOCS_URL_OR_DOC_ID` (required): Google Docs URL (e.g. `https://docs.google.com/document/d/DOC_ID/edit`) or DOC_ID
- `OUTPUT_DIR` (required): Output directory (e.g. `tmp/`)

## Workflow

1. Run the script.
2. The path to the generated Markdown file is printed to stdout.
3. Read that path with the Read tool.
4. To inspect images, use the Read tool on files under `{OUTPUT_DIR}/images_{DOC_ID_FIRST_8_CHARS}/` (Claude is multimodal, so it can render images).

## How it works

1. Export the Google Docs as Markdown via `gws drive files export`.
2. Detect base64-embedded images in the exported Markdown.
3. Decode base64 and save them as PNG files under `{OUTPUT_DIR}/images_{DOC_ID_FIRST_8_CHARS}/`.
4. Replace image references in the Markdown with local file paths.
5. Output the cleaned Markdown to `{OUTPUT_DIR}/`.

## Notes

- `gws` CLI authentication is required (must be set up in advance).
- The Google Docs API export has a 10 MB limit.
- Google normalizes exported images to PNG (GIF/JPG uploads are returned as PNG).
