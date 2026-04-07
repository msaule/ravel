# Ravel Showcase Workflows

## Why this package exists

Ravel is meant to feel closer to an analysis copilot than a generic chat
box. The point is not just to answer a question about R syntax. The
point is to reason with the current script, the selected code, the
loaded objects, the models already in memory, the surrounding project,
and the reporting workflow.

## Workflow 1: diagnose a model that technically runs but feels wrong

Imagine you just fit a model and the output looks suspicious.
Coefficients are huge, standard errors are unstable, or the interaction
terms are hard to explain.

``` r
fit <- lm(mpg ~ wt * am, data = mtcars)
ravel::ravel_summarize_model(fit)
#> $name
#> [1] "fit"
#> 
#> $class
#> [1] "lm"
#> 
#> $formula
#> [1] "mpg ~ wt * am"
#> 
#> $fit
#> $fit$n
#> [1] 32
#> 
#> $fit$aic
#> [1] 157.476
#> 
#> $fit$bic
#> [1] 164.8046
#> 
#> $fit$r_squared
#> [1] 0.8330375
#> 
#> $fit$adj_r_squared
#> [1] 0.8151486
#> 
#> $fit$sigma
#> [1] 2.591247
#> 
#> 
#> $coefficients
#> # A tibble: 4 × 5
#>   term        estimate std_error statistic  p_value
#>   <chr>          <dbl>     <dbl>     <dbl>    <dbl>
#> 1 (Intercept)    31.4      3.02      10.4  4.00e-11
#> 2 wt             -3.79     0.786     -4.82 4.55e- 5
#> 3 am             14.9      4.26       3.49 1.62e- 3
#> 4 wt:am          -5.30     1.44      -3.67 1.02e- 3
```

Ravel is designed for prompts like:

> Explain this model in plain English, tell me how the interaction
> changes the interpretation of the main effects, and list the next
> diagnostics I should run before I trust it.

``` r
cat(ravel::ravel_interpret_model(fit))
#> Model type: lm.
#> Formula: mpg ~ wt * am.
#> The model explains about 83.3% of the observed variance (R-squared = 0.833).
#> Term `am` has a positive association (estimate = 14.878) with statistical evidence at the 0.05 level.
#> Term `wt:am` has a negative association (estimate = -5.298) with statistical evidence at the 0.05 level.
#> Term `wt` has a negative association (estimate = -3.786) with statistical evidence at the 0.05 level.
#> Interaction terms are present (wt:am), so main effects should be interpreted conditionally.
```

``` r
ravel::ravel_suggest_diagnostics(fit)
#> [1] "Inspect residuals versus fitted values for non-linearity and heteroskedasticity."   
#> [2] "Review a Q-Q plot of residuals for heavy tails or strong departures from normality."
#> [3] "Check leverage and Cook's distance for influential observations."                   
#> [4] "Consider multicollinearity diagnostics if predictors are strongly related."
```

## Workflow 2: turn analysis output into Quarto writing

Once you already have a fitted object, the next bottleneck is often
writing. Ravel can help scaffold methods, results, and diagnostics
sections without leaving the IDE.

``` r
cat(ravel::ravel_draft_quarto_section("results", model = fit))
```

    #> ## Results
    #> 
    #> ```{r results}
    #> # Fit or summarize the final model here
    #> ```
    #> 
    #> Model type: lm.
    #> Formula: mpg ~ wt * am.
    #> The model explains about 83.3% of the observed variance (R-squared = 0.833).
    #> Term `am` has a positive association (estimate = 14.878) with statistical evidence at the 0.05 level.
    #> Term `wt:am` has a negative association (estimate = -5.298) with statistical evidence at the 0.05 level.
    #> Term `wt` has a negative association (estimate = -3.786) with statistical evidence at the 0.05 level.
    #> Interaction terms are present (wt:am), so main effects should be interpreted conditionally.

For a more diagnostics-heavy turn:

> Draft a Quarto diagnostics section for this model, summarize the main
> caveats, and include a chunk for the checks I should run next.

``` r
cat(ravel::ravel_draft_quarto_section("diagnostics", model = fit))
```

    #> ## Diagnostics
    #> 
    #> ```{r diagnostics}
    #> # Produce diagnostic plots or checks here
    #> ```
    #> 
    #> Model type: lm.
    #> Formula: mpg ~ wt * am.
    #> The model explains about 83.3% of the observed variance (R-squared = 0.833).
    #> Term `am` has a positive association (estimate = 14.878) with statistical evidence at the 0.05 level.
    #> Term `wt:am` has a negative association (estimate = -5.298) with statistical evidence at the 0.05 level.
    #> Term `wt` has a negative association (estimate = -3.786) with statistical evidence at the 0.05 level.
    #> Interaction terms are present (wt:am), so main effects should be interpreted conditionally.
    #> 
    #> Suggested checks:
    #> - Inspect residuals versus fitted values for non-linearity and heteroskedasticity.
    #> - Review a Q-Q plot of residuals for heavy tails or strong departures from normality.
    #> - Check leverage and Cook's distance for influential observations.
    #> - Consider multicollinearity diagnostics if predictors are strongly related.

