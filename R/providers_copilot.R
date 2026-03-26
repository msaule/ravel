ravel_copilot_cli_installed <- function() {
  if (!ravel_command_available("gh")) {
    return(FALSE)
  }

  output <- tryCatch(
    system2("gh", c("copilot", "--", "--help"), stdout = TRUE, stderr = TRUE),
    error = function(e) "Copilot CLI not installed"
  )

  !any(grepl("not installed", tolower(output), fixed = TRUE))
}

ravel_copilot_prompt <- function(messages, context) {
  normalized <- ravel_normalize_messages(messages, context)
  system_prompt <- normalized[[1]]$content
  history <- vapply(
    normalized[-1],
    function(msg) paste0(toupper(msg$role), ": ", msg$content),
    character(1)
  )

  paste(
    "System instructions:",
    system_prompt,
    "",
    "Conversation:",
    paste(history, collapse = "\n\n"),
    sep = "\n"
  )
}

ravel_copilot_chat <- function(messages, context, model, settings) {
  status <- ravel_auth_status("copilot")
  if (!isTRUE(status$configured)) {
    cli::cli_abort(c(
      "GitHub CLI is not authenticated for Copilot use.",
      "i" = "Run {.code gh auth login} and ensure Copilot access is available."
    ))
  }

  if (!ravel_copilot_cli_installed()) {
    cli::cli_abort(c(
      "The official Copilot CLI surface is not installed locally.",
      "i" = "Ravel does not use private or unofficial Copilot endpoints.",
      "i" = "Install or enable the official `gh copilot` CLI first."
    ))
  }

  prompt <- ravel_copilot_prompt(messages, context)
  output <- system2("gh", c("copilot", "-p", prompt), stdout = TRUE, stderr = TRUE)
  status_code <- attr(output, "status", exact = TRUE) %||% 0L
  if (!identical(status_code, 0L)) {
    cli::cli_abort(ravel_trim_text(output, 1000L))
  }

  list(
    provider = "copilot",
    model = "copilot-cli",
    content = paste(output, collapse = "\n"),
    raw = output
  )
}

ravel_provider_copilot <- function() {
  ravel_new_provider(
    name = "copilot",
    label = "GitHub Copilot",
    auth_modes = c("gh_cli"),
    default_model = "copilot-cli",
    models = "copilot-cli",
    supports_model_selection = FALSE,
    capabilities = list(
      code_generation = TRUE,
      stats_reasoning = TRUE,
      quarto_drafting = TRUE,
      login_first = TRUE,
      experimental = TRUE
    ),
    is_available = function() {
      isTRUE(ravel_auth_status("copilot")$configured)
    },
    auth_status = function() ravel_auth_status("copilot"),
    chat = ravel_copilot_chat
  )
}
