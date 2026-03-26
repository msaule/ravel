ravel_active_doc_context_raw <- function() {
  if (!ravel_is_rstudio_available()) {
    return(NULL)
  }

  tryCatch(rstudioapi::getActiveDocumentContext(), error = function(e) NULL)
}

# nolint start: object_usage_linter
ravel_relative_path <- function(path, root) {
  path <- ravel_normalize_path(path)
  root <- ravel_normalize_path(root)

  if (!nzchar(path) || !nzchar(root) || !ravel_path_is_within(path, root)) {
    return(NULL)
  }

  if (identical(path, root)) {
    return(".")
  }

  substring(path, nchar(root) + 2L)
}

ravel_recent_activity_context <- function(limit = 5L) {
  state <- ravel_runtime_state()
  actions <- unname(state$pending_actions %||% list())
  recent_actions <- utils::tail(actions, limit)

  list(
    chat_turns = as.integer(length(state$chat_history %||% list()) / 2L),
    recent_actions = lapply(recent_actions, function(action) {
      list(
        id = action$id %||% NULL,
        type = action$type %||% NULL,
        label = action$label %||% NULL,
        status = action$status %||% NULL,
        created_at = action$created_at %||% NULL,
        provider = action$provider %||% NULL,
        model = action$model %||% NULL,
        path = action$payload$path %||% NULL
      )
    })
  )
}

ravel_active_document_context <- function(include_file = TRUE,
                                          include_selection = TRUE,
                                          workspace_root = NULL,
                                          sibling_limit = 30L) {
  if (!ravel_is_rstudio_available()) {
    return(list())
  }

  doc <- ravel_active_doc_context_raw()
  if (is.null(doc)) {
    return(list())
  }

  path <- doc$path %||% ""
  directory <- if (nzchar(path)) dirname(path) else ""
  workspace_root <- ravel_normalize_path(workspace_root)
  within_workspace_root <- if (nzchar(path) && nzchar(workspace_root)) {
    ravel_path_is_within(path, workspace_root)
  } else {
    NA
  }
  include_sibling_files <- nzchar(directory) &&
    !isTRUE(within_workspace_root) &&
    !identical(ravel_normalize_path(directory), workspace_root)
  selections <- vapply(doc$selection, function(sel) sel$text %||% "", character(1))

  list(
    path = path,
    name = if (nzchar(path)) basename(path) else "",
    directory = directory,
    within_workspace_root = within_workspace_root,
    relative_to_workspace_root = ravel_relative_path(path, workspace_root),
    sibling_files = if (include_sibling_files) {
      ravel_list_project_files(directory, limit = sibling_limit)
    } else {
      NULL
    },
    selection = if (include_selection) {
      paste(selections[nzchar(selections)], collapse = "\n\n")
    } else {
      NULL
    },
    contents = if (include_file) ravel_trim_text(doc$contents %||% "", 6000L) else NULL
  )
}

ravel_session_info_context <- function(workspace_root = NULL) {
  list(
    r_version = R.version.string,
    working_directory = getwd(),
    workspace_root = workspace_root %||% ravel_project_root(),
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
#' @param include_git Include git status and diff summaries when available.
#' @param include_activity Include recent Ravel action state.
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
                                  include_git = TRUE,
                                  include_activity = TRUE,
                                  envir = .GlobalEnv,
                                  max_objects = 10L) {
  root <- ravel_project_root()
  context <- list()

  context$document <- ravel_active_document_context(
    include_file = include_file,
    include_selection = include_selection,
    workspace_root = root
  )

  if (include_project) {
    context$project <- list(
      root = root,
      working_directory = getwd(),
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
    context$session <- ravel_session_info_context(workspace_root = root)
  }

  if (include_git) {
    context$git <- ravel_collect_git_context(
      workspace_root = root,
      active_path = context$document$path %||% ""
    )
  }

  if (include_activity) {
    context$activity <- ravel_recent_activity_context()
  }

  context
}
# nolint end
