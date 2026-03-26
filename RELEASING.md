# Releasing Ravel

This file is the release path for GitHub, R-universe, and CRAN.

## Pre-release checks

From the package root:

```r
devtools::document()
devtools::test()
lintr::lint_package()
rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"))
```

Update these files before a public release:

- `NEWS.md`
- `README.md`
- `cran-comments.md`

## R-universe

R-universe's official setup documentation says you need:

1. A GitHub repository named `<username>.r-universe.dev`
2. A `packages.json` registry in that repository
3. The R-universe GitHub app installed on the same account

For this project, the target registry repository is:

- `https://github.com/msaule/msaule.r-universe.dev`

Minimal `packages.json`:

```json
[
  {
    "package": "ravel",
    "url": "https://github.com/msaule/ravel"
  }
]
```

After the first successful build, add the install instructions and badges from
the R-universe dashboard to `README.md`.

## CRAN

Before a CRAN submission:

1. Confirm `R CMD check --as-cran` is clean locally.
2. Re-read the CRAN Repository Policy and submission checklist.
3. Make sure `DESCRIPTION` and `Authors@R` are accurate and complete.
4. Update `cran-comments.md` with current platforms and check results.
5. Submit with `devtools::release()` when ready.

## Notes for this package

- Revalidate live provider support before release if auth behavior changed.
- Keep provider claims conservative and official.
- Do not advertise consumer-login support for providers that only expose API-key auth.
