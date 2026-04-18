---
paths:
  - "tests/**/*.bats"
  - "tests/helpers/**"
  - "tests/build-meta-tests"
---

# BATS Rules

**Version:** v1.0.0

## File Naming

| Pattern | Purpose |
|---------|---------|
| `test_<component>.bats` | Unit tests for a single script or library |
| `test_integration_<feature>.bats` | Multi-component integration tests |
| `meta_<check>.bats` | Auto-generated quality checks (do not edit manually) |
| `tests/helpers/<name>.bash` | Shared helper functions |

## Invocation

```bash
bats tests/                                          # all tests
bats tests/test_<component>.bats                     # single file
bats --filter "pattern" tests/test_<component>.bats  # matching tests only
```

## Test Structure

```bash
#!/usr/bin/env bats

setup()      { load helpers/common; }   # runs before each test
teardown()   { cleanup_temp_files; }    # runs after each test
setup_file() { }                        # runs once for the file
teardown_file() { }                     # runs once for the file

@test "descriptive name" {
  run command arg1 arg2
  [ "$status" -eq 0 ]
  [ "$output" = "expected" ]
}
```

## Assertions

```bash
[ "$status" -eq 0 ]              # exit code
[ "$output" = "exact match" ]   # exact output
[[ "$output" =~ "pattern" ]]    # regex match
[[ "$stderr" =~ "error" ]]      # stderr
[ -f "/path/to/file" ]          # file exists
```

## Agent Behavior

- Every new script in `bin/` and every function in `lib/` MUST have a
  corresponding `test_<name>.bats` file covering success and failure paths.
- Bug fixes MUST include a regression test that fails before the fix.
- After writing or modifying `.bats` files, run the specific test file
  (`bats tests/test_<component>.bats`) first. Run the full suite
  (`bats tests/`) only before committing or when cross-component impact
  is plausible. The full suite is reserved for CI in general use.
- Regenerate meta-tests after adding or removing files:
  ```bash
  cd tests && ./build-meta-tests
  ```
