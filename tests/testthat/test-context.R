test_that("context collection summarizes loaded objects", {
  reset_ravel_test_state()
  env <- new.env(parent = emptyenv())
  env$df <- data.frame(x = 1:3, y = c("a", "b", "c"))
  env$model <- stats::lm(mpg ~ wt, data = mtcars)

  context <- ravel_collect_context(
    include_selection = FALSE,
    include_file = FALSE,
    include_console = FALSE,
    include_plot = FALSE,
    include_session = FALSE,
    include_project = FALSE,
    envir = env,
    max_objects = 5L
  )

  names <- vapply(context$objects, function(x) x$name, character(1))
  expect_true(all(c("df", "model") %in% names))
  expect_equal(context$objects[[match("df", names)]]$kind, "data.frame")
  expect_equal(context$objects[[match("model", names)]]$kind, "model")
})
