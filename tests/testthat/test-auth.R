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

test_that("Codex binary lookup falls back to the VS Code extension install", {
  home <- tempfile("ravel-home-")
  binary_dir <- file.path(
    home,
    ".vscode",
    "extensions",
    "openai.chatgpt-99.0.0-win32-x64",
    "bin",
    "windows-x86_64"
  )
  dir.create(binary_dir, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(binary_dir, "codex.exe"))

  old_home <- Sys.getenv("HOME", unset = NA_character_)
  old_userprofile <- Sys.getenv("USERPROFILE", unset = NA_character_)
  old_path <- Sys.getenv("PATH", unset = NA_character_)
  on.exit({
    if (is.na(old_home)) Sys.unsetenv("HOME") else Sys.setenv(HOME = old_home)
    if (is.na(old_userprofile)) {
      Sys.unsetenv("USERPROFILE")
    } else {
      Sys.setenv(USERPROFILE = old_userprofile)
    }
    if (is.na(old_path)) Sys.unsetenv("PATH") else Sys.setenv(PATH = old_path)
  }, add = TRUE)

  Sys.setenv(HOME = home, USERPROFILE = home, PATH = "")

  binary <- ravel:::ravel_codex_binary()
  expect_true(nzchar(binary))
  expect_match(basename(binary), "codex(\\.exe)?$", perl = TRUE)

  login <- ravel_login("openai", "codex_cli")
  expect_match(login$command, "codex", perl = TRUE)
  expect_false(identical(login$command, "codex login"))
})
