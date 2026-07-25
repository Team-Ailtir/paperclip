#!/usr/bin/env python3
"""Replace the generated Ailtir state block and optionally append an event."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path

START = "<!-- AILTIR-CURRENT:START -->"
END = "<!-- AILTIR-CURRENT:END -->"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=Path, default=Path("CHANGELOG.md"))
    parser.add_argument("--upstream", required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--image-tag", default="not published")
    parser.add_argument("--image-digest", default="not published")
    parser.add_argument("--infrastructure-commit", default="not deployed")
    parser.add_argument("--live-version", default="not deployed")
    parser.add_argument("--verification", default="pending")
    parser.add_argument("--patches-file", type=Path)
    parser.add_argument("--event")
    args = parser.parse_args()

    path = args.file
    content = path.read_text() if path.exists() else "# Ailtir Paperclip Changelog\n\n"
    patches = (
        args.patches_file.read_text().strip()
        if args.patches_file
        else "| Patch | Source | Status |\n| --- | --- | --- |\n| None | Ailtir | clean upstream |"
    )
    block = "\n".join(
        [
            START,
            "## Current State",
            "",
            f"- Upstream base: `{args.upstream}`",
            f"- Ailtir source: `{args.source}`",
            f"- Image tag: `{args.image_tag}`",
            f"- Image digest: `{args.image_digest}`",
            f"- Infrastructure commit: `{args.infrastructure_commit}`",
            f"- Live version: `{args.live_version}`",
            f"- Verification: {args.verification}",
            "",
            "## Active Downstream Patches",
            "",
            patches,
            END,
        ]
    )
    if START in content and END in content:
        before, remainder = content.split(START, 1)
        _, after = remainder.split(END, 1)
        content = before.rstrip() + "\n\n" + block + after
    else:
        content = content.rstrip() + "\n\n" + block + "\n\n## History\n"
    if args.event:
        marker = "## History"
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        entry = f"{marker}\n\n### {timestamp}\n\n{args.event}"
        if marker not in content:
            content = content.rstrip() + "\n\n" + entry + "\n"
        else:
            content = content.replace(marker, entry, 1)
    path.write_text(content.rstrip() + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
