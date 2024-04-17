import numpy as np

# Based on https://shawnrhoads.github.io/gu-psyc-347/module-03-01_Models-of-Learning.html


def simulate_random_responders(bias: float,
                               trials: int,
                               mu: list[float]):
    """Model to simulate random responders with a bias towards one of two options.

    Parameters
    ----------
    bias : float
        The bias of the responder for one of two choices. [between 0 and 1]
    trials : int
        The amount of trials.
    mu : list[float]
        A list containing floats for the chance that each choice results in a positive outcome.

    Returns
    -------
    choices : numpy.ndarray
        all choices
    responses : numpy.ndarray
        all rewards
    """

    choices = np.zeros(trials, dtype=int)
    rewards = np.zeros(trials, dtype=int)

    for trial in range(trials):

        # compute choice probabilities
        probability = [bias, 1-bias]

        # make choice according to choice probabilities
        choices[trial] = np.random.choice(range(len(mu)), p=probability)

        # generate reward based on choice
        rewards[trial] = np.random.rand() < mu[choices[trial]]

    return choices, rewards


def simulate_win_stay_lose_shift(epsilon: float,
                                 trials: int,
                                 mu_sequence: list[float]):
    """Model to simulate responders that base their decision to stay or shift on the previous trial only.

    Parameters
    ----------
    epsilon : float
        Random noise. [between 0 and 1]
    trials : int
        The amount of trials.
    mu_sequence : list[float]
        A list containing floats for the chance that each choice results in a positive outcome.

    Returns
    -------
    choices : numpy.ndarray
        all choices
    responses : numpy.ndarray
        all rewards
    """

    choices = np.zeros(trials, dtype=int)
    rewards = np.zeros(trials, dtype=int)

    # last reward/action (initialize as nan)
    last_reward = np.nan
    last_choice = np.nan

    for trial in range(trials):

        # Calculate mu for current trial (added by Kenneth)
        mu = mu_sequence[trial]
        mu = [round(1-mu, 1), mu]

        # compute choice probabilities
        if np.isnan(last_reward):

            # first trial choose randomly
            probability = [0.5, 0.5]

        else:

            # choice depends on last reward
            if last_reward == 1:

                # win stay (with probability 1-epsilon)
                probability = [(epsilon/2) * i for i in [1, 1]]
                probability[last_choice] = 1 - epsilon/2
            else:

                # lose shift (with probability 1-epsilon)
                probability = [(1 - epsilon/2) * i for i in [1, 1]]
                probability[last_choice] = epsilon / 2

        # make choice according to choice probabilities
        choices[trial] = np.random.choice(range(len(mu)), p=probability)

        # generate reward based on choice
        rewards[trial] = np.random.rand() < mu[choices[trial]]

        last_choice = choices[trial]
        last_reward = rewards[trial]

    return choices, rewards


def simulate_rescorla_wagner(alpha,
                             theta,
                             trials,
                             mu_sequence,
                             noisy_choice=True):
    """Model to simulate responders that operate in accordance with the Rescorla-Wagner model.

    Parameters
    ----------
    alpha : float
        not sure yet
    theta: float
        not sure yet
    trials : int
        The amount of trials.
    mu_sequence : list[float]
        A list containing floats for the chance that each choice results in a positive outcome.
    noisy_choice: bool
        not sure yet

    Returns
    -------
    choices : numpy.ndarray
        all choices
    responses : numpy.ndarray
        all rewards
    Q_stored: numpy.ndarray
        not sure yet
    """

    choices = np.zeros(trials, dtype=int)
    responses = np.zeros(trials, dtype=int)

    q_stored = np.zeros((2, trials), dtype=float)
    q = [0.5, 0.5]

    for trial in range(trials):

        # Calculate mu for current trial (added by Kenneth)
        mu = mu_sequence[trial]
        mu = [round(1-mu, 1), mu]

        # store values for Q_{t+1}
        q_stored[:, trial] = q

        # compute choice probabilities
        p0 = np.exp(theta*q[0]) / (np.exp(theta*q[0]) + np.exp(theta*q[1]))
        p1 = 1 - p0

        # make choice according to choice probabilities
        # as weighted coin flip to make a choice
        # choose stim 0 if random number is in the [0 p0] interval
        # and 1 otherwise
        if noisy_choice:
            if np.random.random_sample(1) < p0:
                choices[trial] = 0
            else:
                choices[trial] = 1
        else:  # make choice without noise
            choices[trial] = np.argmax([p0, p1])

        # generate reward based on reward probability
        responses[trial] = np.random.rand() < mu[choices[trial]]

        # update values
        delta = responses[trial] - q[choices[trial]]
        q[choices[trial]] = q[choices[trial]] + alpha * delta

    return choices, responses, q_stored