## Workflow 3: ask for a safe code change instead of blindly running it

Ravel stages actions before execution, which matters for analysis work
where a small change can silently alter results.

``` r
action <- ravel::ravel_preview_code("
summary(mtcars$mpg)
quantile(mtcars$mpg)
")
action$label
#> [1] "Run generated R code"
```

You can then approve and run it explicitly:

``` r
approved <- ravel::ravel_approve_action(action)
ravel::ravel_run_code(approved)
#> $success
#> [1] TRUE
#> 
#> $output
#> [1] "   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. "
#> [2] "  10.40   15.43   19.20   20.09   22.80   33.90 "
#> [3] "    0%    25%    50%    75%   100% "             
#> [4] "10.400 15.425 19.200 22.800 33.900 "             
#> 
#> $warnings
#> character(0)
#> 
#> $messages
#> character(0)
#> 
#> $value
#>     0%    25%    50%    75%   100% 
#> 10.400 15.425 19.200 22.800 33.900 
#> 
#> $error
#> NULL
```

## Workflow 4: use object-aware context instead of re-explaining everything

When Ravel inspects the current session, it can summarize data frames,
models, formulas, and other objects directly.

``` r
analysis_objects <- list(
  data = mtcars,
  formula = mpg ~ wt * am,
  model = fit
)

lapply(analysis_objects, ravel::ravel_summarize_object)
#> $data
#> $data$name
#> [1] "X[[i]]"
#> 
#> $data$kind
#> [1] "data.frame"
#> 
#> $data$class
#> [1] "data.frame"
#> 
#> $data$rows
#> [1] 32
#> 
#> $data$cols
#> [1] 11
#> 
#> $data$columns
#>  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
#> [11] "carb"
#> 
#> $data$column_types
#>  [1] "numeric" "numeric" "numeric" "numeric" "numeric" "numeric" "numeric"
#>  [8] "numeric" "numeric" "numeric" "numeric"
#> 
#> $data$preview
#> [1] "               mpg cyl disp  hp drat    wt  qsec vs am gear carb\nMazda RX4     21.0   6  160 110 3.90 2.620 16.46  0  1    4    4\nMazda RX4 Wag 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4\nDatsun 710    22.8   4  108  93 3.85 2.320 18.61  1  1    4    1"
#> 
#> 
#> $formula
#> $formula$name
#> [1] "X[[i]]"
#> 
#> $formula$kind
#> [1] "formula"
#> 
#> $formula$class
#> [1] "formula"
#> 
#> $formula$formula
#> [1] "mpg ~ wt * am"
#> 
#> 
#> $model
#> $model$name
#> [1] "X[[i]]"
#> 
#> $model$class
#> [1] "lm"
#> 
#> $model$formula
#> [1] "mpg ~ wt * am"
#> 
#> $model$fit
#> $model$fit$n
#> [1] 32
#> 
#> $model$fit$aic
#> [1] 157.476
#> 
#> $model$fit$bic
#> [1] 164.8046
#> 
#> $model$fit$r_squared
#> [1] 0.8330375
#> 
#> $model$fit$adj_r_squared
#> [1] 0.8151486
#> 
#> $model$fit$sigma
#> [1] 2.591247
#> 
#> 
#> $model$coefficients
#> # A tibble: 4 × 5
#>   term        estimate std_error statistic  p_value
#>   <chr>          <dbl>     <dbl>     <dbl>    <dbl>
#> 1 (Intercept)    31.4      3.02      10.4  4.00e-11
#> 2 wt             -3.79     0.786     -4.82 4.55e- 5
#> 3 am             14.9      4.26       3.49 1.62e- 3
#> 4 wt:am          -5.30     1.44      -3.67 1.02e- 3
#> 
#> $model$kind
#> [1] "model"
```

This enables prompts like:

> Summarize the objects I have loaded, tell me which one looks like the
> main modeling artifact, and propose the next analysis step.

## Workflow 5: review analytical code, not just syntax

Ravel is also designed for prompts that depend on the active editor and
project-level context:

> Use the selected code and the current project context to tell me
> whether this refactor changes results or just changes style.

> Summarize the latest analysis diff and tell me what I should validate
> before I merge it.

> Convert this selected tidyverse pipeline to base R, but keep it
> readable and consistent with the rest of the file.

These are exactly the kinds of tasks where a project-aware assistant
feels different from a plain browser chat.

## Workflow 6: start inside RStudio

The intended flow is:

``` r
install.packages("ravel")
library(ravel)
ravel::ravel_setup_addin()
ravel::ravel_chat_addin()
```

Once the addin is open, Ravel can answer questions like:

- Why did this join fail with the currently loaded objects?
- Explain these coefficients as if I had to present them.
- Draft a results paragraph from the model I just fit.
- Suggest diagnostics for this glm() before I report it.
- Turn this selected code into a safer, simpler version.

## What the package is aiming for

The long-term goal is not to mimic a chat website inside RStudio. It is
to make RStudio feel like it has an analysis-aware copilot that
understands:

- code
- context
- models
- diagnostics
- git state
- reproducible writing
- safe execution

That is the difference Ravel is trying to push.
