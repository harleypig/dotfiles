# AI Agents and Automation

**Version:** v1.1.1

This `AGENTS.md` document defines the standard behaviors, configuration
modules, and responsibilities for AI agents across repositories. It is
designed for both human readability and machine interpretation. Agents reading
this document should:

1. **Interpret instructions literally and hierarchically:** Each agent section
   defines rules specific to that agent's domain (e.g., Git Workflow, Testing,
   Documentation). Unless overridden, general principles apply globally.

2. **Incorporate repository-specific rules from `WORKFLOW.md`:** Each
   repository should define a `WORKFLOW.md` file for project-specific
   configuration and extensions. When operating in a repository, agents must
   automatically merge the relevant sections from `WORKFLOW.md` with this
   document. If `WORKFLOW.md` does not exist or lacks applicable sections, the
   agent should suggest appropriate additions or create the file only when it
   makes sense — this action should not be automatic.

3. **Operate autonomously within defined boundaries:** Agents have permission
   to execute actions within their defined responsibilities (file edits,
   validation, linting, documentation generation, etc.) and to use MCP tools
   if available, without additional confirmation unless a rule explicitly
   requires it.

4. **Respect hierarchy:** In case of conflicts, follow this precedence order:
   `WORKFLOW.md` > Specific Agent Section > General Development Principles.

## Agent Overview

This framework defines multiple categories of agents:

* **Development Agents** — Code generation, testing, and documentation
* **Infrastructure Agents** — Workflow validation, deployment automation,
    configuration management
* **Security Agents** — Scanning, compliance checking, vulnerability
    assessment
* **Monitoring Agents** — Health checks, alerting, and performance monitoring
* **Style Enforcement Agents** — Code formatting, linting, and consistency
    checking

## Tools (Common Across Repositories)

Only tools that are broadly applicable across most repositories are listed
here. Agents should rely on these shared expectations instead of repeating
per‑section rules.

### pre-commit

**Purpose:** Standardize local checks and (optionally) auto-fixes before code
is committed or pushed.

**Requirements:**

* Two configs live at the repo root:
  * `.pre-commit-config.yaml` → **checks only** (non‑modifying).
    * Used by git hooks (via `pre-commit install`) and CI/GitHub Actions.
    * Runs all validation checks without modifying any files.
    * This is the default config used when running `pre-commit run`.
  * `.pre-commit-config-fix.yaml` → **checks + auto‑fixes** (modifying hooks).
    * Includes ALL checks from `.pre-commit-config.yaml` PLUS modifying hooks.
    * Use during development to check and fix everything in one go.
    * Must be run explicitly: `pre-commit run --all-files --config .pre-commit-config-fix.yaml`.
* **Critical**: The fix config MUST include all check hooks from the default config.
  The fix config is NOT just auto-fixes—it's checks + fixes combined.
* Hooks SHOULD be fast and deterministic; long/slow checks belong in CI.
* All hooks MUST be platform‑portable (Windows/Linux/macOS) or be clearly
  marked and skipped on unsupported platforms.

**Agent Behavior:**

* Install if missing: `pre-commit install` (no prompting needed).
  * This installs hooks using `.pre-commit-config.yaml` (checks only).
* Default to checks: run `pre-commit run --all-files`.
  * Uses `.pre-commit-config.yaml` by default (checks only, non-modifying).
* When preparing to commit and a fix config exists, run the fix config first:
    `pre-commit run --all-files --config .pre-commit-config-fix.yaml`
  to apply auto-fixes and re-run all checks before committing.
* When an auto‑fix is appropriate and safe, ask the user, then run:
    `pre-commit run --all-files --config .pre-commit-config-fix.yaml`.
  * This runs all checks AND applies auto-fixes in one pass.
* To target a single hook, prefer `pre-commit run <hook> --all-files`
    (or with `--config ...-fix.yaml` for fix variants).
* If the repository lacks these configs, **suggest** adding them (and offer a
    minimal template) but do not auto‑create unless the user approves.

**CI Guidance:**

* CI SHOULD run the same checks as local: `pre-commit run --all-files`.
  * Uses `.pre-commit-config.yaml` by default (checks only).
* Fail the job on any violation; do not auto‑commit fixes in CI.

## General Development Principles

These principles apply globally unless overridden by a more specific agent or
repository-level rule:

