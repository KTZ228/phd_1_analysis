# Clean house
rm(list=ls())

library(aod)

responses <- read.csv('/Users/kenneth.van.der.zee/Documents/phd_1_analysis/pre-processed/combined_results_modelling.csv', sep=';')

head(responses)

responses$WSLS <- factor(responses$WSLS)

logistical_regression_model <- glm(response_integer ~ WSLS, data = responses, family = 'binomial')

summary(logistical_regression_model)