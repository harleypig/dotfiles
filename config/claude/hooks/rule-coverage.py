#!/usr/bin/env python3
"""PostToolUse hook: flag tools/libraries/languages used without a rule.

Reminds (non-blocking) when:

  A. a dependency manifest (package.json, pyproject.toml) gains a
     dependency that has no rules/<name>.md, or
  B. a source file is written whose language has no rules/<lang>.md.

Per the global CLAUDE.md "Missing or Conflicting Tool Rules" policy, the
agent should then surface the gap and propose creating the rule. The
reminder is deduped per project, so it nags once — not on every edit.

Fail-safe: any error exits 0 silently so the tool flow is never disrupted.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

MANIFESTS = {"package.json", "pyproject.toml"}

LANG_BY_EXT = {
    ".ts": "typescript",
    ".tsx": "typescript",
    ".mts": "typescript",
    ".cts": "typescript",
    ".js": "javascript",
    ".jsx": "javascript",
    ".mjs": "javascript",
    ".cjs": "javascript",
    ".py": "python",
    ".pyi": "python",
    ".css": "css",
    ".scss": "scss",
    ".sass": "scss",
    ".go": "go",
    ".rs": "rust",
    ".java": "java",
    ".rb": "ruby",
    ".sh": "bash",
    ".bash": "bash",
    ".html": "html",
    ".htm": "html",
    ".sql": "sql",
    ".lua": "lua",
    ".php": "php",
    ".kt": "kotlin",
    ".kts": "kotlin",
    ".swift": "swift",
    ".tf": "terraform",
    ".vue": "vue",
}

# Dependencies that never warrant their own rule (type stubs, etc.).
IGNORE_DEP = re.compile(r"^@types/")


def _rules_dir() -> Path:
    base = os.environ.get("CLAUDE_CONFIG_DIR") or str(Path.home() / ".claude")
    return Path(base).expanduser() / "rules"


def _rule_exists(rules_dir: Path, name: str) -> bool:
    return (rules_dir / f"{name}.md").exists()


def _dep_candidates(dep: str) -> list[str]:
    dep = dep.strip().lower()
    cands: list[str] = []

    if dep.startswith("@") and "/" in dep:
        scope, pkg = dep[1:].split("/", 1)
        cands += [scope, pkg, f"{scope}-{pkg}"]

    cands.append(dep)
    cands.append(re.sub(r"[^a-z0-9]+", "-", dep).strip("-"))

    seen: set[str] = set()
    out: list[str] = []
    for cand in cands:
        if cand and cand not in seen:
            seen.add(cand)
            out.append(cand)

    return out


def _has_rule_for_dep(rules_dir: Path, dep: str) -> bool:
    return any(_rule_exists(rules_dir, c) for c in _dep_candidates(dep))


def _pep508_name(spec: str) -> str:
    return re.split(r"[\s<>=!~\[;()]", spec.strip(), maxsplit=1)[0]


def _current_deps(manifest: Path) -> set[str]:
    try:
        if manifest.name == "package.json":
            data = json.loads(manifest.read_text(encoding="utf-8"))
            deps: set[str] = set()
            for key in (
                "dependencies",
                "devDependencies",
                "peerDependencies",
                "optionalDependencies",
            ):
                deps.update((data.get(key) or {}).keys())
            return deps

        if manifest.name == "pyproject.toml":
            try:
                import tomllib
            except ModuleNotFoundError:
                return set()

            data = tomllib.loads(manifest.read_text(encoding="utf-8"))
            deps = set()

            project = data.get("project", {})
            for spec in project.get("dependencies", []) or []:
                deps.add(_pep508_name(spec))
            for group in (project.get("optional-dependencies", {}) or {}).values():
                for spec in group or []:
                    deps.add(_pep508_name(spec))

            poetry = data.get("tool", {}).get("poetry", {})
            for name in poetry.get("dependencies", {}) or {}:
                if name.lower() != "python":
                    deps.add(name)
            for grp in (poetry.get("group", {}) or {}).values():
                for name in grp.get("dependencies", {}) or {}:
                    if name.lower() != "python":
                        deps.add(name)

            return {d for d in deps if d}
    except Exception:
        return set()

    return set()


def _added_tokens(project_dir: str, manifest: str) -> set[str] | None:
    """Tokens on added (+) diff lines for the manifest; None if no git."""

    def diff(*extra: str) -> str:
        result = subprocess.run(
            ["git", "-C", project_dir, "diff", "--unified=0", *extra, "--", manifest],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout if result.returncode == 0 else ""

    try:
        text = diff() or diff("--cached")
    except Exception:
        return None

    tokens: set[str] = set()
    for line in text.splitlines():
        if line.startswith("+") and not line.startswith("+++"):
            tokens.update(re.findall(r"[A-Za-z0-9_.@/-]+", line))

    return tokens


def _newly_added_deps(project_dir: str, manifest: Path) -> set[str]:
    current = _current_deps(manifest)
    if not current:
        return set()

    tokens = _added_tokens(project_dir, str(manifest))
    if tokens is None:
        # No git diff available — fall back to all current deps; the
        # per-project dedup keeps this from repeating.
        return current

    return {dep for dep in current if dep in tokens}


def _state_file(project_dir: str) -> Path:
    git = Path(project_dir) / ".git"
    if git.is_dir():
        return git / "claude-rule-reminders"

    import hashlib
    import tempfile

    digest = hashlib.sha1(project_dir.encode()).hexdigest()[:12]
    return Path(tempfile.gettempdir()) / f"claude-rule-reminders-{digest}"


def _filter_new(project_dir: str, items: list[str]) -> list[str]:
    state = _state_file(project_dir)

    seen: set[str] = set()
    try:
        if state.exists():
            seen = set(state.read_text(encoding="utf-8").split())
    except Exception:
        seen = set()

    new = [item for item in items if item not in seen]

    if new:
        try:
            with state.open("a", encoding="utf-8") as handle:
                for item in new:
                    handle.write(item + "\n")
        except Exception:
            pass

    return new


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except Exception:
        return 0

    file_path = (event.get("tool_input") or {}).get("file_path")
    if not file_path:
        return 0

    project_dir = (
        os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()
    )
    rules_dir = _rules_dir()
    path = Path(file_path)

    items: list[str] = []

    if path.name in MANIFESTS and path.exists():
        for dep in sorted(_newly_added_deps(project_dir, path)):
            if IGNORE_DEP.match(dep):
                continue
            if not _has_rule_for_dep(rules_dir, dep):
                items.append(f"dep:{dep}")
    else:
        lang = LANG_BY_EXT.get(path.suffix.lower())
        if lang and not _rule_exists(rules_dir, lang):
            items.append(f"lang:{lang}")

    if not items:
        return 0

    new = _filter_new(project_dir, items)
    if not new:
        return 0

    deps = [i.split(":", 1)[1] for i in new if i.startswith("dep:")]
    langs = [i.split(":", 1)[1] for i in new if i.startswith("lang:")]

    lines: list[str] = []
    if deps:
        lines.append("dependencies with no rule: " + ", ".join(deps))
    if langs:
        lines.append("languages with no rule: " + ", ".join(langs))

    message = (
        "Rule coverage: these are now in use here but have no "
        f"{rules_dir}/<name>.md —\n - "
        + "\n - ".join(lines)
        + '\n\nPer the global CLAUDE.md "Missing or Conflicting Tool Rules" '
        "policy, surface this to the user and propose creating the rule(s) "
        "(decide scope via the three-tier model). Skip genuinely trivial "
        "utilities. This reminder will not repeat for the same items in "
        "this project."
    )

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "additionalContext": message,
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
