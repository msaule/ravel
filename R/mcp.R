#' Declare a remote MCP tool for OpenAI Responses API calls
#'
#' @param server_label Short label for the MCP server.
#' @param server_url HTTPS URL for the remote MCP server.
#' @param allowed_tools Optional character vector limiting exposed MCP tools.
#' @param require_approval Approval policy sent to providers that support it.
#'   Ravel defaults to `"always"` so remote MCP calls stay approval-gated unless
#'   the user explicitly chooses a looser provider-side policy.
#'
#' @return A provider-ready MCP tool definition.
#' @export
ravel_mcp_tool <- function(server_label,
                           server_url,
                           allowed_tools = NULL,
                           require_approval = c("always", "never")) {
  require_approval <- match.arg(require_approval)
  stopifnot(is.character(server_label), length(server_label) == 1L, nzchar(server_label))
  stopifnot(is.character(server_url), length(server_url) == 1L, nzchar(server_url))

  tool <- list(
    type = "mcp",
    server_label = server_label,
    server_url = server_url,
    require_approval = require_approval
  )

  if (!is.null(allowed_tools)) {
    stopifnot(is.character(allowed_tools))
    tool$allowed_tools <- allowed_tools
  }

  tool
}

#' Normalize MCP tool definitions for provider requests
#'
#' @param tools A list of MCP tool definitions created by `ravel_mcp_tool()`.
#'
#' @return A list suitable for provider payloads.
#' @export
ravel_mcp_tools <- function(tools = list()) {
  if (is.null(tools) || !length(tools)) {
    return(list())
  }

  if (is.list(tools) && identical(tools$type %||% NULL, "mcp")) {
    tools <- list(tools)
  }

  lapply(tools, function(tool) {
    if (!is.list(tool) || !identical(tool$type %||% NULL, "mcp")) {
      cli::cli_abort("MCP tools must be created with {.fun ravel_mcp_tool}.")
    }
    tool
  })
}
