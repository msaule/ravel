ravel_anthropic_models <- function() {
  c("claude-sonnet-4-20250514", "claude-opus-4-1-20250805")
}

ravel_anthropic_chat <- function(messages, context, model, settings) {
  api_key <- ravel_get_secret("anthropic", "api_key")
  if (is.null(api_key)) {
    cli::cli_abort(c(
      "Anthropic API key not configured.",
      "i" = "Use {.fun ravel_set_api_key} or set {.envvar ANTHROPIC_API_KEY}."
    ))
  }

  normalized <- ravel_normalize_messages(messages, context)
  system_prompt <- normalized[[1]]$content
  content_messages <- normalized[-1]

  req <- httr2::request("https://api.anthropic.com/v1/messages") |>
    httr2::req_headers(
      `x-api-key` = api_key,
      `anthropic-version` = "2023-06-01",
      `content-type` = "application/json"
    ) |>
    httr2::req_body_json(list(
      model = model,
      max_tokens = 1500,
      system = system_prompt,
      messages = lapply(content_messages, function(msg) {
        list(
          role = msg$role,
          content = list(list(type = "text", text = msg$content))
        )
      })
    ))

  resp <- ravel_perform_request(req, "Anthropic")
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  content <- parsed$content %||% list()
  text <- paste(vapply(content, function(part) part$text %||% "", character(1)), collapse = "\n")

  list(
    provider = "anthropic",
    model = parsed$model %||% model,
    content = text,
    raw = parsed
  )
}

ravel_provider_anthropic <- function() {
  ravel_new_provider(
    name = "anthropic",
    label = "Anthropic",
    auth_modes = c("api_key"),
    default_model = ravel_read_settings()$default_models$anthropic %||% "claude-sonnet-4-20250514",
    models = ravel_anthropic_models(),
    capabilities = list(
      code_generation = TRUE,
      stats_reasoning = TRUE,
      quarto_drafting = TRUE,
      consumer_login_supported = FALSE
    ),
    is_available = function() {
      isTRUE(ravel_auth_status("anthropic")$configured)
    },
    auth_status = function() ravel_auth_status("anthropic"),
    chat = ravel_anthropic_chat
  )
}
