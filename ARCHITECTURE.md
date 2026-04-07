# Ravel Architecture

## Design goals

Ravel is built around five principles:

1.  R-first context, not generic text chat
2.  honest provider support and auth messaging
3.  safe execution with explicit approval
4.  reproducible, logged actions
5.  extensible adapters for providers and tools

## Layered design

### 1. UI layer

Files:

- `R/addin_chat.R`
- `R/addin_settings.R`
- `R/ui_gadget.R`

Responsibilities:

- launch the RStudio gadget
- provide a first-run setup assistant and live readiness checks
- let users choose provider and model
- expose context toggles
- display chat history and staged actions
- route user requests through the orchestration layer

### 2. Orchestration layer

Files:

- `R/provider_interface.R`
- `R/history.R`

Responsibilities:

- normalize provider discovery
- build message payloads from chat + context
- store chat history and action records
- turn provider responses into user-visible messages and staged actions

### 3. Auth and settings layer

Files:

- `R/auth.R`

Responsibilities:

- store provider defaults and non-sensitive settings
- resolve secrets from environment, optional keyring, or session cache
- report supported auth modes per provider
- expose honest login/logout flows
- surface doctor/setup information and official docs or key-console
  links

### 4. Context layer

Files:

- `R/context_git.R`
- `R/context_session.R`
- `R/context_objects.R`
- `R/context_console.R`
- `R/context_plot.R`
- `R/tools_files.R`

Responsibilities:

- collect active document and selection state
- summarize loaded objects with type-aware compression
- collect project and package metadata
- collect git branch, file status, and compact diff excerpts
- summarize plot/device state when available
- capture console output generated through Ravel-managed execution

### 5. Tooling and execution layer

Files:

- `R/tools_models.R`
- `R/tools_quarto.R`
- `R/execution.R`
- `R/approvals.R`

Responsibilities:

- summarize and interpret model objects
- suggest diagnostics and common statistical checks
- draft Quarto or R Markdown sections
- preview, approve, and run code
- stage and apply file edits

## Provider contract

Each provider adapter returns a normalized provider object with:

- `name`
- `label`
- `auth_modes`
- `default_model`
- `supports_model_selection`
- `is_available()`
- `auth_status()`
- `chat(messages, context, settings)`

This keeps the UI and orchestration layers provider-agnostic.

## Auth model

Ravel supports four auth categories:

- API key
- OAuth or bearer token
- CLI login state
- unsupported or unavailable

Provider honesty matters more than symmetry:

- OpenAI API: API key
- OpenAI Codex CLI: official sign-in or API key, but through the CLI
  boundary
- GitHub Copilot: CLI login state through GitHub CLI / Copilot CLI, not
  private endpoints
- Gemini: API key and bearer token slot
- Anthropic: API key only

## Context contract

The normalized context payload contains:

- active document path
- selected code
- truncated active file contents
- project root
- project file listing
- git branch, changed files, and focused diff excerpts
- package/session info
- object summaries
- recent Ravel-managed console output
- current plot metadata

Context is summarized before it is sent to a provider. Large objects are
compressed to schema, dimensions, classes, model statistics, and a small
preview.

## Execution model

Provider responses stay as text until Ravel extracts an explicit action
candidate.

Action types:

- `run_code`
- `insert_into_document`
- `write_file`
- `append_file`
- `draft_quarto`

Actions move through:

1.  proposed
2.  previewed
3.  approved or rejected
4.  executed
5.  logged

Nothing is auto-applied by default in the MVP.

## Logging

Ravel keeps history in session memory by default. If a contributor or
user explicitly configures
`options(ravel.user_dirs = list(data = "<path>"))`, Ravel can mirror
those logs to disk as JSON Lines.

Logs include:

- timestamp
- provider
- model
- prompt summary hash
- action metadata
- execution outcome
- captured console output for Ravel-run actions

## Known platform constraints

- Public RStudio APIs do not expose every aspect of the console or plot
  state, so native console capture is partial.
- GitHub Copilot integration is limited to official CLI surfaces.
- ChatGPT subscription access is not treated as a general-purpose API.
- Gemini OAuth support varies by runtime and deployment context; the
  abstraction is present even where API-key mode is the simpler path.

## MVP definition

The MVP is successful when users can:

- open an RStudio chat addin
- choose a provider
- authenticate through at least one official path
- ask questions about selected code and loaded objects
- receive R-focused and stats-aware responses
- preview generated R code before running it
- draft a Quarto section from model or data context
- inspect a persistent action history
