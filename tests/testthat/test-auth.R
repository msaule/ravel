test_that("session-scoped secrets affect auth status", {
  on.exit(ravel_logout("anthropic"), add = TRUE)
  ravel_set_api_key("anthropic", "test-key", persist = FALSE)

  status <- ravel_auth_status("anthropic")
  expect_true(status$configured)
  expect_equal(status$mode, "api_key")
})

test_that("OpenAI auth mode selection honors settings and availability", {
  settings <- list(provider_auth_modes = list(openai = "auto"))
  expect_equal(ravel:::ravel_openai_auth_mode(settings, TRUE, FALSE), "api_key")
  expect_equal(ravel:::ravel_openai_auth_mode(settings, FALSE, TRUE), "codex_cli")

  settings$provider_auth_modes$openai <- "codex_cli"
  expect_equal(ravel:::ravel_openai_auth_mode(settings, TRUE, TRUE), "codex_cli")
})
