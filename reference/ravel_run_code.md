# Run R code with explicit approval semantics

Run R code with explicit approval semantics

## Usage

``` r
ravel_run_code(
  action,
  approve = FALSE,
  envir = NULL,
  allow_outside_project = FALSE
)
```

## Arguments

- action:

  Either a `ravel_action` or a character string of R code.

- approve:

  Whether to approve and run immediately.

- envir:

  Evaluation environment. When `NULL`, code runs in Ravel's dedicated
  session-scoped execution environment instead of `.GlobalEnv`.

- allow_outside_project:

  Whether approved file actions may write outside the detected project
  root. Ignored for character R code.

## Value

A structured result list.
