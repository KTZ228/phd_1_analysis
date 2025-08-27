import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt
from scipy.special import expit  # sigmoid function

def process_stimuli_file(base_dir, file_name):
    # Function to check if 'Angry' or 'Happy' is in the stimuli_name
    def get_stimuli_type(stimuli_name):
        if 'Angry' in stimuli_name:
            return 'Angry'
        elif 'Happy' in stimuli_name:
            return 'Happy'
        else:
            return None

    # Load CSV from the specified path
    def load_csv(file_path):
        return pd.read_csv(file_path, sep=';')

    # Construct the full file path
    file_path = os.path.join(base_dir, file_name)

    # Read the CSV file into a DataFrame
    df = load_csv(file_path)

    # Initialize empty list to collect trial values
    trial_array = []

    # Variables to track previous state
    previous_stimuli_type = None

    # Initialize variables to track the previous probability conditions for Angry and Happy
    previous_prob_condition_angry = None
    previous_prob_condition_happy = None

    # Iterate over the DataFrame rows
    for index, row in df.iterrows():
        current_stimuli_type = get_stimuli_type(row['stimuli_name'])
        current_prob_condition = row['probability_condition']

        if current_stimuli_type is None:
            continue  # Skip if no 'Angry' or 'Happy' in stimuli_name

        # Check and update for Angry stimuli
        if current_stimuli_type == 'Angry':
            if previous_prob_condition_angry is not None and previous_prob_condition_angry != current_prob_condition:
                trial_array.append(row['trial'])  # Add trial if there's a change
            previous_prob_condition_angry = current_prob_condition
            previous_prob_condition_happy = 100 - current_prob_condition

        # Check and update for Happy stimuli
        elif current_stimuli_type == 'Happy':
            if previous_prob_condition_happy is not None and previous_prob_condition_happy != current_prob_condition:
                trial_array.append(row['trial'])  # Add trial if there's a change
            previous_prob_condition_happy = current_prob_condition
            previous_prob_condition_angry = 100 - current_prob_condition

    # Convert the list to a NumPy array
    trial_array = np.array(trial_array)

    # Calculate differences between consecutive trials
    differences = np.diff(trial_array)

    # Return the results
    return trial_array, differences

def split_df_by_subject(df):
    """
    Splits a DataFrame into multiple DataFrames based on unique values 
    in the 'subject_id' column.

    Parameters:
        df (pd.DataFrame): The input DataFrame with a 'subject_id' column.

    Returns:
        dict: A dictionary where keys are subject_ids and values are DataFrames.
    """
    return {subject_id: group_df for subject_id, group_df in df.groupby("subject_id")}

# helper methods
def softmax(beta=3):
    va = np.arange(0,1.02,0.02)
    vb = 1 - va
    x = 0.02

    pa = np.exp(beta*va)/(np.exp(beta*va)+np.exp(beta*vb))
    tmp = np.random.rand(51)< pa*(1+x)
    data = tmp
    x_axis = va-vb
    return pa, data, x_axis


# def prepSubDict_approach(data):
#     # Assuming rows 1-8 have already been filtered out
#     df = data.copy()

#     # Drop rows with no response or no correctness label
#     df = df[(df['response'].isin(['down', 'up'])) & (df['objectively_correct'].isin(['True', 'False']))]

#     # Convert responses to 0 (down) and 1 (up)
#     df['choice'] = df['response'].map({'down': 0, 'up': 1})

#     # Convert correctness to binary outcome
#     df['outcome'] = df['objectively_correct'].map({'True': 1, 'False': 0})

#     # Convert to numpy arrays and reshape
#     choice = np.reshape(df['choice'].to_numpy(), (-1, 1))
#     outcome = np.reshape(df['outcome'].to_numpy(), (-1, 1))

#     simData = {'choice': choice, 'outcome': outcome}
#     return simData

def prepSubDict_approach(data):
    df = data.copy()

    df = df[(df['response'].isin(['down', 'up'])) & (df['objectively_correct'].isin(['True', 'False']))]

    df['choice'] = df['response'].map({'down': 0, 'up': 1})
    df['outcome'] = df['objectively_correct'].map({'True': 1, 'False': 0})
    
    # Add stimulus identity: 0 for Angry (1), 1 for Happy (3)
    df['stimulus'] = df['stimuli_type'].map({1: 0, 3: 1})

    simData = {
        'choice': df['choice'].to_numpy().reshape(-1, 1),
        'outcome': df['outcome'].to_numpy().reshape(-1, 1),
        'stimulus': df['stimulus'].to_numpy().reshape(-1, 1)
    }
    return simData


def runGridSearch(simData,fitSettings,sim=True):
    stepAlpha = (fitSettings['bounds'][0][1]-fitSettings['bounds'][0][0])/fitSettings['nBin'][0]
    alphaVals = np.arange(fitSettings['bounds'][0][0],fitSettings['bounds'][0][1],stepAlpha)
    stepBeta = (fitSettings['bounds'][1][1]-fitSettings['bounds'][1][0])/fitSettings['nBin'][1]
    betaVals = np.arange(fitSettings['bounds'][1][0],fitSettings['bounds'][1][1],stepBeta)

    loglik=np.zeros((fitSettings['nBin'][0],fitSettings['nBin'][1]),'float')

    for i,alpha in enumerate(alphaVals):
      for j,beta in enumerate(betaVals):
        simPars = {'alpha': alpha, 'beta': beta}
        logl, pp = revlFitData(simData, simPars,sim) # simulate data with grid search parameters
        loglik[i,j] = logl

    #print(loglik)
    loglik = loglik-np.min(loglik) # remove the minimum;
    #print(loglik)
    lik = np.exp(loglik)  # compute the likelihood, (rather than the log)
    #print(lik)

    return lik

