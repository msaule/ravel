# Draft a Quarto section from analysis context

Draft a Quarto section from analysis context

## Usage

``` r
ravel_draft_quarto_section(
  section = c("results", "methods", "diagnostics"),
  model = NULL,
  context = NULL,
  include_chunk = TRUE
)
```

## Arguments

- section:

  Section type.

- model:

  Optional fitted model object.

- context:

  Optional collected context.

- include_chunk:

  Whether to include a placeholder code chunk.

## Value

A character string containing Quarto markdown.
