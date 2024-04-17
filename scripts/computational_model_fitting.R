# Clean house
rm(list=ls())

library(data.table)
library(stringr)
library(dplyr)
library(ggplot2)
library(ggthemes)
library(tidyverse)
library(RColorBrewer)
library(readxl)
library(rstatix)
library(glue)
library(lme4)

responses <- read.csv('/Users/kenneth.van.der.zee/Documents/phd_1_analysis/pre-processed/responses_models_and_subs.csv')

stimuli_types = list(1,2,3,4)

for (stimuli_type in stimuli_types) {
  participant_column <- glue('participant_responses_stimuli_{stimuli_type}')
  model_column <- glue('WSLS_model_responses_stimuli_{stimuli_type}')
  responses_participant_and_model <- responses[c('X', participant_column, model_column, 'subject_id')]
  responses_participant_and_model <- responses_participant_and_model[complete.cases(responses_participant_and_model), ]
  
  subject_id <- responses_participant_and_model[c('subject_id')]
  trials <- responses_participant_and_model[c('X')]
  participant_model <- responses_participant_and_model[c(participant_column)]
  responses_model <- responses_participant_and_model[c(model_column)]
  
  data <- data.frame(subject = subject_id, time = trials, series = participant_model, response = responses_model)
  colnames(data) <- c("subject","time", "series","response")
  
  model <- glmer(response ~ time + series + (1 | subject), family = binomial(link = "logit"), data = data)
  
  print(summary(model))
}