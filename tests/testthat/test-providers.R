test_that("provider registry exposes expected adapters", {
  providers <- ravel_list_providers()

  expect_setequal(
    providers$provider,
    c("openai", "copilot", "gemini", "anthropic")
  )

  caps <- ravel_provider_capabilities("openai")
  expect_true("api_key" %in% caps$auth_modes)
  expect_true(caps$supports_model_selection)
  expect_true(isTRUE(caps$capabilities$responses_api))
  expect_true(isTRUE(caps$capabilities$remote_mcp))
})

test_that("response parsing stages executable code", {
  reset_ravel_test_state()
  actions <- ravel:::ravel_response_to_actions("Try this:\n```r\n1 + 1\n```")

  expect_length(actions, 1L)
  expect_s3_class(actions[[1]], "ravel_action")
  expect_equal(actions[[1]]$type, "run_code")
})

test_that("OpenAI Responses API helpers normalize MCP tools", {
  tool <- ravel_mcp_tool(
    server_label = "analysis",
    server_url = "https://example.com/mcp",
    allowed_tools = c("summarize_model")
  )

  expect_equal(tool$type, "mcp")
  expect_equal(tool$require_approval, "always")
  expect_equal(ravel_mcp_tools(tool), list(tool))

  input <- ravel:::ravel_openai_responses_input(list(
    list(role = "user", content = "hello")
  ))
  expect_equal(input, "USER: hello")

  text <- ravel:::ravel_openai_resp_text(list(
    output = list(list(
      content = list(list(type = "output_text", text = "ok"))
    ))
  ))
  expect_equal(text, "ok")
})
