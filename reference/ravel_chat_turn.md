# Run one chat turn through a provider

Run one chat turn through a provider

## Usage

``` r
ravel_chat_turn(
  prompt,
  provider = NULL,
  model = NULL,
  context = NULL,
  history = NULL
)
```

## Arguments

- prompt:

  User prompt.

- provider:

  Provider name.

- model:

  Optional model override.

- context:

  Optional precomputed context.

- history:

  Optional existing chat history.

## Value

A list with `message`, `actions`, and `raw`.
