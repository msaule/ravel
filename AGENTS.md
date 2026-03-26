# AGENTS.md

This repository is designed to be friendly to both human contributors and coding agents.

## Project intent

Ravel is a serious open-source R package, not a thin chat wrapper. Changes should improve one or more of these traits:

- RStudio-native workflow quality
- statistics-aware reasoning
- safe and auditable actions
- honest provider/auth boundaries
- extensibility for future providers and tools

## Working agreements

- Keep provider support honest. Never imply a consumer subscription exposes an official API when it does not.
- Prefer official SDKs, official HTTP APIs, or official CLIs over reverse-engineered integrations.
- Default to safe execution. Code should be previewed before it is run or applied to files.
- Preserve structured logs when actions are taken.
- When extending context collection, prefer summarized signals over dumping entire objects or files.
- Statistical helpers should favor conservative, reproducible language over overconfident claims.

## Repository landmarks

- `R/provider_interface.R`: provider registry and common contract
- `R/auth.R`: auth modes, secrets, login/logout helpers
- `R/context_*.R`: context ingestion from session, objects, console, and plots
- `R/execution.R` and `R/approvals.R`: staged actions, previews, approvals, execution
- `R/ui_gadget.R`: RStudio addin chat UI
- `R/tools_models.R`: statistics-aware helpers
- `R/tools_quarto.R`: reproducible writing helpers
- `tests/testthat/`: behavior-focused unit tests

## Engineering guidance

- Avoid provider-specific logic in the UI layer.
- Add tests for new context summarizers and action helpers.
- Keep prompts small and structured; send summarized context, not raw workspace dumps.
- Treat RStudio APIs as optional and degrade cleanly outside the IDE.
- Prefer additive provider adapters over hard-coding one backend into the product.

## Review checklist

- Does the change keep auth support accurate?
- Does it preserve or improve safety defaults?
- Does it help R users with real analysis work?
- Does it avoid hidden execution or hidden file edits?
- Is the behavior logged or explainable when an action is taken?
