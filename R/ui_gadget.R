ravel_render_messages <- function(messages) {
  if (!length(messages)) {
    return(
      paste(
        "Ravel is ready.",
        "",
        "Ask about selected code, loaded objects, model output, or Quarto drafting.",
        sep = "\n"
      )
    )
  }

  blocks <- vapply(messages, function(msg) {
    provider <- if (!is.null(msg$provider)) paste0(" [", msg$provider, "]") else ""
    paste0(
      toupper(msg$role %||% "user"),
      provider,
      "\n",
      msg$content %||% ""
    )
  }, character(1))

  paste(blocks, collapse = "\n\n")
}

ravel_collect_context_from_ui <- function(selected, envir = .GlobalEnv) {
  ravel_collect_context(
    include_selection = "selection" %in% selected,
    include_file = "file" %in% selected,
    include_objects = "objects" %in% selected,
    include_console = "console" %in% selected,
    include_plot = "plot" %in% selected,
    include_session = "session" %in% selected,
    include_project = "project" %in% selected,
    envir = envir
  )
}

ravel_insert_active_doc <- function(text) {
  if (!rstudioapi::isAvailable()) {
    cli::cli_abort("RStudio is not available; cannot insert text into the active document.")
  }

  context <- rstudioapi::getActiveDocumentContext()
  rstudioapi::insertText(location = context$selection[[1]]$range, text = text, id = context$id)
  invisible(TRUE)
}

