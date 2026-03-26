test_that("session-scoped secrets affect auth status", {
  on.exit(ravel_logout("anthropic"), add = TRUE)
  ravel_set_api_key("anthropic", "test-key", persist = FALSE)

  status <- ravel_auth_status("anthropic")
  expect_true(status$configured)
  expect_equal(status$mode, "api_key")
})
