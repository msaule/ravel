ravel_openai_models <- function() {
  c("gpt-5.5", "gpt-5.4", "gpt-5.3-codex", "gpt-4.1")
}

ravel_openai_extract_text <- function(content) {
  if (is.character(content)) {
    return(paste(content, collapse = "\n"))
  }
  if (is.list(content)) {
    text <- vapply(
      content,
      function(item) {
        item$text %||% ""
      },
      character(1)
    )
    return(paste(text[nzchar(text)], collapse = "\n"))
  }
  as.character(content %||% "")
}

ravel_openai_resp_text <- function(body) {
  output <- body$output %||% list()
  parts <- unlist(lapply(output, function(item) {
    content <- item$content %||% list()
    vapply(content, function(part) {
      if (identical(part$type %||% "", "output_text")) {
        return(part$text %||% "")
      }
      part$text %||% ""
    }, character(1))
  }), use.names = FALSE)

  text <- paste(parts[nzchar(parts)], collapse = "\n")
  if (nzchar(text)) {
    return(text)
  }

  body$output_text %||% ""
}

ravel_openai_responses_input <- function(messages) {
  lines <- vapply(messages, function(msg) {
    role <- msg$role %||% "user"
    sprintf("%s: %s", toupper(role), as.character(msg$content %||% ""))
  }, character(1))

  paste(lines, collapse = "\n\n")
}

ravel_openai_chat_comps <- function(api_key, messages, context, model) {
  payload_messages <- ravel_normalize_messages(messages, context)

  req <- httr2::request("https://api.openai.com/v1/chat/completions") |>
    httr2::req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    httr2::req_body_json(list(
      model = model,
      messages = payload_messages
    ))

  resp <- ravel_perform_request(req, "OpenAI")
  body <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  content <- body$choices[[1]]$message$content %||% ""

  list(
    provider = "openai",
    auth_mode = "api_key",
    api_mode = "chat_completions",
    model = body$model %||% model,
    content = ravel_openai_extract_text(content),
    raw = body
  )
}

ravel_openai_api_responses <- function(api_key, messages, context, model, settings) {
  normalized <- ravel_normalize_messages(messages, context)
  system_prompt <- normalized[[1]]$content
  input_messages <- normalized[-1]

  body <- list(
    model = model,
    instructions = system_prompt,
    input = ravel_openai_responses_input(input_messages)
  )

  tools <- ravel_mcp_tools(settings$openai_mcp_tools %||% list())
  if (length(tools)) {
    body$tools <- tools
  }

  req <- httr2::request("https://api.openai.com/v1/responses") |>
    httr2::req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    httr2::req_body_json(body)

  resp <- ravel_perform_request(req, "OpenAI")
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  list(
    provider = "openai",
    auth_mode = "api_key",
    api_mode = "responses",
    model = parsed$model %||% model,
    content = ravel_openai_resp_text(parsed),
    raw = parsed
  )
}

ravel_openai_api_chat <- function(messages, context, model, settings) {
  api_key <- ravel_get_secret("openai", "api_key")
  if (is.null(api_key)) {
    cli::cli_abort("OpenAI API key not configured.")
  }

  api_mode <- settings$provider_api_modes$openai %||% "responses"
  if (identical(api_mode, "chat_completions")) {
    return(ravel_openai_chat_comps(api_key, messages, context, model))
  }

  ravel_openai_api_responses(api_key, messages, context, model, settings)
}

ravel_openai_codex_cli_chat <- function(messages, context, model) {
  binary <- ravel_codex_binary()
  if (is.null(binary) || !ravel_codex_cli_logged_in()) {
    cli::cli_abort(c(
      "Codex CLI is not logged in.",
      "i" = "Run {.code codex login} or switch the OpenAI auth mode back to API key."
    ))
  }

  prompt <- ravel_cli_provider_prompt(messages, context, provider_label = "OpenAI Codex CLI")
  output_file <- tempfile(fileext = ".txt")
  prompt_file <- tempfile(fileext = ".txt")
  on.exit(unlink(c(output_file, prompt_file), force = TRUE), add = TRUE)
  writeLines(prompt, prompt_file, useBytes = TRUE)
  args <- c(
    "exec",
    "--skip-git-repo-check",
    "--ephemeral",
    "--sandbox",
    "read-only",
    "--output-last-message",
    output_file,
    "-"
  )

  if (!is.null(model) && nzchar(model)) {
    args <- c(args, "--model", model)
  }

  output <- system2(binary, args, stdout = TRUE, stderr = TRUE, stdin = prompt_file)
  status_code <- attr(output, "status", exact = TRUE) %||% 0L
  if (!identical(status_code, 0L)) {
    cli::cli_abort(ravel_trim_text(output, 1000L))
  }

  content <- if (file.exists(output_file)) {
    paste(readLines(output_file, warn = FALSE), collapse = "\n")
  } else {
    paste(output, collapse = "\n")
  }

  list(
    provider = "openai",
    auth_mode = "codex_cli",
    model = model %||% "codex-cli",
    content = content,
    raw = list(stdout = output)
  )
}

ravel_openai_chat <- function(messages, context, model, settings) {
  api_key <- ravel_get_secret("openai", "api_key")
  has_api_key <- !is.null(api_key)
  has_codex <- ravel_codex_cli_logged_in()
  mode <- ravel_openai_auth_mode(settings, has_api_key = has_api_key, has_codex = has_codex)

  if (identical(mode, "codex_cli")) {
    return(ravel_openai_codex_cli_chat(messages, context, model))
  }

  if (!has_api_key && has_codex) {
    return(ravel_openai_codex_cli_chat(messages, context, model))
  }

  if (!has_api_key) {
    cli::cli_abort(c(
      "OpenAI credentials are not configured.",
      "i" = paste(
        "Use {.fun ravel_set_api_key}, set {.envvar OPENAI_API_KEY},",
        "or log in with {.code codex login}."
      )
    ))
  }

  result <- tryCatch(
    ravel_openai_api_chat(messages, context, model, settings),
    error = function(e) e
  )

  if (!inherits(result, "error")) {
    return(result)
  }

  if (identical(settings$provider_auth_modes$openai %||% "auto", "auto") &&
        has_codex &&
        grepl("429", conditionMessage(result), fixed = TRUE)) {
    cli::cli_warn(c(
      "OpenAI API request failed in auto mode.",
      "x" = conditionMessage(result),
      "i" = "Falling back to the logged-in Codex CLI."
    ))
    return(ravel_openai_codex_cli_chat(messages, context, model))
  }

  stop(result)
}

ravel_provider_openai <- function() {
  ravel_new_provider(
    name = "openai",
    label = "OpenAI",
    auth_modes = c("api_key", "codex_cli"),
    default_model = ravel_read_settings()$default_models$openai %||% "gpt-5.5",
    models = ravel_openai_models(),
    capabilities = list(
      code_generation = TRUE,
      stats_reasoning = TRUE,
      quarto_drafting = TRUE,
      login_first = TRUE,
      responses_api = TRUE,
      remote_mcp = TRUE
    ),
    is_available = function() {
      isTRUE(ravel_auth_status("openai")$configured)
    },
    auth_status = function() ravel_auth_status("openai"),
    chat = ravel_openai_chat
  )
}
