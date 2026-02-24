import pandas as pd


def add_WSLS_column(dataframe: pd.DataFrame) -> (
        pd.DataFrame):
    """ Function to use the subjectively or objectively correct data and the responses to determine when the participant
    stayed with the current response, shifted when lost and vice versa.

    Parameters
    ----------
    dataframe: pd.DataFrame
        A dataframe that must contain the subject_id, session, stimuli_type, trial, subjectively_correct and the response.

    Returns
    -------
    dataframe: pd.DataFrame
        A dataframe containing the new columns subjectively_correct_previous_trial, response_previous_trial and WSLS.
    """

    # Orders the dataframe on the four following columns so that we can compare trials of the same stimuli condition
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    # Takes the values from 'subjectively_correct' and shifts them by one to look back at a previous trial
    dataframe['subjectively_correct_previous_trial'] = dataframe.groupby('stimuli_type')['subjectively_correct'].shift(1)

    # Determine whether participants stuck with their choices
    dataframe['response_previous_trial'] = dataframe.groupby('stimuli_type')['response'].shift(1)
    dataframe['stay'] = (dataframe['response'] == dataframe['response_previous_trial']).astype(int) # same_response_as_previous_trial

    # Determine choice stickiness
    dataframe['response_before_previous_trial'] = dataframe.groupby('stimuli_type')['response'].shift(2)
    dataframe['choicestickiness'] = (dataframe['response_previous_trial'] == dataframe['response_before_previous_trial']).astype(int)

    print(dataframe[['subject_id','session','subjectively_correct_previous_trial','subjectively_correct','stay']])

    return dataframe

