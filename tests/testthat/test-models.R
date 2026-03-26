test_that("model helpers summarize and interpret lm objects", {
  model <- stats::lm(mpg ~ wt * am, data = mtcars)
  summary <- ravel_summarize_model(model)
  interpretation <- ravel_interpret_model(model)
  diagnostics <- ravel_suggest_diagnostics(model)

  expect_true("coefficients" %in% names(summary))
  expect_true("fit" %in% names(summary))
  expect_true(grepl("R-squared", interpretation, fixed = TRUE))
  expect_true(any(grepl("Interaction terms are present", interpretation, fixed = TRUE)))
  expect_gte(length(diagnostics), 3L)
})
