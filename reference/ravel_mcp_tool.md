# Declare a remote MCP tool for OpenAI Responses API calls

Declare a remote MCP tool for OpenAI Responses API calls

## Usage

``` r
ravel_mcp_tool(
  server_label,
  server_url,
  allowed_tools = NULL,
  require_approval = c("always", "never")
)
```

## Arguments

- server_label:

  Short label for the MCP server.

- server_url:

  HTTPS URL for the remote MCP server.

- allowed_tools:

  Optional character vector limiting exposed MCP tools.

- require_approval:

  Approval policy sent to providers that support it. Ravel defaults to
  `"always"` so remote MCP calls stay approval-gated unless the user
  explicitly chooses a looser provider-side policy.

## Value

A provider-ready MCP tool definition.
