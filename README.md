
<!-- README.md is generated from README.Rmd. Please edit that file -->

# FootballStanVsTMB

This repository compares Stan and TMB for modeling of football results.

Stan is a state-of-the-art platform for statistical modeling and
high-performance statistical computation. It has become the go-to tool
for Bayesian modeling. The R package TMB (Template Model Builder) is a
frequentist alternative that performs maximum likelihood estimation
where latent variables are integrated out of the likelihood using the
Laplace approximation. Both Stan and TMB use automatic differentiation
(AD) for accurate evaluation of derivatives.

## Model

## Plots

``` r
p1 = ggplot(dt_plot, aes(n_games, Runtime, color = Model)) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.8) + 
  scale_y_log10() + 
  xlab("Number of games") + 
  ggtitle("Runtime in seconds on log-scale")
ggsave(paste0(fig_dir, "runtime.pdf"), plot = p1, width = 12, height = 8, units = "cm")

p2 = ggplot(dt_time, aes(n_games, relative_time)) +
  geom_point(size = 2.5) + 
  geom_line(linewidth = 0.8) + 
  xlab("Number of games") + 
  ylab("Stan / TMB") + 
  ggtitle("Relative runtime")
ggsave(paste0(fig_dir, "relative_runtime.pdf"), plot = p2, width = 12, height = 8, units = "cm")

p1 + p2
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

``` r


# Compare parameter estimates
plots = list()
for (i in c(1, 5)) {
  dt_tmb = extract_params_tmb(res[[i]]$tmb$obj)
  dt_stan = extract_params_stan(res[[i]]$stan$fit)  
  dt_tmb[, model := "TMB"]
  dt_stan[, model := "Stan"]
  keep = names(dt_tmb)
  dt_comb = rbindlist(list(dt_tmb, dt_stan[, ..keep]))
  
  plots[[paste(i)]] = 
  ggplot(dt_comb, aes(reorder(index, estimate), estimate, color = model)) + 
    facet_wrap(vars(param)) + 
    geom_point(size = 2, position=position_dodge(width=1)) + 
    geom_errorbar(aes(ymin = param_lower, ymax = param_upper),
                  width = 1, 
                  linewidth = 1.2,
                  position=position_dodge(width = 1),
                  alpha = 0.7) + 
    xlab("team") + 
    ylab("") + 
    ggtitle("Estimated parameters", subtitle = "With 95% confidence interval")  
}
#> Constructing atomic D_lgamma
#> iter: 1  Constructing atomic D_lgamma
#> mgc: 4.52971e-14 
#> Constructing atomic D_lgamma
#> Optimizing tape... Done
#> Matching hessian patterns... Done
#> outer mgc:  0.0001067846 
#> iter: 1  value: 5384.065 mgc: 0.4109207 ustep: 1 
#> iter: 2  value: 5384.065 mgc: 0.0001954603 ustep: 1 
#> iter: 3  mgc: 4.431033e-11 
#> outer mgc:  0.1946196 
#> iter: 1  value: 5384.067 mgc: 0.41051 ustep: 1 
#> iter: 2  value: 5384.067 mgc: 0.0001955684 ustep: 1 
#> iter: 3  mgc: 4.432543e-11 
#> outer mgc:  0.1948328 
#> iter: 1  value: 5384.067 mgc: 0.01455482 ustep: 1 
#> iter: 2  value: 5384.067 mgc: 5.475227e-07 ustep: 1 
#> mgc: 4.440892e-14 
#> outer mgc:  0.03436617 
#> iter: 1  value: 5384.064 mgc: 0.01458396 ustep: 1 
#> iter: 2  value: 5384.064 mgc: 5.493267e-07 ustep: 1 
#> mgc: 3.091971e-14 
#> outer mgc:  0.03441749 
#> iter: 1  value: 5384.069 mgc: 0.02072551 ustep: 1 
#> iter: 2  value: 5384.069 mgc: 6.509188e-07 ustep: 1 
#> mgc: 2.930989e-14 
#> outer mgc:  0.02815971 
#> iter: 1  value: 5384.062 mgc: 0.020767 ustep: 1 
#> iter: 2  value: 5384.062 mgc: 6.526409e-07 ustep: 1 
#> mgc: 4.263256e-14 
#> outer mgc:  0.0281801 
#> iter: 1  value: 5384.075 mgc: 0.03488016 ustep: 1 
#> iter: 2  value: 5384.075 mgc: 7.164478e-07 ustep: 1 
#> mgc: 2.930989e-14 
#> outer mgc:  0.01135002 
#> iter: 1  value: 5384.057 mgc: 0.03494999 ustep: 1 
#> iter: 2  value: 5384.057 mgc: 7.166058e-07 ustep: 1 
#> mgc: 5.240253e-14 
#> outer mgc:  0.0112905 
#> outer mgc:  0.2639318 
#> iter: 1  mgc: 1.018741e-12 
#> Optimizing tape... Done
#> Matching hessian patterns... Done
#> outer mgc:  0.005776332 
#> iter: 1  value: 86661.24 mgc: 6.920587 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 0.003448493 ustep: 1 
#> iter: 3  mgc: 8.582575e-10 
#> outer mgc:  0.178744 
#> iter: 1  value: 86661.24 mgc: 6.913669 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 0.003450772 ustep: 1 
#> iter: 3  mgc: 8.593952e-10 
#> outer mgc:  0.178321 
#> iter: 1  value: 86661.24 mgc: 0.01529033 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 6.299559e-08 ustep: 1 
#> mgc: 1.07292e-12 
#> outer mgc:  0.04176905 
#> iter: 1  value: 86661.24 mgc: 0.01532095 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 6.324519e-08 ustep: 1 
#> mgc: 1.352807e-12 
#> outer mgc:  0.03718829 
#> iter: 1  value: 86661.24 mgc: 0.02378235 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 6.583696e-08 ustep: 1 
#> mgc: 1.06648e-12 
#> outer mgc:  0.043485 
#> iter: 1  value: 86661.24 mgc: 0.02382996 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 6.609415e-08 ustep: 1 
#> mgc: 1.389583e-12 
#> outer mgc:  0.03200251 
#> iter: 1  value: 86661.24 mgc: 0.03922773 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 2.597358e-07 ustep: 0.008923143 
#> mgc: 5.086265e-09 
#> outer mgc:  0.03443198 
#> iter: 1  value: 86661.24 mgc: 0.03930627 ustep: 1 
#> iter: 2  value: 86661.24 mgc: 2.606784e-07 ustep: 1 
#> mgc: 1.565859e-12 
#> outer mgc:  0.03752605 
#> outer mgc:  0.2921375

plots[["1"]] / (plots[["5"]] + ggtitle("", subtitle = "")) +  plot_layout(guides = "collect") 
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r
# ggsave(paste0(fig_dir, "param_estimates.pdf"), width = 12, height = 8, units = "cm")
```
