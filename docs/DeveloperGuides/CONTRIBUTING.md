# Contributing to HealthAI 2030

Thank you for your interest in contributing! Please read our guidelines:

- Open an issue to discuss new features or bug fixes before submitting a PR.
- Follow our code style (SwiftLint/SwiftFormat enforced).
- Write tests for new features and bug fixes.
- Document public APIs using Swift documentation comments.
- For major changes, update the architecture diagram in `/docs`.

## Pre-commit Hooks

Before committing, run:

    .git/hooks/pre-commit

Or set up your git client to run this automatically.

## Documentation

To generate API docs, open the HealthAI2030DocC catalog in Xcode and build documentation.

## How to Contribute a Copilot Skill

1. Add your skill to `CopilotSkills/SkillManifest.json`.
2. Implement your skill logic in a new Swift file in `CopilotSkills/`.
3. Add documentation and tests for your skill.
4. Submit a pull request!
