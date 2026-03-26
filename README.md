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
| OpenAI Codex / ChatGPT | Working | Codex CLI sign-in, API key fallback | Ravel can use the official Codex CLI as a login-first OpenAI path, and can fall back to it automatically when the API path is rate-limited in `auto` mode. |
| GitHub Copilot | Working | Copilot CLI OAuth/device flow, GitHub CLI OAuth token | Ravel uses the official standalone Copilot CLI. It can authenticate via `copilot login` or supported GitHub tokens such as the OAuth token from `gh auth`. |
| Gemini | Implemented for API key, OAuth-ready abstraction | API key, bearer token/OAuth-style token slot | API-key flow is implemented. OAuth is represented in the auth abstraction so the provider boundary stays clean. |
| Anthropic | Implemented | API key | Official API-key auth only. No consumer-login mode is claimed. |

## Auth policy

Ravel follows official patterns:

- OpenAI API uses bearer API keys.
- OpenAI login-first support uses the official Codex CLI sign-in flow, not a pretend ChatGPT API.
- GitHub Copilot support uses the official Copilot CLI and supported GitHub OAuth tokens.
- Gemini supports API-key mode and a bearer-token auth slot for official OAuth-based flows.
- Anthropic requires API keys.

If a provider is unavailable or only partially supported, Ravel surfaces that clearly instead of silently falling back to an unofficial path.

## Installation

For regular users, the easiest install path is one command:

```r
install.packages("pak")
pak::pak("msaule/ravel")
```

This installs Ravel and its package dependencies without requiring you to
manually list them one by one.

Optional but recommended:

```r
install.packages("keyring")
```

`keyring` lets Ravel store API keys more securely than plain session memory.

### Development installs

If you are iterating on the repository locally, prefer:

```r
devtools::load_all(".")
```

Use `devtools::install(".")` only when you specifically need the installed
package. Reinstalling over a loaded package can leave behind a stale or corrupt
lazy-load database in a long-lived R session.

If you ever hit an error like `lazy-load database ... is corrupt`:

1. Restart R.
2. Remove the stale install:
   ```r
   remove.packages("ravel")
   ```
3. Reinstall cleanly:
   ```r
   pak::pak("msaule/ravel")
   ```

If you are developing from source on Windows and want to run full package
checks, install Rtools and ensure its toolchain is available on `PATH`.

## First-run setup

After installing:

```r
ravel::ravel_setup_addin()
```

The setup assistant runs inside RStudio and helps you:

- check whether the Viewer pane, CLI tools, and secure secret storage are available
- launch official login flows for OpenAI Codex CLI and GitHub Copilot CLI
- save API keys for OpenAI, Gemini, and Anthropic
- open the official docs or key-management pages for each provider
- verify a provider with a tiny live prompt before you open chat

If at least one provider is ready, open chat with:

```r
ravel::ravel_chat_addin()
```

You can also launch the setup panel from the RStudio Addins menu.

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
