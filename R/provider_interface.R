ravel_new_provider <- function(
    name,
    label,
    auth_modes,
    default_model,
    models,
    supports_model_selection = TRUE,
    capabilities = list(),
    is_available,
    auth_status,
    chat) {
  structure(
    list(
      name = name,
      label = label,
      auth_modes = auth_modes,
      default_model = default_model,
      models = models,
      supports_model_selection = supports_model_selection,
      capabilities = capabilities,
      is_available = is_available,
      auth_status = auth_status,
      chat = chat
    ),
    class = "ravel_provider"
  )
}

ravel_provider_registry <- function() {
  list(
    openai = ravel_provider_openai(),
    copilot = ravel_provider_copilot(),
    gemini = ravel_provider_gemini(),
    anthropic = ravel_provider_anthropic()
  )
}

ravel_get_provider <- function(provider = NULL) {
  provider <- provider %||% ravel_get_setting("default_provider", "openai")
  registry <- ravel_provider_registry()
  if (!provider %in% names(registry)) {
    cli::cli_abort("Unknown Ravel provider: {.val {provider}}.")
  }
  registry[[provider]]
}

#' List configured providers
#'
#' @return A tibble describing the available provider adapters.
#' @export
ravel_list_providers <- function() {
  registry <- ravel_provider_registry()
  tibble::tibble(
    provider = names(registry),
    label = vapply(registry, `[[`, character(1), "label"),
    auth_modes = I(lapply(registry, `[[`, "auth_modes")),
    default_model = vapply(registry, `[[`, character(1), "default_model")
  )
}

#' Report provider capabilities
#'
#' @param provider Provider name.
#'
#' @return A named list.
#' @export
ravel_provider_capabilities <- function(provider = c("openai", "copilot", "gemini", "anthropic")) {
  provider <- match.arg(provider)
  obj <- ravel_get_provider(provider)
  list(
    provider = obj$name,
    label = obj$label,
    auth_modes = obj$auth_modes,
    default_model = obj$default_model,
    models = obj$models,
    supports_model_selection = obj$supports_model_selection,
    capabilities = obj$capabilities
  )
}

ravel_system_prompt <- function() {
  paste(
    "You are Ravel, an R-first analytics copilot embedded in RStudio.",
    "Prioritize reproducible, conservative, statistics-aware answers.",
    "When you suggest executable R code, put it in fenced ```r code blocks.",
    paste(
      "If you interpret statistical output, include a brief warnings or",
      "assumptions section when appropriate."
    ),
    "Do not claim to have run code unless the provided context says it was executed.",
    paste(
      "If context was used, include a short 'Basis:' section that names",
      "the context signals you relied on."
    ),
    sep = "\n"
  )
}

ravel_format_context <- function(context) {
  if (is.null(context) || !length(context)) {
    return("")
  }

  json <- jsonlite::toJSON(context, auto_unbox = TRUE, pretty = TRUE, null = "null")
  paste(
    "Context for this turn:",
    "```json",
    ravel_trim_text(json, 8000L),
    "```",
    sep = "\n"
  )
}

ravel_normalize_messages <- function(messages, context = NULL) {
  messages <- messages %||% list()
  if (!length(messages)) {
    return(list(list(role = "system", content = ravel_system_prompt())))
  }

  normalized <- lapply(messages, function(msg) {
    list(role = msg$role %||% "user", content = as.character(msg$content %||% ""))
  })

  normalized <- c(list(list(role = "system", content = ravel_system_prompt())), normalized)

  if (!is.null(context) && length(context)) {
    last_idx <- length(normalized)
    normalized[[last_idx]]$content <- paste(
      normalized[[last_idx]]$content,
      "",
      ravel_format_context(context),
      sep = "\n"
    )
  }

  normalized
}

ravel_cli_provider_prompt <- function(messages, context, provider_label) {
  normalized <- ravel_normalize_messages(messages, context)
  system_prompt <- normalized[[1]]$content
  history <- vapply(
    normalized[-1],
    function(msg) paste0(toupper(msg$role), ": ", msg$content),
    character(1)
  )

  paste(
    sprintf("Provider: %s", provider_label),
    "System instructions:",
    system_prompt,
    "",
    "Conversation:",
    paste(history, collapse = "\n\n"),
    sep = "\n"
  )
}

ravel_extract_code_blocks <- function(text) {
  pattern <- "```([[:alnum:]{}_:-]*)\\n([\\s\\S]*?)```"
  matches <- gregexpr(pattern, text, perl = TRUE)
  parts <- regmatches(text, matches)[[1]]
  if (!length(parts)) {
    return(list())
  }

  lapply(parts, function(block) {
    groups <- regexec(pattern, block, perl = TRUE)
    pieces <- regmatches(block, groups)[[1]]
    list(
      language = trimws(pieces[2]),
      code = pieces[3]
    )
  })
}

ravel_response_to_actions <- function(text, provider = NULL, model = NULL) {
  blocks <- ravel_extract_code_blocks(text)
  if (!length(blocks)) {
    return(list())
  }

  actions <- list()
  for (block in blocks) {
    language <- tolower(block$language %||% "")
    if (language %in% c("r", "{r}", "rscript", "")) {
      actions[[length(actions) + 1L]] <- ravel_preview_code(
        code = block$code,
        label = "Run generated R code",
        provider = provider,
        model = model
      )
    } else if (grepl("qmd|markdown|md|quarto", language)) {
      actions[[length(actions) + 1L]] <- ravel_new_action(
        type = "draft_quarto",
        label = "Draft Quarto content",
        payload = list(text = block$code),
        provider = provider,
        model = model
      )
    }
  }
  actions
}

ravel_append_chat_history <- function(history, entries) {
  state <- ravel_runtime_state()
  state$chat_history <- c(history, entries)
  ravel_set_runtime_state(state)
}

#' Run one chat turn through a provider
#'
#' @param prompt User prompt.
#' @param provider Provider name.
#' @param model Optional model override.
#' @param context Optional precomputed context.
#' @param history Optional existing chat history.
#'
#' @return A list with `message`, `actions`, and `raw`.
#' @export
ravel_chat_turn <- function(prompt,
                            provider = NULL,
                            model = NULL,
                            context = NULL,
                            history = NULL) {
  stopifnot(is.character(prompt), length(prompt) == 1L, nzchar(prompt))

  provider_obj <- ravel_get_provider(provider)
  provider_name <- provider_obj$name
  history <- history %||% ravel_runtime_state()$chat_history
  context <- context %||% ravel_collect_context()

  user_entry <- list(role = "user", content = prompt)
  messages <- c(history, list(user_entry))

  response <- provider_obj$chat(
    messages = messages,
    context = context,
    model = model %||% provider_obj$default_model,
    settings = ravel_read_settings()
  )

  assistant_entry <- list(
    role = "assistant",
    content = response$content,
    provider = provider_name,
    model = response$model %||% provider_obj$default_model
  )

  ravel_append_chat_history(history, list(user_entry, assistant_entry))
  ravel_log_chat_turn(
    provider = provider_name,
    model = assistant_entry$model,
    prompt = prompt,
    response = response$content
  )

  list(
    message = assistant_entry,
    actions = ravel_response_to_actions(
      response$content,
      provider = provider_name,
      model = assistant_entry$model
    ),
    raw = response
  )
}
