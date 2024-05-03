import pandas as pd

def determine_WSLS(row):
    if (row['subjectively_correct_one_back'] == True and row['response'] == 'up' and row['response_one_back'] == 'up') or (
            row['subjectively_correct_one_back'] == True and row['response'] == 'down' and row['response_one_back'] == 'down'):
        return 'win-stay'
    elif (row['subjectively_correct_one_back'] == True and row['response'] == 'up' and row['response_one_back'] == 'down') or (
            row['subjectively_correct_one_back'] == True and row['response'] == 'down' and row['response_one_back'] == 'up'):
        return 'win-shift'
    elif (row['subjectively_correct_one_back'] == False and row['response'] == 'up' and row['response_one_back'] == 'up') or (
            row['subjectively_correct_one_back'] == False and row['response'] == 'down' and row['response_one_back'] == 'down'):
        return 'lose-stay'
    elif (row['subjectively_correct_one_back'] == False and row['response'] == 'up' and row['response_one_back'] == 'down') or (
            row['subjectively_correct_one_back'] == False and row['response'] == 'down' and row['response_one_back'] == 'up'):
        return 'lose-shift'
    else:
        return 'undefined'


def add_WSLS_column(dataframe: pd.DataFrame) -> (
        pd.DataFrame):
    """ Function to use the subjectively correct data and the responses to determine when the participant
    stayed with the current response, shifted when lost and vice-versa.

    Parameters
    ----------
    dataframe: pd.DataFrame
        A dataframe that must contain the subject_id, session, stimuli_type, trial, subjectively_correct and the response.

    Returns
    -------
    dataframe: pd.DataFrame
        A dataframe containing the new columns subjectively_correct_one_back, response_one_back and WSLS.
    """

    # Orders the dataframe on the four following columns so that we can compare trials of the same stimuli condition
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    # Takes the values from 'subjectively_correct' and shifts them by one to look back at a previous trial
    dataframe['subjectively_correct_one_back'] = dataframe.groupby('stimuli_type')['subjectively_correct'].shift(1)

    # Takes the values from 'response' and shifts them by one to look back at a previous trial
    dataframe['response_one_back'] = dataframe.groupby('stimuli_type')['response'].shift(1)

    dataframe['WSLS'] = dataframe.apply(determine_WSLS, axis=1)

    return dataframe