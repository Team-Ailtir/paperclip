#!/usr/bin/env python3
"""Inspect the source, infrastructure pin, and live Paperclip deployment."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import urllib.request
from pathlib import Path


def run(repo: Path, *args: str) -> str:
    return subprocess.check_output(args, cwd=repo, text=True).strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--infrastructure-repo", type=Path)
    parser.add_argument(
        "--health-url",
        default="https://paperclip.ailtir.ai/api/health",
    )
    args = parser.parse_args()
    repo = args.repo.resolve()
    infrastructure = (
        args.infrastructure_repo.resolve()
        if args.infrastructure_repo
        else (repo.parent / "infrastructure").resolve()
    )
    pin_text = (infrastructure / "src/service_paperclip.py").read_text()
    match = re.search(r'repository_paperclip\.repository_url.*?f"\{url\}:([0-9a-f]{9})"', pin_text)
    if not match:
        raise SystemExit("Could not resolve the infrastructure image pin")
    with urllib.request.urlopen(args.health_url, timeout=15) as response:
        health = json.load(response)
    state = {
        "repository": str(repo),
        "branch": run(repo, "git", "branch", "--show-current"),
        "head": run(repo, "git", "rev-parse", "HEAD"),
        "master": run(repo, "git", "rev-parse", "master"),
        "ailtir": run(repo, "git", "rev-parse", "ailtir"),
        "originMaster": run(repo, "git", "ls-remote", "origin", "refs/heads/master").split()[0],
        "originAiltir": run(repo, "git", "ls-remote", "origin", "refs/heads/ailtir").split()[0],
        "upstreamMaster": run(repo, "git", "ls-remote", "upstream", "refs/heads/master").split()[0],
        "worktreeClean": run(repo, "git", "status", "--porcelain") == "",
        "infrastructureRepository": str(infrastructure),
        "infrastructureHead": run(infrastructure, "git", "rev-parse", "HEAD"),
        "infrastructurePin": match.group(1),
        "live": health,
    }
    print(json.dumps(state, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
