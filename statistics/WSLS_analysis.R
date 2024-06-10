# Clean house
rm(list=ls())

library(aod)

responses <- read.csv('/Users/kenneth.van.der.zee/Documents/phd_1_analysis/pre-processed/combined_results_modelling.csv', sep=';')

head(responses)

#Response bias: an array with all ones. (this is also the mean response or the intersect)
#Stickiness: predicts the same response for trial ‘t’ as was given in trial ‘t-1’, regardless of cues and outcome.
#Objective reward: predicts you follow exactly the underlying reward schedule
#WSLS: look up the last time the current cue was presented, if it was rewarded the last time, predict that the same action will be taken again, otherwise predict the opposite action.

# WSLS implementation does not work yet. it should include what the ideal WSLS strategy should be, not what the participant is doing

logistical_regression_model <- glm(formula = response_integer ~ WSLS,
                                   data = responses,
                                   family = 'binomial')

summary(logistical_regression_model)