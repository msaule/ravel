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

test_that("context keeps active editor and workspace context together", {
  root <- file.path(tempdir(), "ravel-context-root")
  external <- file.path(tempdir(), "ravel-context-external")
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  dir.create(external, recursive = TRUE, showWarnings = FALSE)
  writeLines("helper <- TRUE", file.path(external, "helper.R"))

  local_mocked_bindings(
    ravel_is_rstudio_available = function() TRUE,
    ravel_active_doc_context_raw = function() {
      list(
        path = file.path(external, "analysis.R"),
        selection = list(list(text = "summary(model)")),
        contents = c("model <- lm(mpg ~ wt, data = mtcars)", "summary(model)")
      )
    },
    ravel_project_root = function() root,
    ravel_recent_activity_context = function(limit = 5L) {
      list(chat_turns = 1L, recent_actions = list())
    }
  )

  context <- ravel_collect_context(
    include_objects = FALSE,
    include_console = FALSE,
    include_plot = FALSE,
    include_session = FALSE,
    envir = new.env(parent = emptyenv())
  )

  expect_equal(context$document$name, "analysis.R")
  expect_false(context$document$within_workspace_root)
  expect_match(context$document$contents, "lm\\(mpg ~ wt", perl = TRUE)
  expect_true("helper.R" %in% context$document$sibling_files)
  expect_equal(context$project$root, root)
  expect_equal(context$project$working_directory, getwd())
  expect_true("activity" %in% names(context))
})
