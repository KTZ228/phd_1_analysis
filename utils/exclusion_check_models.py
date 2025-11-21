import numpy as np
from scipy.optimize import differential_evolution
from scipy.special import expit

def rw_transfer_llf(para, cue, outcome, action):
    """
    Transfer learning RW (Rescorla-Wagner) model
    This model assumes a single Q-value that transfers between happy and angry faces

    args:
        para: parameter tuple (alpha, tau, bias0, bias1, ep)
        cue: happy/angry face, +0.5 denotes happy face, -0.5 denotes angry face
        outcome: reward/punishment, 1 denotes reward outcome, 0 denotes punishment outcome
        action: approach/avoidance, 1 denotes approach action, 0 denotes avoid action

    returns:
        nll: negative log-likelihood of the observed actions
    """

    # Unpack parameters
    alpha, tau, bias0, bias1, ep = para
    # alpha: learning rate
    # tau: inverse temperature (controls randomness in decision-making)
    # bias0: general bias towards approach/avoidance
    # bias1: cue-dependent bias (happy vs angry face)
    # ep: epsilon-greedy (probability of random choice)

    trial_len = len(action)
    nll = 0  # Initialize negative log-likelihood
    q_u = .5  # Initialize universal Q-value (shared between cues)

    for t in range(trial_len):
        cue_t = cue[t]
        a_t = action[t]
        r_t = outcome[t]

        # Transform universal Q-value based on cue type
        # For happy faces: use q_u directly
        # For angry faces: use inverted value (1 - q_u)
        q_t = q_u if cue_t > 0 else 1 - q_u

        ## Decision stage: epsilon-softmax
        # Calculate probability of approach action
        p_app = expit(tau * (2*q_t - 1) + bias0 + bias1 * cue_t)
        # Apply lapse rate (adds noise to account for random choices)
        p_app = (1-ep) * p_app + ep/2

        # Calculate log-likelihood for the observed action
        if a_t == 1:
            p_choice = p_app
        else:
            p_choice = 1 - p_app
        # Clip probability to avoid log(0)
        p_choice = np.clip(p_choice, 1e-8, 1 - 1e-8)
        nll -= np.log(p_choice)

        ## Outcome alignment stage
        # Align outcome to "happy face + approach" reference frame
        # This creates a consistent learning signal across different conditions

        # First, reverse outcome if avoid action was taken
        rev_outcome = r_t if a_t == 1 else 1 - r_t
        # Then, reverse again if angry face was shown
        cue_outcome = rev_outcome if cue_t > 0 else 1 - rev_outcome

        ## Learning stage: update universal Q-value
        q_u += alpha * (cue_outcome - q_u)

    return nll


def rw_seprate_llf(para, cue, outcome, action):
    """
    Separate cue learning RW model
    This model maintains separate Q-values for happy and angry faces

    args:
        para: parameter tuple (alpha, tau, bias0, bias1, ep)
        cue: happy/angry face, +0.5 denotes happy face, -0.5 denotes angry face
        outcome: reward/punishment, 1 denotes reward outcome, 0 denotes punishment outcome
        action: approach/avoidance, 1 denotes approach action, 0 denotes avoid action

    returns:
        nll: negative log-likelihood of the observed actions
    """

    # Unpack parameters (same as transfer model)
    alpha, tau, bias0, bias1, ep = para

    trial_len = len(action)
    nll = 0
    q_h = .5  # Initialize Q-value for happy face
    q_a = .5  # Initialize Q-value for angry face (separate from happy)

    for t in range(trial_len):
        cue_t = cue[t]
        a_t = action[t]
        r_t = outcome[t]

        # Select appropriate Q-value based on cue type
        q_t = q_h if cue_t > 0 else q_a

        ## Decision stage: epsilon-softmax (same as transfer model)
        p_app = expit(tau * (2*q_t - 1) + bias0 + bias1 * cue_t)
        p_app = (1-ep) * p_app + ep/2

        # Calculate log-likelihood
        if a_t == 1:
            p_choice = p_app
        else:
            p_choice = 1 - p_app
        p_choice = np.clip(p_choice, 1e-8, 1 - 1e-8)
        nll -= np.log(p_choice)

        ## Outcome alignment stage (simpler than transfer model)
        # Only reverse outcome based on action (approach/avoid)
        rev_outcome = r_t if a_t == 1 else 1 - r_t

        ## Learning stage: update cue-specific Q-value
        pe = rev_outcome - q_t  # Calculate prediction error
        if cue[t] > 0:
            q_h += alpha * pe  # Update happy face Q-value
        else:
            q_a += alpha * pe  # Update angry face Q-value

    return nll


