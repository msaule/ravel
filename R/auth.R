ravel_default_settings <- function() {
  list(
    default_provider = "openai",
    default_models = list(
      openai = "gpt-5.3-codex",
      gemini = "gemini-2.5-pro",
      anthropic = "claude-sonnet-4-20250514",
      copilot = "copilot-cli"
    ),
    context_defaults = list(
      selection = TRUE,
      file = TRUE,
      objects = TRUE,
      console = TRUE,
      plot = TRUE,
      session = TRUE,
      project = TRUE
    )
  )
}

ravel_settings_path <- function() {
  ravel_path_config("settings.json")
}

ravel_read_settings <- function() {
  path <- ravel_settings_path()
  defaults <- ravel_default_settings()
  if (!file.exists(path)) {
    return(defaults)
  }

  parsed <- tryCatch(
    jsonlite::read_json(path, simplifyVector = FALSE),
    error = function(e) defaults
  )

  utils::modifyList(defaults, parsed, keep.null = TRUE)
}

ravel_write_settings <- function(settings) {
  jsonlite::write_json(
    settings,
    path = ravel_settings_path(),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  invisible(settings)
}

#' Get a Ravel setting
#'
#' @param key Setting name.
#' @param default Default value when the setting is missing.
#'
#' @return The setting value.
#' @export
ravel_get_setting <- function(key, default = NULL) {
  settings <- ravel_read_settings()
  settings[[key]] %||% default
}

#' Set a Ravel setting
#'
#' @param key Setting name.
#' @param value Setting value.
#'
#' @return The written settings list, invisibly.
#' @export
ravel_set_setting <- function(key, value) {
  settings <- ravel_read_settings()
  settings[[key]] <- value
  invisible(ravel_write_settings(settings))
}

ravel_secret_specs <- function() {
  list(
    openai = list(
      env_vars = c("OPENAI_API_KEY"),
      keyring_key = "openai_api_key",
      token_key = "openai_bearer_token"
    ),
    gemini = list(
      env_vars = c("GEMINI_API_KEY", "GOOGLE_API_KEY"),
      keyring_key = "gemini_api_key",
      token_key = "gemini_bearer_token"
    ),
    anthropic = list(
      env_vars = c("ANTHROPIC_API_KEY"),
      keyring_key = "anthropic_api_key",
      token_key = "anthropic_bearer_token"
    ),
    copilot = list(
      env_vars = character(),
      keyring_key = NULL,
      token_key = NULL
    )
  )
}

ravel_lookup_env_secret <- function(env_vars) {
  if (!length(env_vars)) {
    return(NULL)
  }
  for (name in env_vars) {
    value <- Sys.getenv(name, unset = "")
    if (!identical(value, "")) {
      return(value)
    }
  }
  NULL
}

ravel_keyring_available <- function() {
  requireNamespace("keyring", quietly = TRUE)
}

ravel_get_secret <- function(provider, type = c("api_key", "token")) {
  type <- match.arg(type)
  specs <- ravel_secret_specs()[[provider]]
  if (is.null(specs)) {
    return(NULL)
  }

  cache_name <- paste(provider, type, sep = "::")
  cache <- ravel_session_cache()
  if (exists(cache_name, envir = cache, inherits = FALSE)) {
    return(get(cache_name, envir = cache, inherits = FALSE))
  }

  if (type == "api_key") {
    env_secret <- ravel_lookup_env_secret(specs$env_vars)
    if (!is.null(env_secret)) {
      return(env_secret)
    }
  }

  keyring_name <- if (identical(type, "api_key")) specs$keyring_key else specs$token_key
  if (!is.null(keyring_name) && ravel_keyring_available()) {
    secret <- tryCatch(
      keyring::key_get(service = "ravel", username = keyring_name),
      error = function(e) NULL
    )
    if (!is.null(secret)) {
      assign(cache_name, secret, envir = cache)
      return(secret)
    }
  }

  NULL
}

ravel_set_secret <- function(provider, value, type = c("api_key", "token"), persist = TRUE) {
  type <- match.arg(type)
  specs <- ravel_secret_specs()[[provider]]
  if (is.null(specs)) {
    cli::cli_abort("Unknown provider secret target: {.val {provider}}.")
  }

  cache_name <- paste(provider, type, sep = "::")
  assign(cache_name, value, envir = ravel_session_cache())

  keyring_name <- if (identical(type, "api_key")) specs$keyring_key else specs$token_key
  if (persist && !is.null(keyring_name)) {
    if (ravel_keyring_available()) {
      keyring::key_set_with_value(service = "ravel", username = keyring_name, password = value)
    } else {
      cli::cli_warn(c(
        "Secure persistent storage requires the {.pkg keyring} package.",
        "i" = "The secret was stored for the current R session only."
      ))
    }
  }

  invisible(value)
}

ravel_clear_secret <- function(provider, type = c("api_key", "token")) {
  type <- match.arg(type)
  specs <- ravel_secret_specs()[[provider]]
  if (is.null(specs)) {
    return(invisible(FALSE))
  }

  cache_name <- paste(provider, type, sep = "::")
  if (exists(cache_name, envir = ravel_session_cache(), inherits = FALSE)) {
    rm(list = cache_name, envir = ravel_session_cache())
  }

  keyring_name <- if (identical(type, "api_key")) specs$keyring_key else specs$token_key
  if (!is.null(keyring_name) && ravel_keyring_available()) {
    try(keyring::key_delete(service = "ravel", username = keyring_name), silent = TRUE)
  }

  invisible(TRUE)
}

ravel_command_available <- function(command) {
  nzchar(Sys.which(command))
}

ravel_copilot_auth_status <- function() {
  if (!ravel_command_available("gh")) {
    return(list(
      configured = FALSE,
      mode = "gh_cli",
      detail = "GitHub CLI (`gh`) is not installed."
    ))
  }

  output <- tryCatch(
    system2("gh", c("auth", "status"), stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  ok <- any(grepl("Logged in to github.com", output, fixed = TRUE))
  detail <- if (ok) "GitHub CLI is authenticated." else ravel_trim_text(output, 500L)
  list(configured = ok, mode = "gh_cli", detail = detail)
}

ravel_openai_auth_status <- function() {
  api_key <- ravel_get_secret("openai", "api_key")
  codex <- ravel_command_available("codex")
  if (!is.null(api_key)) {
    return(list(configured = TRUE, mode = "api_key", detail = "OpenAI API key is configured."))
  }
  if (codex) {
    return(list(
      configured = TRUE,
      mode = "codex_cli",
      detail = "Codex CLI is available for official sign-in style workflows."
    ))
  }
  list(
    configured = FALSE,
    mode = "api_key",
    detail = "Configure OPENAI_API_KEY or install the Codex CLI for login-first workflows."
  )
}

ravel_api_key_auth_status <- function(provider) {
  configured <- !is.null(ravel_get_secret(provider, "api_key"))
  label <- switch(
    provider,
    gemini = "Gemini API key",
    anthropic = "Anthropic API key",
    paste(provider, "API key")
  )
  list(
    configured = configured,
    mode = "api_key",
    detail = if (configured) paste(label, "is configured.") else paste(label, "is not configured.")
  )
}

#' Report provider auth status
#'
#' @param provider Provider name.
#'
#' @return A named list describing auth configuration.
#' @export
ravel_auth_status <- function(provider = c("openai", "copilot", "gemini", "anthropic")) {
  provider <- match.arg(provider)
  status <- switch(
    provider,
    openai = ravel_openai_auth_status(),
    copilot = ravel_copilot_auth_status(),
    gemini = {
      bearer <- !is.null(ravel_get_secret("gemini", "token"))
      key <- ravel_api_key_auth_status("gemini")
      if (bearer) {
        list(configured = TRUE, mode = "oauth_token", detail = "Gemini bearer token is configured.")
      } else {
        key
      }
    },
    anthropic = ravel_api_key_auth_status("anthropic")
  )
  c(list(provider = provider), status)
}

#' Store an API key for a provider
#'
#' @param provider Provider name.
#' @param key API key value.
#' @param persist Whether to try to persist the secret using `keyring`.
#'
#' @return The stored key, invisibly.
#' @export
ravel_set_api_key <- function(provider = c("openai", "gemini", "anthropic"), key, persist = TRUE) {
  provider <- match.arg(provider)
  stopifnot(is.character(key), length(key) == 1L, nzchar(key))
  ravel_set_secret(provider, key, type = "api_key", persist = persist)
}

#' Store a bearer token for a provider
#'
#' @param provider Provider name.
#' @param token Bearer token value.
#' @param persist Whether to try to persist the token using `keyring`.
#'
#' @return The stored token, invisibly.
#' @export
ravel_set_bearer_token <- function(provider = c("gemini"), token, persist = TRUE) {
  provider <- match.arg(provider)
  stopifnot(is.character(token), length(token) == 1L, nzchar(token))
  ravel_set_secret(provider, token, type = "token", persist = persist)
}

#' Start a provider login flow
#'
#' @param provider Provider name.
#' @param mode Optional auth mode override.
#'
#' @return A list describing the supported login action.
#' @export
ravel_login <- function(provider = c("openai", "copilot", "gemini", "anthropic"), mode = NULL) {
  provider <- match.arg(provider)

  switch(
    provider,
    openai = {
      chosen <- mode %||% "codex_cli"
      list(
        provider = provider,
        mode = chosen,
        supported = TRUE,
        command = if (identical(chosen, "codex_cli")) "codex" else NULL,
        detail = if (identical(chosen, "codex_cli")) {
          "Install and run the official Codex CLI to sign in with a ChatGPT account or API key."
        } else {
          "Set OPENAI_API_KEY or call ravel_set_api_key('openai', ...)."
        }
      )
    },
    copilot = list(
      provider = provider,
      mode = mode %||% "gh_cli",
      supported = TRUE,
      command = "gh auth login",
      detail = paste(
        "Authenticate GitHub CLI, then ensure the Copilot CLI",
        "surface is available through `gh copilot`."
      )
    ),
    gemini = list(
      provider = provider,
      mode = mode %||% "api_key",
      supported = TRUE,
      command = NULL,
      detail = paste(
        "Use ravel_set_api_key('gemini', ...) or supply an official bearer token",
        "with ravel_set_bearer_token('gemini', ...)."
      )
    ),
    anthropic = list(
      provider = provider,
      mode = "api_key",
      supported = TRUE,
      command = NULL,
      detail = "Anthropic support uses API keys only. Use ravel_set_api_key('anthropic', ...)."
    )
  )
}

#' Logout a provider from Ravel-managed credentials
#'
#' @param provider Provider name.
#'
#' @return Invisibly `TRUE`.
#' @export
ravel_logout <- function(provider = c("openai", "copilot", "gemini", "anthropic")) {
  provider <- match.arg(provider)
  ravel_clear_secret(provider, "api_key")
  ravel_clear_secret(provider, "token")
  invisible(TRUE)
}
