ravel_stage_action <- function(action) {
  state <- ravel_runtime_state()
  state$pending_actions[[action$id]] <- action
  ravel_set_runtime_state(state)
  invisible(action)
}

#' Create a new staged Ravel action
#'
#' @param type Action type.
#' @param label Human-readable label.
#' @param payload Action payload.
#' @param provider Optional provider name.
#' @param model Optional model name.
#'
#' @return A `ravel_action` object.
ravel_new_action <- function(type,
                             label,
                             payload,
                             provider = NULL,
                             model = NULL) {
  action <- structure(
    list(
      id = paste0(
        "action_",
        format(Sys.time(), "%Y%m%d%H%M%S"),
        "_",
        substr(ravel_hash_text(label), 1L, 8L)
      ),
      type = type,
      label = label,
      payload = payload,
      provider = provider,
      model = model,
      status = "proposed",
      created_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    class = c("ravel_action", "list")
  )
  ravel_stage_action(action)
  action
}

ravel_file_action_safety <- function(path, project_root = NULL) {
  project_root <- project_root %||% ravel_project_root()
  target_path <- ravel_normalize_path(path)
  project_root <- ravel_normalize_path(project_root)
  within_project <- ravel_path_is_within(target_path, project_root)

  list(
    target_path = target_path,
    project_root = project_root,
    within_project = within_project,
    policy = if (within_project) {
      "project_write_allowed_after_approval"
    } else {
      "outside_project_blocked_by_default"
    }
  )
}

ravel_assert_file_allowed <- function(action, allow_outside_project = FALSE) {
  safety <- action$payload$safety %||% ravel_file_action_safety(action$payload$path)
  if (!isTRUE(safety$within_project) && !isTRUE(allow_outside_project)) {
    cli::cli_abort(c(
      "This approved file action targets a path outside the detected project root.",
      "i" = "Ravel blocks outside-project writes by default even after approval.",
      "i" = "Pass `allow_outside_project = TRUE` only if you intentionally trust this target.",
      "x" = sprintf("Target: %s", safety$target_path %||% action$payload$path),
      "x" = sprintf("Project root: %s", safety$project_root %||% "")
    ))
  }

  invisible(TRUE)
}

#' Preview generated code as a staged action
#'
#' @param code R code text.
#' @param label Label for the staged action.
#' @param provider Optional provider name.
#' @param model Optional model name.
#'
#' @return A `ravel_action` object.
#' @export
ravel_preview_code <- function(code,
                               label = "Run generated R code",
                               provider = NULL,
                               model = NULL) {
  stopifnot(is.character(code), length(code) == 1L)
  ravel_new_action(
    type = "run_code",
    label = label,
    payload = list(code = code),
    provider = provider,
    model = model
  )
}

#' Stage a file write action
#'
#' @param path Target file path.
#' @param text Text to write.
#' @param append Whether to append instead of overwrite.
#' @param provider Optional provider name.
#' @param model Optional model name.
#'
#' @return A `ravel_action` object.
#' @export
ravel_stage_file_write <- function(path,
                                   text,
                                   append = FALSE,
                                   provider = NULL,
                                   model = NULL) {
  ravel_new_action(
    type = if (append) "append_file" else "write_file",
    label = sprintf("%s file %s", if (append) "Append" else "Write", path),
    payload = list(
      path = path,
      text = text,
      append = append,
      safety = ravel_file_action_safety(path)
    ),
    provider = provider,
    model = model
  )
}

#' Approve a staged action
#'
#' @param action A `ravel_action`.
#'
#' @return The updated action.
#' @export
ravel_approve_action <- function(action) {
  action$status <- "approved"
  ravel_stage_action(action)
  action
}

#' Reject a staged action
#'
#' @param action A `ravel_action`.
#'
#' @return The updated action.
#' @export
ravel_reject_action <- function(action) {
  action$status <- "rejected"
  ravel_stage_action(action)
  action
}
