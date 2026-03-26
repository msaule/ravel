ravel_openai_models <- function() {
  c("gpt-5.3-codex", "gpt-5.4", "gpt-4.1")
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

ravel_openai_chat <- function(messages, context, model, settings) {
  api_key <- ravel_get_secret("openai", "api_key")
  if (is.null(api_key)) {
    cli::cli_abort(c(
      "OpenAI API key not configured.",
      "i" = "Use {.fun ravel_set_api_key} or set {.envvar OPENAI_API_KEY}.",
      "i" = "Codex CLI sign-in is modeled separately, but the MVP addin chat uses the API path."
    ))
  }

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
    model = body$model %||% model,
    content = ravel_openai_extract_text(content),
    raw = body
  )
}

ravel_provider_openai <- function() {
  ravel_new_provider(
    name = "openai",
    label = "OpenAI",
    auth_modes = c("api_key", "codex_cli"),
    default_model = ravel_read_settings()$default_models$openai %||% "gpt-5.3-codex",
    models = ravel_openai_models(),
    capabilities = list(
      code_generation = TRUE,
      stats_reasoning = TRUE,
      quarto_drafting = TRUE,
      login_first = TRUE
    ),
    is_available = function() {
      isTRUE(ravel_auth_status("openai")$configured)
    },
    auth_status = function() ravel_auth_status("openai"),
    chat = ravel_openai_chat
  )
}
