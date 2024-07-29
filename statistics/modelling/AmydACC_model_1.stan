data {
  int<lower=0> N; // Number of trials
  int<lower=0> S; // Number of subjects
  int<lower=1,upper=S> subject_id[N]; // Subject identifiers
  int<lower=0,upper=1> subjectively_correct_int[N]; // Subjective feedback (0 or 1)
  int<lower=0,upper=1> stimuli_type[N]; // stimuli type (1 or 3)
  int<lower=0,upper=1> response_int[N]; // the response given by the participant
}

parameters {
  real<lower=0, upper=1> alpha0[S]; // Learning rates for stimulus type 1
  real<lower=0, upper=1> alpha1[S]; // Learning rates for stimulus type 3
  real<lower=0, upper=1> V1_type1[S]; // Initial expected values for stimulus type 1
  real<lower=0, upper=1> V1_type3[S]; // Initial expected values for stimulus type 3
}

transformed parameters {
  vector<lower=0, upper=1>[S] alpha;
  vector<lower=-mu_pr[2]/sigma[2]>[S] tau;
  vector[ns] ep;
  matrix[ns,nt] utility;
  
  //matt-trick
  alpha = inv_logit(mu_pr[1] + sigma[1] * alpha_raw);
  tau = mu_pr[2] + sigma[2] * tau_raw;
  ep = inv_logit(mu_pr[3] + sigma[3] * ep_raw);
  
  real V_type1[N]; // Expected values for stimulus type 1
  real V_type3[N]; // Expected values for stimulus type 3
  
  // Initialize the first trial values for each subject
  for (s in 1:S) {
    int first_trial = 0;
    for (t in 1:N) {
      if (subject_id[t] == s) {
        first_trial = t;
        break;
      }
    }
    V_type1[first_trial] = V1_type1[s];
    V_type3[first_trial] = V1_type3[s];
  }
  
  for (t in 2:N) {
    if (subject_id[t] == subject_id[t-1]) {
      if (stimuli_type[t-1] == 0) {
        V_type1[t] = V_type1[t-1] + alpha0[subject_id[t]] * (subjectively_correct_int[t-1] - V_type1[t-1]);
        V_type3[t] = V_type3[t-1]; // No update for type 3
      } else if (stimuli_type[t-1] == 1) {
        V_type3[t] = V_type3[t-1] + alpha1[subject_id[t]] * (subjectively_correct_int[t-1] - V_type3[t-1]);
        V_type1[t] = V_type1[t-1]; // No update for type 1
      }
    }
  }
}

model {
  // Priors for learning rates and initial expected values
  for (s in 1:S) {
    alpha0[s] ~ beta(1, 1);
    alpha1[s] ~ beta(1, 1);
    V1_type1[s] ~ beta(1, 1);
    V1_type3[s] ~ beta(1, 1);
  }
  
  // Likelihood
  for (t in 1:N) {
    if (stimuli_type[t] == 0) {
      response_int[t] ~ bernoulli(V_type1[t]);
    } else if (stimuli_type[t] == 1) {
      response_int[t] ~ bernoulli(V_type3[t]);
    }
  }
}
