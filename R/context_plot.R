ravel_plot_context <- function() {
  cur <- grDevices::dev.cur()
  if (identical(names(cur), "null device")) {
    return(list(has_plot = FALSE))
  }

  params <- tryCatch(graphics::par(c("mfrow", "mar", "xlog", "ylog")), error = function(e) NULL)
  list(
    has_plot = TRUE,
    device = names(cur),
    device_index = unname(cur),
    parameters = params
  )
}
