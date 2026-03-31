ravel_escape_html <- function(text) {
  text <- text %||% ""
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  text <- gsub("\"", "&quot;", text, fixed = TRUE)
  gsub("'", "&#39;", text, fixed = TRUE)
}

ravel_message_role_class <- function(role) {
  switch(
    role %||% "assistant",
    user = "ravel-message-user",
    assistant = "ravel-message-assistant",
    system = "ravel-message-system",
    "ravel-message-system"
  )
}

ravel_message_heading <- function(message) {
  role <- message$role %||% "assistant"
  role_label <- switch(
    role,
    user = "You",
    assistant = "Ravel",
    system = "System",
    "Ravel"
  )

  extras <- c(message$provider %||% NULL, message$model %||% NULL)
  extras <- extras[nzchar(extras)]
  if (!length(extras)) {
    return(role_label)
  }

  paste(role_label, paste(extras, collapse = " | "), sep = " | ")
}

ravel_render_message_html <- function(message) {
  sprintf(
    paste0(
      "<div class='ravel-message %s'>",
      "<div class='ravel-message-head'>%s</div>",
      "<div class='ravel-message-body'>%s</div>",
      "</div>"
    ),
    ravel_message_role_class(message$role),
    ravel_escape_html(ravel_message_heading(message)),
    ravel_escape_html(message$content %||% "")
  )
}

ravel_render_messages_ui <- function(messages, waiting = FALSE) {
  if (!length(messages) && !isTRUE(waiting)) {
    return(shiny::HTML(paste(
      "<div class='ravel-empty-state'>",
      "<div class='ravel-empty-title'>Ravel is ready.</div>",
      "<div class='ravel-empty-body'>",
      "Ask about selected code, loaded objects, model output, diagnostics,",
      "or Quarto drafting.",
      "</div>",
      "</div>",
      sep = "\n"
    )))
  }

  blocks <- vapply(messages, ravel_render_message_html, character(1))

  if (isTRUE(waiting)) {
    blocks <- c(
      blocks,
      paste(
        "<div class='ravel-message ravel-message-assistant ravel-message-waiting'>",
        "<div class='ravel-message-head'>Ravel</div>",
        "<div class='ravel-message-body'>",
        "<span class='ravel-spinner' aria-hidden='true'></span>",
        "Waiting for a response...",
        "</div>",
        "</div>",
        sep = "\n"
      )
    )
  }

  shiny::HTML(paste(blocks, collapse = "\n"))
}

# nolint start: object_usage_linter
ravel_collect_context_from_ui <- function(selected, envir = NULL) {
  ravel_collect_context(
    include_selection = "selection" %in% selected,
    include_file = "file" %in% selected,
    include_objects = "objects" %in% selected,
    include_console = "console" %in% selected,
    include_plot = "plot" %in% selected,
    include_session = "session" %in% selected,
    include_project = "project" %in% selected,
    include_git = "git" %in% selected,
    envir = envir
  )
}
# nolint end

ravel_context_with_preview <- function(context, pending_action = NULL, preview_text = NULL) {
  preview_text <- trimws(preview_text %||% "")
  if (!nzchar(preview_text) && is.null(pending_action)) {
    return(context)
  }

  context$preview <- list(
    has_staged_preview = TRUE,
    action_type = pending_action$type %||% "preview",
    label = pending_action$label %||% "Staged preview",
    text = if (nzchar(preview_text)) ravel_trim_text(preview_text, 4000L) else NULL
  )
  context
}

