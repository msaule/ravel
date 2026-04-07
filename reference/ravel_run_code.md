# Run R code with explicit approval semantics

Run R code with explicit approval semantics

## Usage

``` r
ravel_run_code(action, approve = FALSE, envir = NULL)
```

## Arguments

- action:

  Either a `ravel_action` or a character string of R code.

- approve:

  Whether to approve and run immediately.

- envir:

  Evaluation environment. When `NULL`, code runs in Ravel's dedicated
  session-scoped execution environment instead of `.GlobalEnv`.

## Value

A structured result list.