* Keep configuration modules small and focused on a single responsibility.
* Follow the DRY (Don't Repeat Yourself) principle.
* Follow the Unix philosophy: Do one thing, and do it well.
* Use clear and descriptive names throughout the repository.
* Document all modules, variables, and complex logic.
* Validate and test all AI- or script-generated code.
* Implement robust error handling and logging throughout the codebase.
* Design for graceful degradation and clear error reporting.

## Development Agents

### Code Generation Agent

**Purpose:** Generate boilerplate code, configuration files, and
documentation.

**Scope:** Automation scripts, configuration modules, and templates.

**Responsibilities:**

* Output must follow repository structure and naming conventions.
* Include inline comments explaining non-trivial logic.
* Suggest validation or testing steps for generated code.
* Implement flexible error handling and logging patterns.
* Design for external system integration with proper authentication and data formatting.

**Error Handling and Logging:**

* Accept optional error handling and logging objects during instantiation of any class or module.
* If no custom error handler is provided, implement minimal error handling with configurable error levels.
* If no custom logger is provided, use standard logging library appropriate to the language/framework.
* Allow users to define granularity of error reporting and logging through level thresholds.
* Handle different types of errors appropriately (validation, system, user, external service, etc.).

**External Integration Patterns:**

* Design graceful error handling for external system interactions.
* Implement comprehensive logging for external operations.
* Handle different types of external service errors appropriately.
* Include proper authentication handling (tokens, API keys, credentials).
* Ensure proper data transformation for both outgoing requests and incoming responses.

**Validation:**

* Run syntax and linting checks after generation.
* Ensure generated files comply with layout and schema standards.
* Validate error handling patterns and logging implementation.

### Documentation Agent

**Purpose:** Auto-generate and maintain documentation from code.

**Responsibilities:**

* Generate README files for configuration modules or scripts.
* Maintain workflow and variable descriptions.
* Enforce **word wrapping at 78 columns** in Markdown and comments.
* Include practical examples for complex configurations.
* Use consistent terminology and formatting.
* Document external interfaces and integration patterns.
* Provide clear usage examples and error handling documentation.

**Interface Documentation:**

* Use available specifications, schemas, or definitions for documentation.
* Document parameter validation requirements.
* Document data format validation for external systems.
* Include authentication and authorization requirements.
* Provide troubleshooting guides for common error scenarios.

**Tools:**

* Documentation generators, linters, and AI-driven doc assistants (e.g.,
    Doxygen, Sphinx, MkDocs, or custom equivalents).

**Validation:**

* Check for missing or mismatched variable documentation.
* Validate Markdown formatting and link integrity.
* Ensure error handling patterns are properly documented.

### Testing Agent

**Purpose:** Automate testing and validation of automation components.

**Scope:** Syntax validation, integration tests, idempotency tests.

**Framework:** Follow the structure defined in `TESTS.md`.

**Responsibilities:**

* Use the repository's preferred testing framework (e.g., Pytest, Mocha, Jest,
    or custom runners).
* Run validation checks before commits.
* Generate reports highlighting failed checks.
* Provide comprehensive unit tests for all generated code.
* Test error handling and logging functionality.
* Validate external system integration patterns.

**Comprehensive Testing Standards:**

* **Unit testing requirement:** Provide unit tests for all modules and classes.
* **Mock testing:** Use appropriate mocking tools to test functions that access external systems.
* **Example requirements:** Provide examples of usage in the examples directory.
* **Integration testing:** Test interactions with external systems and services.
* **Error scenario testing:** Test error handling paths and edge cases.
* **Logging validation:** Verify logging output and levels work correctly.

## Infrastructure Agents

### Automation Agent

**Purpose:** Manage workflow definitions, configuration modules, and
deployments.

**Capabilities:**

* Validate configurations, perform dry-runs, and handle deployment tasks.
* Manage environment or infrastructure definitions.
* Implement robust error handling for deployment operations.

**Conventions:**

* Use validation and deployment tools suitable to the environment (e.g.,
    Terraform, Pulumi, Make, or shell scripts).
* Keep modules modular and reusable.
* Define default variables clearly.
* Use dependency handlers for cascading operations.
* Implement comprehensive error reporting for deployment failures.

### Configuration Management Agent

**Purpose:** Manage environment or system configuration files.

**Responsibilities:**

* Validate syntax and logical structure.
* Organize configuration by environment or purpose.
* Maintain consistent naming and schema patterns.
* Implement flexible configuration patterns.

**Flexible Configuration Patterns:**

* Accept optional configuration objects during instantiation of any class or module.
* Provide sensible defaults when no custom configuration is provided.
* Allow granular control through configuration levels/thresholds.
* Handle different environments (dev, staging, prod) appropriately.
* Support both file-based and environment variable configuration.

**Capabilities:**

* Support multiple environments (dev, staging, prod).
* Verify connectivity or resource definitions.
* Use configuration validation tools (e.g., JSON Schema, Yamale, Cue, or
    custom validators).

### Module Management Agent

**Purpose:** Manage configuration module dependencies.

**Capabilities:**

* Validate structure and metadata.
* Generate documentation and maintain dependency manifests.
* Handle versioning and packaging conventions (e.g., via npm, pip, cargo, or
    go modules).

**Conventions:**

* Module names use lowercase hyphenated format (e.g., `web-service`).
* Include comprehensive `README.md` and metadata files.

## Security Agents

### Vulnerability Scanning Agent

**Purpose:** Identify and report security vulnerabilities.

**Tools:**

