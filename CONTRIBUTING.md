# Contributing to Ravel

Thanks for helping build Ravel.

## Principles

Ravel is not a generic chat wrapper. Contributions should improve at least one
of these qualities:

- RStudio-native workflow quality
- statistics-aware reasoning
- safe and auditable actions
- honest provider/auth boundaries
- extensibility for future providers and tools

## Local setup

```r
install.packages("pak")
pak::pak(c(
  "devtools",
  "lintr",
  "pkgdown",
  "rcmdcheck",
  "testthat"
))
pak::pak("msaule/ravel")
```

For development from the repository root:

```r
devtools::load_all(".")
devtools::test()
lintr::lint_package()
```

## Before opening a pull request

Please run:

```r
devtools::document()
devtools::test()
lintr::lint_package()
rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"))
```

## Provider and auth changes

- Prefer official SDKs, HTTP APIs, or official CLIs.
- Do not imply that a consumer subscription exposes an API if it does not.
- Keep login-first and API-key support explicitly separated in docs and code.

## UI and workflow changes

- Favor explicit previews before execution or file edits.
- Keep chat, staged actions, and context basis visually distinct.
- Degrade cleanly when RStudio APIs are unavailable.

## Statistical helpers

- Use conservative language.
- Call out assumptions and limitations when they matter.
- Prefer summaries over raw dumps of large objects.
