import numpy as np
from scipy.optimize import differential_evolution
from scipy.special import expit


def rw_transfer_llf(para, cue, outcome, action):
    """
    Transfer learning RW model

    args:
        para: parameter

        cue: happy/angry face, +0.5 denotes happy face, -0.5 denotes angry face

        outcome: reward/punishement, 1 denotes reward outcome, 0 denotes punishement outcome

        action: appraoch/avoidance, 1 denotes appraoch action, 0 denotes avoid action


    """

    alpha, tau, bias0, bias1, ep = para

    trial_len = len(action)
    nll = 0
    q_u = .5

    for t in range(trial_len):

        cue_t = cue[t]
        a_t = action[t]
        r_t = outcome[t]

        q_t = q_u if cue_t > 0 else 1 - q_u

        ## decision: e-softmax

        p_app = expit(tau * (2 * q_t - 1) + bias0 + bias1 * cue_t)
        p_app = (1 - ep) * p_app + ep / 2

        # log-likelihood
        if a_t == 1:
            p_choice = p_app
        else:
            p_choice = 1 - p_app
        p_choice = np.clip(p_choice, 1e-8, 1 - 1e-8)
        nll -= np.log(p_choice)

        ## align outcome to happy face appraoch action

        rev_outcome = r_t if a_t == 1 else 1 - r_t
        cue_outcome = rev_outcome if cue_t > 0 else 1 - rev_outcome

        ## update

        q_u += alpha * (cue_outcome - q_u)

    return nll


def rw_seprate_llf(para, cue, outcome, action):
    """
    Separate cue learning RW model

    args:
        para: parameter

        cue: happy/angry face, +0.5 denotes happy face, -0.5 denotes angry face

        outcome: reward/punishement, 1 denotes reward outcome, 0 denotes punishement outcome

        action: appraoch/avoidance, 1 denotes appraoch action, 0 denotes avoid action


    """

    alpha, tau, bias0, bias1, ep = para

    trial_len = len(action)
    nll = 0
    q_h = .5  ## happy face
    q_a = .5  ## angry face

    for t in range(trial_len):

        cue_t = cue[t]
        a_t = action[t]
        r_t = outcome[t]

        q_t = q_h if cue_t > 0 else q_a

        ## decision: e-softmax

        p_app = expit(tau * (2 * q_t - 1) + bias0 + bias1 * cue_t)
        p_app = (1 - ep) * p_app + ep / 2

        # log-likelihood
        if a_t == 1:
            p_choice = p_app
        else:
            p_choice = 1 - p_app
        p_choice = np.clip(p_choice, 1e-8, 1 - 1e-8)
        nll -= np.log(p_choice)

        ## align outcome to happy face appraoch action

        rev_outcome = r_t if a_t == 1 else 1 - r_t

        ## update

        pe = rev_outcome - q_t
        if cue[t] > 0:
            q_h += alpha * pe
        else:
            q_a += alpha * pe

    return nll


def fit_model(data):
    """
    Fit transfer learning and separate cue learning model

    args:

        data: list{'cue','outcome','action'}

    return:
        result: list('t_para','s_para','t_nll','s_nll')

    """
    cue = data['cue']
    outcome = data['outcome']
    action = data['choice']

    bounds = [
        (1e-4, 0.9999),  # alpha
        (1e-4, 20.0),  # tau
        (-8.0, 8.0),  # bias0
        (-8.0, 8.0),  # bias1
        (1e-4, 0.999)  # ep
    ]

    ## fit transfer learning model

    t_result = differential_evolution(
        rw_transfer_llf,
        bounds=bounds,
        args=(cue, outcome, action),
        maxiter=1000,
        popsize=30,
        polish=True,
        disp=True
    )

    ## fit separate cue learning model

    s_result = differential_evolution(
        rw_seprate_llf,
        bounds=bounds,
        args=(cue, outcome, action),
        maxiter=1000,
        popsize=30,
        polish=True,
        disp=True
    )

    return {'t_para': t_result.x,
            's_para': s_result.x,
            't_nll': t_result.fun,
            's_nll': s_result.fun}


def simulate_rw(para_true, n_trial=200, seed=0):
    rng = np.random.default_rng(seed)
    alpha, tau, bias0, bias1, ep = para_true

    cue = rng.choice([0.5, -0.5], size=n_trial)

    p_happy_app = 0.8
    p_angry_app = 0.2

    action = np.zeros(n_trial, dtype=int)
    outcome = np.zeros(n_trial, dtype=int)

    q_u = 0.5

    for t in range(n_trial):
        cue_t = cue[t]

        q_t = q_u if cue_t > 0 else 1 - q_u

        p_app = expit(tau * (2 * q_t - 1) + bias0 + bias1 * cue_t)
        p_app = (1 - ep) * p_app + ep / 2

        a_t = rng.binomial(1, p_app)
        action[t] = a_t

        if cue_t > 0:
            p_app_env = p_happy_app
        else:
            p_app_env = p_angry_app

        if a_t == 1:
            p_r = p_app_env
        else:
            p_r = 1 - p_app_env

        r_t = rng.binomial(1, p_r)
        outcome[t] = r_t

        #  update
        rev_outcome = r_t if a_t == 1 else 1 - r_t
        cue_outcome = rev_outcome if cue_t > 0 else 1 - rev_outcome
        q_u += alpha * (cue_outcome - q_u)

    return cue, outcome, action