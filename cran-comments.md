## Test environments

- local Windows 11, R 4.4.1
- GitHub Actions: ubuntu-latest (release, devel), macos-latest (release), windows-latest (release)

## R CMD check results

0 errors | 0 warnings | 1 note

## Notes

- This is a maintenance release.
- Provider model defaults were refreshed and OpenAI API-key mode now uses the Responses API by default, while retaining the chat-completions path as an explicit compatibility mode.
- Remote MCP tool declarations were added without adding new required or suggested dependencies.
- Approved file writes outside the detected project root are now blocked by default unless explicitly allowed by the caller.
- Ravel still does not write settings or history to the user's home filespace by default. Those records stay in session memory unless storage paths are configured explicitly.
- Code execution still does not write into `.GlobalEnv` by default. `ravel_run_code()` and `ravel_apply_action()` use a dedicated session-scoped execution environment unless an `envir` is supplied explicitly.
- One local Windows note reports "unable to verify current time", which appears to be environment-specific.
- Provider integrations use official APIs or official CLIs only.
- Network-backed providers are not contacted in examples or tests.
