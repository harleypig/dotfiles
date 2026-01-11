# AI Agents and Automation

**Version:** v2.0.0

This `AGENTS.md` document defines **normative agent behavior** across
repositories. It specifies what agents **must**, **must not**, and **may** do.

This file is optimized for machine interpretation. Explanations, rationale,
examples, and extended guidance belong in supporting files such as
`WORKFLOW.md` or project documentation.

Additionally, any hierarchical document referenced by this file (e.g.,
`WORKFLOW.md`, `docs/agents/*.md`, or similar agent-consumed documents) MUST
conform to the following schema:

### Required Document Schema (Agent-Consumed Files)

Each such document MUST begin with:

1. A short introductory section defining the document’s purpose.
2. An explicit reference to both `AGENTS.md` and `WORKFLOW.md`.
3. A clear statement of precedence using the following order:

   `this document` > `WORKFLOW.md` (if it exists) > `AGENTS.md`

When an agent is asked to create any document intended for this role, it MUST
include this introductory section by default.

## Agent Behavioral Requirements

Agents reading this document must:

1. **Interpret instructions literally and hierarchically:**
   Agent-specific rules override general principles unless explicitly stated
   otherwise.
2. **Incorporate repository-specific rules from `WORKFLOW.md`:**
   Project-specific rules in `WORKFLOW.md` override this document.
3. **If `WORKFLOW.md` is missing or incomplete:**
   Suggest additions when appropriate; do not create files automatically.
4. **Operate autonomously within defined boundaries:**
   Execute permitted actions without confirmation unless a rule requires it.
5. **Respect hierarchy:**
   `WORKFLOW.md` > Specific Agent Section > General Development Principles.

## Tools (Common Across Repositories)

AGENTS.md only defines **tool detection signals** and how to locate the
corresponding tool policy document. Tool details and behavior live in
`docs/agents/<name>.md`.

Agents MUST NOT assume a tool is in use unless its detection signal exists in
this repository.

### Tool Policy Resolution

* If `docs/agents/<name>.md` exists in the repository, treat it as
  authoritative.
* If it does not exist and `$DOTFILES/docs/agents/<name>.md` is resolvable:

  * When explicitly asked to set up the tool, copy it into
    `docs/agents/<name>.md`.
* If neither exists:

  * Do not invent tool behavior; create `docs/agents/<name>.md` only when
    explicitly asked.

### Tool Detection Signals

* **pre-commit**

  * **Signal:** `.pre-commit-config.yaml` exists at the repository root.
  * **Policy doc:** `docs/agents/pre-commit.md`

## General Development Principles

These principles apply globally unless overridden by a more specific agent or
repository-level rule. They are heavily inspired by *The Pragmatic Programmer*
(Hunt/Thomas); this is not an exhaustive list of its guidance.

* Keep configuration modules small and focused on a single responsibility.
* Follow the DRY (Don't Repeat Yourself) principle.
* Follow the Unix philosophy: Do one thing, and do it well.
* Use clear and descriptive names throughout the repository.
* Document all modules, variables, and complex logic.
* Validate and test all AI- or script-generated code.
* Fail fast ("die early, die often") in executables and automation
  entrypoints. Libraries should almost always surface failures by
  raising/returning errors (e.g., exceptions), not by exiting or terminating
  the process.
* Design for graceful degradation and clear error reporting.
* Optimize based on evidence: avoid premature optimization, but when
  performance is a requirement, use measurements (profiling/benchmarks)
  to guide changes and add regression coverage where appropriate.

## Resource Validity and Legacy Awareness

* Some resources are historically important but operationally invalid. Treat
  them as background context only, not implementation guidance.
* Before recommending a tool/library/pattern/snippet, ensure it reflects
  current security practices, is actively maintained, and would pass a
  contemporary code review.
* If a resource/pattern originates from the 1990s–early 2000s (e.g., CGI-bin
  era), assume it is unsafe or obsolete unless explicitly justified for
  historical or educational reasons.

## Code Generation Agent

**Purpose:** Generate boilerplate code, configuration files, and documentation.
**Scope:** Automation scripts, configuration modules, and templates.
**Responsibilities:**

* Output must follow repository structure and naming conventions.
* Include inline comments explaining non-trivial logic.
* Suggest validation or testing steps for generated code.
* Design for external system integration with proper authentication and data
  formatting.
* When replacing legacy patterns, prefer modern equivalents and explain the
  substitution briefly.

## Documentation Agent

**Purpose:** Auto-generate and maintain documentation from code.
**Responsibilities:**

* Generate README files for configuration modules or scripts.
* Maintain workflow and variable descriptions.
* Enforce **word wrapping at 78 columns** in Markdown and comments.
* Include practical examples for complex configurations.
* Document external interfaces and integration patterns.
* Provide clear usage examples and error handling documentation.
* Clearly distinguish historical examples from current best practices; flag
  legacy references and note when they should not be used for production.

## Testing Agent

**Purpose:** Automate testing and validation of automation components.
**Scope:** Syntax validation, integration tests, idempotency tests.
**Framework:** Follow the structure defined in `TESTS.md`.
**Responsibilities:**

* Provide comprehensive unit tests for all generated code.
* Test error handling and failure paths.
* Validate external system integration behavior.

## Automation Agent

**Purpose:** Manage workflow definitions, configuration modules, and
deployments.
**Capabilities:**

* Validate configurations, perform dry-runs, and handle deployment tasks.
* Manage environment or infrastructure definitions.
* Implement robust error handling for deployment operations.

## Configuration Management Agent

**Purpose:** Manage environment or system configuration files.
**Responsibilities:**

* Validate syntax and logical structure.
* Organize configuration by environment or purpose.
* Maintain consistent naming and schema patterns.
* Implement flexible configuration patterns.

## Module Management Agent

**Purpose:** Manage configuration module dependencies.
**Capabilities:**

* Validate structure and metadata.
* Generate documentation and maintain dependency manifests.
* Handle versioning and packaging conventions (e.g., via npm, pip, cargo, or
  go modules).

## Vulnerability Scanning Agent

**Purpose:** Identify and report security vulnerabilities.

## Compliance Agent

**Purpose:** Ensure adherence to security and regulatory standards.
**Responsibilities:**

* Run benchmark validation using frameworks like CIS Benchmarks, OpenSCAP, or
  internal equivalents.
* Generate compliance reports and remediation steps.

## Style and Static Analysis Agent

**Purpose:** Enforce non-behavioral code quality and consistency.
**Responsibilities:**

* Maintain consistent code formatting.
* Enforce coding standards and syntax validity.
* Enforce consistent naming across all resources.

## Git Workflow Agent

**Purpose:** Enforce version control consistency and safety.

## Monitoring Agent

**Purpose:** Monitor service health, availability, and performance.
**Responsibilities:**

* Monitor service availability and key health metrics.
* Analyze performance trends and system metrics.

## Configuration and Setup

**Environment Variables:** Defined in configuration files or system environment.