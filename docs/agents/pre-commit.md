# pre-commit Agent Contract

**Version:** v1.0.0

This document defines **normative agent behavior** for interacting with
**pre-commit** in this repository.

This document is subordinate to, and governed by, `AGENTS.md`. Repository-
specific workflow rules may further refine behavior via `WORKFLOW.md`.

Precedence is resolved as follows:

`this document` > `WORKFLOW.md` (if it exists) > `AGENTS.md`

## Purpose

This document specifies how agents must behave when **pre-commit** is in use
within a repository. It does not describe how to configure pre-commit itself,
only how agents are allowed to interact with it.

## Tool Detection

The repository is considered to be using **pre-commit** if:

* `.pre-commit-config.yaml` exists at the repository root.

No other signal is required.

## Agent Rules

* Agents MUST treat `.pre-commit-config.yaml` as **non-modifying checks only**.
* If `.pre-commit-config-fix.yaml` exists:
  * It defines optional, modifying hooks.
* Agents MUST NOT apply auto-fixes without explicit user approval.
* Default agent behavior:
  * Run non-modifying checks only.
* When explicitly approved by the user:
  * Agents MAY run modifying hooks.
* In CI contexts:
  * Agents MUST run checks only.
  * Agents MUST NOT apply or commit fixes.
