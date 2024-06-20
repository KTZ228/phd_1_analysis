import pandas as pd


def determine_WSLS(row) -> (
    int):
    """ A simple function that accepts a row from a dataframe with the columns subjectively_correct_one_back,
    response and response_one_back and tells you what WSLS strategy is used by participants.
    Made to work together with the 'add_WSLS_column' function.

    Parameters
    ----------
    row
        A row of a dataframe.

    Returns
    -------
    strategy : int
        An integer describing the strategy used for that specific row.
    """
    if row['subjectively_correct_one_back'] == 'True' and row['response'] == row['response_one_back']:
        strategy = 2 #'win-stay'
    elif row['subjectively_correct_one_back'] == 'True' and row['response'] != row['response_one_back']:
        strategy = 1 #'win-shift'
    elif row['subjectively_correct_one_back'] == 'False' and row['response'] == row['response_one_back']:
        strategy = 4 #'lose-stay'
    elif row['subjectively_correct_one_back'] == 'False' and row['response'] != row['response_one_back']:
        strategy = 3 #'lose-shift'
    else:
        strategy = 0 #'undefined'

    return strategy


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

    test_dataframe = dataframe.sort_values(by=['WSLS'], ascending=[True])
    print(test_dataframe[['subjectively_correct_one_back', 'response_one_back', 'response', 'WSLS']])

    dataframe.drop(columns=['subjectively_correct_one_back', 'response_one_back'], inplace=True)

    return dataframe
