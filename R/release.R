release_questions <- function() {
  c(
    "Have you rerun live provider validation if auth or provider behavior changed?",
    "Have you updated README.md, NEWS.md, and cran-comments.md for this release?",
    paste(
      "If you are releasing to CRAN, have you checked that provider claims stay within",
      "official auth and API boundaries?"
    )
  )
}