# def runGridSearch(simData, fitSettings, sim=True):
#     alpha_bounds, beta_bounds = fitSettings['bounds']
#     n_alpha, n_beta = fitSettings['nBin']

#     alphas = np.linspace(alpha_bounds[0], alpha_bounds[1], n_alpha)
#     betas = np.linspace(beta_bounds[0], beta_bounds[1], n_beta)

#     likelihood_matrix = np.zeros((n_alpha, n_beta))

#     for i, alpha in enumerate(alphas):
#         for j, beta in enumerate(betas):
#             simPars = {'alpha': alpha, 'beta': beta}
#             loglik, _ = revlFitData(simData, simPars, sim)
#             likelihood_matrix[i, j] = loglik

#     return likelihood_matrix, alphas, betas

def revlFitData(simData,simPars,sim):
  v = np.array([0.5, 0.5])
  nTrials = len(simData['choice']) # changed

  #VV = np.empty((0,2),int)
  PP1 = np.empty((0,1),float) # changed
  PP2 = np.empty((0,1),float) # changed

  choiceC = simData['choice'].flatten() # new
  outcome = simData['outcome'].flatten() # new

  #   if len(simData['choice'].shape) > 1:
  #     choiceC = np.mod(simData['choice'].flatten(),2)
  #   else:
  #     choiceC = np.mod(simData['choice'],2)

  for i in range(nTrials): # changed whole loop basically
        c = int(choiceC[i])  # chosen action (0 or 1)
        r = outcome[i]       # received outcome (0 or 1)

        # Softmax policy
        ev = np.exp(simPars['beta'] * v) # np.exp(simPars['beta'] * v)
        #print(ev)
        p = ev / np.sum(ev)

        # Store probabilities
        PP1 = np.row_stack([PP1, p[0]])
        PP2 = np.row_stack([PP2, p[1]])

        # Value update (Rescorla-Wagner)
        v[c] += simPars['alpha'] * (r - v[c])
  #print(PP1, PP2)
  eps = 1e-10
  if sim:
    loglik = np.sum(np.log(PP1[choiceC==1]) + eps)+ np.sum(np.log(PP2[choiceC==0]) + eps)
  else:
    loglik = np.sum(np.log(PP1[choiceC==0]) + eps)+ np.sum(np.log(PP2[choiceC==1]) + eps)    
  return loglik,PP1

def revlFitData1(simData, simPars, sim):
    stimuli_list = np.unique(simData['stimulus'].flatten())
    nTrials = len(simData['choice'])

    # Initialize value dictionary: one value per action (0/1) per stimulus
    v = {stim: np.array([0.5, 0.5]) for stim in stimuli_list}

    PP1 = np.empty((0,1), float)
    PP2 = np.empty((0,1), float)

    choiceC = simData['choice'].flatten()
    outcome = simData['outcome'].flatten()
    stimulus = simData['stimulus'].flatten()

    eps = 1e-10

    for i in range(nTrials):
        stim = stimulus[i]
        c = int(choiceC[i])
        r = outcome[i]

        values = v[stim]
        ev = np.exp(simPars['beta'] * values)
        p = ev / np.sum(ev)

        PP1 = np.row_stack([PP1, p[0]])
        PP2 = np.row_stack([PP2, p[1]])

        v[stim][c] += simPars['alpha'] * (r - v[stim][c])

    if sim:
        loglik = np.sum(np.log(PP1[choiceC==1] + eps)) + np.sum(np.log(PP2[choiceC==0] + eps))
    else:
        loglik = np.sum(np.log(PP1[choiceC==0] + eps)) + np.sum(np.log(PP2[choiceC==1] + eps))

    return loglik, PP1


def plotGridSearch(lik,fitSettings,realData=False):
    fig, ax = plt.subplots()
    al, be = getParamEst(lik,fitSettings)
    ax.plot([0,15],[al,al],'w')
    ax.plot([be,be],[0,1],'w')
    ax.imshow(lik, cmap='jet', extent=[0,15,1,0],aspect=15, interpolation='none')
    if realData==False:
      ax.scatter(4, 0.25, s=500, c='k', marker='+')

    ax.set_title( "2-D Heat Map" )
    ax.set_ylabel('Alpha')
    ax.set_xlabel('Beta')

# def plotGridSearch(lik, fitSettings, realData=False):
#     extent = [fitSettings['bounds'][1][0], fitSettings['bounds'][1][1],
#               fitSettings['bounds'][0][0], fitSettings['bounds'][0][1]]

#     plt.figure(figsize=(8, 6))
#     cmap = 'viridis' if realData else 'plasma'
#     plt.imshow(lik, aspect='auto', origin='lower', extent=extent, cmap=cmap)
#     plt.colorbar(label='Log-likelihood')
#     plt.xlabel('Beta')
#     plt.ylabel('Alpha')
#     plt.title('Grid Search Log-likelihoods' + (' (Real Data)' if realData else ' (Simulated)'))
#     plt.tight_layout()
#     plt.show()