ravel_context_basis_html <- function(context) {
  document <- context$document %||% list()
  project <- context$project %||% list()

  doc_path <- document$path %||% ""
  doc_name <- document$name %||% if (nzchar(doc_path)) basename(doc_path) else "Untitled editor"
  workspace_root <- project$root %||% context$session$workspace_root %||% ""
  working_directory <- project$working_directory %||% context$session$working_directory %||% ""
  within_workspace <- document$within_workspace_root

  lines <- character()

  if (nzchar(doc_path)) {
    lines <- c(
      lines,
      sprintf(
        "<strong>Active editor:</strong> %s",
        ravel_escape_html(doc_name)
      ),
      sprintf(
        "<span class='ravel-context-path'>%s</span>",
        ravel_escape_html(doc_path)
      )
    )
  } else {
    lines <- c(lines, "<strong>Active editor:</strong> Unsaved or unavailable")
  }

  if (nzchar(workspace_root)) {
    lines <- c(
      lines,
      sprintf(
        "<strong>Workspace root:</strong> <span class='ravel-context-path'>%s</span>",
        ravel_escape_html(workspace_root)
      )
    )
  }

  if (nzchar(working_directory) && !identical(working_directory, workspace_root)) {
    lines <- c(
      lines,
      sprintf(
        "<strong>Working directory:</strong> <span class='ravel-context-path'>%s</span>",
        ravel_escape_html(working_directory)
      )
    )
  }

  if (isTRUE(within_workspace)) {
    lines <- c(lines, "Ravel is using the active editor and the workspace context together.")
  } else if (identical(within_workspace, FALSE)) {
    lines <- c(
      lines,
      paste(
        "Ravel is using the active editor even though it is outside the workspace root,",
        "and it is keeping the workspace context alongside it."
      )
    )
    if (length(document$sibling_files %||% character())) {
      lines <- c(
        lines,
        sprintf(
          "Nearby files from the active editor folder are also included (%d tracked).",
          length(document$sibling_files)
        )
      )
    }
  } else {
    lines <- c(lines, "Ravel is using the editor context alongside the current workspace context.")
  }

  if (isTRUE(context$preview$has_staged_preview %||% FALSE)) {
    lines <- c(lines, "The current action preview is also included in context.")
  }

  if (length(context$activity$recent_actions %||% list())) {
    lines <- c(
      lines,
      sprintf(
        "Recent Ravel actions in memory: %d.",
        length(context$activity$recent_actions)
      )
    )
  }

  workspace_git <- context$git$workspace %||% NULL
  if (!is.null(workspace_git)) {
    lines <- c(
      lines,
      sprintf(
        "Workspace git context: branch %s, %d changed files.",
        ravel_escape_html(workspace_git$branch %||% "detached"),
        workspace_git$changed_file_count %||% 0L
      )
    )
  }

  editor_git <- context$git$editor %||% NULL
  if (!is.null(editor_git)) {
    lines <- c(
      lines,
      sprintf(
        "Active editor repo is also tracked separately on branch %s.",
        ravel_escape_html(editor_git$branch %||% "detached")
      )
    )
  }

  shiny::HTML(paste(lines, collapse = "<br/>"))
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
  default_context <- names(Filter(base::isTRUE, settings$context_defaults))

  ui <- miniUI::miniPage(
    shiny::tags$head(
      shiny::tags$style(shiny::HTML("
        .ravel-shell {
          background: linear-gradient(180deg, #f7f1e6 0%, #f3efe7 100%);
          min-height: 100%;
        }
        .ravel-panel {
          border-left: 4px solid #2c5f5d;
          padding-left: 12px;
        }
        .ravel-chat-shell,
        .ravel-compose-shell,
        .ravel-preview-shell {
          background: #fffdf8;
          border: 1px solid #d8d1c3;
          border-radius: 14px;
          box-shadow: 0 8px 20px rgba(67, 58, 45, 0.08);
          padding: 14px 16px;
          margin-bottom: 14px;
        }
        .ravel-chat-topline {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 12px;
          margin-bottom: 10px;
        }
        .ravel-chat-title {
          font-size: 18px;
          font-weight: 700;
          color: #2a2a24;
        }
        .ravel-chat-subtitle {
          font-size: 12px;
          color: #6c655b;
          margin-top: 2px;
        }
        .ravel-status-chip {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          background: #ece7da;
          border-radius: 999px;
          padding: 7px 12px;
          color: #433a2d;
          font-size: 12px;
          font-weight: 600;
        }
        .ravel-status-chip-waiting {
          background: #dceceb;
          color: #1f4b49;
        }
        .ravel-chat-log {
          height: 440px;
          overflow-y: auto;
          padding: 8px 6px 6px 2px;
          background: linear-gradient(180deg, #fdf9f1 0%, #f8f3ea 100%);
          border-radius: 12px;
          border: 1px solid #ebe4d8;
        }
        .ravel-message {
          max-width: 90%;
          border-radius: 16px;
          padding: 12px 14px;
          margin: 0 0 12px 0;
          box-shadow: 0 4px 14px rgba(67, 58, 45, 0.06);
        }
        .ravel-message-user {
          margin-left: auto;
          background: #2c5f5d;
          color: #f8fbfb;
        }
        .ravel-message-assistant {
          margin-right: auto;
          background: #ffffff;
          color: #2e2b27;
          border: 1px solid #ddd5c7;
        }
        .ravel-message-system {
          margin-right: auto;
          background: #f2efe7;
          color: #51493d;
          border: 1px dashed #c7bdad;
        }
        .ravel-message-head {
          font-size: 11px;
          font-weight: 700;
          letter-spacing: 0.04em;
          text-transform: uppercase;
          margin-bottom: 6px;
          opacity: 0.78;
        }
        .ravel-message-body {
          white-space: pre-wrap;
          line-height: 1.45;
          font-size: 14px;
        }
        .ravel-message-waiting .ravel-message-body {
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .ravel-spinner {
          width: 12px;
          height: 12px;
          border-radius: 999px;
          border: 2px solid rgba(44, 95, 93, 0.25);
          border-top-color: #2c5f5d;
          animation: ravel-spin 0.8s linear infinite;
          display: inline-block;
        }
        .ravel-empty-state {
          padding: 24px 18px;
          color: #4d463d;
        }
        .ravel-empty-title {
          font-size: 18px;
          font-weight: 700;
          margin-bottom: 6px;
        }
        .ravel-empty-body {
          font-size: 14px;
          line-height: 1.5;
          max-width: 560px;
        }
        .ravel-helper-text {
          font-size: 12px;
          color: #6f665b;
          margin: 4px 0 10px 0;
        }
        .ravel-context-shell {
          background: #f8f3ea;
          border: 1px solid #ddd5c7;
          border-radius: 12px;
          padding: 10px 12px;
          margin-bottom: 12px;
          color: #4d463d;
          font-size: 12px;
          line-height: 1.5;
        }
        .ravel-context-path {
          font-family: Consolas, 'Courier New', monospace;
          font-size: 11px;
        }
        .ravel-preview-label {
          font-size: 16px;
          font-weight: 700;
          color: #2a2a24;
          margin-bottom: 6px;
        }
        .ravel-preview-note {
          font-size: 12px;
          color: #6f665b;
          margin-bottom: 8px;
        }
        .ravel-preview-shell textarea,
        .ravel-compose-shell textarea {
          font-family: Consolas, 'Courier New', monospace;
        }
        @keyframes ravel-spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      ")),
      shiny::tags$script(shiny::HTML("
        Shiny.addCustomMessageHandler('ravel-scroll-chat', function(message) {
          var el = document.getElementById(message.id);
          if (!el) {
            return;
          }
          window.setTimeout(function() {
            el.scrollTop = el.scrollHeight;
          }, 0);
        });

        $(document).on('shiny:connected', function() {
          $('#prompt').attr(
            'placeholder',
            'Ask about code, data frames, model output, errors, diagnostics, or Quarto sections...'
          );
        });
      "))
    ),
    miniUI::gadgetTitleBar("Ravel"),
    miniUI::miniContentPanel(
      shiny::div(
        class = "ravel-shell",
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
                  project = "project",
                  git = "git"
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
              class = "ravel-chat-shell",
              shiny::div(
                class = "ravel-chat-topline",
                shiny::div(
                  shiny::div(class = "ravel-chat-title", "Conversation"),
                  shiny::div(
                    class = "ravel-chat-subtitle",
                    "Messages appear here. Type your next message in the composer below."
                  )
                ),
                shiny::uiOutput("chat_status")
              ),
              shiny::div(
                class = "ravel-context-shell",
                shiny::uiOutput("context_basis")
              ),
              shiny::div(
                id = "ravel-chat-scroll",
                class = "ravel-chat-log",
                shiny::uiOutput("conversation_ui")
              )
            ),
            shiny::div(
              class = "ravel-compose-shell",
              shiny::div(class = "ravel-chat-title", "Message"),
              shiny::div(
                class = "ravel-helper-text",
                "Send one message at a time. Ravel will keep the full conversation context."
              ),
              shiny::textAreaInput("prompt", NULL, rows = 5, width = "100%")
            ),
            shiny::fluidRow(
              shiny::column(
                width = 4,
                shiny::actionButton(
                  "send",
                  "Send To Ravel",
                  class = "btn-primary"
                )
              ),
              shiny::column(
                width = 4,
                shiny::actionButton("run_code", "Run Preview")
              ),
              shiny::column(
                width = 4,
                shiny::actionButton("insert_code", "Insert Preview")
              )
            ),
            shiny::div(
              class = "ravel-preview-shell",
              shiny::div(class = "ravel-preview-label", "Action Preview"),
              shiny::div(
                class = "ravel-preview-note",
                "Generated code or drafted content appears here before you run or insert anything."
              ),
              shiny::textAreaInput(
                "code_preview",
                NULL,
                value = "",
                rows = 10,
                width = "100%"
              )
            )
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    rv <- shiny::reactiveValues(
      messages = list(),
      pending_action = NULL,
      last_context = NULL,
      is_waiting = FALSE
    )
    context_refresh_nonce <- shiny::reactiveVal(0L)
    live_context <- shiny::reactive({
      input$context_sources
      input$code_preview
      rv$pending_action
      context_refresh_nonce()
      shiny::invalidateLater(1500, session)

      context <- ravel_collect_context_from_ui(input$context_sources)
      ravel_context_with_preview(
        context,
        pending_action = rv$pending_action,
        preview_text = input$code_preview
      )
    })

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

    output$conversation_ui <- shiny::renderUI({
      ravel_render_messages_ui(rv$messages, waiting = rv$is_waiting)
    })

    output$chat_status <- shiny::renderUI({
      if (isTRUE(rv$is_waiting)) {
        return(shiny::HTML(paste(
          "<div class='ravel-status-chip ravel-status-chip-waiting'>",
          "<span class='ravel-spinner' aria-hidden='true'></span>",
          "Ravel is thinking...",
          "</div>"
        )))
      }

      if (!length(rv$messages)) {
        return(shiny::HTML(
          "<div class='ravel-status-chip'>Ready for your first message.</div>"
        ))
      }

      if (!is.null(rv$pending_action)) {
        return(shiny::HTML(
          "<div class='ravel-status-chip'>A staged action is ready to review.</div>"
        ))
      }

      shiny::HTML("<div class='ravel-status-chip'>Ready for the next message.</div>")
    })

    output$context_basis <- shiny::renderUI({
      ravel_context_basis_html(live_context())
    })

    shiny::observe({
      rv$messages
      rv$is_waiting
      session$sendCustomMessage("ravel-scroll-chat", list(id = "ravel-chat-scroll"))
      shiny::updateActionButton(
        session,
        "send",
        label = if (isTRUE(rv$is_waiting)) "Waiting..." else "Send To Ravel"
      )
    })

    shiny::observe({
      rv$last_context <- live_context()
    })

    shiny::observeEvent(input$refresh_context, {
      context_refresh_nonce(context_refresh_nonce() + 1L)
      shiny::showNotification("Context refreshed.", type = "message")
    })

    shiny::observeEvent(input$clear_history, {
      rv$messages <- list()
      rv$pending_action <- NULL
      rv$is_waiting <- FALSE
      state <- ravel_runtime_state()
      state$chat_history <- list()
      ravel_set_runtime_state(state)
      shiny::updateTextAreaInput(session, "code_preview", value = "")
    })

    shiny::observeEvent(input$send, {
      if (isTRUE(rv$is_waiting)) {
        shiny::showNotification("Ravel is still working on the previous request.", type = "warning")
        return()
      }

      req_prompt <- trimws(input$prompt %||% "")
      if (!nzchar(req_prompt)) {
        shiny::showNotification("Enter a prompt first.", type = "warning")
        return()
      }

      history <- rv$messages
      user_message <- list(role = "user", content = req_prompt)
      provider_label <- ravel_get_provider(input$provider)$label
      thinking_id <- "ravel-thinking"

      rv$messages <- c(rv$messages, list(user_message))
      rv$is_waiting <- TRUE
      shiny::updateTextAreaInput(session, "prompt", value = "")
      shiny::showNotification(
        sprintf("Waiting for %s...", provider_label),
        id = thinking_id,
        duration = NULL,
        closeButton = FALSE,
        type = "message"
      )

      turn <- tryCatch(
        shiny::withProgress(
          message = sprintf("Waiting for %s", provider_label),
          detail = "Gathering context and sending your request.",
          value = 0.2,
          {
            context <- live_context()
            rv$last_context <- context
            shiny::incProgress(0.35, detail = "Provider request in flight.")
            result <- ravel_chat_turn(
              prompt = req_prompt,
              provider = input$provider,
              model = input$model,
              context = context,
              history = history
            )
            shiny::incProgress(0.45, detail = "Preparing the reply.")
            result
          }
        ),
        error = function(e) e
      )
      rv$is_waiting <- FALSE
      shiny::removeNotification(id = thinking_id)

      if (inherits(turn, "error")) {
        rv$messages <- c(
          rv$messages,
          list(list(
            role = "system",
            content = paste("Request failed:\n", conditionMessage(turn))
          ))
        )
        shiny::showNotification(conditionMessage(turn), type = "error", duration = NULL)
        return()
      }

      rv$messages <- c(rv$messages, list(turn$message))

      if (length(turn$actions)) {
        rv$pending_action <- turn$actions[[1]]
        preview_text <- turn$actions[[1]]$payload$code %||% turn$actions[[1]]$payload$text %||% ""
        shiny::updateTextAreaInput(session, "code_preview", value = preview_text)
      } else {
        rv$pending_action <- NULL
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

  shiny::runGadget(ui, server, viewer = ravel_gadget_viewer("chat"))
}

ravel_launch_settings_gadget <- function() {
  settings <- ravel_read_settings()
  providers <- ravel_list_providers()

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("Ravel Setup"),
    miniUI::miniContentPanel(
      shiny::tabsetPanel(
        id = "setup_tabs",
        shiny::tabPanel(
          "Overview",
          shiny::p(
            paste(
              "Ravel should be easy to install, easy to trust, and easy to recover",
              "when setup goes wrong."
            )
          ),
          shiny::fluidRow(
            shiny::column(
              width = 4,
              shiny::actionButton("refresh_status", "Refresh Checks")
            ),
            shiny::column(
              width = 4,
              shiny::actionButton("open_chat", "Open Chat", class = "btn-primary")
            )
          ),
          shiny::tags$br(),
          shiny::verbatimTextOutput("setup_summary"),
          shiny::tableOutput("doctor_table")
        ),
        shiny::tabPanel(
          "Provider Setup",
          shiny::selectInput(
            "provider",
            "Provider",
            choices = stats::setNames(providers$provider, providers$label),
            selected = settings$default_provider
          ),
          shiny::uiOutput("openai_mode_ui"),
          shiny::verbatimTextOutput("provider_status"),
          shiny::verbatimTextOutput("provider_actions"),
          shiny::uiOutput("credential_inputs"),
          shiny::checkboxInput(
            "persist",
            "Persist secrets with keyring when available",
            value = TRUE
          ),
          shiny::fluidRow(
            shiny::column(
              width = 4,
              shiny::actionButton("save_auth", "Save Credentials", class = "btn-primary")
            ),
            shiny::column(width = 4, shiny::actionButton("launch_login", "Launch Sign-In")),
            shiny::column(width = 4, shiny::actionButton("verify_provider", "Verify Connection"))
          ),
          shiny::tags$br(),
          shiny::fluidRow(
            shiny::column(width = 4, shiny::actionButton("open_docs", "Open Docs")),
            shiny::column(width = 4, shiny::actionButton("open_keys", "Open Key Page")),
            shiny::column(width = 4, shiny::actionButton("clear_auth", "Clear Stored Auth"))
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    refresh_counter <- shiny::reactiveVal(0L)

    refresh_status <- function() {
      refresh_counter(refresh_counter() + 1L)
    }

    provider_name <- shiny::reactive({
      input$provider %||% settings$default_provider %||% "openai"
    })

    doctor <- shiny::reactive({
      refresh_counter()
      ravel_doctor()
    })

    provider_info <- shiny::reactive({
      refresh_counter()
      ravel_provider_setup_info(provider_name())
    })

    output$setup_summary <- shiny::renderText({
      checks <- doctor()
      ready_providers <- vapply(ravel_ready_providers(), `[[`, character(1), "provider")

      if (length(ready_providers)) {
        paste(
          sprintf("Ready providers: %s.", paste(ready_providers, collapse = ", ")),
          "",
          "Open chat now, or keep configuring more providers while you are here.",
          "",
          sprintf("%d of %d checks are currently passing.", sum(checks$ok), nrow(checks)),
          sep = "\n"
        )
      } else {
        paste(
          "No provider is fully ready yet.",
          "",
          "Use the Provider Setup tab to sign in with OpenAI or Copilot,",
          "or save an API key for Gemini or Anthropic.",
          "",
          sprintf("%d of %d checks are currently passing.", sum(checks$ok), nrow(checks)),
          sep = "\n"
        )
      }
    })

    output$doctor_table <- shiny::renderTable({
      checks <- doctor()
      data.frame(
        Check = checks$check,
        Ready = ifelse(checks$ok, "yes", "no"),
        Detail = checks$detail,
        Fix = checks$fix,
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
    }, striped = TRUE, bordered = TRUE, spacing = "xs")

    output$openai_mode_ui <- shiny::renderUI({
      if (!identical(provider_name(), "openai")) {
        return(NULL)
      }

      shiny::selectInput(
        "openai_auth_mode",
        "OpenAI auth mode",
        choices = c(
          auto = "auto",
          api_key = "api_key",
          codex_cli = "codex_cli"
        ),
        selected = ravel_read_settings()$provider_auth_modes$openai %||% "auto"
      )
    })

    output$provider_status <- shiny::renderText({
      info <- provider_info()
      status <- info$auth
      paste(
        sprintf("Provider: %s", info$label),
        sprintf("Configured: %s", if (isTRUE(status$configured)) "yes" else "no"),
        sprintf("Available locally: %s", if (isTRUE(status$available)) "yes" else "no"),
        sprintf("Auth mode: %s", status$mode),
        status$detail,
        sep = "\n"
      )
    })

    output$provider_actions <- shiny::renderText({
      info <- provider_info()
      caps <- ravel_provider_capabilities(provider_name())
      lines <- c(
        sprintf("Supported auth modes: %s", paste(caps$auth_modes, collapse = ", ")),
        sprintf("Default model: %s", caps$default_model),
        if (!is.null(info$login$command)) sprintf("Login command: %s", info$login$command),
        if (!is.null(info$binary)) sprintf("Detected CLI: %s", info$binary),
        if (!is.null(info$docs_url)) sprintf("Docs: %s", info$docs_url),
        if (!is.null(info$api_keys_url)) sprintf("API keys / console: %s", info$api_keys_url)
      )
      paste(lines, collapse = "\n")
    })

    output$credential_inputs <- shiny::renderUI({
      switch(
        provider_name(),
        openai = shiny::tagList(
          shiny::passwordInput("openai_key", "OpenAI API key", value = ""),
          shiny::helpText(
            "Leave this blank if you prefer the official Codex CLI sign-in path.",
            paste(
              "The saved auth mode controls whether Ravel prefers API requests,",
              "Codex CLI, or auto fallback."
            )
          )
        ),
        gemini = shiny::tagList(
          shiny::passwordInput("gemini_key", "Gemini API key", value = ""),
          shiny::passwordInput("gemini_token", "Gemini bearer token", value = ""),
          shiny::helpText(
            "Use the API key for the simplest setup. Bearer token support is reserved",
            "for official OAuth-style flows."
          )
        ),
        anthropic = shiny::tagList(
          shiny::passwordInput("anthropic_key", "Anthropic API key", value = ""),
          shiny::helpText("Anthropic support is API-key only. Consumer Claude login is not used.")
        ),
        copilot = shiny::tagList(
          shiny::helpText(
            "Copilot uses the official Copilot CLI login flow or a supported GitHub token.",
            "No separate API key field is required here."
          )
        )
      )
    })

    shiny::observeEvent(input$refresh_status, {
      refresh_status()
      shiny::showNotification("Ravel readiness checks refreshed.", type = "message")
    })

    shiny::observeEvent(input$save_auth, {
      selected_provider <- provider_name()
      ravel_set_setting("default_provider", selected_provider)

      if (identical(selected_provider, "openai")) {
        modes <- ravel_get_setting("provider_auth_modes", default = list())
        modes$openai <- input$openai_auth_mode %||% "auto"
        ravel_set_setting("provider_auth_modes", modes)
      }

      if (nzchar(trimws(input$openai_key %||% ""))) {
        ravel_set_api_key("openai", trimws(input$openai_key), persist = input$persist)
      }
      if (nzchar(trimws(input$gemini_key %||% ""))) {
        ravel_set_api_key("gemini", trimws(input$gemini_key), persist = input$persist)
      }
      if (nzchar(trimws(input$gemini_token %||% ""))) {
        ravel_set_bearer_token("gemini", trimws(input$gemini_token), persist = input$persist)
      }
      if (nzchar(trimws(input$anthropic_key %||% ""))) {
        ravel_set_api_key("anthropic", trimws(input$anthropic_key), persist = input$persist)
      }

      refresh_status()
      shiny::showNotification("Ravel setup updated.", type = "message")
    })

    shiny::observeEvent(input$launch_login, {
      result <- tryCatch(
        {
          ravel_launch_login(provider_name(), mode = input$openai_auth_mode %||% NULL)
          NULL
        },
        error = function(e) e
      )

      if (inherits(result, "error")) {
        shiny::showNotification(conditionMessage(result), type = "error", duration = NULL)
      } else {
        shiny::showNotification(
          sprintf("Launched the official %s sign-in flow.", provider_info()$label),
          type = "message"
        )
      }
    })

    shiny::observeEvent(input$verify_provider, {
      verification <- ravel_verify_provider(provider_name())
      refresh_status()

      if (isTRUE(verification$ok)) {
        shiny::showNotification(
          sprintf("%s verified successfully.", provider_info()$label),
          type = "message"
        )
      } else {
        shiny::showNotification(
          paste("Provider verification failed:", verification$content),
          type = "error",
          duration = NULL
        )
      }
    })

    shiny::observeEvent(input$open_docs, {
      ravel_open_provider_page(provider_name(), "docs")
    })

    shiny::observeEvent(input$open_keys, {
      result <- tryCatch(
        {
          ravel_open_provider_page(provider_name(), "api_keys")
          NULL
        },
        error = function(e) e
      )
      if (inherits(result, "error")) {
        shiny::showNotification(conditionMessage(result), type = "error", duration = NULL)
      }
    })

    shiny::observeEvent(input$clear_auth, {
      ravel_logout(provider_name())
      refresh_status()
      shiny::showNotification(
        sprintf("Cleared stored auth for %s.", provider_name()),
        type = "message"
      )
    })

    shiny::observeEvent(input$open_chat, {
      if (!ravel_has_ready_provider()) {
        shiny::showNotification(
          "Finish at least one provider setup path before opening chat.",
          type = "warning"
        )
        return()
      }
      shiny::stopApp("chat")
    })

    shiny::observeEvent(input$done, {
      shiny::stopApp(invisible(NULL))
    })

    shiny::observeEvent(input$cancel, {
      shiny::stopApp(invisible(NULL))
    })
  }

  result <- shiny::runGadget(ui, server, viewer = ravel_gadget_viewer("settings"))
  if (identical(result, "chat")) {
    return(invisible(ravel_launch_chat_gadget()))
  }
  invisible(result)
}
