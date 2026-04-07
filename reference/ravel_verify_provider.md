# Verify a provider with a tiny live prompt

Verify a provider with a tiny live prompt

## Usage

``` r
ravel_verify_provider(
  provider = c("openai", "copilot", "gemini", "anthropic"),
  model = NULL
)
```

## Arguments

- provider:

  Provider name.

- model:

  Optional model override.

## Value

A named list with `ok`, `content`, `provider`, and `model`.
