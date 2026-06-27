# Snippets

Reusable code fragments kept around so they don't have to be redeveloped
later — copy-paste reference material, **not** code that the shell or any
tool loads automatically. (Loaded shell libraries live in `lib/`; these are
just snippets to pull from when writing something new.)

Organized by type:

- **`bash/`** — shell function snippets (e.g. `join_array.bash`).
- **`pre-commit/`** — reusable pre-commit hook blocks (add as needed).

Add a subdirectory per type as new kinds of snippet show up. Shell snippets
(`*.sh` / `*.bash`) are still linted by the repo's `shellcheck` / `shfmt`
pre-commit hooks, so keep them clean even though nothing sources them.
