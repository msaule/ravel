# Ravel

Ravel is an RStudio/Posit-native coding and analytics copilot for R users.

It is designed for code generation, object-aware analysis, statistical interpretation, safe execution, and reproducible authoring inside RStudio workflows. The package is intentionally R-first: it understands scripts, selections, data frames, formulas, model objects, console state captured through Ravel actions, and Quarto/R Markdown authoring tasks.

## Why Ravel

Most IDE assistants for R focus on inline completion or generic chat. Ravel is built to feel closer to an analysis agent:

- It gathers project and session context before answering.
- It summarizes loaded objects instead of treating R like plain text.
- It specializes in `lm`, `glm`, formulas, diagnostics, and interpretation.
- It previews code and file edits before running them.
- It logs actions for auditability.
- It supports multiple providers through a common interface.

## MVP status

The repository currently includes:

- An installable R package skeleton with exports, tests, CI, and vignettes
- An RStudio addin and Shiny gadget chat UI
- Provider abstractions for OpenAI, GitHub Copilot CLI, Gemini, and Anthropic
- Auth and settings helpers with optional secure secret storage via `keyring`
- Context gathering for active document, selection, workspace objects, project files, session info, plot metadata, and Ravel-captured console output
- Safe code preview / approval helpers for running code or applying file edits
- Statistical helpers for model summarization, coefficient interpretation, and diagnostic suggestions
- Quarto drafting helpers for results, methods, and diagnostics sections
- Action and conversation history logging

## Honest provider support

Ravel is explicit about what is supported today, what is experimental, and what is not available through official APIs.

| Provider | Status in MVP | Auth modes in package | Notes |
| --- | --- | --- | --- |
| OpenAI API | Implemented | API key | Implemented against OpenAI HTTP APIs. |
| OpenAI Codex / ChatGPT | Partial | Codex CLI sign-in, API key fallback | Official Codex CLI supports sign-in with a ChatGPT account or API key. Ravel exposes the auth boundary and settings, but in-addin chat is implemented through the OpenAI API path today. |
| GitHub Copilot | Experimental | GitHub CLI login / Copilot CLI | Ravel includes a provider adapter for `gh copilot`. It uses official GitHub auth state and CLI execution when available. Deep Copilot internals are intentionally not used. |
| Gemini | Implemented for API key, OAuth-ready abstraction | API key, bearer token/OAuth-style token slot | API-key flow is implemented. OAuth is represented in the auth abstraction so the provider boundary stays clean. |
| Anthropic | Implemented | API key | Official API-key auth only. No consumer-login mode is claimed. |

## Auth policy

Ravel follows official patterns:

- OpenAI API uses bearer API keys.
- OpenAI login-first support is modeled through the official Codex CLI sign-in flow, not by pretending ChatGPT subscriptions are a drop-in API.
- GitHub Copilot support is routed through the official GitHub CLI / Copilot CLI surface when available.
- Gemini supports API-key mode and a bearer-token auth slot for official OAuth-based flows.
- Anthropic requires API keys.

If a provider is unavailable or only partially supported, Ravel surfaces that clearly instead of silently falling back to an unofficial path.

## Installation

From the repository root in R:

```r
install.packages(c(
  "cli",
  "httr2",
  "jsonlite",
  "miniUI",
  "rstudioapi",
  "shiny",
  "tibble",
  "vctrs",
  "digest",
  "xml2",
  "curl",
  "testthat"
))

# Optional but recommended for secure key storage
install.packages("keyring")

devtools::install(".")
```

If you are developing from source on Windows and want to run full package checks,
install Rtools and ensure its toolchain is available on `PATH`.

## Launching the addin

After installing:

```r
ravel::ravel_chat_addin()
```

You can also launch the settings gadget with:

```r
ravel::ravel_settings_addin()
```

## What the addin can do

- Ask questions about selected R code
- Explain model summaries and coefficients
- Summarize loaded data frames and model objects
- Draft Quarto sections from live analysis context
- Propose code blocks for execution
- Insert generated code into the active RStudio document
- Preview and approve console execution before anything runs

## Statistical differentiation

Ravel is tuned for analysis workflows, not just chat:

- `lm` / `glm` explanation
- coefficient and interaction interpretation
- common diagnostic suggestions
- residual and fit discussion
- modeling tradeoff prompts
- tidyverse/base-R translation help
- Quarto-ready prose from model summaries

## Safety model

Ravel does not silently execute generated code by default.

- Proposed code is previewed before execution.
- File edits are staged as actions.
- History is written to a persistent log.
- Statistical answers include warnings when assumptions or limitations are visible from the context.

## Repository guide

- [ARCHITECTURE.md](ARCHITECTURE.md) explains the layers and execution model.
- [ROADMAP.md](ROADMAP.md) lays out the planned phases beyond the MVP.
- [AGENTS.md](AGENTS.md) describes collaboration conventions for contributors and coding agents.

## References

The auth and provider boundaries in this project follow official documentation:

- OpenAI Codex CLI: <https://developers.openai.com/codex/cli>
- OpenAI API auth: <https://developers.openai.com/api/reference/overview>
- GitHub CLI `gh copilot`: <https://cli.github.com/manual/gh_copilot>
- Gemini API docs: <https://ai.google.dev/gemini-api/docs>
- Anthropic API docs: <https://docs.anthropic.com/en/api>