def getParamEst(lik,fitSettings):
    maxCoord = np.where(lik == np.amax(lik))
    y = maxCoord[0]
    x = maxCoord[1]

    stepAlpha = (fitSettings['bounds'][0][1]-fitSettings['bounds'][0][0])/fitSettings['nBin'][0]
    alphaVals = np.arange(fitSettings['bounds'][0][0],fitSettings['bounds'][0][1],stepAlpha)
    stepBeta = (fitSettings['bounds'][1][1]-fitSettings['bounds'][1][0])/fitSettings['nBin'][1]
    betaVals = np.arange(fitSettings['bounds'][1][0],fitSettings['bounds'][1][1],stepBeta)

    estBeta = betaVals[x] - stepBeta/2
    estAlpha = alphaVals[y] - stepAlpha/2

    return estAlpha, estBeta

# how do we fit the Rescorla-Wagner model to the data? 
# We take the csv file first and reformat it using prepSubDict to only take
# the binary movement performed and the binary correctness of the movememnt
# I.e., moving the joystick up means 1, moving it down means 0, correct is 1 and wrong is 0


# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# LEARNING RATE MODELS

# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


def model_null_speakup(params, data):
    """
    Null model: no learning, fixed Q-values per cue-action pair.

    Args:
        params: array of shape (6,) - [q00, q01, q10, q11, beta, bias]
                q00 = Q for cue0-action1
                q01 = Q for cue0-action2
                q10 = Q for cue1-action1
                q11 = Q for cue1-action2
                beta = softmax inverse temperature (log scale)
                bias = bias parameter
        data: dict with 'choice' and 'outcome' (both arrays)

    Returns:
        loglik: log-likelihood of the choices given fixed Q-values
    """
    choice = data['choice']
    nt, nq = choice.shape
    beta = np.exp(params[4])
    be = params[5]
    
    # Construct bias vector (as in existing models)
    bb = np.array([be, -be])
    
    # Extract static Q-values
    q = np.array([
        [params[0], params[1]],  # cue 0 → action 1, 2
        [params[2], params[3]],  # cue 1 → action 1, 2
    ])  # shape (2 cues, 2 actions)

    # Compute Q-difference per cue: Q(action1) - Q(action2)
    q_diff = q[:, 0] - q[:, 1]  # shape (2,)

    # Repeat across trials
    xQ = np.tile(q_diff, (nt + 1, 1))  # same prediction for each trial

    # Prepare data for softmax
    Y = (choice == 1).astype(int)  # action 1 == "go" or "down"

    loglik, _ = response_speakup(xQ[:nt, :], choice, beta, bb)
    return loglik

def model_m1_speakup(params, data):
    """
    Python version of model_m1 (Rescorla-Wagner with 5 parameters).
    
    Args:
        params: numpy array of shape (5,)
        data: dict with keys 'choice' and 'outcome' (both arrays)
        
    Returns:
        loglik: float, log-likelihood of data under the model
    """
    choice = data['choice']
    outcome = data['outcome']

    def safe_expit(x):
        return expit(np.clip(x, -10, 10))  # avoids exact 0 or 1

    # The softmax temperature determines how people noise people's choices are
    # The smaller the beta, the more noisy choices are
    beta = np.exp(np.clip(params[0], -5, 4.6))  # softmax temperature, clipped to avoid extreme values

    # Learning rate decay
    kappa1 = safe_expit(params[1]) # decay rate, sigmoid to [0,1]

    # Bias terms
    be = params[2]
    
    # Construct 2-element bias vector instead of 4-element bias vector (bb)
    # we are not cueing reward/punishment separately. I.e., there is no color indicating reward or punishment. Thus, we only need a single bias value
    bb = np.array([be, -be])
    
    # Learning setup
    lambda1 = 0
    lambda2 = 0
    weight1 = 0
    weight2 = 0

    lambda_ = [lambda1, lambda2]
    weight = [weight1, weight2]
    kappa = [kappa1, kappa1]
    
    # Get model predictions
    xQ, xalpha, xdelta = model_hybrid_speakup_new(lambda_, weight, kappa, choice, outcome)
    
    # Compute log-likelihood
    X = xQ[:len(choice), :]
    Y = (choice == 1)
    
    loglik, _ = response_speakup(X, choice, beta, bb)
    return loglik

def model_m2_speakup(params, data):
    choice = data['choice']
    outcome = data['outcome']

    def safe_expit(x):
        return expit(np.clip(x, -10, 10))  # avoids exact 0 or 1
    
    beta = np.exp(np.clip(params[0], -5, 4.6))                     # softmax temperature
    lambda1 = safe_expit(params[1]) # learning rate, sigmoid to [0,1]
    weight1 = safe_expit(params[2]) # PE weighting, sigmoid to [0,1]
    kappa1 = safe_expit(params[3]) # decay rate, sigmoid to [0,1]
    
    if np.any(np.isnan([lambda1, weight1, kappa1])):
        return -np.inf, None, None, None

    # shared across cues
    weight2 = weight1
    lambda2 = lambda1
    kappa2 = kappa1

    # bias parameters
    be = params[4]

    # Construct 2-element bias vector instead of 4-element bias vector (bb)
    # we are not cueing reward/punishment separately. I.e., there is no color indicating reward or punishment. Thus, we only need a single bias value
    bb = np.array([be, -be])

    # duplicate params for each cue
    lambda_all = [lambda1, lambda2]
    weight_all = [weight1, weight2]
    kappa_all  = [kappa1, kappa2]

    # run hybrid model (this function must be implemented)
    xQ, xalf, xdelta = model_hybrid_speakup_new(lambda_all, weight_all, kappa_all, choice, outcome)

    nt = len(choice)
    X = xQ[:nt, :]  # predicted values for each trial
    Y = (choice == 1).astype(int)  # convert to binary

    loglik, CV = response_speakup(X, choice, beta, bb)

    return loglik, xalf, xdelta, CV


