ravel_git_run <- function(args, root = NULL) {
  if (!ravel_command_available("git")) {
    return(list(ok = FALSE, status = 127L, output = character()))
  }

  cmd_args <- args
  if (!is.null(root) && nzchar(root)) {
    cmd_args <- c("-C", root, cmd_args)
  }

  output <- tryCatch(
    system2("git", cmd_args, stdout = TRUE, stderr = TRUE),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )

  list(
    ok = identical(attr(output, "status", exact = TRUE) %||% 0L, 0L),
    status = attr(output, "status", exact = TRUE) %||% 0L,
    output = trimws(output)
  )
}

ravel_git_repo_root <- function(root = NULL) {
  result <- ravel_git_run(c("rev-parse", "--show-toplevel"), root = root)
  if (!isTRUE(result$ok) || !length(result$output) || !nzchar(result$output[[1]])) {
    return(NULL)
  }

  ravel_normalize_path(result$output[[1]])
}

ravel_git_branch <- function(repo_root) {
  result <- ravel_git_run(c("branch", "--show-current"), root = repo_root)
  if (!isTRUE(result$ok) || !length(result$output)) {
    return(NULL)
  }

  branch <- trimws(result$output[[1]])
  if (!nzchar(branch)) {
    return(NULL)
  }
  branch
}

ravel_git_status_entries <- function(lines, limit = 20L) {
  lines <- lines[nzchar(lines)]
  if (!length(lines)) {
    return(list())
  }

  entries <- lapply(utils::head(lines, limit), function(line) {
    index_status <- substr(line, 1L, 1L)
    worktree_status <- substr(line, 2L, 2L)
    path <- trimws(substr(line, 4L, nchar(line)))

    state <- if (identical(substr(line, 1L, 2L), "??")) {
      "untracked"
    } else if (index_status != " " && worktree_status != " ") {
      "staged_and_unstaged"
    } else if (index_status != " ") {
      "staged"
    } else if (worktree_status != " ") {
      "unstaged"
    } else {
      "unknown"
    }

    list(
      path = path,
      state = state,
      index_status = index_status,
      worktree_status = worktree_status
    )
  })

  unname(entries)
}

ravel_git_diff_excerpt <- function(repo_root,
                                   staged = FALSE,
                                   path = NULL,
                                   max_chars = 2500L) {
  args <- c(
    "diff",
    if (isTRUE(staged)) "--cached",
    "--no-ext-diff",
    "--no-color",
    "--unified=0"
  )

  relative_path <- ravel_relative_path(path %||% "", repo_root)
  if (!is.null(relative_path)) {
    args <- c(args, "--", relative_path)
  }

  result <- ravel_git_run(args, root = repo_root)
  if (!isTRUE(result$ok) || !length(result$output)) {
    return(NULL)
  }

  excerpt <- paste(result$output[nzchar(result$output)], collapse = "\n")
  if (!nzchar(excerpt)) {
    return(NULL)
  }

  ravel_trim_text(excerpt, max_chars = max_chars)
}

ravel_git_recent_commits <- function(repo_root, limit = 5L) {
  result <- ravel_git_run(
    c("log", "--oneline", sprintf("-%d", as.integer(limit))),
    root = repo_root
  )
  if (!isTRUE(result$ok)) {
    return(character())
  }

  result$output[nzchar(result$output)]
}

ravel_git_focus_context <- function(repo_root, focus_path, max_diff_chars = 2000L) {
  relative_path <- ravel_relative_path(focus_path %||% "", repo_root)
  if (is.null(relative_path)) {
    return(NULL)
  }

  list(
    path = focus_path,
    relative_path = relative_path,
    staged_diff_excerpt = ravel_git_diff_excerpt(
      repo_root,
      staged = TRUE,
      path = focus_path,
      max_chars = max_diff_chars
    ),
    unstaged_diff_excerpt = ravel_git_diff_excerpt(
      repo_root,
      staged = FALSE,
      path = focus_path,
      max_chars = max_diff_chars
    )
  )
}

ravel_git_context <- function(root = NULL,
                              focus_path = NULL,
                              status_limit = 20L,
                              max_diff_chars = 2500L,
                              commit_limit = 5L) {
  repo_root <- ravel_git_repo_root(root)
  if (is.null(repo_root)) {
    return(NULL)
  }

  status_result <- ravel_git_run(c("status", "--short", "--untracked-files=all"), root = repo_root)
  status_entries <- if (isTRUE(status_result$ok)) {
    ravel_git_status_entries(status_result$output, limit = status_limit)
  } else {
    list()
  }

  states <- vapply(status_entries, `[[`, character(1), "state")

  list(
    repo_root = repo_root,
    branch = ravel_git_branch(repo_root),
    dirty = length(status_entries) > 0L,
    changed_file_count = length(status_entries),
    staged_file_count = sum(states %in% c("staged", "staged_and_unstaged")),
    unstaged_file_count = sum(states %in% c("unstaged", "staged_and_unstaged")),
    untracked_file_count = sum(states %in% c("untracked")),
    changed_files = status_entries,
    recent_commits = ravel_git_recent_commits(repo_root, limit = commit_limit),
    staged_diff_excerpt = ravel_git_diff_excerpt(
      repo_root,
      staged = TRUE,
      max_chars = max_diff_chars
    ),
    unstaged_diff_excerpt = ravel_git_diff_excerpt(
      repo_root,
      staged = FALSE,
      max_chars = max_diff_chars
    ),
    focused_file = ravel_git_focus_context(
      repo_root,
      focus_path = focus_path,
      max_diff_chars = max_diff_chars
    )
  )
}

ravel_collect_git_context <- function(workspace_root = NULL, active_path = NULL) {
  workspace_root <- workspace_root %||% ravel_project_root()
  active_path <- active_path %||% ""

  if (!ravel_command_available("git")) {
    return(list(available = FALSE))
  }

  workspace_git <- ravel_git_context(workspace_root, focus_path = active_path)
  editor_git <- NULL

  if (nzchar(active_path)) {
    editor_root <- ravel_git_repo_root(dirname(active_path))
    if (!is.null(editor_root) &&
          !identical(editor_root, workspace_git$repo_root %||% "")) {
      editor_git <- ravel_git_context(editor_root, focus_path = active_path)
    }
  }

  result <- list(available = TRUE)
  if (!is.null(workspace_git)) {
    result$workspace <- workspace_git
  }
  if (!is.null(editor_git)) {
    result$editor <- editor_git
  }

  result
}
