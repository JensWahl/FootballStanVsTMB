library(TMB)
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

library(data.table)
library(worldfootballR)
library(ggplot2)
library(patchwork)
theme_set(theme_bw())


simulate_games = function(intercept = 0.16, 
                          sigma_attack = 0.3, 
                          sigma_defense = 0.2, 
                          sigma_home = 0.1, 
                          n_teams = 20, 
                          n_games = 5, 
                          seed = 123) {
  
  set.seed(seed)
  attack = rnorm(n_teams, 0, sigma_attack)
  defense = rnorm(n_teams, 0, sigma_defense)
  home = rnorm(n_teams, 0, sigma_home)
  
  dt_teams = data.table(expand.grid(home = 1:n_teams, away = 1:n_teams))
  # Don't play agains yourself
  dt_teams = dt_teams[home != away]
  # Replicate n_games
  
}
