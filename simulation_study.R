library(TMB)
library(rstan)
library(data.table)
library(ggplot2)
library(patchwork)
library(ggrepel)
theme_set(theme_bw())
source("functions.R")

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
fig_dir = "figs/"
n_games = c(5, 10, 20, 40, 80)
stan_mod = stan_model("poisson_goals_model.stan")
compile("poisson_goals_model.cpp")
dyn.load(dynlib("poisson_goals_model"))

res = lapply(n_games, function(n_games) {
  cat("Fitting for", n_games, "games\n")
  data = simulate_games(n_games = n_games)
  tmb_fit = fit_tmb(data$data)
  stan_fit = fit_stan(data$data, stan_mod)
  return(list(tmb = tmb_fit, 
              stan = stan_fit))
})

saveRDS(res, "sim_results.rds")

dt_time = data.table(n_games = n_games * 19 * 20)
dt_time[, TMB := sapply(res, \(x) as.double(x[["tmb"]]$time, units = "secs"))]
dt_time[, Stan := sapply(res, \(x) as.double(x[["stan"]]$time, units = "secs"))]
dt_time[, relative_time := Stan / TMB]
dt_plot = melt(dt_time, id.vars = "n_games", variable.name = "Model", value.name = "Runtime")

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
  