def model_m3_speakup(params, data):
    choice = data['choice']
    outcome = data['outcome']

    def safe_expit(x):
        return expit(np.clip(x, -10, 10))  # avoids exact 0 or 1

    beta = np.exp(np.clip(params[0], -5, 4.6))  # softmax temperature
    lambda1 = safe_expit(params[1])            # learning rate
    weight1 = safe_expit(params[2])            # weight for cue 1
    weight2 = safe_expit(params[3])            # weight for cue 2
    kappa1 = safe_expit(params[4])             # decay rate
    be = params[5]                             # bias

    if np.any(np.isnan([lambda1, weight1, weight2, kappa1])):
        return -np.inf, None, None, None

    # assume same learning rate and kappa for both cues
    lambda_all = [lambda1, lambda1]
    weight_all = [weight1, weight2]
    kappa_all  = [kappa1, kappa1]

    # Bias vector
    bb = np.array([be, -be])

    # Run hybrid model
    xQ, xalf, xdelta = model_hybrid_speakup_new(lambda_all, weight_all, kappa_all, choice, outcome)

    nt = len(choice)
    X = xQ[:nt, :]
    Y = (choice == 1).astype(int)

    loglik, CV = response_speakup(X, choice, beta, bb)

    return loglik, xalf, xdelta, CV

def model_m4_speakup(params, data):
    """
    Python version of model_m1 (Rescorla-Wagner with 5 parameters).
    
    Args:
        params: numpy array of shape (5,)
        data: dict with keys 'choice' and 'outcome' (both arrays)
        
    Returns:
        loglik: float, log-likelihood of data under the model
    """
    choice = data['choice']
    outcome = data['outcome']
    volatility = data['volatility']

    def safe_expit(x):
        return expit(np.clip(x, -10, 10))  # avoids exact 0 or 1

    beta = np.exp(np.clip(params[0], -5, 4.6))  # softmax temperature, clipped to avoid extreme values
    
    kappa1 = safe_expit(params[1]) # learning scale for stable condition, sigmoid to [0,1]
    
    kappa2 = safe_expit(params[2]) # learning scale for volatile condition, sigmoid to [0,1]
    
    kappa = [kappa1, kappa2]

    # Bias terms
    be = params[3]
    
    # Construct 2-element bias vector instead of 4-element bias vector (bb)
    # we are not cueing reward/punishment separately. I.e., there is no color indicating reward or punishment. Thus, we only need a single bias value
    bb = np.array([be, -be])

    # Get model predictions
    xQ, xalpha, xdelta = model_hybrid_speakup_volatility(kappa, choice, outcome, volatility)
    
    # Compute log-likelihood
    X = xQ[:len(choice), :]
    Y = (choice == 1)
    
    loglik, _ = response_speakup(X, choice, beta, bb)
    return loglik


def model_vkf_speakup(params, data):
    """
    Variable Kalman Filter model with free hyperparameters.

    Args:
        params: array of shape (6,) - [beta, v0, omega0, k_volatility, k_omega, bias]
                beta = log softmax inverse temperature for choice randomness (higher is more deterministic)
                volatility_log_initial: initial log volatility
                stochasticity_log_initial: initial log stochasticity
                volatility_learning_rate: volatility learning rate
                stochasticity_learning_rate: stochasticity learning rate
                bias = bias parameter
        data: dict with 'choice' and 'outcome' (both arrays)

    Returns:
        loglik: log-likelihood of choices
        learning_rates: learning rates per trial
        prediction_errors: prediction errors per trial
        CV: choice values
    """
    actions = data['choice']
    outcomes = data['outcome']

    # Prevent numerical overflow by clipping before exponentiating
    def safe_exp(x):
        return np.exp(np.clip(x, -10, 10))

    # Sigmoid transformation to bound parameters between 0 and 1
    def safe_expit(x):
        return expit(np.clip(x, -10, 10))

    # Extract parameters
    softmax_temperature = safe_exp(params[0])  # softmax temperature: higher = more deterministic choices
    volatility_log_initial = params[1]  # initial log volatility
    stochasticity_log_initial = params[2]  # initial log stochasticity
    volatility_learning_rate = safe_expit(params[3])  # volatility learning rate (sigmoid to [0,1])
    stochasticity_learning_rate = safe_expit(params[4])  # stochasticity learning rate (sigmoid to [0,1])
    bias = params[5]  # bias

    # Bias vector
    bias_vector = np.array([bias, -bias])

    # Run VKF model with free hyperparameters
    reward_rate_means, learning_rates, prediction_errors, volatility_estimates, stochasticity_estimates = vkf_update(actions, outcomes, volatility_log_initial, stochasticity_log_initial, volatility_learning_rate, stochasticity_learning_rate)

    # Compute log-likelihood
    X = reward_rate_means[:len(actions), :]
    loglik, CV = response_speakup(X, actions, softmax_temperature, bias_vector)

    return loglik, learning_rates, prediction_errors, CV


