ravel_column_types <- function(x) {
  vapply(
    x,
    function(col) paste(class(col), collapse = "/"),
    character(1)
  )
}

ravel_preview_data_frame <- function(x, n = 3L) {
  preview <- utils::capture.output(utils::head(x, n))
  ravel_trim_text(preview, 1000L)
}

#' Summarize an R object for provider context
#'
#' @param x An R object.
#' @param name Optional object name.
#'
#' @return A named list.
#' @export
ravel_summarize_object <- function(x, name = NULL) {
  classes <- class(x)
  label <- name %||% deparse(substitute(x))

  if (inherits(x, c("lm", "glm"))) {
    summary <- ravel_summarize_model(x, name = label)
    summary$kind <- "model"
    return(summary)
  }

  if (is.data.frame(x)) {
    return(list(
      name = label,
      kind = "data.frame",
      class = classes,
      rows = nrow(x),
      cols = ncol(x),
      columns = names(x),
      column_types = unname(ravel_column_types(x)),
      preview = ravel_preview_data_frame(x)
    ))
  }

  if (inherits(x, "formula")) {
    return(list(
      name = label,
      kind = "formula",
      class = classes,
      formula = paste(base::deparse(x), collapse = " ")
    ))
  }

  if (is.function(x)) {
    return(list(
      name = label,
      kind = "function",
      class = classes,
      arguments = names(formals(x))
    ))
  }

  if (is.atomic(x)) {
    return(list(
      name = label,
      kind = "atomic",
      class = classes,
      length = length(x),
      preview = ravel_trim_text(
        utils::capture.output(utils::str(utils::head(x, 10L))),
        1000L
      )
    ))
  }

  if (is.list(x)) {
    return(list(
      name = label,
      kind = "list",
      class = classes,
      length = length(x),
      names = utils::head(names(x), 20L),
      preview = ravel_trim_text(utils::capture.output(utils::str(x, max.level = 1L)), 1200L)
    ))
  }

  list(
    name = label,
    kind = "object",
    class = classes,
    preview = ravel_trim_text(utils::capture.output(utils::str(x, max.level = 1L)), 1200L)
  )
}

ravel_collect_objects <- function(envir = NULL, max_objects = 10L) {
  envir <- envir %||% globalenv()
  object_names <- utils::head(ls(envir = envir, all.names = FALSE), max_objects)
  lapply(object_names, function(name) {
    obj <- get(name, envir = envir, inherits = FALSE)
    ravel_summarize_object(obj, name = name)
  })
}
