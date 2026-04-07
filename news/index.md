# Changelog

## ravel 0.1.1

CRAN release: 2026-04-03

- Published on CRAN, so `install.packages("ravel")` now works for the
  stable release.
- Tightened install guidance with a resilient `pak`-first quick start.
- Added a release-assets GitHub Actions workflow so tagged releases
  upload source tarballs automatically.
- Simplified the root license files so the repository presents a
  canonical MIT license.

## ravel 0.1.0

- Initial public MVP for an RStudio-native analytics copilot for R.
- Added multi-provider support for OpenAI, GitHub Copilot CLI, Gemini,
  and Anthropic.
- Added guided setup, auth helpers, and live provider verification.
- Added active-editor, workspace, object, console, plot, activity, and
  git-aware context collection.
- Added safe staged execution, action logging, model interpretation
  helpers, and Quarto drafting tools.
