#' Launch the Ravel chat addin
#'
#' @return Invisibly launches a Shiny gadget.
#' @export
ravel_chat_addin <- function() {
  if (!interactive()) {
    cli::cli_abort("Ravel chat must be launched from an interactive R session.")
  }

  if (ravel_is_rstudio_available()) {
    cli::cli_inform("Launching Ravel chat in the RStudio Viewer pane.")
  } else {
    cli::cli_inform("Launching Ravel chat in your default browser.")
  }

  invisible(ravel_launch_chat_gadget())
}
