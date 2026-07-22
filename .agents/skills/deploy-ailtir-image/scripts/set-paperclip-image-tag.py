#!/usr/bin/env python3

import argparse
import re
from pathlib import Path


IMAGE_PATTERN = re.compile(
    r'(_image_paperclip\s*=\s*repository_paperclip\.repository_url\.apply\('
    r'lambda url: f"\{url\}:)([0-9a-f]{9})("\))'
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update the immutable Paperclip image tag in Ailtir infrastructure."
    )
    parser.add_argument("--infrastructure-repo", required=True, type=Path)
    parser.add_argument("--tag", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not re.fullmatch(r"[0-9a-f]{9}", args.tag):
        raise SystemExit("error: --tag must be exactly nine lowercase hexadecimal characters")

    service_file = args.infrastructure_repo.resolve() / "src" / "service_paperclip.py"
    content = service_file.read_text(encoding="utf-8")
    matches = list(IMAGE_PATTERN.finditer(content))
    if len(matches) != 1:
        raise SystemExit(
            f"error: expected exactly one Paperclip image tag in {service_file}, found {len(matches)}"
        )

    previous_tag = matches[0].group(2)
    updated = IMAGE_PATTERN.sub(rf"\g<1>{args.tag}\g<3>", content, count=1)
    service_file.write_text(updated, encoding="utf-8")
    print(f"file={service_file}")
    print(f"previous_tag={previous_tag}")
    print(f"current_tag={args.tag}")


if __name__ == "__main__":
    main()
