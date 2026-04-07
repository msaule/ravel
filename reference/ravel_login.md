# Start a provider login flow

Start a provider login flow

## Usage

``` r
ravel_login(
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

A list describing the supported login action.
