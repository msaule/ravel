# Store a bearer token for a provider

Store a bearer token for a provider

## Usage

``` r
ravel_set_bearer_token(provider = c("gemini"), token, persist = TRUE)
```

## Arguments

- provider:

  Provider name.

- token:

  Bearer token value.

- persist:

  Whether to try to persist the token using `keyring`.

## Value

The stored token, invisibly.
