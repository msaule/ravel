ravel_model_formula_text <- function(model) {
  formula_obj <- tryCatch(stats::formula(model), error = function(e) NULL)
  if (is.null(formula_obj)) {
    return(NULL)
  }
  paste(base::deparse(formula_obj), collapse = " ")
}

ravel_model_coefficients <- function(model) {
  summary_obj <- tryCatch(summary(model), error = function(e) NULL)
  coeffs <- summary_obj$coefficients %||% NULL
  if (is.null(coeffs)) {
    return(tibble::tibble())
  }

  coeffs <- as.data.frame(coeffs, stringsAsFactors = FALSE)
  names(coeffs) <- make.names(names(coeffs))
  tibble::tibble(
    term = rownames(coeffs),
    estimate = coeffs$Estimate %||% NA_real_,
    std_error = coeffs$Std..Error %||% NA_real_,
    statistic = coeffs[[3]] %||% NA_real_,
    p_value = coeffs[[4]] %||% NA_real_
  )
}

ravel_model_fit_stats <- function(model) {
  summary_obj <- tryCatch(summary(model), error = function(e) NULL)
  out <- list(
    n = tryCatch(stats::nobs(model), error = function(e) NA_integer_),
    aic = tryCatch(stats::AIC(model), error = function(e) NA_real_),
    bic = tryCatch(stats::BIC(model), error = function(e) NA_real_)
  )

  if (inherits(model, "lm")) {
    out$r_squared <- summary_obj$r.squared %||% NA_real_
    out$adj_r_squared <- summary_obj$adj.r.squared %||% NA_real_
    out$sigma <- summary_obj$sigma %||% NA_real_
  }

  if (inherits(model, "glm")) {
    out$family <- model$family$family %||% NULL
    out$link <- model$family$link %||% NULL
    out$deviance <- model$deviance %||% NA_real_
    out$null_deviance <- model$null.deviance %||% NA_real_
  }

  out
}

#' Summarize a model object
#'
#' @param model A fitted model object.
#' @param name Optional object name.
#'
#' @return A named list with model metadata and coefficient summaries.
#' @export
ravel_summarize_model <- function(model, name = NULL) {
  coeffs <- ravel_model_coefficients(model)
  list(
    name = name %||% deparse(substitute(model)),
    class = class(model),
    formula = ravel_model_formula_text(model),
    fit = ravel_model_fit_stats(model),
    coefficients = coeffs
  )
}

#' Interpret a model in plain English
#'
#' @param model A fitted model object.
#'
#' @return A character string.
#' @export
ravel_interpret_model <- function(model) {
  summary <- ravel_summarize_model(model)
  coeffs <- summary$coefficients
  coeffs <- coeffs[coeffs$term != "(Intercept)", , drop = FALSE]

  lines <- character()
  model_class <- summary$class[[1]] %||% "model"
  lines <- c(lines, sprintf("Model type: %s.", model_class))

  if (!is.null(summary$formula)) {
    lines <- c(lines, sprintf("Formula: %s.", summary$formula))
  }

  if (inherits(model, "lm") && !is.na(summary$fit$r_squared)) {
    lines <- c(
      lines,
      sprintf(
        "The model explains about %.1f%% of the observed variance (R-squared = %.3f).",
        100 * summary$fit$r_squared,
        summary$fit$r_squared
      )
    )
  }

  if (inherits(model, "glm")) {
    lines <- c(
      lines,
      sprintf(
        "This is a %s model with a %s link.",
        summary$fit$family %||% "GLM",
        summary$fit$link %||% "default"
      )
    )
  }

  if (nrow(coeffs)) {
    ranked <- coeffs[order(abs(coeffs$estimate), decreasing = TRUE), , drop = FALSE]
    ranked <- utils::head(ranked, 3L)
    for (i in seq_len(nrow(ranked))) {
      direction <- if (isTRUE(ranked$estimate[i] >= 0)) "positive" else "negative"
      sig <- if (!is.na(ranked$p_value[i]) && ranked$p_value[i] < 0.05) {
        "with statistical evidence at the 0.05 level"
      } else {
        "with limited statistical evidence at the 0.05 level"
      }
      lines <- c(
        lines,
        sprintf(
          "Term `%s` has a %s association (estimate = %.3f) %s.",
          ranked$term[i],
          direction,
          ranked$estimate[i],
          sig
        )
      )
    }
  }

  interactions <- coeffs$term[grepl(":", coeffs$term, fixed = TRUE)]
  if (length(interactions)) {
    lines <- c(
      lines,
      sprintf(
        "Interaction terms are present (%s), so main effects should be interpreted conditionally.",
        paste(interactions, collapse = ", ")
      )
    )
  }

  paste(lines, collapse = "\n")
}

#' Suggest diagnostics for a model
#'
#' @param model A fitted model object.
#'
#' @return A character vector of suggested checks.
#' @export
ravel_suggest_diagnostics <- function(model) {
  if (inherits(model, "lm")) {
    return(c(
      "Inspect residuals versus fitted values for non-linearity and heteroskedasticity.",
      "Review a Q-Q plot of residuals for heavy tails or strong departures from normality.",
      "Check leverage and Cook's distance for influential observations.",
      "Consider multicollinearity diagnostics if predictors are strongly related."
    ))
  }

  if (inherits(model, "glm")) {
    return(c(
      "Inspect deviance or Pearson residuals for systematic patterns.",
      "Check influential observations and leverage diagnostics.",
      "Review calibration and separation issues for binomial models.",
      "Consider overdispersion checks for count models."
    ))
  }

  c(
    "Review residual behavior and influential observations.",
    "Check whether model assumptions match the data-generating process.",
    "Consider out-of-sample validation where possible."
  )
}
