library(TMB)
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

library(data.table)
library(worldfootballR)
library(ggplot2)
library(patchwork)
theme_set(theme_bw())

compile("poisson_goals_model.cpp")
dyn.load(dynlib("poisson_goals_model"))

dt_all = load_fotmob_matches_by_date(
  country = "ENG",
  league_name = "Premier League"
)
setDT(dt_all)

dt = dt_all[, .(home_score, home_name, home_id, away_score, away_name, away_id, match_time)]

home_name = dt[, unique(home_name)]
team_id = 1:length(home_name)
names(team_id) = home_name
dt[, home_id := team_id[home_name] - 1] # TMB index starts at 0
dt[, away_id := team_id[away_name] - 1]


# Fit model in TMB ------------------------------------------------------------------------------------------------
# Prepare data for TMB
data = list(home_goals = dt[, home_score], 
            away_goals = dt[, away_score], 
            home_team = dt[, home_id], 
            away_team = dt[, away_id], 
            n_games = dt[, .N])


param = list(intercept = 0, 
             attack = rep(0, length(team_id)), 
             defense = rep(0, length(team_id)), 
             home = rep(0, length(team_id)),
             log_sigma_attack = 0,
             log_sigma_defense = 0, 
             log_sigma_home = 0
             )

obj = MakeADFun(data = data, 
                parameters = param, 
                random = c("attack", "defense", "home"), 
                DLL = "poisson_goals_model")

opt = nlminb(obj$par, obj$fn, obj$gr)

rep = sdreport(obj)
dt_fixed = as.data.table(summary(rep, select = c("fixed", "report")), keep.rownames = TRUE)
dt_fixed[, index := 1:.N, rn]
dt_fixed[, team := ""]
names(dt_fixed)[1:3] = c("param", "estimate", "std_error")

dt_tmb = as.data.table(summary(rep, select = "random"), keep.rownames = TRUE)
dt_tmb[, index := 1:.N, rn]
dt_tmb[, team := names(team_id[index])]
names(dt_tmb)[1:3] = c("param", "estimate", "std_error")
dt_tmb[, team := reorder(team, estimate)]
dt_tmb[, param_upper := qnorm(0.975, estimate, std_error)]
dt_tmb[, param_lower := qnorm(0.025, estimate, std_error)]

# Fit model in Stan -----------------------------------------------------------------------------------------------

fit_stan = stan("poisson_goals_model.stan", 
                data = list(home_goals = dt[, home_score], 
                            away_goals = dt[, away_score], 
                            home_team = dt[, home_id] + 1, 
                            away_team = dt[, away_id] + 1, 
                            n_games = dt[, .N], 
                            n_teams = length(team_id)))

dt_stan = as.data.table(summary(fit_stan)$summary, keep.rownames = TRUE)
dt_stan = dt_stan[grepl("attack\\[|defense\\[|home\\[", rn)]
dt_stan[, rn := gsub("\\[\\d+\\]", "", rn)]
dt_stan[, index := 1:.N, rn]
dt_stan[, team := names(team_id[index])]
setnames(dt_stan, c("rn", "mean", "sd", "2.5%", "97.5%"), c("param", "estimate", "std_error", "param_lower", "param_upper"))

dt_tmb[, model := "TMB"]
dt_stan[, model := "Stan"]
keep = names(dt_tmb)
dt_comb = rbindlist(list(dt_tmb, dt_stan[, ..keep]))

p1 = ggplot(dt_comb[param == "attack"], aes(reorder(team, estimate), estimate, color = model)) + 
  geom_point() + 
  geom_errorbar(aes(ymin = param_lower, ymax = param_upper), width = 1, linewidth = 1.2) + 
  geom_point(size=3) + 
  scale_x_discrete(guide = guide_axis(angle = 90)) + 
  xlab("") + 
  ylab("") + 
  ggtitle("attack effect", subtitle = "With 95% confidence interval")

p2 = ggplot(dt_comb[param == "defense"], aes(reorder(team, estimate), estimate, color = model)) + 
  geom_point() + 
  geom_errorbar(aes(ymin = param_lower, ymax = param_upper), width = 1, linewidth = 1.2) +
  geom_point(size=3) + 
  scale_x_discrete(guide = guide_axis(angle = 90)) + 
  xlab("") + 
  ylab("") + 
  ggtitle("Defense effect", subtitle = "With 95% confidence interval")

p3 = ggplot(dt_comb[param == "home"], aes(reorder(team, estimate), estimate, color = model)) + 
  geom_point() + 
  geom_errorbar(aes(ymin = param_lower, ymax = param_upper), width = 1, linewidth = 1.2) + 
  geom_point(size=3) + 
  scale_x_discrete(guide = guide_axis(angle = 90)) + 
  xlab("") + 
  ylab("") + 
  ggtitle("Home effect", subtitle = "With 95% confidence interval")


p1 + p2 + p3 + plot_layout(guides = "collect") 

