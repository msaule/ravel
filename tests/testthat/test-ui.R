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
