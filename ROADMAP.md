# Ravel Roadmap

## Phase 1: Foundation

- Package scaffold, metadata, and addin registration
- Foundational docs and contribution guidance
- Provider interface and registry
- Auth abstraction and settings store
- Action history format

## Phase 2: Core experience

- RStudio chat gadget
- OpenAI API end-to-end provider
- Context gathering for scripts, selections, objects, and session info
- Basic action proposal flow for generated R code
- Initial tests and CI

## Phase 3: Analysis-native workflows

- Model-aware summarization for `lm`, `glm`, and formula-rich workflows
- Diagnostic suggestion helpers
- Quarto / R Markdown drafting helpers
- Safer execution previews and file-edit staging
- Better context compression for large workspaces

## Phase 4: More providers

- Gemini API completion support
- Anthropic API completion support
- GitHub Copilot CLI integration polish
- OpenAI Codex CLI bridge for login-first local workflows
- Provider-specific model selection and capability discovery

## Phase 5: Posit-native polish

- Guided first-run setup assistant with live provider verification
- Better document insertion and patch previews in RStudio
- Settings UX for auth and provider defaults
- Conversation/session persistence across projects
- More plot-aware and console-aware tooling
- Vignettes, examples, and contributor docs

## Phase 6: Agentic actions

- Structured file edit proposals
- Project-aware search and selective file reads
- Safer multi-step plans with approval checkpoints
- Reproducible reporting pipelines
- Model comparison workflows with explicit diagnostics
