#' Ravel
#'
#' Ravel is an RStudio-native coding and analytics copilot for R users.
#'
#' @keywords internal
"_PACKAGE"

ravel_state_env <- new.env(parent = emptyenv())

ravel_default_runtime_state <- function() {
  list(
    console_log = character(),
    chat_history = list(),
    pending_actions = list(),
    settings = NULL,
    history = list(),
    execution_env = NULL
  )
}

ravel_merge_runtime_state <- function(state = NULL) {
  merged <- ravel_default_runtime_state()
  if (is.null(state) || !length(state)) {
    return(merged)
  }

  for (name in names(state)) {
    merged[[name]] <- state[[name]]
  }

  merged
}

.onAttach <- function(libname, pkgname) {
  if (!interactive()) {
    return(invisible(NULL))
  }

  packageStartupMessage(
    "Ravel loaded. Launch chat with ravel::ravel_chat_addin() or run ",
    "ravel::ravel_setup_addin() for first-run setup."
  )
}

`%||%` <- function(x, y) {
  if (is.null(x) || identical(x, "")) {
    return(y)
  }
  x
}

ravel_path_config <- function(...) {
  override <- getOption("ravel.user_dirs", default = NULL)
  path <- override$config %||% NULL
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  file.path(path, ...)
}

ravel_path_data <- function(...) {
  override <- getOption("ravel.user_dirs", default = NULL)
  path <- override$data %||% NULL
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  file.path(path, ...)
}

ravel_session_cache <- function() {
  if (is.null(ravel_state_env$session_cache)) {
    ravel_state_env$session_cache <- new.env(parent = emptyenv())
  }
  ravel_state_env$session_cache
}

ravel_runtime_state <- function() {
  if (is.null(ravel_state_env$runtime)) {
    ravel_state_env$runtime <- ravel_default_runtime_state()
  } else {
    ravel_state_env$runtime <- ravel_merge_runtime_state(ravel_state_env$runtime)
  }
  ravel_state_env$runtime
}

ravel_set_runtime_state <- function(state) {
  merged <- ravel_merge_runtime_state(state %||% list())
  ravel_state_env$runtime <- merged
  invisible(merged)
}

ravel_execution_environment <- function(parent = globalenv(), reset = FALSE) {
  state <- ravel_runtime_state()
  needs_reset <- isTRUE(reset) ||
    !is.environment(state$execution_env) ||
    !identical(parent.env(state$execution_env), parent)

  if (needs_reset) {
    state$execution_env <- new.env(parent = parent)
    ravel_set_runtime_state(state)
  }

  state$execution_env
}

ravel_trim_text <- function(x, max_chars = 4000L) {
  x <- paste(x, collapse = "\n")
  if (nchar(x, type = "chars") <= max_chars) {
    return(x)
  }
  paste0(substr(x, 1L, max_chars), "\n...[truncated]")
}

ravel_hash_text <- function(x) {
  digest::digest(paste(x, collapse = "\n"), algo = "xxhash64")
}

ravel_normalize_path <- function(path) {
  path <- path %||% ""
  if (!nzchar(path)) {
    return("")
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

ravel_path_is_within <- function(path, root) {
  path <- ravel_normalize_path(path)
  root <- ravel_normalize_path(root)

  if (!nzchar(path) || !nzchar(root)) {
    return(FALSE)
  }

  identical(path, root) || startsWith(path, paste0(root, "/"))
}

ravel_json_safe <- function(x, depth = 0L) {
  if (depth > 4L) {
    return(ravel_trim_text(utils::capture.output(utils::str(x, max.level = 1L)), 500L))
  }

  if (is.matrix(x) || inherits(x, "table")) {
    return(ravel_trim_text(utils::capture.output(print(x)), 800L))
  }

  if (is.null(x) || is.character(x) || is.numeric(x) || is.logical(x)) {
    if (length(x) <= 20L) {
      return(x)
    }
    return(c(utils::head(x, 20L), "...[truncated]"))
  }

  if (inherits(x, "data.frame")) {
    return(list(
      class = class(x),
      rows = nrow(x),
      cols = ncol(x),
      preview = ravel_trim_text(utils::capture.output(utils::head(x, 5L)), 800L)
    ))
  }

  if (is.list(x)) {
    return(lapply(x, ravel_json_safe, depth = depth + 1L))
  }

  ravel_trim_text(utils::capture.output(utils::str(x, max.level = 1L)), 800L)
}

ravel_cli_alert <- function(..., class = "info") {
  switch(
    class,
    info = cli::cli_inform(...),
    warning = cli::cli_warn(...),
    danger = cli::cli_abort(...),
    cli::cli_inform(...)
  )
}

ravel_is_rstudio_available <- function() {
  isTRUE(tryCatch(rstudioapi::isAvailable(), error = function(e) FALSE))
}

ravel_gadget_viewer <- function(kind = c("chat", "settings")) {
  kind <- match.arg(kind)

  if (ravel_is_rstudio_available()) {
    if (identical(kind, "chat")) {
      return(shiny::paneViewer(minHeight = 900))
    }
    return(shiny::dialogViewer("Ravel Setup", width = 980, height = 860))
  }

  shiny::browserViewer()
}

ravel_perform_request <- function(req, provider) {
  tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      message <- conditionMessage(e)
      extra <- if (grepl("429", message, fixed = TRUE)) {
        "The provider reported rate limiting or quota exhaustion."
      } else {
        "Review credentials, model access, network connectivity, or provider status."
      }
      cli::cli_abort(c(
        sprintf("%s request failed.", provider),
        "x" = message,
        "i" = extra
      ))
    }
  )
}
