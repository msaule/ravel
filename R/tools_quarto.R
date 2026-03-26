ravel_quarto_code_chunk <- function(code, label = NULL) {
  label_text <- if (!is.null(label) && nzchar(label)) paste0(" ", label) else ""
  paste(
    paste0("```{r", label_text, "}"),
    code,
    "```",
    sep = "\n"
  )
}

#' Draft a Quarto section from analysis context
#'
#' @param section Section type.
#' @param model Optional fitted model object.
#' @param context Optional collected context.
#' @param include_chunk Whether to include a placeholder code chunk.
#'
#' @return A character string containing Quarto markdown.
#' @export
ravel_draft_quarto_section <- function(section = c("results", "methods", "diagnostics"),
                                       model = NULL,
                                       context = NULL,
                                       include_chunk = TRUE) {
  section <- match.arg(section)
  title <- tools::toTitleCase(section)
  lines <- c(sprintf("## %s", title), "")

  if (include_chunk) {
    chunk_code <- switch(
      section,
      results = "# Fit or summarize the final model here",
      methods = "# Document preprocessing or modeling steps here",
      diagnostics = "# Produce diagnostic plots or checks here"
    )
    lines <- c(lines, ravel_quarto_code_chunk(chunk_code, label = section), "")
  }

  if (!is.null(model)) {
    lines <- c(lines, ravel_interpret_model(model), "")
    if (identical(section, "diagnostics")) {
      lines <- c(lines, "Suggested checks:", paste0("- ", ravel_suggest_diagnostics(model)))
    }
  } else if (!is.null(context) && length(context$objects %||% list())) {
    object_names <- vapply(context$objects, function(x) x$name %||% "object", character(1))
    lines <- c(
      lines,
      sprintf(
        "This section is based on the current R session objects: %s.",
        paste(object_names, collapse = ", ")
      )
    )
  } else {
    lines <- c(
      lines,
      paste(
        "Summarize the analysis goal, the main findings, and any",
        "statistical caveats in plain language."
      )
    )
  }

  paste(lines, collapse = "\n")
}
