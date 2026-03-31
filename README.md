<p align="center" class="ravel-hero-image">
  <img src="man/figures/ravel-banner.svg" alt="Abstract woven banner for Ravel" width="100%" />
</p>

<h1 align="center">Ravel</h1>

<p align="center" class="ravel-tagline">
  <strong>R-first AI copilot for RStudio and Posit workflows.</strong><br />
  Context-aware code help, model interpretation, safe execution, and Quarto drafting.
</p>

<p align="center" class="ravel-badges">
  <a href="https://github.com/msaule/ravel/actions/workflows/R-CMD-check.yaml"><img src="https://github.com/msaule/ravel/actions/workflows/R-CMD-check.yaml/badge.svg" alt="R-CMD-check" /></a>
  <a href="https://github.com/msaule/ravel/releases"><img src="https://img.shields.io/github/v/release/msaule/ravel?display_name=tag" alt="Release" /></a>
  <a href="https://github.com/msaule/ravel/blob/main/LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT" /></a>
  <a href="https://github.com/msaule/ravel"><img src="https://img.shields.io/badge/lifecycle-experimental-orange.svg" alt="Lifecycle: experimental" /></a>
  <a href="https://msaule.github.io/ravel/"><img src="https://img.shields.io/badge/docs-pkgdown-2c5f5d.svg" alt="Docs" /></a>
</p>

Ravel is not just chat inside an IDE. It is designed to behave like an analysis copilot for R users: it understands the active script, selected code, loaded objects, model outputs, git changes, and reproducible reporting workflows so it can help with real RStudio work instead of acting like a generic web chatbot.

## Install now

```r
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("msaule/ravel")
library(ravel)
ravel::ravel_setup_addin()
```

> GitHub install works today. A standard `install.packages("ravel")` flow will be available once CRAN publishes the package.

## Why it feels different

- **Context-aware by default.** Ravel gathers the active editor, selected code, workspace objects, console state captured through Ravel actions, project files, and recent git diffs before it responds.
- **Built for statistical work.** It explains `lm()` and `glm()` results, coefficients, interactions, fit diagnostics, and common modeling pitfalls in plain English.
- **Safe when it acts.** Generated code is previewed, file edits are staged, and actions are logged instead of silently executed.
- **Designed for RStudio.** The setup flow, chat UI, and action workflow live inside RStudio addins rather than treating R as a thin wrapper around a generic chat window.
- **Multi-provider without pretending.** Ravel supports official APIs and official CLIs only, with clear messaging when a provider or auth path is unavailable.

## What works today

- RStudio addins for setup and chat
- Provider adapters for OpenAI, GitHub Copilot CLI, Gemini, and Anthropic
- Active-editor, selection, object, session, console, plot, project, and git-aware context
- Statistical helpers for model summaries, coefficients, diagnostics, and Quarto drafting
- Code preview, approval, execution, file staging, and action history logging

## Provider support

Ravel is explicit about what is supported today and what is still constrained by official provider boundaries.

| Provider | Status | Auth paths in Ravel | Notes |
| --- | --- | --- | --- |
| OpenAI API | Implemented | API key | Implemented against OpenAI HTTP APIs. |
| OpenAI Codex / ChatGPT | Working | Codex CLI sign-in, API key fallback | Ravel can use the official Codex CLI as a login-first OpenAI path, and can fall back to it automatically when the API path is rate-limited in `auto` mode. |
| GitHub Copilot | Working | Copilot CLI OAuth/device flow, GitHub CLI OAuth token | Ravel uses the official standalone Copilot CLI. It can authenticate via `copilot login` or supported GitHub tokens such as the OAuth token from `gh auth`. |
| Gemini | Implemented for API key, OAuth-ready abstraction | API key, bearer token/OAuth-style token slot | API-key flow is implemented. OAuth is represented in the auth abstraction so the provider boundary stays clean. |
| Anthropic | Implemented | API key | Official API-key auth only. No consumer-login mode is claimed. |

## First-run setup

1. Install and load `ravel`.
2. Run the setup assistant:
   ```r
   ravel::ravel_setup_addin()
   ```
3. Sign in or save a key for at least one provider.
4. Verify the provider from the setup panel.
5. Open chat:
   ```r
   ravel::ravel_chat_addin()
   ```

## What you can ask Ravel to do

- Ask questions about selected R code
- Explain an error, warning, or traceback
- Interpret model summaries, coefficients, and interactions
- Suggest diagnostics and next modeling steps
- Summarize loaded data frames and model objects
- Draft Quarto results, methods, and diagnostics sections
- Refactor tidyverse code to base R or the reverse
- Propose code and stage it before execution or insertion

## Safety and trust

- No silent code execution by default
- No silent file edits by default
- Explicit previews and approvals
- Structured history for actions and conversations, stored in session memory by default
- Honest provider and auth messaging
- Statistical caveats when assumptions or limitations are visible

Non-sensitive settings and history stay in session memory by default, so Ravel
does not write into a user's home filespace unless storage paths are configured
explicitly through `options(ravel.user_dirs = list(config = "<path>", data = "<path>"))`.

## Documentation and project guide

- Package website: <https://msaule.github.io/ravel/>
- [ARCHITECTURE.md](ARCHITECTURE.md) explains the layers and execution model.
- [ROADMAP.md](ROADMAP.md) lays out the planned phases beyond the MVP.
- [CONTRIBUTING.md](CONTRIBUTING.md) explains the developer workflow and release checks.
- [RELEASING.md](RELEASING.md) captures the CRAN and R-universe release path.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) describes community expectations.
- [AGENTS.md](AGENTS.md) describes collaboration conventions for contributors and coding agents.

## For contributors

If you are developing on the repository locally, prefer:

```r
devtools::load_all(".")
```

Use `devtools::install(".")` only when you specifically need the installed
package. Full release and submission details live in [RELEASING.md](RELEASING.md).

## References

The auth and provider boundaries in this project follow official documentation:

- OpenAI Codex CLI: <https://developers.openai.com/codex/cli>
- OpenAI API auth: <https://developers.openai.com/api/reference/overview>
- GitHub CLI `gh copilot`: <https://cli.github.com/manual/gh_copilot>
- Gemini API docs: <https://ai.google.dev/gemini-api/docs>
- Anthropic API docs: <https://docs.anthropic.com/en/api>
