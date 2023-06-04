library(TMB)
library(rstan)
library(data.table)
library(ggplot2)
library(patchwork)
theme_set(theme_bw())
source("functions.R")

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
fig_dir = "figs/"
n_games = c(5, 10, 20, 40, 80)
stan_mod = stan_model("poisson_goals_model.stan")

res = lapply(n_games, function(n_games) {
  cat("Fitting for", n_games, "games\n")
  data = simulate_games(n_games = n_games)
  tmb_fit = fit_tmb(data$data)
  stan_fit = fit_stan(data$data, stan_mod)
  return(list(tmb = tmb_fit, 
              stan = stan_fit))
})

saveRDS("sim_results.rds")