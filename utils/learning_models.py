import pandas as pd


def determine_WS(row,
                 subjective_or_objective: str) -> (
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
    match subjective_or_objective:
        case 'subjective':
            correct_one_back = str(row['subjectively_correct_one_back'])
        case 'objective':
            correct_one_back = str(row['objectively_correct_one_back'])

    if correct_one_back == 'True' and row['same_response_as_one_back'] == 1:
        strategy = 1 #'win-stay'
    elif correct_one_back == 'True' and row['same_response_as_one_back'] != 1:
        strategy = -1 #'win-shift'
    elif correct_one_back == 'False' and row['same_response_as_one_back'] == 1:
        strategy = 0 #'lose-stay'
    elif correct_one_back == 'False' and row['same_response_as_one_back'] != 1:
        strategy = 0 #'lose-shift'
    else:
        strategy = 0 #'undefined'

    return strategy


def determine_LS(row,
                 subjective_or_objective: str) -> (
    int):
    """ A simple function that accepts a row from a dataframe with the columns subjectively_correct_one_back,
    response and response_one_back and tells you what LS strategy is used by participants.
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
    match subjective_or_objective:
        case 'subjective':
            correct_one_back = str(row['subjectively_correct_one_back'])
        case 'objective':
            correct_one_back = str(row['objectively_correct_one_back'])

    if correct_one_back == 'True' and row['same_response_as_one_back'] == 1:
        strategy = 0 #'win-stay'
    elif correct_one_back == 'True' and row['same_response_as_one_back'] != 1:
        strategy = 0 #'win-shift'
    elif correct_one_back == 'False' and row['same_response_as_one_back'] == 1:
        strategy = -1 #'lose-stay'
    elif correct_one_back == 'False' and row['same_response_as_one_back'] != 1:
        strategy = 1 #'lose-shift'
    else:
        strategy = 0 #'undefined'

    return strategy


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
        A dataframe containing the new columns subjectively_correct_one_back, response_one_back and WSLS.
    """

    # Orders the dataframe on the four following columns so that we can compare trials of the same stimuli condition
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    # Takes the values from 'subjectively_correct' and shifts them by one to look back at a previous trial
    dataframe['subjectively_correct_one_back'] = dataframe.groupby('stimuli_type')['subjectively_correct'].shift(1)
    dataframe['objectively_correct_one_back'] = dataframe.groupby('stimuli_type')['objectively_correct'].shift(1)

    # Takes the values from 'response' and shifts them by one to look back at a previous trial
    dataframe['response_one_back'] = dataframe.groupby('stimuli_type')['response'].shift(1)
    dataframe['same_response_as_one_back'] = (dataframe['response'] == dataframe['response_one_back']).astype(int)
    dataframe['response_two_back'] = dataframe.groupby('stimuli_type')['response'].shift(2)
    dataframe['choicestickiness'] = (dataframe['response_one_back'] == dataframe['response_two_back']).astype(int)

    dataframe['WS_subjective'] = dataframe.apply(determine_WS, args=('subjective',), axis=1)
    dataframe['LS_subjective'] = dataframe.apply(determine_LS, args=('subjective',), axis=1)
    dataframe['WS_objective'] = dataframe.apply(determine_WS, args=('objective',), axis=1)
    dataframe['LS_objective'] = dataframe.apply(determine_LS, args=('objective',), axis=1)

    print(dataframe[['subject_id','session','subjectively_correct_one_back','subjectively_correct','same_response_as_one_back','WS_subjective','LS_subjective']])
    print(dataframe[['subject_id','session','objectively_correct_one_back','objectively_correct','same_response_as_one_back','WS_objective','LS_objective']])

    return dataframe

