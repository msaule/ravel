ravel_console_append <- function(text) {
  state <- ravel_runtime_state()
  state$console_log <- c(state$console_log, paste(text, collapse = "\n"))
  state$console_log <- utils::tail(state$console_log, 20L)
  ravel_set_runtime_state(state)
  invisible(state$console_log)
}

ravel_console_context <- function(limit = 5L) {
  state <- ravel_runtime_state()
  list(
    recent_output = utils::tail(state$console_log, limit),
    last_error = tryCatch(geterrmessage(), error = function(e) "")
  )
}

ravel_console_clear <- function() {
  state <- ravel_runtime_state()
  state$console_log <- character()
  ravel_set_runtime_state(state)
  invisible(TRUE)
}
