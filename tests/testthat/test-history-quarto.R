test_that("executed actions are written to history", {
  reset_ravel_test_state()
  action <- ravel_preview_code("1 + 1")
  action <- ravel_approve_action(action)

  ravel_run_code(action, envir = new.env(parent = baseenv()))
  history <- ravel_read_history()

  expect_gte(nrow(history), 1L)
  expect_true("type" %in% names(history))
})

test_that("quarto drafting returns a section header and chunk", {
  text <- ravel_draft_quarto_section(
    section = "diagnostics",
    model = stats::lm(mpg ~ wt, data = mtcars),
    include_chunk = TRUE
  )

  expect_true(grepl("^## Diagnostics", text))
  expect_true(grepl("```\\{r diagnostics\\}", text))
  expect_true(grepl("Suggested checks:", text, fixed = TRUE))
})
