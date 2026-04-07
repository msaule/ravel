# Collect context for a Ravel chat turn

Collect context for a Ravel chat turn

## Usage

``` r
ravel_collect_context(
  include_selection = TRUE,
  include_file = TRUE,
  include_objects = TRUE,
  include_console = TRUE,
  include_plot = TRUE,
  include_session = TRUE,
  include_project = TRUE,
  include_git = TRUE,
  include_activity = TRUE,
  envir = NULL,
  max_objects = 10L
)
```

## Arguments

- include_selection:

  Include the active selection.

- include_file:

  Include the active file contents.

- include_objects:

  Include summaries of loaded objects.

- include_console:

  Include recent Ravel-managed console output.

- include_plot:

  Include current plot metadata when available.

- include_session:

  Include session information.

- include_project:

  Include project root and file listing.

- include_git:

  Include git status and diff summaries when available.

- include_activity:

  Include recent Ravel action state.

- envir:

  Environment used for object summaries. When `NULL`, Ravel reads from
  the current global workspace without modifying it.

- max_objects:

  Maximum number of objects to summarize.

## Value

A named list.
