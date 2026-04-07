# Store an API key for a provider

Store an API key for a provider

## Usage

``` r
ravel_set_api_key(
  provider = c("openai", "gemini", "anthropic"),
  key,
  persist = TRUE
)
```

## Arguments

- provider:

  Provider name.

- key:

  API key value.

- persist:

  Whether to try to persist the secret using `keyring`.

## Value

The stored key, invisibly.
