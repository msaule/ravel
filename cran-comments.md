## Test environments

- local Windows 11, R 4.4.1
- GitHub Actions: ubuntu-latest (release, devel), macos-latest (release), windows-latest (release)

## R CMD check results

0 errors | 0 warnings | 2 notes

## Notes

- This is a resubmission after CRAN feedback requesting single quotes around software names in the Title and Description fields of DESCRIPTION.
- One note is the expected "New submission" incoming check because the package is not yet on CRAN.
- One local Windows note reports "unable to verify current time", which appears to be environment-specific.
- Provider integrations use official APIs or official CLIs only.
- Network-backed providers are not contacted in examples or tests.