def response_speakup(X, choice, beta, bb):
    """
    Compute log-likelihood of observed choices using logistic function.

    Args:
        X: Q-value differences, shape (n_trials, n_cues)
        choice: choice array, shape (n_trials, n_cues), values in {0, 1, 2}
        beta: inverse temperature (scalar)
        bb: bias vector, shape (2,) — biases for the two cue types

    Returns:
        loglik: scalar log-likelihood
        CV: choice values (optional)
    """
    n_trials, n_cues = X.shape
    nrep = n_cues // 2
    bias_vector = np.tile(bb, nrep)

    z = X * beta + bias_vector
    f = 1 / (1 + np.exp(-z))

    # Extract active cue and action
    active_cue_idx = np.argmax(choice > 0, axis=1)
    actions = choice[np.arange(n_trials), active_cue_idx]
    #print(actions)
    f_active = f[np.arange(n_trials), active_cue_idx]
    #print(f_active)

    # Actual choice probability
    p_active = np.where(actions == 1, f_active, 1 - f_active)
    #print(p_active)

    loglik = np.sum(np.log(p_active + 1e-10))
    CV = np.where(actions == 1, z[np.arange(n_trials), active_cue_idx],
                               -z[np.arange(n_trials), active_cue_idx])
    return loglik, CV



def model_hybrid_speakup(lambda_, weight, kappa, actions, outcome):
    """
    Hybrid Rescorla-Wagner / Kalman model update.
    
    Args:
        lambda_ : list or array of length nq
        weight  : list or array of length nq
        kappa   : list or array of length nq
        actions : (nt, nq) array of actions (1 or 2) per trial and cue
        outcome : (nt, nq) array of outcomes per trial and cue
        
    Returns:
        xQ      : (nt+1, nq) predicted Q differences (go - no-go)
        xalpha  : (nt, nq) effective learning rates
        xdelta  : (nt, nq) prediction errors
    """
    # ensure that both actions and outcome (reward/punishment) are arrays, for math
    outcome = np.array(outcome)
    actions = np.array(actions)
    
    # we take the dimensions of the number of trials (rows) x number of stimulus-action combinations (all might have different probs)
    nt, nq = outcome.shape

    # just check that ncue is a multiple of 2; usually 2, but we might have a multiple
    ncue = 2
    if nq % ncue != 0:
        raise ValueError("Unexpected number of cues (should be multiple of 2)")
    
    # if it's a multiple of 2, we should incorporate that (different cue sets?)
    nrep = nq // ncue
    lambda_ = np.tile(lambda_, nrep)
    weight = np.tile(weight, nrep) # weights for K_t, if = 0 only static, if = 0 only dynamic
    kappa = np.tile(kappa, nrep) # the static learning rate

    if not (len(lambda_) == len(weight) == len(kappa) == nq):
        raise ValueError("lambda_, weight, and kappa must match number of cues (columns).")


    xalpha = np.full((nt, nq), np.nan) # will be used to store kalman; will be 1 if only static learning used 
    xdelta = np.full((nt, nq), np.nan) # will be used to store prediction errors
    xQ = np.full((nt + 1, nq), np.nan) # will be used to store Q-value differences (i.e., expected value of action 1 - action 2)
    xQ[0, :] = 0.0 # that difference will be 0 before the first trial
    q = np.zeros((nq, 2))  # for each cue: Q-values for actions 1 and 2
    Apost = lambda_ * (1 - lambda_) * 2 # initial posterior uncertainty per cue; only relevant for adaptive learning
    for t in range(nt): # let's go over all trials
        a = actions[t, :]  # action indices on this trial
        o = outcome[t, :]  # observed outcomes on this trial
        
        active = a > 0 # let's get the index of the relevant actions-stimulus combination
        if np.sum(active) != 1:
            raise ValueError(f"Expected exactly one active cue at trial {t}, got {np.sum(active)}")
        
        for c in np.where(active)[0]:  # get the index of the active cue
            a = a[c] - 1  # action (0 or 1)
            o = o[c]

            A = lambda_[c] * Apost[c]
            kalman = weight[c] * A + (1 - weight[c])
            delta = o - q[c, a]
            
            # before updating q, clip delta to avoid unexpected explosion due to bad q
            delta = np.clip(delta, -2.0, 2.0)
            
            # Q-value update
            q[c, a] += kappa[c] * kalman * delta

            # clip q to reflect the bounded expected values
            q = np.clip(q, -1.0, 1.0)

            # Posterior uncertainty update
            Apost[c] = A + (1 - lambda_[c]) * (delta ** 2)

            # Save values
            xdelta[t, c] = delta
            xalpha[t, c] = kalman
            xQ[t + 1, c] = q[c, 0] - q[c, 1]  # value difference (action 1 - action 2)

        # For inactive cues, Q stays the same
        for c in np.where(~active)[0]:
            xQ[t + 1, c] = xQ[t, c]        

    return xQ, xalpha, xdelta

