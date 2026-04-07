# Ravel MVP Walkthrough

## What Ravel is

Ravel is an RStudio-native analytics copilot for R users. The MVP
focuses on:

- context-aware chat orchestration
- provider abstraction
- safe code staging and execution
- model interpretation helpers
- Quarto drafting helpers

## Provider support

``` r
ravel::ravel_list_providers()
#> # A tibble: 4 × 4
#>   provider  label          auth_modes default_model           
#>   <chr>     <chr>          <I<list>>  <chr>                   
#> 1 openai    OpenAI         <chr [2]>  gpt-5.3-codex           
#> 2 copilot   GitHub Copilot <chr [2]>  copilot-cli             
#> 3 gemini    Gemini         <chr [2]>  gemini-2.5-pro          
#> 4 anthropic Anthropic      <chr [1]>  claude-sonnet-4-20250514
```

The provider layer keeps auth and capability boundaries explicit.
OpenAI, Gemini, and Anthropic can run over official HTTP APIs. GitHub
Copilot is kept behind the official `gh copilot` CLI surface when
available.

## Analysis-aware helpers

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

## Safe execution

``` r
action <- ravel::ravel_preview_code("summary(mtcars$mpg)")
approved <- ravel::ravel_approve_action(action)
ravel::ravel_run_code(approved)
#> $success
#> [1] TRUE
#> 
#> $output
#> [1] "   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. "
#> [2] "  10.40   15.43   19.20   20.09   22.80   33.90 "
#> 
#> $warnings
#> character(0)
#> 
#> $messages
#> character(0)
#> 
#> $value
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   10.40   15.43   19.20   20.09   22.80   33.90 
#> 
#> $error
#> NULL
```

## Quarto drafting

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

## RStudio addin

After installation, launch the chat gadget with:

``` r
ravel::ravel_chat_addin()
```

Use the settings gadget to configure default providers or store API
keys:

``` r
ravel::ravel_settings_addin()
```
