# Agent Guidelines

Welcome, fellow agent! These instructions govern the entire repository unless a subdirectory contains its own `AGENTS.md` file.

## Engineering Principles
- **Optimize for correctness and clarity.** Prefer well-structured, readable solutions over clever shortcuts. Favor explicitness and maintainability.
- **Uphold Ruby on Rails best practices.** Follow conventional Rails patterns (RESTful controllers, strong parameters, validations, service objects, etc.) and leverage the framework idioms instead of reinventing them.
- **Respect technology norms.** When working with supporting technologies (e.g., JavaScript, CSS, database migrations, background jobs), conform to their community best practices and project style.
- **Justify every change.** Understand the problem you are solving before modifying code. Avoid speculative features, dead code, or "quick hacks." Always know _why_ something is being added.

## Quality Expectations
- **Comprehensive testing.** Add or update automated tests covering the functional changes. Tests should be deterministic, meaningful, and fast.
- **Static and dynamic checks.** Run the relevant linters, formatters, and test suites before committing. Document the commands executed in your final report.
- **Thoughtful documentation.** Update READMEs, inline comments, or commit messages when necessary to explain non-obvious behavior.

## Security & Configuration
- **Keep secrets out of the repo.** Never commit credentials or `.env` contents. Mirror any required configuration changes in `.env.example`.
- **Review third-party code paths.** Be mindful of dependencies, generated code, and configuration that could expose sensitive data.

## Workflow Requirements
- **Explain the why.** Capture the rationale behind each change in commit messages, PR descriptions, and comments when appropriate.
- **Minimize churn.** Do not edit files unrelated to the task at hand. When refactoring, keep changes logically grouped and well justified.
- **Verify before shipping.** Ensure the application boots and affected features function locally when possible. Address any warnings or failures promptly.
- **Ensure CI parity.** Locally run the same linters, builds, and tests that CI uses. If an external dependency blocks execution, record the exact failure and why it cannot be resolved.

## Pull Request Expectations
- **Clear description.** Summarize the motivation, scope, and high-level implementation details.
- **Link related work.** Reference the associated issue or ticket when one exists.
- **Call out breaking changes.** Explicitly note any backwards-incompatible behavior and provide migration guidance.
- **Document verification steps.** Include local run instructions, test commands, or representative `curl` examples so reviewers can reproduce results.
- **Keep history clean.** Commit logical units of work with informative messages; avoid noise and unnecessary churn.

Happy building, and keep the codebase exceptional!