def model_hybrid_speakup_new(lambda_, weight, kappa, actions, outcome):
    """
    Hybrid Rescorla-Wagner / Kalman model update with:
    - Within-cue opposing action value updates
    - Across-cue opponent cue logic (cue pairs have inverse contingencies)

    Args:
        lambda_ : list or array of length nq (volatility per cue)
        weight  : list or array of length nq (weight for Kalman gain)
        kappa   : list or array of length nq (static learning rate)
        actions : (nt, nq) array of actions (1 or 2) per trial and cue
        outcome : (nt, nq) array of outcomes per trial and cue

    Returns:
        xQ      : (nt+1, nq) predicted Q differences (action 1 - action 2)
        xalpha  : (nt, nq) effective learning rates
        xdelta  : (nt, nq) prediction errors
    """
    outcome = np.array(outcome)
    actions = np.array(actions)
    
    nt, nq = outcome.shape

    if nq % 2 != 0:
        raise ValueError("Number of cues (columns) must be even for pairing.")

    ncue = 2
    nrep = nq // ncue
    lambda_ = np.tile(lambda_, nrep)
    weight = np.tile(weight, nrep)
    kappa = np.tile(kappa, nrep)

    if not (len(lambda_) == len(weight) == len(kappa) == nq):
        raise ValueError("lambda_, weight, and kappa must match number of cues.")

    xalpha = np.full((nt, nq), np.nan)
    xdelta = np.full((nt, nq), np.nan)
    xQ = np.full((nt + 1, nq), np.nan)
    xQ[0, :] = 0.0

    q = np.zeros((nq, 2))  # Q-values for each cue and action
    Apost = lambda_ * (1 - lambda_) * 2  # initial posterior uncertainty

    for t in range(nt):
        a_trial = actions[t, :]
        o_trial = outcome[t, :]
        active = a_trial > 0

        if np.sum(active) != 1:
            raise ValueError(f"Expected exactly one active cue at trial {t}, got {np.sum(active)}")

        c = np.where(active)[0][0]
        a = a_trial[c] - 1  # action (0 or 1)
        o = o_trial[c]

        # Kalman gain and prediction error
        A = lambda_[c] * Apost[c]
        kalman = weight[c] * A + (1 - weight[c])
        delta = o - q[c, a]
        delta = np.clip(delta, -2.0, 2.0)

        # Update Q-values for chosen cue with opposing action update
        q[c, a] += kappa[c] * kalman * delta
        q[c, 1 - a] -= kappa[c] * kalman * delta
        q[c] = np.clip(q[c], -1.0, 1.0)

        # Posterior uncertainty update
        Apost[c] = A + (1 - lambda_[c]) * (delta ** 2)

        # Save updates
        xdelta[t, c] = delta
        xalpha[t, c] = kalman
        xQ[t + 1, c] = q[c, 0] - q[c, 1]

        # Update paired (opponent) cue with inverse contingencies
        c_opponent = c ^ 1  # XOR flips even↔odd (0↔1, 2↔3, etc.)
        if 0 <= c_opponent < nq:
            # Opponent cue uses same delta, reversed effect
            q[c_opponent, a] -= kappa[c_opponent] * kalman * delta
            q[c_opponent, 1 - a] += kappa[c_opponent] * kalman * delta
            q[c_opponent] = np.clip(q[c_opponent], -1.0, 1.0)

            # Save for opponent
            xdelta[t, c_opponent] = -delta
            xalpha[t, c_opponent] = kalman
            xQ[t + 1, c_opponent] = q[c_opponent, 0] - q[c_opponent, 1]

        # For all other cues, Q stays the same
        for c_rest in np.setdiff1d(np.arange(nq), [c, c_opponent]):
            xQ[t + 1, c_rest] = xQ[t, c_rest]

    return xQ, xalpha, xdelta


def model_hybrid_speakup_volatility(kappa, actions, outcome, volatility):
    """
    Hybrid Rescorla-Wagner / Kalman model update with:
    - Within-cue opposing action value updates
    - Across-cue opponent cue logic (cue pairs have inverse contingencies)
    - Different LRs for stable vs volatile trials

    Args:
        lambda_ : list or array of length nq (volatility per cue)
        weight  : list or array of length nq (weight for Kalman gain)
        kappa   : list or array of length nq (static learning rate)
        actions : (nt, nq) array of actions (1 or 2) per trial and cue
        outcome : (nt, nq) array of outcomes per trial and cue

    Returns:
        xQ      : (nt+1, nq) predicted Q differences (action 1 - action 2)
        xalpha  : (nt, nq) effective learning rates
        xdelta  : (nt, nq) prediction errors
    """
    outcome = np.array(outcome)
    actions = np.array(actions)
    volatility = np.array(volatility)
    
    nt, nq = outcome.shape

    if nq % 2 != 0:
        raise ValueError("Number of cues (columns) must be even for pairing.")

    ncue = 2
    nrep = nq // ncue
    kappa = np.tile(kappa, nrep)

    if not (len(kappa) == nq):
        raise ValueError("kappa must match number of cues.")

    xalpha = np.full((nt, nq), np.nan)
    xdelta = np.full((nt, nq), np.nan)
    xQ = np.full((nt + 1, nq), np.nan)
    xQ[0, :] = 0.0

    q = np.zeros((nq, 2))  # Q-values for each cue and action

    for t in range(nt):
        a_trial = actions[t, :]
        o_trial = outcome[t, :]
        vol_trial = volatility[t]
        active = a_trial > 0

        if np.sum(active) != 1:
            raise ValueError(f"Expected exactly one active cue at trial {t}, got {np.sum(active)}")

        c = np.where(active)[0][0]
        a = a_trial[c] - 1  # action (0 or 1)
        o = o_trial[c]

        # prediction error
        delta = o - q[c, a]
        delta = np.clip(delta, -2.0, 2.0)

        # Update Q-values for chosen cue with opposing action update
        if vol_trial == 'stable':
            q[c, a] += kappa[0] * delta
            q[c, 1 - a] -= kappa[0] * delta
            q[c] = np.clip(q[c], -1.0, 1.0)
        else:
            q[c, a] += kappa[1] * delta
            q[c, 1 - a] -= kappa[1] * delta
            q[c] = np.clip(q[c], -1.0, 1.0)

        # Save updates
        xdelta[t, c] = delta
        xalpha[t, c] = 1
        xQ[t + 1, c] = q[c, 0] - q[c, 1]

        # Update paired (opponent) cue with inverse contingencies
        c_opponent = c ^ 1  # XOR flips even↔odd (0↔1, 2↔3, etc.)
        if 0 <= c_opponent < nq:
            # Opponent cue uses same delta, reversed effect
            if vol_trial == 'stable':
                q[c_opponent, a] -= kappa[0] * delta
                q[c_opponent, 1 - a] += kappa[0] * delta
                q[c_opponent] = np.clip(q[c_opponent], -1.0, 1.0)
            else:
                q[c_opponent, a] -= kappa[1] * delta
                q[c_opponent, 1 - a] += kappa[1] * delta
                q[c_opponent] = np.clip(q[c_opponent], -1.0, 1.0)              

            # Save for opponent
            xdelta[t, c_opponent] = -delta
            xalpha[t, c_opponent] = 1
            xQ[t + 1, c_opponent] = q[c_opponent, 0] - q[c_opponent, 1]

        # For all other cues, Q stays the same
        for c_rest in np.setdiff1d(np.arange(nq), [c, c_opponent]):
            xQ[t + 1, c_rest] = xQ[t, c_rest]

    return xQ, xalpha, xdelta


