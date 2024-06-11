import numpy as np
import pandas as pd
import os
import re
import glob

# Based on https://shawnrhoads.github.io/gu-psyc-347/module-03-01_Models-of-Learning.html


def unique_subject_ids_and_sessions(file_path: str) -> (
        list, list):
    """Extracts the subject ID's and sessions from the filenames.
    Made to work together with the 'list_files_with_date_and_subject_id' function.

    Parameters
    ----------
    file_path : str
        Path to the experiment output folder.

    Returns
    -------
    unique_subject_ids : list
        Unique subject IDs.
    unique_sessions : list
        Unique sessions.
    """
    # Use regex to match pattern to filenames
    pattern = r'parameters_per_stimuli_sub-(\d{3})_session-(\d{2}).csv$'
    unique_subject_ids = []
    unique_sessions = []
    for filename in os.listdir(file_path):
        match = re.match(pattern, filename)
        if match:
            # Extract sub and session numbers as int
            subject_id = int(match.group(1))
            session_number = int(match.group(2))
            # Append to the lists
            unique_subject_ids.append(subject_id)
            unique_sessions.append(session_number)

    unique_subject_ids = list(set(unique_subject_ids))
    unique_sessions = list(set(unique_sessions))
    return unique_subject_ids, unique_sessions


def list_sequences(file_path: str,
                   unique_subject_ids: list = None,
                   unique_sessions: list = None) -> (
        list):
    """This will create a list of the sequences of every subject and every session.

    Parameters
    ----------
    file_path : str
        Path to the sequence folder.
    unique_subject_ids : list(int)
        A list containing all subject ID's found in the folder.
    unique_sessions : list(int)
        A list containing all sessions found in the folder.

    Returns
    -------
    recent_files : list
        A list of all the most recent files of every subject and every session.
    """
    if unique_subject_ids is None or unique_sessions is None:
        # Creates a list of the most recent results for each subject ID and session
        unique_subject_ids, unique_sessions = unique_subject_ids_and_sessions(file_path)

    # Loop through subject ID's and sessions and pick the most recent result for each of them
    recent_files = []
    for subject_id, value in enumerate(unique_subject_ids):
        for session_number, value in enumerate(unique_sessions):
            file_structure_filtered = os.path.join(file_path,
                                                   f'*sub-{unique_subject_ids[subject_id]:003}_session-{unique_sessions[session_number]:02}*')
            list_files_filtered = glob.glob(file_structure_filtered)
            try:
                recent_file = max(list_files_filtered)
                recent_files.append(recent_file)
            except ValueError:
                print(
                    f'sub-{unique_subject_ids[subject_id]:003} did not complete session-{unique_sessions[session_number]:02}')

    return recent_files


def combine_sequence_files(recent_results: list) -> pd.DataFrame:
    """ This function takes a list of csv's and combines them into one big dataframe.

    Parameters
    ----------
    recent_results : list
        This list should contain the location of the to be imported CSV's with the full path.
        The filenames of each CSV should adhere to the format [experiment_output_sub-001_session-01*.csv].

    Returns
    -------
    combined_sequences_dataframe : pd.DataFrame
        A dataframe containing the sequences of all files listed in the folder.
    """
    try:
        if not isinstance(recent_results, list) or not all(isinstance(item, str) for item in recent_results):
            raise ValueError('Input must be a list of strings')
    except ValueError as error:
        print(f'error: {error}')

    combined_sequences_dataframe = pd.DataFrame()
    for list_number, value in enumerate(recent_results):
        result_dataframe = pd.read_csv(recent_results[list_number], sep=';')
        recent_result_basename = os.path.basename(recent_results[list_number])
        result_dataframe['subject_id'] = recent_result_basename.split('_')[3]
        result_dataframe['session'] = recent_result_basename.split('_')[4].removesuffix('.csv')
        combined_sequences_dataframe = pd.concat([combined_sequences_dataframe, result_dataframe], ignore_index=True)

    combined_sequences_dataframe.drop(columns=['iti', 'reinforcement_condition', 'face_type', 'stimuli_name'], inplace=True)
    return combined_sequences_dataframe


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
