#' Launch the Ravel chat addin
#'
#' @return Invisibly launches a Shiny gadget.
#' @export
ravel_chat_addin <- function() {
  if (!interactive()) {
    cli::cli_abort("Ravel chat must be launched from an interactive R session.")
  }

  if (!ravel_has_ready_provider()) {
    cli::cli_inform(c(
      "No provider is ready yet.",
      "i" = "Launching the Ravel setup assistant first."
    ))
    return(invisible(ravel_setup_addin()))
  }

  if (ravel_is_rstudio_available()) {
    cli::cli_inform("Launching Ravel chat in the RStudio Viewer pane.")
  } else {
    cli::cli_inform("Launching Ravel chat in your default browser.")
  }

  invisible(ravel_launch_chat_gadget())
}
