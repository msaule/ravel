ravel_history_path <- function() {
  ravel_path_data("history.jsonl")
}

ravel_log_event <- function(type, data = list()) {
  entry <- c(
    list(
      timestamp = format(Sys.time(), tz = "UTC", usetz = TRUE),
      type = type,
      project_root = ravel_project_root()
    ),
    data
  )

  line <- jsonlite::toJSON(ravel_json_safe(entry), auto_unbox = TRUE, null = "null")
  state <- ravel_runtime_state()
  state$history <- c(state$history %||% list(), list(entry))
  ravel_set_runtime_state(state)

  path <- ravel_history_path()
  if (!is.null(path)) {
    cat(line, file = path, sep = "\n", append = TRUE)
  }
  invisible(entry)
}

ravel_log_chat_turn <- function(provider, model, prompt, response) {
  ravel_log_event(
    "chat_turn",
    list(
      provider = provider,
      model = model,
      prompt_hash = ravel_hash_text(prompt),
      response_hash = ravel_hash_text(response),
      prompt_preview = ravel_trim_text(prompt, 250L),
      response_preview = ravel_trim_text(response, 250L)
    )
  )
}

ravel_log_action <- function(action, outcome) {
  ravel_log_event(
    "action",
    list(
      action_id = action$id,
      action_type = action$type,
      provider = action$provider,
      model = action$model,
      status = action$status,
      outcome = outcome
    )
  )
}

#' Read recent Ravel history entries
#'
#' @param limit Maximum number of history entries to return.
#'
#' @return A tibble.
#'
#' @details
#' History stays in session memory by default. To mirror it to disk explicitly,
#' configure `options(ravel.user_dirs = list(data = "<path>"))`.
#' @export
ravel_read_history <- function(limit = 100L) {
  path <- ravel_history_path()
  if (!is.null(path) && file.exists(path)) {
    lines <- utils::tail(readLines(path, warn = FALSE), limit)
  } else {
    entries <- utils::tail(ravel_runtime_state()$history %||% list(), limit)
    if (!length(entries)) {
      return(tibble::tibble())
    }
    lines <- vapply(
      entries,
      function(entry) jsonlite::toJSON(ravel_json_safe(entry), auto_unbox = TRUE, null = "null"),
      character(1)
    )
  }
  if (!length(lines)) {
    return(tibble::tibble())
  }
  parsed <- jsonlite::stream_in(textConnection(lines), verbose = FALSE)
  tibble::as_tibble(parsed)
}
