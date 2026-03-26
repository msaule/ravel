---
name: CRAN release checklist
about: Track the release-preparation work for a new CRAN submission
title: "CRAN release: "
labels: release
assignees: ""
---

## Release checklist

- [ ] `NEWS.md` updated
- [ ] `cran-comments.md` updated
- [ ] `devtools::document()` run
- [ ] `devtools::test()` passes
- [ ] `lintr::lint_package()` passes
- [ ] `rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"))` passes
- [ ] Provider support table in `README.md` is still accurate
- [ ] Auth claims remain within official boundaries
- [ ] Reverse dependency or breaking-change review completed if needed
- [ ] Submission comments drafted
