ravel_provider_resource_urls <- function() {
  list(
    openai = list(
      docs = "https://developers.openai.com/codex/cli",
      api_keys = "https://platform.openai.com/api-keys"
    ),
    copilot = list(
      docs = "https://docs.github.com/copilot/how-tos/copilot-cli",
      api_keys = "https://github.com/settings/tokens?type=beta"
    ),
    gemini = list(
      docs = "https://ai.google.dev/gemini-api/docs",
      api_keys = "https://aistudio.google.com/app/apikey"
    ),
    anthropic = list(
      docs = "https://docs.anthropic.com/en/api/getting-started",
      api_keys = "https://console.anthropic.com/settings/keys"
    )
  )
}

ravel_provider_resource_url <- function(provider, kind = c("docs", "api_keys")) {
  kind <- match.arg(kind)
  urls <- ravel_provider_resource_urls()[[provider]]
  urls[[kind]] %||% NULL
}

ravel_provider_setup_info <- function(provider = c("openai", "copilot", "gemini", "anthropic")) {
  provider <- match.arg(provider)
  auth <- ravel_auth_status(provider)
  plan <- ravel_login(provider)

  list(
    provider = provider,
    label = ravel_get_provider(provider)$label,
    auth = auth,
    login = plan,
    docs_url = ravel_provider_resource_url(provider, "docs"),
    api_keys_url = ravel_provider_resource_url(provider, "api_keys"),
    binary = switch(
      provider,
      openai = ravel_codex_binary(),
      copilot = ravel_copilot_binary(),
      NULL
    )
  )
}

ravel_ready_providers <- function() {
  providers <- c("openai", "copilot", "gemini", "anthropic")
  statuses <- lapply(providers, ravel_auth_status)
  Filter(function(status) isTRUE(status$configured), statuses)
}

ravel_has_ready_provider <- function() {
  length(ravel_ready_providers()) > 0L
}

ravel_viewer_available <- function() {
  is.function(getOption("viewer")) || ravel_is_rstudio_available()
}

#' Inspect local Ravel readiness
#'
#' @return A tibble of system and provider checks with suggested fixes.
#' @export
ravel_doctor <- function() {
  openai <- ravel_auth_status("openai")
  copilot <- ravel_auth_status("copilot")
  gemini <- ravel_auth_status("gemini")
  anthropic <- ravel_auth_status("anthropic")

  tibble::tibble(
    check = c(
      "RStudio available",
      "Viewer available",
      "Keyring installed",
      "Codex CLI detected",
      "Copilot CLI detected",
      "OpenAI ready",
      "GitHub Copilot ready",
      "Gemini ready",
      "Anthropic ready",
      "At least one provider ready"
    ),
    ok = c(
      ravel_is_rstudio_available(),
      ravel_viewer_available(),
      ravel_keyring_available(),
      !is.null(ravel_codex_binary()),
      !is.null(ravel_copilot_binary()),
      isTRUE(openai$configured),
      isTRUE(copilot$configured),
      isTRUE(gemini$configured),
      isTRUE(anthropic$configured),
      ravel_has_ready_provider()
    ),
    detail = c(
      if (ravel_is_rstudio_available()) {
        "RStudio APIs are available for addins and document context."
      } else {
        "Run Ravel inside RStudio or Positron for the smoothest addin workflow."
      },
      if (ravel_viewer_available()) {
        "A Shiny viewer is available for gadgets."
      } else {
        "No viewer was detected; gadgets will need a browser fallback."
      },
      if (ravel_keyring_available()) {
        "Secure secret storage via keyring is available."
      } else {
        "Secrets can still be used, but they will only persist for the current session."
      },
      if (!is.null(ravel_codex_binary())) {
        sprintf("Codex CLI detected at %s.", ravel_codex_binary())
      } else {
        "Codex CLI was not detected on this machine."
      },
      if (!is.null(ravel_copilot_binary())) {
        sprintf("Copilot CLI detected at %s.", ravel_copilot_binary())
      } else {
        "Copilot CLI was not detected on this machine."
      },
      openai$detail,
      copilot$detail,
      gemini$detail,
      anthropic$detail,
      if (ravel_has_ready_provider()) {
        sprintf(
          "Ready providers: %s.",
          paste(vapply(ravel_ready_providers(), `[[`, character(1), "provider"), collapse = ", ")
        )
      } else {
        "No provider is ready yet."
      }
    ),
    fix = c(
      "Open the project in RStudio before using the chat addin.",
      "Use the RStudio Viewer pane or allow browser-based gadget display.",
      "Optional: install.packages('keyring') for secure persistent secrets.",
      paste("Install or use", ravel_codex_login_command(), "for login-first OpenAI."),
      paste("Install or use", ravel_copilot_login_command(), "for official Copilot auth."),
      "Use the setup assistant to sign in with Codex CLI or save an OpenAI API key.",
      "Use the setup assistant to run Copilot login or provide a supported GitHub token.",
      "Save a Gemini API key or bearer token in the setup assistant.",
      "Save an Anthropic API key in the setup assistant.",
      "Finish one provider setup path, then launch ravel_chat_addin()."
    )
  )
}

