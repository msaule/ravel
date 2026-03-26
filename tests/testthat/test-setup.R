test_that("doctor reports the expected readiness checks", {
  report <- ravel_doctor()

  expect_s3_class(report, "tbl_df")
  expect_true(all(c("check", "ok", "detail", "fix") %in% names(report)))
  expect_true("At least one provider ready" %in% report$check)
})

test_that("provider setup info includes official URLs and login commands", {
  info <- ravel:::ravel_provider_setup_info("openai")

  expect_equal(info$provider, "openai")
  expect_match(info$docs_url, "openai", ignore.case = TRUE)
  expect_match(info$login$command %||% "", "codex", perl = TRUE)
})

test_that("provider verification reports success and failure clearly", {
  local_mocked_bindings(
    ravel_get_provider = function(provider = NULL) {
      list(
        name = provider %||% "openai",
        default_model = "test-model",
        chat = function(messages, context, model, settings) {
          list(content = "ravel_provider_ok", model = model)
        }
      )
    },
    ravel_read_settings = function() list()
  )

  ok <- ravel_verify_provider("openai")
  expect_true(ok$ok)
  expect_equal(ok$content, "ravel_provider_ok")

  local_mocked_bindings(
    ravel_get_provider = function(provider = NULL) {
      list(
        name = provider %||% "openai",
        default_model = "test-model",
        chat = function(messages, context, model, settings) {
          stop("authentication failed")
        }
      )
    },
    ravel_read_settings = function() list()
  )

  bad <- ravel_verify_provider("openai")
  expect_false(bad$ok)
  expect_match(bad$content, "authentication failed", fixed = TRUE)
})
