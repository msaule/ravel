## Test environments

- local Windows 11, R 4.4.1
- GitHub Actions: ubuntu-latest (release, devel), macos-latest (release), windows-latest (release)

## R CMD check results

0 errors | 0 warnings | 2 notes

## Notes

- This is an initial CRAN submission.
- One note is the expected "New submission" incoming check.
- One local Windows note reports "unable to verify current time", which appears to be environment-specific.
- Provider integrations use official APIs or official CLIs only.
- Network-backed providers are not contacted in examples or tests.
