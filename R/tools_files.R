ravel_project_root <- function() {
  if (rstudioapi::isAvailable() && rstudioapi::hasFun("getActiveProject")) {
    project <- tryCatch(rstudioapi::getActiveProject(), error = function(e) NULL)
    if (!is.null(project) && nzchar(project)) {
      return(project)
    }
  }
  getwd()
}

#' List project files for context gathering
#'
#' @param root Optional project root.
#' @param limit Maximum number of file paths to return.
#'
#' @return A character vector of relative paths.
#' @export
ravel_list_project_files <- function(root = NULL, limit = 200L) {
  root <- root %||% ravel_project_root()
  files <- list.files(
    root,
    recursive = TRUE,
    all.files = FALSE,
    full.names = FALSE,
    no.. = TRUE
  )
  files <- files[!grepl("^(\\.git|renv|packrat|node_modules|check)(/|\\\\|$)", files)]
  utils::head(files, limit)
}

ravel_write_file_text <- function(path, text, append = FALSE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (append && file.exists(path)) {
    write(text, file = path, append = TRUE)
  } else {
    writeLines(text, con = path, useBytes = TRUE)
  }
  invisible(path)
}