ravel_launch_terminal_command <- function(command, working_dir = getwd()) {
  stopifnot(is.character(command), length(command) == 1L, nzchar(command))

  if (ravel_is_rstudio_available() && rstudioapi::hasFun("terminalExecute")) {
    rstudioapi::terminalExecute(command, workingDir = working_dir, show = TRUE)
    return(invisible(command))
  }

  if (.Platform$OS.type == "windows") {
    shell(command, wait = FALSE)
  } else {
    system(command, wait = FALSE)
  }

  invisible(command)
}

#' Launch an official provider login flow
#'
#' @param provider Provider name.
#' @param mode Optional auth mode override.
#'
#' @return A login plan list, invisibly.
#' @export
ravel_launch_login <- function(provider = c("openai", "copilot", "gemini", "anthropic"),
                               mode = NULL) {
  provider <- match.arg(provider)
  plan <- ravel_login(provider, mode = mode)

  if (!isTRUE(plan$supported)) {
    cli::cli_abort("This provider does not expose a supported login flow in Ravel.")
  }

  if (!is.null(plan$command) && nzchar(plan$command)) {
    ravel_launch_terminal_command(plan$command)
    return(invisible(plan))
  }

  api_keys_url <- ravel_provider_resource_url(provider, "api_keys")
  if (!is.null(api_keys_url)) {
    utils::browseURL(api_keys_url)
    return(invisible(plan))
  }

  cli::cli_abort("No launchable login action is available for this provider.")
}

#' Open an official provider documentation or key-management page
#'
#' @param provider Provider name.
#' @param page Which page to open.
#'
#' @return The opened URL, invisibly.
#' @export
ravel_open_provider_page <- function(provider = c("openai", "copilot", "gemini", "anthropic"),
                                     page = c("docs", "api_keys")) {
  provider <- match.arg(provider)
  page <- match.arg(page)
  url <- ravel_provider_resource_url(provider, page)
  if (is.null(url)) {
    cli::cli_abort("No official URL is registered for this provider page.")
  }
  utils::browseURL(url)
  invisible(url)
}

#' Verify a provider with a tiny live prompt
#'
#' @param provider Provider name.
#' @param model Optional model override.
#'
#' @return A named list with `ok`, `content`, `provider`, and `model`.
#' @export
ravel_verify_provider <- function(provider = c("openai", "copilot", "gemini", "anthropic"),
                                  model = NULL) {
  provider <- match.arg(provider)
  provider_obj <- ravel_get_provider(provider)

  result <- tryCatch(
    provider_obj$chat(
      messages = list(list(role = "user", content = "Reply with exactly: ravel_provider_ok")),
      context = list(),
      model = model %||% provider_obj$default_model,
      settings = ravel_read_settings()
    ),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    return(list(
      ok = FALSE,
      provider = provider,
      model = model %||% provider_obj$default_model,
      content = conditionMessage(result)
    ))
  }

  content <- trimws(result$content %||% "")
  list(
    ok = identical(content, "ravel_provider_ok"),
    provider = provider,
    model = result$model %||% model %||% provider_obj$default_model,
    content = content
  )
}
