# Read recent Ravel history entries

Read recent Ravel history entries

## Usage

``` r
ravel_read_history(limit = 100L)
```

## Arguments

- limit:

  Maximum number of history entries to return.

## Value

A tibble.

## Details

History stays in session memory by default. To mirror it to disk
explicitly, configure
`options(ravel.user_dirs = list(data = "<path>"))`.
