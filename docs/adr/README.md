# Architecture Decision Records

This directory holds **Architecture Decision Records** (ADRs) for the dotfiles
system — one document per consequential, hard-to-reverse decision, capturing
its context, the decision, the alternatives rejected (and why), and the
consequences accepted.

See the `adr` skill (the dotagents repo's `skills/adr/`) for when and how to
write one. Claude-config / audit decisions live separately in the dotagents
repo's `adr/`.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-custom-polyglot-version-manager.md) | Build a custom polyglot version-manager orchestrator that wraps native managers | Accepted |
| [0002](0002-perl-qa-tooling-scope.md) | Scope of the Perl QA tooling — what to gate, skip, and defer | Accepted |
| [0003](0003-home-config-symlink.md) | Whether to symlink `~/.config` to `$DOTFILES/config` | Accepted |
| [0004](0004-xdg-audit-mechanism-state-machine.md) | xdg-audit as a dotfile "mechanism" state-machine | Accepted |