ravel_launch_chat_gadget <- function() {
  settings <- ravel_read_settings()
  providers <- ravel_list_providers()
  default_context <- names(Filter(isTRUE, settings$context_defaults))

  ui <- miniUI::miniPage(
    shiny::tags$head(
      shiny::tags$style(shiny::HTML("
        .ravel-transcript textarea {
          font-family: Consolas, 'Courier New', monospace;
          background: #faf7f1;
        }
        .ravel-panel {
          border-left: 4px solid #2c5f5d;
          padding-left: 12px;
        }
      "))
    ),
    miniUI::gadgetTitleBar("Ravel"),
    miniUI::miniContentPanel(
      shiny::fluidRow(
        shiny::column(
          width = 4,
          shiny::div(
            class = "ravel-panel",
            shiny::selectInput(
              "provider",
              "Provider",
              choices = stats::setNames(providers$provider, providers$label),
              selected = settings$default_provider
            ),
            shiny::uiOutput("model_ui"),
            shiny::verbatimTextOutput("auth_status"),
            shiny::checkboxGroupInput(
              "context_sources",
              "Context",
              choices = c(
                selection = "selection",
                file = "file",
                objects = "objects",
                console = "console",
                plot = "plot",
                session = "session",
                project = "project"
              ),
              selected = default_context
            ),
            shiny::actionButton("clear_history", "Clear Chat"),
            shiny::actionButton("refresh_context", "Refresh Context")
          )
        ),
        shiny::column(
          width = 8,
          shiny::div(
            class = "ravel-transcript",
            shiny::textAreaInput(
              "transcript",
              "Conversation",
              value = "",
              rows = 18,
              width = "100%"
            )
          ),
          shiny::textAreaInput("prompt", "Ask Ravel", rows = 6, width = "100%"),
          shiny::fluidRow(
            shiny::column(width = 4, shiny::actionButton("send", "Send", class = "btn-primary")),
            shiny::column(width = 4, shiny::actionButton("run_code", "Run Staged Code")),
            shiny::column(width = 4, shiny::actionButton("insert_code", "Insert Into Editor"))
          ),
          shiny::textAreaInput(
            "code_preview",
            "Staged Action Preview",
            value = "",
            rows = 10,
            width = "100%"
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    rv <- shiny::reactiveValues(
      messages = list(),
      pending_action = NULL,
      last_context = NULL
    )

    output$model_ui <- shiny::renderUI({
      provider <- ravel_get_provider(input$provider)
      shiny::selectInput(
        "model",
        "Model",
        choices = provider$models,
        selected = provider$default_model
      )
    })

    output$auth_status <- shiny::renderText({
      status <- ravel_auth_status(input$provider)
      sprintf(
        "Auth mode: %s\nConfigured: %s\n%s",
        status$mode,
        if (isTRUE(status$configured)) "yes" else "no",
        status$detail
      )
    })

    shiny::observe({
      shiny::updateTextAreaInput(
        session,
        "transcript",
        value = ravel_render_messages(rv$messages)
      )
    })

    shiny::observeEvent(input$refresh_context, {
      rv$last_context <- ravel_collect_context_from_ui(input$context_sources)
      shiny::showNotification("Context refreshed.", type = "message")
    })

    shiny::observeEvent(input$clear_history, {
      rv$messages <- list()
      rv$pending_action <- NULL
      state <- ravel_runtime_state()
      state$chat_history <- list()
      ravel_set_runtime_state(state)
      shiny::updateTextAreaInput(session, "code_preview", value = "")
    })

    shiny::observeEvent(input$send, {
      req_prompt <- trimws(input$prompt %||% "")
      if (!nzchar(req_prompt)) {
        shiny::showNotification("Enter a prompt first.", type = "warning")
        return()
      }

      context <- rv$last_context %||% ravel_collect_context_from_ui(input$context_sources)
      rv$last_context <- context

      turn <- tryCatch(
        ravel_chat_turn(
          prompt = req_prompt,
          provider = input$provider,
          model = input$model,
          context = context,
          history = rv$messages
        ),
        error = function(e) e
      )

      if (inherits(turn, "error")) {
        shiny::showNotification(conditionMessage(turn), type = "error", duration = NULL)
        return()
      }

      rv$messages <- c(
        rv$messages,
        list(list(role = "user", content = req_prompt), turn$message)
      )
      shiny::updateTextAreaInput(session, "prompt", value = "")

      if (length(turn$actions)) {
        rv$pending_action <- turn$actions[[1]]
        preview_text <- turn$actions[[1]]$payload$code %||% turn$actions[[1]]$payload$text %||% ""
        shiny::updateTextAreaInput(session, "code_preview", value = preview_text)
      }
    })

    shiny::observeEvent(input$run_code, {
      code <- input$code_preview %||% ""
      if (!nzchar(trimws(code))) {
        shiny::showNotification("No staged code is available.", type = "warning")
        return()
      }

      action <- rv$pending_action
      if (is.null(action) || !identical(action$type, "run_code")) {
        action <- ravel_preview_code(code, provider = input$provider, model = input$model)
      } else {
        action$payload$code <- code
      }

      action <- ravel_approve_action(action)
      result <- tryCatch(
        ravel_run_code(action, approve = FALSE),
        error = function(e) e
      )

      if (inherits(result, "error")) {
        shiny::showNotification(conditionMessage(result), type = "error", duration = NULL)
        return()
      }

      output_text <- paste(
        c(result$output, result$messages, result$warnings, result$error),
        collapse = "\n"
      )
      rv$messages <- c(
        rv$messages,
        list(list(role = "system", content = paste("Execution result:\n", output_text)))
      )
      shiny::showNotification("Code executed through Ravel.", type = "message")
    })

    shiny::observeEvent(input$insert_code, {
      code <- input$code_preview %||% ""
      if (!nzchar(trimws(code))) {
        shiny::showNotification("No staged text is available.", type = "warning")
        return()
      }

      result <- tryCatch(
        ravel_insert_active_doc(code),
        error = function(e) e
      )

      if (inherits(result, "error")) {
        shiny::showNotification(conditionMessage(result), type = "error", duration = NULL)
      } else {
        shiny::showNotification("Inserted into the active document.", type = "message")
      }
    })

    shiny::observeEvent(input$done, {
      shiny::stopApp(invisible(NULL))
    })

    shiny::observeEvent(input$cancel, {
      shiny::stopApp(invisible(NULL))
    })
  }

  shiny::runGadget(ui, server, viewer = shiny::dialogViewer("Ravel", width = 1200, height = 900))
}

ravel_launch_settings_gadget <- function() {
  settings <- ravel_read_settings()
  providers <- ravel_list_providers()

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("Ravel Settings"),
    miniUI::miniContentPanel(
      shiny::selectInput(
        "default_provider",
        "Default provider",
        choices = stats::setNames(providers$provider, providers$label),
        selected = settings$default_provider
      ),
      shiny::textInput("openai_key", "OpenAI API key", value = ""),
      shiny::textInput("gemini_key", "Gemini API key", value = ""),
      shiny::textInput("gemini_token", "Gemini bearer token", value = ""),
      shiny::textInput("anthropic_key", "Anthropic API key", value = ""),
      shiny::checkboxInput("persist", "Persist secrets with keyring when available", value = TRUE),
      shiny::selectInput(
        "clear_provider",
        "Clear stored auth for provider",
        choices = providers$provider,
        selected = "openai"
      ),
      shiny::fluidRow(
        shiny::column(
          width = 6,
          shiny::actionButton("save", "Save Settings", class = "btn-primary")
        ),
        shiny::column(width = 6, shiny::actionButton("clear_auth", "Clear Selected Auth"))
      ),
      shiny::verbatimTextOutput("settings_status")
    )
  )

  server <- function(input, output, session) {
    output$settings_status <- shiny::renderText({
      statuses <- lapply(c("openai", "copilot", "gemini", "anthropic"), ravel_auth_status)
      paste(vapply(statuses, function(x) {
        sprintf(
          "%s: %s (%s)",
          x$provider,
          x$detail,
          if (x$configured) "configured" else "not configured"
        )
      }, character(1)), collapse = "\n")
    })

    shiny::observeEvent(input$save, {
      ravel_set_setting("default_provider", input$default_provider)
      if (nzchar(trimws(input$openai_key))) {
        ravel_set_api_key("openai", input$openai_key, persist = input$persist)
      }
      if (nzchar(trimws(input$gemini_key))) {
        ravel_set_api_key("gemini", input$gemini_key, persist = input$persist)
      }
      if (nzchar(trimws(input$gemini_token))) {
        ravel_set_bearer_token("gemini", input$gemini_token, persist = input$persist)
      }
      if (nzchar(trimws(input$anthropic_key))) {
        ravel_set_api_key("anthropic", input$anthropic_key, persist = input$persist)
      }
      shiny::showNotification("Settings saved.", type = "message")
    })

    shiny::observeEvent(input$clear_auth, {
      ravel_logout(input$clear_provider)
      shiny::showNotification(
        sprintf("Cleared stored auth for %s.", input$clear_provider),
        type = "message"
      )
    })

    shiny::observeEvent(input$done, {
      shiny::stopApp(invisible(NULL))
    })

    shiny::observeEvent(input$cancel, {
      shiny::stopApp(invisible(NULL))
    })
  }

  shiny::runGadget(
    ui,
    server,
    viewer = shiny::dialogViewer("Ravel Settings", width = 700, height = 700)
  )
}
