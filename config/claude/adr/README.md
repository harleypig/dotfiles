# Architecture Decision Records — global Claude config

ADRs for the **global Claude configuration / setup audit** subsystem (this
`config/claude/` tree, deployed to `~/.claude/`). Dotfiles-*system* decisions
(shell, secrets, chezmoi, packaging) live separately in the repo-root
`docs/adr/` — see the **adr** skill for the two-area routing and the boundary
vs the `SETUP-AUDIT.md` decisions log.

Write these with the **adr** skill. Each is one consequential, hard-to-reverse
decision; immutable once Accepted (supersede, don't rewrite).

## Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| [0001](0001-skills-over-custom-commands.md) | Skills over custom commands for invokable procedures | Accepted | 2026-06-11 |
| [0002](0002-adapt-not-vendor-provenance.md) | Adapt-not-vendor; SOURCE.md only on implementation reuse | Accepted | 2026-06-11 |
| [0003](0003-foreign-library-guidance-is-global.md) | Guidance for repo-foreign libraries is global, front-loaded | Accepted | 2026-06-11 |

## Statuses

- **Proposed** — under consideration.
- **Accepted** — stands and is in effect.
- **Superseded by ADR-NNNN** — reversed by a later ADR (body kept as history).
- **Deprecated** — no longer relevant, not replaced.
