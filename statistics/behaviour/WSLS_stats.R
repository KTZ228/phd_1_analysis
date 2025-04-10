library(emmeans)

WSLS_csv_location <- "/Volumes/project/3025011.02/pre-processed/behaviour/combined_dataframe_for_r.csv"

WSLS_dataframe <- read.csv(WSLS_csv_location, header = TRUE, sep = ";")

# Run the raw model
model <- lm(WS ~ subjectively_correct_one_back_int + session, data = WSLS_dataframe)

summary(model)

# Code dummy variables for the stimulation conditions (now sessions)
WSLS_dataframe$session <- factor(WSLS_dataframe$session, levels = c(2, 3, 4))
#WSLS_dataframe$WS <- factor(WSLS_dataframe$WS, levels = c(-1, 0 ,1))
WSLS_dataframe$subjectively_correct_one_back_int <- factor(WSLS_dataframe$subjectively_correct_one_back_int, levels = c(0 ,1))
contrasts(WSLS_dataframe$session) <- contr.sum(nlevels(WSLS_dataframe$session)) # this means that 1 is the baseline group
WSLS_dataframe$session
contrasts(WSLS_dataframe$session)

#session_2 <- c(1, 0, 0)
#session_3 <- c(0, 1, 0)
#session_4 <- c(0, 0, 1)

#contrasts(WSLS_dataframe$session) <- cbind(session_2, session_3, session_2)

# Run the model with dummy variables, but we might need logistic regression
model <- lm(WS ~ subjectively_correct_one_back_int + session, data = WSLS_dataframe)
# also make different models that take volatility and/or congruency into account
summary(model)

# An option is to do pairwise comparisons instead of contrasts
session_emm <- emmeans(model, ~ session, type = "response")
pairwise_comp <- pairs(session_emm)
print(pairwise_comp)

# A slightly different model with lose-shift instead
model <- lm(LS ~ subjectively_correct_one_back_int + same_choice_as_one_back, data = WSLS_dataframe)

summary(model)