# personal-infra

Infrastructure management for personal projects using OpenTofu and Terragrunt.

## Directory Structure
- `root.hcl`: Root configuration for providers and remote state.
- `modules/`: Local, reusable OpenTofu modules.
- `live/`: Live infrastructure configurations, organized by environment and region.
    - `live/terragrunt.hcl`: Global environment settings.

## AI Agent Conventions
This repository follows strict conventions for AI agents as defined in [AGENTS.md](./AGENTS.md). 

**Key Rules:**
- **No Direct Commits to Main**: All work must be performed in feature branches.
- **Phased Planning**: Every non-trivial task requires a phased plan.
- **Conventional Commits**: Strict adherence to commit message standards.