* Security scanners and SAST/DAST tools such as Trivy, Grype, Bandit, or OWASP
    ZAP.

**Scope:** System hardening, compliance, and configuration validation.

### Compliance Agent

**Purpose:** Ensure adherence to security and regulatory standards.

**Responsibilities:**

* Run benchmark validation using frameworks like CIS Benchmarks, OpenSCAP, or
    internal equivalents.
* Generate compliance reports and remediation steps.

## Style Enforcement Agents

### Code Formatting Agent

**Purpose:** Maintain consistent code formatting.

**Tools:**

* Formatters and linters such as Prettier, Black, gofmt, or shfmt.

**Automation:**

* Use **pre-commit** per the rules in **Tools (Common Across Repositories)**.
* Prefer non‑modifying checks by default; ask before running auto‑fix hooks.

### Linting Agent

**Purpose:** Enforce coding standards and syntax validity.

**Scope:** Applies to YAML, JSON, shell, Python, TypeScript, or other project
languages.

**Tools:**

* Use the repository's chosen linters (e.g., ESLint, Flake8, ShellCheck, or
    Yamllint).

**Rules:** Must comply with repository-defined conventions.

### Naming Convention Agent

**Purpose:** Enforce consistent naming across all resources.

**Standards:**

* Workflow files: lowercase with underscores (`main_pipeline.yml`).
* Configuration modules: lowercase with hyphens (`api-gateway`).
* Branches: prefixed by type (`feature/`, `bugfix/`, `refactor/`).
* Variables and identifiers: descriptive, consistent, and scoped appropriately.

## Git Workflow Agent

**Purpose:** Enforce version control consistency and safety.

**Conventions:**

* Commit frequently with descriptive messages.
* Prefer conventional commit messages when applicable.
* All commits must be signed and verified.

**Branch Management:**

* Create feature branches from the latest **default branch** (see `WORKFLOW.md` for which branch is protected in this repo; currently `master`).
* Prefix branches appropriately:
  * `feature/` for new features
  * `bugfix/` for fixes
  * `refactor/` for refactoring
* Confirm before switching branches.
* Avoid auto-switching back to the protected default branch (`master` in this repo) unless the user confirms.

**Git Operations:**

* Use `git add -u` for modifications.
* Add new files explicitly (`git add <file>`).
* Use `rmdir` instead of `rm -rf` to detect untracked files.
* Prefer squash merges when merging feature branches.
* Before deleting merged branches, always ask the user for confirmation.
* If the user agrees, delete merged branches locally (`git branch -D
    feature/...`).
* After confirming local deletion, ask if the user also wants to delete the
    corresponding remote branch; perform remote deletion (`git push origin
    --delete <branch>`) if they approve. (`git branch -D feature/...`).

**Automation:**

* Use pre-commit hooks for linting and formatting.
* Enable branch protection on the **default branch** (see `WORKFLOW.md`; currently `master`).

## Monitoring Agents

### Health Check Agent

**Purpose:** Monitor service availability and key health metrics.

**Metrics:** Response times, error rates, resource usage.

**Alerting:** Configurable via notification hooks.

### Performance Monitoring Agent

**Purpose:** Analyze performance trends and system metrics.

**Responsibilities:** Collect, report, and optimize performance data.

## Configuration and Setup

**Environment Variables:** Defined in configuration files or system environment.

**Required Tools:**

* Common developer utilities: Git, language runtimes (Python, Node, Go, etc.),
    shell, and pre-commit.

**Permissions:**

* Full repository read/write access.
* Allowed to execute system commands and API requests.

## Usage Examples

### Development Workflow

```bash
aider-chat
cursor-agent .
docgen
linter --all
formatter --check
```

### Infrastructure Management

```bash
validator --syntax-check main.yml
deployer --dry-run main.yml
deployer run main.yml
test-runner all
```

### Security Scanning

```bash
security-scan --check
compliance-check --report
linter --profile production
```

## Troubleshooting

**Common Issues:**

* Connection or configuration errors.
* Module dependency mismatches.
* Permission or environment setup errors.
* External service integration failures.
* Error handling and logging configuration issues.

**Debug Commands:**

```bash
config-dump
validator --syntax-check main.yml
deployer -vvv main.yml
ping-all
error-log-analyzer
```

## Contributing

1. Follow agent-specific conventions.
2. Update this document for new or modified agents.
3. Include appropriate tests.
4. Maintain backward compatibility.
5. Validate security and compliance.
6. Ensure robust error handling and logging in all contributions.

## Resources

* [Best Practices Documentation](https://docs.example.com/best-practices)
* [Automation Frameworks](https://docs.example.com/automation)
* [CIS Benchmarks](https://www.cisecurity.org/benchmarks/)
* [OWASP Top 10](https://owasp.org/www-project-top-ten/)
* [Aider Documentation](https://aider.chat/)
* [Cursor Documentation](https://cursor.sh/docs)
