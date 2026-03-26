ravel_gemini_models <- function() {
  c("gemini-2.5-pro", "gemini-2.5-flash")
}

ravel_gemini_chat <- function(messages, context, model, settings) {
  api_key <- ravel_get_secret("gemini", "api_key")
  bearer <- ravel_get_secret("gemini", "token")
  if (is.null(api_key) && is.null(bearer)) {
    cli::cli_abort(c(
      "Gemini credentials are not configured.",
      "i" = "Use {.fun ravel_set_api_key} or {.fun ravel_set_bearer_token} for Gemini."
    ))
  }

  normalized <- ravel_normalize_messages(messages, context)
  system_prompt <- normalized[[1]]$content
  content_messages <- normalized[-1]

  body <- list(
    systemInstruction = list(parts = list(list(text = system_prompt))),
    contents = lapply(content_messages, function(msg) {
      role <- if (identical(msg$role, "assistant")) "model" else "user"
      list(role = role, parts = list(list(text = msg$content)))
    })
  )

  req <- httr2::request(sprintf(
    "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent",
    model
  )) |>
    httr2::req_body_json(body)

  if (!is.null(api_key)) {
    req <- httr2::req_url_query(req, key = api_key)
  }
  if (!is.null(bearer)) {
    req <- httr2::req_headers(req, Authorization = paste("Bearer", bearer))
  }

  resp <- ravel_perform_request(req, "Gemini")
  parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  parts <- parsed$candidates[[1]]$content$parts %||% list()
  text <- paste(vapply(parts, function(part) part$text %||% "", character(1)), collapse = "\n")

  list(
    provider = "gemini",
    model = model,
    content = text,
    raw = parsed
  )
}

ravel_provider_gemini <- function() {
  ravel_new_provider(
    name = "gemini",
    label = "Gemini",
    auth_modes = c("api_key", "oauth_token"),
    default_model = ravel_read_settings()$default_models$gemini %||% "gemini-2.5-pro",
    models = ravel_gemini_models(),
    capabilities = list(
      code_generation = TRUE,
      stats_reasoning = TRUE,
      quarto_drafting = TRUE,
      oauth_ready = TRUE
    ),
    is_available = function() {
      isTRUE(ravel_auth_status("gemini")$configured)
    },
    auth_status = function() ravel_auth_status("gemini"),
    chat = ravel_gemini_chat
  )
}
