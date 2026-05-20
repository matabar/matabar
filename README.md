# personal-infra

Infrastructure management for personal projects using OpenTofu and Terragrunt.

## Directory Structure
- `root.hcl`: Root configuration for providers and remote state.
- `modules/`: Local, reusable OpenTofu modules.
- `live/`: Live infrastructure configurations, organized by environment and region.
    - `live/terragrunt.hcl`: Global environment settings.

## AI Agent Conventions
This repository follows strict conventions for AI agents as defined in [AGENTS.md](./AGENTS.md). All AI-assisted changes must adhere to these guidelines, including phased planning, branching strategies, and commit standards.
