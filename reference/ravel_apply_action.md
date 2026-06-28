# Execute a staged action

Execute a staged action

## Usage

``` r
ravel_apply_action(
  action,
  approve = FALSE,
  envir = NULL,
  allow_outside_project = FALSE
)
```

## Arguments

- action:

  A `ravel_action`.

- approve:

  Whether to override and treat the action as approved.

- envir:

  Evaluation environment for code execution. When `NULL`, Ravel uses a
  dedicated session-scoped environment that inherits from
  [`globalenv()`](https://rdrr.io/r/base/environment.html) for reads
  without writing into `.GlobalEnv` by default.

- allow_outside_project:

  Whether approved file actions may write outside the detected project
  root. The default is `FALSE`.

## Value

A structured result list.
