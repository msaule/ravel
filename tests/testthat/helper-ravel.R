tmp_root <- file.path(tempdir(), "ravel-tests")
dir.create(file.path(tmp_root, "config"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(tmp_root, "data"), recursive = TRUE, showWarnings = FALSE)

options(ravel.user_dirs = list(
  config = file.path(tmp_root, "config"),
  data = file.path(tmp_root, "data")
))

reset_ravel_test_state <- function() {
  ravel:::ravel_set_runtime_state(list(
    console_log = character(),
    chat_history = list(),
    pending_actions = list(),
    settings = NULL,
    history = list(),
    execution_env = NULL
  ))
  history_path <- ravel:::ravel_history_path()
  if (!is.null(history_path) && file.exists(history_path)) {
    unlink(history_path)
  }
  invisible(TRUE)
}
