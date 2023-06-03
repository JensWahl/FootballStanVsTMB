#include <TMB.hpp>
template<class Type>
Type objective_function<Type>::operator() ()
{
  DATA_IVECTOR(home_goals);
  DATA_IVECTOR(away_goals);
  DATA_IVECTOR(home_team); 
  DATA_IVECTOR(away_team); 
  DATA_INTEGER(n_games); 

  PARAMETER(intercept);
  PARAMETER_VECTOR(attack); // Random effect attack
  PARAMETER_VECTOR(defense); // Random effect defense
  PARAMETER_VECTOR(home); // Random effect home advantage 
  
  PARAMETER(log_sigma_attack); 
  PARAMETER(log_sigma_defense); 
  PARAMETER(log_sigma_home); 
  
  Type sigma_attack = exp(log_sigma_attack); 
  Type sigma_defense = exp(log_sigma_defense); 
  Type sigma_home = exp(log_sigma_home); 
  
  ADREPORT(sigma_attack); 
  ADREPORT(sigma_defense); 
  ADREPORT(sigma_home); 
  
  Type nll = 0; 
    
  // Contribution from random effects
  nll -= sum(dnorm(attack, Type(0), sigma_attack, true)); 
  nll -= sum(dnorm(defense, Type(0), sigma_defense, true)); 
  nll -= sum(dnorm(home, Type(0), sigma_home, true)); 
  
  // Contribution for observations 
  
  for (int i = 0; i < n_games; i++) {
    // Home goals
    nll -= dpois(Type(home_goals(i)), exp(intercept + attack(home_team(i)) - defense(away_team(i)) + home(home_team(i))), true); 
    // Away goals
    nll -= dpois(Type(away_goals(i)), exp(intercept + attack(away_team(i)) - defense(home_team(i)) - home(home_team(i))), true); 
  }
  
  return nll;
}