def vkf_update(actions, outcomes, volatility_log_initial, stochasticity_log_initial, volatility_learning_rate, stochasticity_learning_rate):
    """
    Variable Kalman Filter update with free hyperparameters.

    At each trial, the model:
    1. Makes a prediction based on current Q-values
    2. Observes the outcomes and computes prediction error
    3. Updates beliefs about the reward rate by adjusting both the mean and variance with adaptive learning rate (Kalman gain)
    4. Updates beliefs about volatility and stochasticity
    5. Adjusts uncertainty for next trial

    Args:
        actions: (n_trials, nq) array of actions
        outcomes: (n_trials, nq) array of outcomes
        volatility_log_initial: initial log volatility
        stochasticity_log_initial: initial log stochasticity
        volatility_learning_rate: volatility learning rate
        stochasticity_learning_rate: stochasticity learning rate

    Returns:
        reward_rate_means: Beliefs about the reward rate (combined into the diffence between the two options, which is why only one value has to be stored)
            (positive > action 1 preferred, negative > action 2 preferred) (also called Mean or Mt in the paper)
        learning_rates: all learning rates (Kalman gains)
        prediction_errors: all prediction errors
        volatility_estimates: volatility estimates over time
        stochasticity_estimates: stochasticity estimates over time
    """

    # Ensure that both actions and outcomes (reward/punishment) are arrays
    actions = np.array(actions)
    outcomes = np.array(outcomes)

    # Number of trials and cues
    n_trials, n_cues = outcomes.shape
    if n_cues % 2 != 0:
        raise ValueError("Number of cues must be even for pairing")

    # Create empty arrays to store the models internal states for all trials
    learning_rates = np.full((n_trials, n_cues), np.nan) # Learning rates (Kalman gains)
    prediction_errors = np.full((n_trials, n_cues), np.nan) # Prediction errors
    reward_rate_means = np.full((n_trials + 1, n_cues), np.nan) # Mean reward rate differences (action 1 - action 2)
    volatility_estimates = np.full((n_trials + 1, n_cues), np.nan) # log volatility estimates
    stochasticity_estimates = np.full((n_trials + 1, n_cues), np.nan) # log stochasticity estimates
    reward_rate_mean = np.zeros((n_cues, 2)) # Q-values for each cue and action

    # Set initial values
    reward_rate_means[0, :] = 0.0 # No preference between actions
    reward_rate_variance = np.ones(n_cues) * 0.5 # Initial uncertainty (reward_rate_variance) for each cue (higher is more uncertainty)
    volatility_estimates[0, :] = volatility_log_initial # Initial log volatility
    stochasticity_estimates[0, :] = stochasticity_log_initial # Initial log stochasticity

    # Learning loop
    for trial in range(n_trials):
        # Current trial data
        action_row = actions[trial, :]
        outcome_row = outcomes[trial, :]
        stimuli_type_t = action_row > 0 # Determines in which of the two cue columns one must look for the action and outcome

        if np.sum(stimuli_type_t) != 1:
            raise ValueError(f"Expected exactly one stimuli_type_t at trial {trial}")

        # Identify stimuli_type_t cue and action
        cue = np.where(stimuli_type_t)[0][0] # cue index on trial t
        action = action_row[cue] - 1 # set action codes to 0 and 1 instead of 1 and 2
        outcome = outcome_row[cue] # observed outcome on trial t

        # Convert from log space to actual values
        volatility_estimate = np.exp(volatility_estimates[trial, cue]) # volatility
        stochasticity_estimate = np.exp(stochasticity_estimates[trial, cue]) # stochasticity

        # Compute prediction error
        prediction_error = outcome - reward_rate_mean[cue, action]
        prediction_error = np.clip(prediction_error, -2.0, 2.0) # Avoid clipping

        # Compute Kalman gain (learning rate)
        # K = uncertainty_about_cue + volatility / (uncertainty_about_cue + volatility + stochasticity)
        # Increase in reward_rate_variance (uncertainty) > K closer to 1, learn faster
        # High stochasticity_estimate > K closer to 0, learn slower
        learning_rate = (reward_rate_variance[cue] + volatility_estimate) / (reward_rate_variance[cue] + volatility_estimate + stochasticity_estimate)
        learning_rate = np.clip(learning_rate, 0, 1) # Avoid clipping

        # Update reward rate mean for chosen cue with opposing action update
        reward_rate_mean[cue, action] += learning_rate * prediction_error # Chosen action gets a higher expected mean reward rate
        # Opposing update for the non-chosen action
        reward_rate_mean[cue, 1 - action] -= learning_rate * prediction_error # Unchosen action gets a lower expected mean reward rate
        reward_rate_mean[cue] = np.clip(reward_rate_mean[cue], -1.0, 1.0) # Avoid clipping

        # Update reward rate variance after observing outcome
        # After our observation, we become more certain (reduce reward_rate_variance)
        reward_rate_variance[cue] = (1 - learning_rate) * (reward_rate_variance[cue] + volatility_estimate)

        # Sum all sources of prediction variance into one term
        prediction_variance = reward_rate_variance[cue] + volatility_estimate + stochasticity_estimate

        # Update log volatility estimate
        volatility_update = volatility_learning_rate * (prediction_error ** 2 / prediction_variance - 1)
        volatility_estimates[trial + 1, cue] = volatility_estimates[trial, cue] + volatility_update
        volatility_estimates[trial + 1, cue] = np.clip(volatility_estimates[trial + 1, cue], -5, 2) # Avoid clipping

        # Update log stochasticity estimate
        stochasticity_update = stochasticity_learning_rate * (prediction_error ** 2 / prediction_variance - 1)
        stochasticity_estimates[trial + 1, cue] = stochasticity_estimates[trial, cue] + stochasticity_update
        stochasticity_estimates[trial + 1, cue] = np.clip(stochasticity_estimates[trial + 1, cue], -5, 2) # Avoid clipping

        # Save values for analyses
        reward_rate_means[trial + 1, cue] = reward_rate_mean[cue, 0] - reward_rate_mean[cue, 1]
        learning_rates[trial, cue] = learning_rate
        prediction_errors[trial, cue] = prediction_error

        # Now update the paired (opponent) cue with inverse contingencies
        cue_opposite = cue ^ 1 # Flip bit to get paired cue index
        if 0 <= cue_opposite < n_cues:
            # Convert from log space to actual values
            volatility_estimate_opposite = np.exp(volatility_estimates[trial, cue_opposite])
            stochasticity_estimate_opposite = np.exp(stochasticity_estimates[trial, cue_opposite])

            # Compute Kalman gain (learning rate)
            learning_rate_opposite = (reward_rate_variance[cue_opposite] + volatility_estimate_opposite) / (reward_rate_variance[cue_opposite] + volatility_estimate_opposite + stochasticity_estimate_opposite)
            learning_rate_opposite = np.clip(learning_rate_opposite, 0, 1) # Avoid clipping

            # Update reward rate mean for chosen cue with opposing action update
            reward_rate_mean[cue_opposite, action] -= learning_rate_opposite * prediction_error # Chosen action gets a lower expected mean reward rate
            # Opposing update for the non-chosen action
            reward_rate_mean[cue_opposite, 1 - action] += learning_rate_opposite * prediction_error # Unchosen action gets a higher expected mean reward rate
            reward_rate_mean[cue_opposite] = np.clip(reward_rate_mean[cue_opposite], -1.0, 1.0) # Avoid clipping

            # Update reward rate variance after observing outcome
            reward_rate_variance[cue_opposite] = (1 - learning_rate_opposite) * (reward_rate_variance[cue_opposite] + volatility_estimate_opposite)

            # Sum all sources of prediction variance into one term
            prediction_variance_opposite = reward_rate_variance[cue_opposite] + volatility_estimate_opposite + stochasticity_estimate_opposite

            # Update log volatility estimate
            volatility_update_opp = volatility_learning_rate * (prediction_error ** 2 / prediction_variance_opposite - 1)
            volatility_estimates[trial + 1, cue_opposite] = volatility_estimates[trial, cue_opposite] + volatility_update_opp
            volatility_estimates[trial + 1, cue_opposite] = np.clip(volatility_estimates[trial + 1, cue_opposite], -5, 2) # Avoid clipping

            # Update log stochasticity estimate
            stochasticity_update_opp = stochasticity_learning_rate * (prediction_error ** 2 / prediction_variance_opposite - 1)
            stochasticity_estimates[trial + 1, cue_opposite] = stochasticity_estimates[trial, cue_opposite] + stochasticity_update_opp
            stochasticity_estimates[trial + 1, cue_opposite] = np.clip(stochasticity_estimates[trial + 1, cue_opposite], -5, 2) # Avoid clipping

            # Save values for analyses
            reward_rate_means[trial + 1, cue_opposite] = reward_rate_mean[cue_opposite, 0] - reward_rate_mean[cue_opposite, 1]
            learning_rates[trial, cue_opposite] = learning_rate_opposite
            prediction_errors[trial, cue_opposite] = -prediction_error

        # Carry forward values for inactive cues
        for cues_remaining in np.setdiff1d(np.arange(n_cues), [cue, cue_opposite]):
            reward_rate_means[trial + 1, cues_remaining] = reward_rate_means[trial, cues_remaining]
            volatility_estimates[trial + 1, cues_remaining] = volatility_estimates[trial, cues_remaining]
            stochasticity_estimates[trial + 1, cues_remaining] = stochasticity_estimates[trial, cues_remaining]

    return reward_rate_means, learning_rates, prediction_errors, volatility_estimates, stochasticity_estimates