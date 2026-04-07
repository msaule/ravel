# Set a Ravel setting

Set a Ravel setting

## Usage

``` r
ravel_set_setting(key, value)
```

## Arguments

- key:

  Setting name.

- value:

  Setting value.

## Value

The written settings list, invisibly.

## Details

Settings are stored in session memory by default. To mirror
non-sensitive settings to disk explicitly, configure
`options(ravel.user_dirs = list( config = "<path>"))` before calling
this function.
