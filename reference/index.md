# Package index

## Addins and setup

- [`ravel_chat_addin()`](https://msaule.github.io/ravel/reference/ravel_chat_addin.md)
  : Launch the Ravel chat addin
- [`ravel_settings_addin()`](https://msaule.github.io/ravel/reference/ravel_settings_addin.md)
  : Launch the Ravel settings addin
- [`ravel_setup_addin()`](https://msaule.github.io/ravel/reference/ravel_setup_addin.md)
  : Launch the Ravel setup assistant
- [`ravel_doctor()`](https://msaule.github.io/ravel/reference/ravel_doctor.md)
  : Inspect local Ravel readiness
- [`ravel_verify_provider()`](https://msaule.github.io/ravel/reference/ravel_verify_provider.md)
  : Verify a provider with a tiny live prompt

## Context and orchestration

- [`ravel_collect_context()`](https://msaule.github.io/ravel/reference/ravel_collect_context.md)
  : Collect context for a Ravel chat turn
- [`ravel_chat_turn()`](https://msaule.github.io/ravel/reference/ravel_chat_turn.md)
  : Run one chat turn through a provider
- [`ravel_list_project_files()`](https://msaule.github.io/ravel/reference/ravel_list_project_files.md)
  : List project files for context gathering
- [`ravel_list_providers()`](https://msaule.github.io/ravel/reference/ravel_list_providers.md)
  : List configured providers
- [`ravel_provider_capabilities()`](https://msaule.github.io/ravel/reference/ravel_provider_capabilities.md)
  : Report provider capabilities
- [`ravel_read_history()`](https://msaule.github.io/ravel/reference/ravel_read_history.md)
  : Read recent Ravel history entries

## Auth and settings

- [`ravel_auth_status()`](https://msaule.github.io/ravel/reference/ravel_auth_status.md)
  : Report provider auth status
- [`ravel_login()`](https://msaule.github.io/ravel/reference/ravel_login.md)
  : Start a provider login flow
- [`ravel_logout()`](https://msaule.github.io/ravel/reference/ravel_logout.md)
  : Logout a provider from Ravel-managed credentials
- [`ravel_launch_login()`](https://msaule.github.io/ravel/reference/ravel_launch_login.md)
  : Launch an official provider login flow
- [`ravel_open_provider_page()`](https://msaule.github.io/ravel/reference/ravel_open_provider_page.md)
  : Open an official provider documentation or key-management page
- [`ravel_set_api_key()`](https://msaule.github.io/ravel/reference/ravel_set_api_key.md)
  : Store an API key for a provider
- [`ravel_set_bearer_token()`](https://msaule.github.io/ravel/reference/ravel_set_bearer_token.md)
  : Store a bearer token for a provider
- [`ravel_get_setting()`](https://msaule.github.io/ravel/reference/ravel_get_setting.md)
  : Get a Ravel setting
- [`ravel_set_setting()`](https://msaule.github.io/ravel/reference/ravel_set_setting.md)
  : Set a Ravel setting

## Safe actions and analysis helpers

- [`ravel_preview_code()`](https://msaule.github.io/ravel/reference/ravel_preview_code.md)
  : Preview generated code as a staged action
- [`ravel_run_code()`](https://msaule.github.io/ravel/reference/ravel_run_code.md)
  : Run R code with explicit approval semantics
- [`ravel_apply_action()`](https://msaule.github.io/ravel/reference/ravel_apply_action.md)
  : Execute a staged action
- [`ravel_stage_file_write()`](https://msaule.github.io/ravel/reference/ravel_stage_file_write.md)
  : Stage a file write action
- [`ravel_approve_action()`](https://msaule.github.io/ravel/reference/ravel_approve_action.md)
  : Approve a staged action
- [`ravel_reject_action()`](https://msaule.github.io/ravel/reference/ravel_reject_action.md)
  : Reject a staged action
- [`ravel_summarize_object()`](https://msaule.github.io/ravel/reference/ravel_summarize_object.md)
  : Summarize an R object for provider context
- [`ravel_summarize_model()`](https://msaule.github.io/ravel/reference/ravel_summarize_model.md)
  : Summarize a model object
- [`ravel_interpret_model()`](https://msaule.github.io/ravel/reference/ravel_interpret_model.md)
  : Interpret a model in plain English
- [`ravel_suggest_diagnostics()`](https://msaule.github.io/ravel/reference/ravel_suggest_diagnostics.md)
  : Suggest diagnostics for a model
- [`ravel_draft_quarto_section()`](https://msaule.github.io/ravel/reference/ravel_draft_quarto_section.md)
  : Draft a Quarto section from analysis context

## Developer internals

- [`ravel_new_action()`](https://msaule.github.io/ravel/reference/ravel_new_action.md)
  : Create a new staged Ravel action
