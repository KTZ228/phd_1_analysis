data {
  int<lower=0> N; // Number of trials
  int<lower=0> S; // Number of subjects
  int<lower=1,upper=S> subject_id[N]; // Subject identifiers
  int<lower=0,upper=1> subjectively_correct_int[N]; // Subjective feedback (0 or 1)
  int stimuli_type[N]; // stimuli type (1 or 2)
  int<lower=0,upper=1> volatility[N]; // volatility type (0 or 1)
  int response_int[N]; // the response given by the participant (0 or 1)
}

parameters {
  real alpha0_mu; // Learning rates for volatility 0
  real alpha1_mu; // Learning rates for volatility 1
  real beta_mu;   // 
  real<lower=0> alpha0_sigma; // Learning rates for volatility 0
  real<lower=0> alpha1_sigma; // Learning rates for volatility 1
  real<lower=0> beta_sigma;   // 
  vector[S] alpha0_raw_indiv; // raw alpha for every participant
  vector[S] alpha1_raw_indiv; // raw alpha for every participant
  vector[S] beta_raw_indiv; // raw alpha for every participant
}

transformed parameters {
  vector[S] alpha0_real_indiv;
  vector[S] alpha1_real_indiv;
  vector[S] beta_real_indiv;
  matrix[2,2] Q_value;
  real delta_utility[N];
  real prev_subject_id;
  real alpha_real;
  
  //matt-trick
  alpha0_real_indiv = alpha0_mu + alpha0_sigma * alpha0_raw_indiv;
  alpha1_real_indiv = alpha1_mu + alpha1_sigma * alpha1_raw_indiv;
  beta_real_indiv = exp(beta_mu + beta_sigma * beta_raw_indiv);
 
  // Loop through trials
  prev_subject_id = subject_id[1]; // Set initial subject_id
  for(i in 1:2){ for (j in 1:2) { Q_value[i,j] = 0.5;}} // Initialise Q_value
  
  for (t in 1:N) {
    if(t > 2 && prev_subject_id != subject_id[t]) { // Reinitialise Q-value only if new participant
      prev_subject_id = subject_id[t-1];
      for(i in 1:2){ for (j in 1:2) {Q_value[i,j] = 0.5;}} // Initialise Q_value, reinitialise after each participant
    }
    // Calculate alpha for the model
    alpha_real = inv_logit(alpha0_real_indiv[subject_id[t]] + volatility[t] * alpha1_real_indiv[subject_id[t]]);
    
    // Map the choice to the responses
    if(response_int[t] == 1) {
      delta_utility[t] = Q_value[stimuli_type[t],1] - Q_value[stimuli_type[t],2];
    }
    else if(response_int[t] == 2) {
      delta_utility[t] = Q_value[stimuli_type[t],2] - Q_value[stimuli_type[t],1];
    }
    // This is the Rescorla Wagner function
    Q_value[stimuli_type[t],response_int[t]] = Q_value[stimuli_type[t],response_int[t]] + alpha_real * (subjectively_correct_int[t] - Q_value[stimuli_type[t],response_int[t]]);
  }
}

model {
  // Priors for learning rates and initial expected values
  alpha0_mu ~ std_normal();
  alpha1_mu ~ std_normal();
  alpha0_sigma ~ std_normal();
  alpha1_sigma ~ std_normal();
  beta_mu ~ std_normal();
  beta_sigma ~ std_normal();
  alpha0_raw_indiv ~ std_normal();
  alpha1_raw_indiv ~ std_normal();
  beta_raw_indiv ~ std_normal();
  
  for (t in 1:N) {
    1 ~ bernoulli_logit(beta_raw_indiv[subject_id[t]]*delta_utility[t]); # Does not require me to map the choice to this because we do it with response == 1 etc.
  }
}
