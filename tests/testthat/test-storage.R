test_that("settings stay in session memory by default", {
  old_dirs <- getOption("ravel.user_dirs", default = NULL)
  on.exit(options(ravel.user_dirs = old_dirs), add = TRUE)
  options(ravel.user_dirs = NULL)

  reset_ravel_test_state()

  expect_null(ravel:::ravel_settings_path())
  ravel_set_setting("default_provider", "gemini")
  expect_equal(ravel_get_setting("default_provider"), "gemini")
  expect_null(ravel:::ravel_settings_path())
})

test_that("history stays in session memory by default", {
  old_dirs <- getOption("ravel.user_dirs", default = NULL)
  on.exit(options(ravel.user_dirs = old_dirs), add = TRUE)
  options(ravel.user_dirs = NULL)

  reset_ravel_test_state()
  action <- ravel_preview_code("1 + 1")
  action <- ravel_approve_action(action)

  expect_null(ravel:::ravel_history_path())
  ravel_run_code(action)

  history <- ravel_read_history()
  expect_gte(nrow(history), 1L)
  expect_true("type" %in% names(history))
})

test_that("explicit storage paths write only to configured temp locations", {
  root <- tempfile("ravel-storage-")
  config_dir <- file.path(root, "config")
  data_dir <- file.path(root, "data")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)

  old_dirs <- getOption("ravel.user_dirs", default = NULL)
  on.exit(options(ravel.user_dirs = old_dirs), add = TRUE)
  options(ravel.user_dirs = list(config = config_dir, data = data_dir))

  reset_ravel_test_state()
  ravel_set_setting("default_provider", "anthropic")

  action <- ravel_preview_code("2 + 2")
  action <- ravel_approve_action(action)
  ravel_run_code(action)

  expect_true(file.exists(ravel:::ravel_settings_path()))
  expect_true(file.exists(ravel:::ravel_history_path()))
  expect_true(ravel:::ravel_path_is_within(ravel:::ravel_settings_path(), root))
  expect_true(ravel:::ravel_path_is_within(ravel:::ravel_history_path(), root))
})

test_that("default execution environment does not write into its parent", {
  reset_ravel_test_state()
  parent_env <- new.env(parent = baseenv())
  parent_env$input_value <- 10

  exec_env <- ravel:::ravel_execution_environment(parent = parent_env, reset = TRUE)
  result <- ravel:::ravel_capture_eval(
    "output_value <- input_value + 1; output_value",
    envir = exec_env
  )

  expect_true(result$success)
  expect_equal(result$value, 11)
  expect_false(exists("output_value", envir = parent_env, inherits = FALSE))
  expect_equal(exec_env$output_value, 11)
})
