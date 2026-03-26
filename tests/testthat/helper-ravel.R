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
    pending_actions = list()
  ))
  if (file.exists(ravel:::ravel_history_path())) {
    unlink(ravel:::ravel_history_path())
  }
  invisible(TRUE)
}
