# AGENTS.md

## Core Principles
- **Agent-First**: This file is the primary source of truth for AI agent behavior in this repo.
- **Strict Compliance**: All instructions here are mandatory.

## Planning & Strategy
- **Phased Planning**: Every non-trivial task MUST start with a phased implementation plan.
- **Structure**: Plans must be broken down into Chapters/Phases, each specifying:
    - Dedicated feature branches.
    - Atomic commits (following Conventional Commits).
    - Documentation updates per step.
- **Abstraction**: Plans should focus on architectural decisions and workflow, AVOIDING literal code snippets to prevent redundancy and keep plans focused on intent.

## Code Style & Conventions
- **Tooling**: Use `opentofu` and `terragrunt`.
- **Formatting**: Mandatory `terragrunt hclfmt`.
- **Naming**: kebab-case for resources, underscores for variables.
- **Documentation**: 
    - Maintain `README.md` and `AGENTS.md` in sync with all changes.
    - Plan documentation updates as first-class citizens in every task.

## Workflow & Git
- **Branching**: Mandatory `feature/<name>` branches.
- **Commits**: Strict **Conventional Commits**.
- **Atomicity**: One logical change per commit.
