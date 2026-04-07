# Stage a file write action

Stage a file write action

## Usage

``` r
ravel_stage_file_write(
  path,
  text,
  append = FALSE,
  provider = NULL,
  model = NULL
)
```

## Arguments

- path:

  Target file path.

- text:

  Text to write.

- append:

  Whether to append instead of overwrite.

- provider:

  Optional provider name.

- model:

  Optional model name.

## Value

A `ravel_action` object.
