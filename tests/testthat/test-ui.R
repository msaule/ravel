test_that("message headings include provider and model details when available", {
  heading <- ravel:::ravel_message_heading(list(
    role = "assistant",
    provider = "openai",
    model = "gpt-5.4"
  ))

  expect_equal(heading, "Ravel | openai | gpt-5.4")
})

test_that("message UI renders waiting state and content clearly", {
  ui <- ravel:::ravel_render_messages_ui(
    list(list(role = "user", content = "Explain this model.")),
    waiting = TRUE
  )

  html <- as.character(ui)
  expect_match(html, "Explain this model\\.", perl = TRUE)
  expect_match(html, "Waiting for a response\\.\\.\\.", perl = TRUE)
  expect_match(html, "ravel-message-user", perl = TRUE)
})

test_that("context basis explains editor and workspace together", {
  html <- as.character(ravel:::ravel_context_basis_html(list(
    document = list(
      path = "C:/outside/analysis.R",
      name = "analysis.R",
      within_workspace_root = FALSE,
      sibling_files = c("helper.R", "notes.qmd")
    ),
    project = list(
      root = "C:/workspace",
      working_directory = "C:/workspace"
    ),
    preview = list(
      has_staged_preview = TRUE
    ),
    activity = list(
      recent_actions = list(list(id = "action_1"))
    )
  )))

  expect_match(html, "Active editor", fixed = TRUE)
  expect_match(html, "Workspace root", fixed = TRUE)
  expect_match(html, "outside the workspace root", fixed = TRUE)
  expect_match(html, "action preview", fixed = TRUE)
  expect_match(html, "Recent Ravel actions", fixed = TRUE)
})
