ravel_powershell_quote <- function(x) {
  paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
}

ravel_copilot_run <- function(binary, prompt, token = NULL) {
  if (.Platform$OS.type != "windows") {
    old_token <- Sys.getenv("GH_TOKEN", unset = NA_character_)
    if (!is.null(token) && !nzchar(Sys.getenv("GH_TOKEN", unset = ""))) {
      Sys.setenv(GH_TOKEN = token)
      on.exit({
        if (is.na(old_token)) {
          Sys.unsetenv("GH_TOKEN")
        } else {
          Sys.setenv(GH_TOKEN = old_token)
        }
      }, add = TRUE)
    }

    return(system2(
      binary,
      c("-p", prompt, "--silent", "--allow-all-tools"),
      stdout = TRUE,
      stderr = TRUE
    ))
  }

  prompt_file <- tempfile(fileext = ".txt")
  on.exit(unlink(prompt_file, force = TRUE), add = TRUE)
  writeLines(prompt, prompt_file, useBytes = TRUE)

  token_cmd <- if (!is.null(token) && nzchar(token)) {
    paste0("$env:GH_TOKEN = ", ravel_powershell_quote(token), "; ")
  } else {
    ""
  }

  ps_command <- paste0(
    "$ErrorActionPreference = 'Stop'; ",
    token_cmd,
    "& ",
    ravel_powershell_quote(binary),
    " -p (Get-Content -Raw ",
    ravel_powershell_quote(prompt_file),
    ") --silent --allow-all-tools"
  )

  system2(
    "powershell",
    c("-NoProfile", "-Command", ps_command),
    stdout = TRUE,
    stderr = TRUE
  )
}

ravel_copilot_chat <- function(messages, context, model, settings) {
  binary <- ravel_copilot_binary()
  status <- ravel_auth_status("copilot")
  if (is.null(binary)) {
    cli::cli_abort(c(
      "The official Copilot CLI is not installed.",
      "i" = "Install the official `copilot` CLI before using this provider."
    ))
  }

  prompt <- ravel_cli_provider_prompt(messages, context, provider_label = "GitHub Copilot CLI")
  token <- ravel_copilot_token()
  output <- ravel_copilot_run(binary, prompt, token = token)
  status_code <- attr(output, "status", exact = TRUE) %||% 0L
  text <- paste(output, collapse = "\n")

  if (identical(status_code, 0L)) {
    return(list(
      provider = "copilot",
      auth_mode = status$mode,
      model = "copilot-cli",
      content = text,
      raw = output
    ))
  }

  if (!isTRUE(status$configured)) {
    cli::cli_abort(c(
      "Copilot CLI is installed but not authenticated for use yet.",
      "i" = "Run {.code copilot login} for the official OAuth device flow, or provide GH_TOKEN.",
      "x" = ravel_trim_text(output, 800L)
    ))
  }

  cli::cli_abort(ravel_trim_text(output, 1000L))
}

ravel_provider_copilot <- function() {
  ravel_new_provider(
    name = "copilot",
    label = "GitHub Copilot",
    auth_modes = c("oauth_device_flow", "gh_cli_oauth_token"),
    default_model = "copilot-cli",
    models = "copilot-cli",
    supports_model_selection = FALSE,
    capabilities = list(
      code_generation = TRUE,
      stats_reasoning = TRUE,
      quarto_drafting = TRUE,
      login_first = TRUE,
      official_cli = TRUE
    ),
    is_available = function() {
      isTRUE(ravel_auth_status("copilot")$configured)
    },
    auth_status = function() ravel_auth_status("copilot"),
    chat = ravel_copilot_chat
  )
}
