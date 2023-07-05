#' Simulate football games based on the Poisson model
simulate_games = function(intercept = 0.16, 
                          sigma_attack = 0.3, 
                          sigma_defense = 0.2, 
                          sigma_home = 0.1, 
                          n_teams = 20, 
                          n_games = 5, 
                          seed = 123) {
  
  set.seed(seed)
  
  # Simulate random effects 
  attack = rnorm(n_teams, 0, sigma_attack)
  defense = rnorm(n_teams, 0, sigma_defense)
  home_add = rnorm(n_teams, 0, sigma_home)
  
  dt_teams = data.table(expand.grid(home = 1:n_teams, away = 1:n_teams))
  
  # Don't play against yourself
  dt_teams = dt_teams[home != away]
  
  # Replicate n_games
  dt_teams = dt_teams[rep(seq(1, .N), n_games)]
  
  # simulate goals 
  dt_teams[, home_goals := rpois(.N, exp(intercept + attack[home] - defense[away] + home_add[home]))]
  dt_teams[, away_goals := rpois(.N, exp(intercept + attack[away] - defense[home] - home_add[home]))]
  
  
  return(list(data = dt_teams, 
              param = list(intercept = intercept, 
                           sigma_attack = sigma_attack, 
                           sigma_defense = sigma_defense, 
                           sigma_home = sigma_home, 
                           attack = attack, 
                           defense = defense, 
                           home = home_add)))    
}


#' Estimate parameters using TMB.
#' dt - data.table with all games 
fit_tmb = function(dt) {
  
  data = list(home_goals = dt[, home_goals], 
              away_goals = dt[, away_goals], 
              home_team = dt[, home] - 1, 
              away_team = dt[, away] - 1, 
              n_games = dt[, .N])
  
  param = list(intercept = 0, 
               attack = rep(0, length(unique(dt$home))), 
               defense = rep(0, length(unique(dt$home))), 
               home = rep(0, length(unique(dt$home))),
               log_sigma_attack = 0,
               log_sigma_defense = 0, 
               log_sigma_home = 0)
  
  obj = MakeADFun(data = data, 
                  parameters = param, 
                  random = c("attack", "defense", "home"), 
                  DLL = "poisson_goals_model")
  
  start = Sys.time()
  opt = nlminb(obj$par, obj$fn, obj$gr)
  end = Sys.time()
  if (opt$convergence != 0) stop("Optimization didn't converge")
  
  return(list(obj = obj, 
              opt = opt, 
              time = end - start))
  
}

#' Estimate parameters using Stan
#' dt - data.table with all games 
#' mod - Compiled stan model. 
fit_stan = function(dt, mod) {
  # Pass compiled model to avoid including it in the timing
  
  start = Sys.time()
  fit_stan = sampling(mod, 
                  data = list(home_goals = dt[, home_goals], 
                              away_goals = dt[, away_goals], 
                              home_team = dt[, home], 
                              away_team = dt[, away], 
                              n_games = dt[, .N], 
                              n_teams = length(unique(dt$home))))
  end = Sys.time()
  return(list(fit = fit_stan, 
              time = end - start))
}

extract_params_tmb = function(obj) {
  rep = sdreport(obj)
  dt_tmb = as.data.table(summary(rep, select = "random"), keep.rownames = TRUE)
  dt_tmb[, index := 1:.N, rn]
  names(dt_tmb)[1:3] = c("param", "estimate", "std_error")
  dt_tmb[, param_upper := qnorm(0.975, estimate, std_error)]
  dt_tmb[, param_lower := qnorm(0.025, estimate, std_error)]
  return(dt_tmb)
}

extract_params_stan = function(obj) {
  dt_stan = as.data.table(summary(obj)$summary, keep.rownames = TRUE)
  dt_stan = dt_stan[grepl("attack\\[|defense\\[|home\\[", rn)]
  dt_stan[, rn := gsub("\\[\\d+\\]", "", rn)]
  dt_stan[, index := 1:.N, rn]
  setnames(dt_stan, c("rn", "mean", "sd", "2.5%", "97.5%"), c("param", "estimate", "std_error", "param_lower", "param_upper"))
  return(dt_stan)
}
