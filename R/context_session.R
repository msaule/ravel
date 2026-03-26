ravel_active_document_context <- function(include_file = TRUE, include_selection = TRUE) {
  if (!rstudioapi::isAvailable()) {
    return(list())
  }

  doc <- tryCatch(rstudioapi::getActiveDocumentContext(), error = function(e) NULL)
  if (is.null(doc)) {
    return(list())
  }

  selections <- vapply(doc$selection, function(sel) sel$text %||% "", character(1))

  list(
    path = doc$path %||% "",
    selection = if (include_selection) {
      paste(selections[nzchar(selections)], collapse = "\n\n")
    } else {
      NULL
    },
    contents = if (include_file) ravel_trim_text(doc$contents %||% "", 6000L) else NULL
  )
}

ravel_session_info_context <- function() {
  list(
    r_version = R.version.string,
    working_directory = getwd(),
    attached_packages = search(),
    loaded_namespaces = utils::head(sort(loadedNamespaces()), 50L)
  )
}

#' Collect context for a Ravel chat turn
#'
#' @param include_selection Include the active selection.
#' @param include_file Include the active file contents.
#' @param include_objects Include summaries of loaded objects.
#' @param include_console Include recent Ravel-managed console output.
#' @param include_plot Include current plot metadata when available.
#' @param include_session Include session information.
#' @param include_project Include project root and file listing.
#' @param envir Environment used for object summaries.
#' @param max_objects Maximum number of objects to summarize.
#'
#' @return A named list.
#' @export
ravel_collect_context <- function(include_selection = TRUE,
                                  include_file = TRUE,
                                  include_objects = TRUE,
                                  include_console = TRUE,
                                  include_plot = TRUE,
                                  include_session = TRUE,
                                  include_project = TRUE,
                                  envir = .GlobalEnv,
                                  max_objects = 10L) {
  root <- ravel_project_root()
  context <- list()

  context$document <- ravel_active_document_context(
    include_file = include_file,
    include_selection = include_selection
  )

  if (include_project) {
    context$project <- list(
      root = root,
      files = ravel_list_project_files(root)
    )
  }

  if (include_objects) {
    context$objects <- ravel_collect_objects(envir = envir, max_objects = max_objects)
  }

  if (include_console) {
    context$console <- ravel_console_context()
  }

  if (include_plot) {
    context$plot <- ravel_plot_context()
  }

  if (include_session) {
    context$session <- ravel_session_info_context()
  }

  context
}
