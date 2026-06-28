# ravel 0.1.2

- Modernized provider defaults for the current OpenAI, Gemini, and Anthropic model lanes while keeping older model IDs selectable for compatibility.
- Added OpenAI Responses API support as the default API-key path, with chat-completions retained as an explicit compatibility mode.
- Added optional remote MCP tool declarations for providers that support MCP, beginning with OpenAI Responses API payloads.
- Tightened file-action safety: approved file writes outside the detected project root are blocked by default unless explicitly allowed.
- Documented the current sandbox boundary more clearly: Ravel provides approval-gated execution and a session-scoped R environment, not an operating-system sandbox.

# ravel 0.1.1

- Published on CRAN, so `install.packages("ravel")` now works for the stable release.
- Tightened install guidance with a resilient `pak`-first quick start.
- Added a release-assets GitHub Actions workflow so tagged releases upload source tarballs automatically.
- Simplified the root license files so the repository presents a canonical MIT license.

# ravel 0.1.0

- Initial public MVP for an RStudio-native analytics copilot for R.
- Added multi-provider support for OpenAI, GitHub Copilot CLI, Gemini, and Anthropic.
- Added guided setup, auth helpers, and live provider verification.
- Added active-editor, workspace, object, console, plot, activity, and git-aware context collection.
- Added safe staged execution, action logging, model interpretation helpers, and Quarto drafting tools.
