#!/usr/bin/env python3
"""Find paths on the live branch that are not owned by any Kargo Stage.

Parses every kargo-projects/*/stage.yaml at the given checkout root,
collects the outPath of every `uses: copy` promotion step, classifies
each as a file (exact-match) or subtree (prefix-match) ownership claim,
then walks the checkout and emits one orphan path per line (relative to
the checkout root) suitable for `xargs -d '\\n' git rm -r --`.

The classification of file-vs-subtree is decided by looking at the
corresponding source path (inPath) on disk: if the source is a file,
the outPath is a file claim; if it's a directory, the outPath is a
subtree claim.

A directory is emitted as a single orphan only when no path under it is
owned; otherwise the script recurses and emits the unowned leaves.
"""

import os
import sys
from pathlib import Path

import yaml


SRC_PREFIX = "./src/"
OUT_PREFIX = "./out/"


def parse_stages(root: Path):
    expected_files: set[str] = set()
    expected_subtrees: set[str] = set()

    for stage_file in sorted((root / "kargo-projects").glob("*/stage.yaml")):
        with stage_file.open() as f:
            stage = yaml.safe_load(f) or {}
        steps = (
            stage.get("spec", {})
            .get("promotionTemplate", {})
            .get("spec", {})
            .get("steps", [])
        )
        for step in steps:
            if step.get("uses") != "copy":
                continue
            cfg = step.get("config", {}) or {}
            in_path = cfg.get("inPath", "")
            out_path = cfg.get("outPath", "")
            if not out_path.startswith(OUT_PREFIX):
                continue
            out_rel = out_path[len(OUT_PREFIX):].strip("/")
            if not out_rel:
                continue
            if not in_path.startswith(SRC_PREFIX):
                continue
            src = root / in_path[len(SRC_PREFIX):]
            if src.is_file():
                expected_files.add(out_rel)
            elif src.is_dir():
                expected_subtrees.add(out_rel)
            else:
                sys.stderr.write(
                    f"warning: {stage_file}: source {src} does not exist on live; "
                    f"skipping outPath {out_path}\n"
                )
                continue

    return expected_files, expected_subtrees


def find_orphans(root: Path, files: set[str], subtrees: set[str]) -> list[str]:
    orphans: list[str] = []

    def under_subtree(rel: str) -> bool:
        return any(rel == d or rel.startswith(d + "/") for d in subtrees)

    def has_owned_descendant(rel: str) -> bool:
        prefix = rel + "/"
        return any(p.startswith(prefix) for p in files) or any(
            p.startswith(prefix) for p in subtrees
        )

    def walk(rel: str) -> None:
        if rel and under_subtree(rel):
            return
        directory = root if not rel else root / rel
        for entry in sorted(os.listdir(directory)):
            if entry == ".git":
                continue
            child_rel = f"{rel}/{entry}" if rel else entry
            child = directory / entry
            if child.is_file():
                if child_rel not in files:
                    orphans.append(child_rel)
            elif child.is_dir():
                if child_rel in subtrees:
                    continue
                if has_owned_descendant(child_rel):
                    walk(child_rel)
                else:
                    orphans.append(child_rel)

    walk("")
    return orphans


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write(f"usage: {sys.argv[0]} <live-checkout-root>\n")
        return 2
    root = Path(sys.argv[1]).resolve()
    if not (root / "kargo-projects").is_dir():
        sys.stderr.write(f"{root}: no kargo-projects/ directory found\n")
        return 2
    files, subtrees = parse_stages(root)
    for orphan in find_orphans(root, files, subtrees):
        print(orphan)
    return 0


if __name__ == "__main__":
    sys.exit(main())