def fit_model(data):
    """
    Fit both transfer learning and separate cue learning models to data
    Uses differential evolution optimization to find best parameters

    args:
        data: dictionary with keys:
            - 'cue': array of cue values
            - 'outcome': array of outcome values
            - 'action': array of action values

    return:
        result: dictionary containing:
            - 't_para': best-fit parameters for transfer model
            - 's_para': best-fit parameters for separate model
            - 't_nll': negative log-likelihood for transfer model
            - 's_nll': negative log-likelihood for separate model
    """

    # Extract data arrays
    cue = data['cue']
    outcome = data['outcome']
    action = data['action']

    # Define parameter bounds for optimization
    bounds = [
        (1e-4, 0.9999),   # alpha: learning rate (near 0 to near 1)
        (1e-4, 20.0),     # tau: inverse temperature (low = random, high = deterministic)
        (-8.0, 8.0),      # bias0: general approach/avoid bias
        (-8.0, 8.0),      # bias1: cue-dependent bias
        (1e-4, 0.999)     # ep: lapse rate (probability of random choice)
    ]

    ## Fit transfer learning model
    # Uses differential evolution (global optimization algorithm)
    t_result = differential_evolution(
            rw_transfer_llf,
            bounds=bounds,
            args=(cue, outcome, action),
            maxiter=1000,      # Maximum iterations
            popsize=30,         # Population size for evolution
            polish=True,        # Use local optimization after global search
            disp=True           # Display optimization progress
            )

    ## Fit separate cue learning model
    # Same optimization settings as transfer model
    s_result = differential_evolution(
            rw_seprate_llf,
            bounds=bounds,
            args=(cue, outcome, action),
            maxiter=1000,
            popsize=30,
            polish=True,
            disp=True
            )

    # Return results for both models
    return {'t_para': t_result.x,      # Best parameters for transfer model
            's_para': s_result.x,       # Best parameters for separate model
            't_nll': t_result.fun,      # Best NLL for transfer model
            's_nll': s_result.fun}      # Best NLL for separate model


# simulate data
def simulate_rw(para_true, n_trial=440, seed=0):
    """
    Simulate behavior using the transfer learning RW model
    Generates synthetic data for a given set of parameters

    args:
        para_true: tuple of true parameters (alpha, tau, bias0, bias1, ep)
        n_trial: number of trials to simulate
        seed: random seed for reproducibility

    returns:
        cue: array of randomly generated cues
        outcome: array of simulated outcomes
        action: array of simulated actions
    """

    # Initialize random number generator with seed
    rng = np.random.default_rng(seed)

    # Unpack parameters
    alpha, tau, bias0, bias1, ep = para_true

    # Randomly generate cues (50% happy, 50% angry faces)
    cue = rng.choice([0.5, -0.5], size=n_trial)

    # Define environment probabilities
    # Probability of reward when approaching happy face
    p_happy_app = 0.8
    # Probability of reward when approaching angry face
    p_angry_app = 0.2

    # Initialize arrays to store actions and outcomes
    action = np.zeros(n_trial, dtype=int)
    outcome = np.zeros(n_trial, dtype=int)

    # Initialize universal Q-value
    q_u = 0.5

    for t in range(n_trial):
        cue_t = cue[t]

        # Transform Q-value based on cue (same as transfer model)
        q_t = q_u if cue_t > 0 else 1 - q_u

        # Calculate probability of approach using epsilon-softmax
        p_app = expit(tau * (2 * q_t - 1) + bias0 + bias1 * cue_t)
        p_app = (1 - ep) * p_app + ep / 2

        # Generate action based on probability
        a_t = rng.binomial(1, p_app)
        action[t] = a_t

        # Determine environment's reward probability based on cue
        if cue_t > 0:  # Happy face
            p_app_env = p_happy_app
        else:          # Angry face
            p_app_env = p_angry_app

        # Calculate probability of reward based on action
        if a_t == 1:  # Approach action
            p_r = p_app_env
        else:         # Avoid action
            p_r = 1 - p_app_env

        # Generate outcome based on probability
        r_t = rng.binomial(1, p_r)
        outcome[t] = r_t

        # Update Q-value (same as transfer model)
        # Align outcome to "happy face + approach" reference frame
        rev_outcome = r_t if a_t == 1 else 1 - r_t
        cue_outcome = rev_outcome if cue_t > 0 else 1 - rev_outcome
        # Update universal Q-value
        q_u += alpha * (cue_outcome - q_u)

    return cue, outcome, action