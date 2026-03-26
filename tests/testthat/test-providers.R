test_that("provider registry exposes expected adapters", {
  providers <- ravel_list_providers()

  expect_setequal(
    providers$provider,
    c("openai", "copilot", "gemini", "anthropic")
  )

  caps <- ravel_provider_capabilities("openai")
  expect_true("api_key" %in% caps$auth_modes)
  expect_true(caps$supports_model_selection)
})

test_that("response parsing stages executable code", {
  reset_ravel_test_state()
  actions <- ravel:::ravel_response_to_actions("Try this:\n```r\n1 + 1\n```")

  expect_length(actions, 1L)
  expect_s3_class(actions[[1]], "ravel_action")
  expect_equal(actions[[1]]$type, "run_code")
})
