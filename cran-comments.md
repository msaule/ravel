## Test environments

- local Windows 11, R 4.4.1
- GitHub Actions: ubuntu-latest (release, devel), macos-latest (release), windows-latest (release)

## R CMD check results

0 errors | 0 warnings | 1 note

## Notes

- This is a resubmission after CRAN feedback.
- DESCRIPTION now keeps software names single-quoted while leaving function names unquoted (`lm()` and `glm()`).
- Ravel no longer writes settings or history to the user's home filespace by default. Those records now stay in session memory unless storage paths are configured explicitly.
- Code execution no longer writes into `.GlobalEnv` by default. `ravel_run_code()` and `ravel_apply_action()` now use a dedicated session-scoped execution environment unless an `envir` is supplied explicitly.
- One local Windows note reports "unable to verify current time", which appears to be environment-specific.
- Provider integrations use official APIs or official CLIs only.
- Network-backed providers are not contacted in examples or tests.
