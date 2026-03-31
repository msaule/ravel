ravel_capture_eval <- function(code, envir = NULL) {
  envir <- envir %||% ravel_execution_environment()
  warnings <- character()
  messages <- character()
  value <- NULL
  error_text <- NULL

  output <- utils::capture.output(
    tryCatch(
      withCallingHandlers(
        {
          exprs <- parse(text = code)
          for (expr in exprs) {
            result <- withVisible(eval(expr, envir = envir))
            value <- result$value
            if (result$visible) {
              print(result$value)
            }
          }
        },
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        },
        message = function(m) {
          messages <<- c(messages, conditionMessage(m))
          invokeRestart("muffleMessage")
        }
      ),
      error = function(e) {
        error_text <<- conditionMessage(e)
        NULL
      }
    )
  )

  list(
    success = is.null(error_text),
    output = output,
    warnings = warnings,
    messages = messages,
    value = value,
    error = error_text
  )
}

#' Execute a staged action
#'
#' @param action A `ravel_action`.
#' @param approve Whether to override and treat the action as approved.
#' @param envir Evaluation environment for code execution. When `NULL`,
#'   Ravel uses a dedicated session-scoped environment that inherits from
#'   `globalenv()` for reads without writing into `.GlobalEnv` by default.
#'
#' @return A structured result list.
#' @export
ravel_apply_action <- function(action, approve = FALSE, envir = NULL) {
  if (!inherits(action, "ravel_action")) {
    cli::cli_abort("`action` must inherit from `ravel_action`.")
  }

  if (!approve && !identical(action$status, "approved")) {
    cli::cli_abort(c(
      "Action has not been approved.",
      "i" = "Use {.fun ravel_approve_action} or set `approve = TRUE`."
    ))
  }

  action$status <- "running"
  ravel_stage_action(action)

  result <- switch(
    action$type,
    run_code = ravel_capture_eval(action$payload$code, envir = envir),
    write_file = {
      ravel_write_file_text(action$payload$path, action$payload$text, append = FALSE)
      list(success = TRUE, path = action$payload$path)
    },
    append_file = {
      ravel_write_file_text(action$payload$path, action$payload$text, append = TRUE)
      list(success = TRUE, path = action$payload$path)
    },
    draft_quarto = {
      list(success = TRUE, text = action$payload$text)
    },
    cli::cli_abort("Unsupported action type: {.val {action$type}}.")
  )

  action$status <- if (isTRUE(result$success)) "completed" else "failed"
  ravel_stage_action(action)

  if (!is.null(result$output)) {
    ravel_console_append(c(result$output, result$messages, result$warnings, result$error))
  }
  ravel_log_action(action, outcome = result)
  result
}

#' Run R code with explicit approval semantics
#'
#' @param action Either a `ravel_action` or a character string of R code.
#' @param approve Whether to approve and run immediately.
#' @param envir Evaluation environment. When `NULL`, code runs in Ravel's
#'   dedicated session-scoped execution environment instead of `.GlobalEnv`.
#'
#' @return A structured result list.
#' @export
ravel_run_code <- function(action, approve = FALSE, envir = NULL) {
  if (is.character(action)) {
    action <- ravel_preview_code(action)
  }
  ravel_apply_action(action, approve = approve, envir = envir)
}
