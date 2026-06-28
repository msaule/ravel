test_that("code execution requires approval by default", {
  reset_ravel_test_state()
  action <- ravel_preview_code("x <- 1")

  expect_error(
    ravel_run_code(action),
    "Action has not been approved"
  )
})

test_that("approved code executes and captures output", {
  reset_ravel_test_state()
  env <- new.env(parent = baseenv())
  action <- ravel_preview_code("cat('hello\\n'); x <- 2; x")
  action <- ravel_approve_action(action)

  result <- ravel_run_code(action, approve = FALSE, envir = env)

  expect_true(result$success)
  expect_true(any(grepl("hello", result$output)))
  expect_equal(result$value, 2)
  expect_equal(env$x, 2)
})

test_that("approved file writes outside project are blocked by default", {
  reset_ravel_test_state()
  path <- file.path(tempdir(), "ravel-outside-project.txt")
  action <- ravel_stage_file_write(path, "unsafe")
  action <- ravel_approve_action(action)

  expect_false(isTRUE(action$payload$safety$within_project))
  expect_error(
    ravel_apply_action(action),
    "outside the detected project root",
    fixed = TRUE
  )
  expect_false(file.exists(path))
})
