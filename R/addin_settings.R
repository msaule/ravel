#' Launch the Ravel setup assistant
#'
#' @return Invisibly launches a Shiny gadget.
#' @export
ravel_setup_addin <- function() {
  if (!interactive()) {
    cli::cli_abort("Ravel setup must be launched from an interactive R session.")
  }

  if (ravel_is_rstudio_available()) {
    cli::cli_inform("Launching Ravel setup in an RStudio dialog.")
  } else {
    cli::cli_inform("Launching Ravel setup in your default browser.")
  }

  invisible(ravel_launch_settings_gadget())
}

#' Launch the Ravel settings addin
#'
#' @return Invisibly launches a Shiny gadget.
#' @export
ravel_settings_addin <- function() {
  invisible(ravel_setup_addin())
}
