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
    include_git = FALSE,
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
  on.exit(unlink(c(root, external), recursive = TRUE, force = TRUE), add = TRUE)
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
    ravel_collect_git_context = function(workspace_root = NULL, active_path = NULL) {
      list(
        available = TRUE,
        workspace = list(branch = "main", changed_file_count = 2L)
      )
    },
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
  expect_equal(context$git$workspace$branch, "main")
  expect_true("activity" %in% names(context))
})

test_that("git context summarizes workspace and focused file changes", {
  local_mocked_bindings(
    ravel_command_available = function(command) identical(command, "git"),
    ravel_git_repo_root = function(root = NULL) {
      normalized <- ravel:::ravel_normalize_path(root %||% "")
      if (grepl("workspace", normalized, fixed = TRUE)) {
        return("C:/workspace")
      }
      if (grepl("outside", normalized, fixed = TRUE)) {
        return("C:/outside-repo")
      }
      NULL
    },
    ravel_git_branch = function(repo_root) {
      if (identical(repo_root, "C:/workspace")) {
        return("main")
      }
      "feature/editor"
    },
    ravel_git_recent_commits = function(repo_root, limit = 5L) {
      c("abc123 First", "def456 Second")
    },
    ravel_git_diff_excerpt = function(repo_root,
                                      staged = FALSE,
                                      path = NULL,
                                      max_chars = 2500L) {
      paste(
        repo_root,
        if (isTRUE(staged)) "staged" else "unstaged",
        path %||% "all"
      )
    },
    ravel_git_run = function(args, root = NULL) {
      if (identical(args[[1]], "status")) {
        return(list(
          ok = TRUE,
          status = 0L,
          output = c("M  R/ui_gadget.R", " M R/context_session.R", "?? notes.txt")
        ))
      }
      list(ok = TRUE, status = 0L, output = character())
    }
  )

  git <- ravel:::ravel_collect_git_context(
    workspace_root = "C:/workspace",
    active_path = "C:/outside-repo/analysis.R"
  )

  expect_true(git$available)
  expect_equal(git$workspace$branch, "main")
  expect_equal(git$workspace$changed_file_count, 3L)
  expect_equal(git$workspace$staged_file_count, 1L)
  expect_equal(git$workspace$unstaged_file_count, 1L)
  expect_equal(git$workspace$untracked_file_count, 1L)
  expect_equal(git$editor$branch, "feature/editor")
  expect_equal(git$editor$focused_file$relative_path, "analysis.R")
})
