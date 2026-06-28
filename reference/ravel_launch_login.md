# Launch an official provider login flow

Launch an official provider login flow

## Usage

``` r
ravel_launch_login(
  provider = c("openai", "copilot", "gemini", "anthropic"),
  mode = NULL
)
```

## Arguments

- provider:

  Provider name.

- mode:

  Optional auth mode override.

## Value

A login plan list, invisibly.
