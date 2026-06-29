#!/usr/bin/env python3

"""PostToolUse hook: format (and lightly validate) Terraform/Packer on edit.

After an Edit/Write/MultiEdit, if the touched file is Terraform (.tf, .tfvars,
.tftest.hcl) or Packer (.pkr.hcl, .pkrvars.hcl), run the formatter on that one
file. HCL is whitespace/quote sensitive, so a one-character slip causes
confusing errors; auto-formatting on edit keeps them out. Then surface anything
the format pass could NOT fix (a parse error) plus a cheap validate:

- Terraform: `terraform fmt <file>` (writes), then `terraform validate` ONLY if
  the file's dir is already initialized (a `.terraform/` is present) — never a
  slow `init` per edit; dummy AWS env so the s3 backend skips IMDS probing.
- Packer: `packer fmt <file>` (writes), then `packer validate -syntax-only`
  (no plugins/credentials needed).

Unlike shell-check.py (check-only), this DOES rewrite the edited file — so it
reports when it changed the content (re-read before further edits). It calls
`terraform`/`packer` off PATH (the bin/ docker wrappers).

Fail-open: any problem — no terraform/packer on PATH, no Docker, the file
outside the project, a timeout — exits 0 silently, so the hook can never wedge
an edit. Global config, so it must stay safe in every repo.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

TERRAFORM_SUFFIXES = (".tf", ".tfvars", ".tftest.hcl")
PACKER_SUFFIXES = (".pkr.hcl", ".pkrvars.hcl")
FMT_TIMEOUT_S = 30
VALIDATE_TIMEOUT_S = 90

# Dummy values so `terraform validate` on an s3-backend config doesn't probe
# EC2 IMDS for credentials — throwaway, never real secrets (see terraform.md).
DUMMY_AWS_ENV = {
  "AWS_ACCESS_KEY_ID": "test",
  "AWS_SECRET_ACCESS_KEY": "test",
  "AWS_EC2_METADATA_DISABLED": "true",
}


def _tool_for(path: Path) -> str | None:
  """'terraform', 'packer', or None for the edited file."""
  name = path.name
  if name.endswith(PACKER_SUFFIXES):
    return "packer"
  if name.endswith(TERRAFORM_SUFFIXES):
    return "terraform"
  return None


def _run(
  cmd: list[str],
  cwd: str,
  timeout: int,
  extra_env: dict[str, str] | None = None
) -> subprocess.CompletedProcess[str] | None:
  """Run cmd; return the result, or None on any failure (fail-open)."""
  env = {**os.environ, **extra_env} if extra_env else None
  try:
    return subprocess.run(
      cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=env
    )
  except Exception:
    return None


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  file_path = (event.get("tool_input") or {}).get("file_path")
  if not file_path:
    return 0

  path = Path(file_path)
  if not path.is_file():
    return 0

  tool = _tool_for(path)
  if tool is None:
    return 0

  project_dir = (
    os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()
  )

  # bin/ wrappers mount $PWD; the target must be relative to (under) it.
  try:
    rel = path.resolve().relative_to(Path(project_dir).resolve())
  except ValueError:
    return 0

  rel_dir = str(rel.parent) if str(rel.parent) else "."
  messages: list[str] = []

  # --- format (writes the file) -------------------------------------------
  fmt = _run([tool, "fmt", str(rel)], project_dir, FMT_TIMEOUT_S)
  if fmt is None:
    return 0  # tool/Docker absent — fail-open

  if fmt.returncode != 0:
    err = (fmt.stderr or fmt.stdout or "").strip()
    messages.append(
      f"`{tool} fmt` could not format {rel} (just edited) — likely a syntax "
      f"error it can't parse; fix it:\n\n{err}"
    )
  elif fmt.stdout.strip():
    # terraform/packer fmt prints the filename when it rewrites it.
    messages.append(
      f"Reformatted {rel} with `{tool} fmt` — the on-disk content changed; "
      "re-read it before further edits."
    )

  # --- validate (cheap / conditional only) --------------------------------
  if tool == "terraform":
    if (Path(project_dir) / rel.parent / ".terraform").is_dir():
      val = _run(
        ["terraform", f"-chdir={rel_dir}", "validate", "-no-color"],
        project_dir,
        VALIDATE_TIMEOUT_S,
        extra_env=DUMMY_AWS_ENV,
      )
      if val is not None and val.returncode != 0:
        messages.append(
          f"`terraform validate` failed for {rel_dir}/ (just edited):\n\n"
          f"{(val.stdout or val.stderr or '').strip()}"
        )
  else:
    # packer — syntax-only needs no init or credentials
    val = _run(
      ["packer", "validate", "-syntax-only", rel_dir],
      project_dir,
      VALIDATE_TIMEOUT_S,
    )
    if val is not None and val.returncode != 0:
      messages.append(
        f"`packer validate -syntax-only` failed for {rel_dir}/ (just "
        f"edited):\n\n{(val.stdout or val.stderr or '').strip()}"
      )

  if not messages:
    return 0

  body = "\n\n".join(messages)
  note = (
    f"{body}\n\n(PostToolUse iac-fmt hook: auto-formats HCL on edit and "
    "surfaces fmt/validate problems — see terraform.md / packer.md.)"
  )
  payload = {
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": note,
    }
  }
  print(json.dumps(payload))
  return 0


if __name__ == "__main__":
  sys.exit(main())
