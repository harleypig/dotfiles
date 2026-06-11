---
paths:
  - "**/*.java"
---

# Java Rules

**Version:** v1.0.0

## Testing

### Framework

- JUnit 5 (`junit-jupiter`) for unit tests.
- Mockito for mocking interfaces, classes, and static methods.
- Test source root: `src/test/java/` mirroring the main package structure.

### Naming

- Test class: `<ClassUnderTest>Test` in the same package as the class.
- Test method: `<methodName>_<condition>_<expectedOutcome>` in
  snake_case, e.g. `resolveFilename_blankConfig_returnsNull`.

### Coverage Requirements

- Every public method must have at least one test.
- Test success paths and all distinct failure/error branches.
- Private methods: either test via the public interface or extract to
  package-private so they can be tested directly. Do not leave core
  logic untestable.

### Mocking Policy

- Use `Mockito.mock()` for interfaces and non-final classes.
- Use `Mockito.mockStatic()` for static factory methods; always close
  in a `try`-with-resources block.
- Do not mock value objects — construct them directly.
- Avoid mocking classes you own; prefer real implementations with
  test-friendly constructors or factory methods.

### What NOT to Test

- Framework wiring (dependency injection, event bus registration) —
  these are integration concerns.
- Auto-generated code (protobuf, JAXB, etc.) — test only your code.
- Simple getters/setters with no logic.

## Documentation

- Public API methods require a Javadoc comment.
- Inline comments follow the global `code-style.md` rule: explain the
  WHY, not the WHAT.
- Do not write multi-paragraph Javadoc; one concise sentence is enough
  for most methods.

## Formatting

- Google Java Format is the canonical formatter. Run
  `./gradlew googleJavaFormat` (or equivalent) to apply it. Do not
  manually reformat; the pre-commit hook enforces this.
- Line length follows the formatter's default (100 characters).

## Static Analysis

- **SpotBugs**: suppress with `@SuppressFBWarnings(value = "RULE",
  justification = "...")`. Justification is mandatory.
- **PMD**: suppress with `@SuppressWarnings("PMD.RuleName")` on the
  smallest scope (method preferred over class).
- Fix the root cause before reaching for suppression. Suppress only
  when the finding is a false positive or the fix would make the code
  worse.

## Agent Rules

- Write or update tests for every new or changed public method before
  committing.
- Run `./gradlew build` (or equivalent) before committing to confirm
  compilation, tests, and static analysis all pass.
- When a method is untestable due to framework coupling, extract its
  logic to a package-private helper so it can be unit-tested.
- Do not suppress static analysis findings without first explaining
  why fixing the root cause is not the right approach.
