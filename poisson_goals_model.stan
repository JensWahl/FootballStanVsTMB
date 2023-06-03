
data {
  int<lower=0> n_games;
  int<lower=0> n_teams; 
  int<lower=0> home_goals[n_games];
  int<lower=0> away_goals[n_games];
  int<lower=0> home_team[n_games];
  int<lower=0> away_team[n_games];
}

parameters {
  real intercept; 
  vector[n_teams] attack; 
  vector[n_teams] defense; 
  vector[n_teams] home; 
  real<lower=0> sigma_attack; 
  real<lower=0> sigma_defense; 
  real<lower=0> sigma_home; 
}


model {
  
  // Priors
  attack ~ normal(0, sigma_attack); 
  defense ~ normal(0, sigma_defense); 
  home ~ normal(0, sigma_home); 
  intercept ~ normal(0.15, 0.3);
  sigma_attack ~ normal(0.15, 0.05);
  sigma_defense ~ normal(0.15, 0.05);
  sigma_home ~ normal(0.15, 0.05);


  // Likelihood 
  for (i in 1:n_games) {
    home_goals[i] ~ poisson(exp(intercept + attack[home_team[i]] - defense[away_team[i]] + home[home_team[i]])); 
    away_goals[i] ~ poisson(exp(intercept + attack[away_team[i]] - defense[home_team[i]] - home[home_team[i]])); 
  }
}

