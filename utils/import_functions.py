import os
import glob
import re
import pandas as pd
import numpy as np
from collections import defaultdict


def unique_subject_ids_and_sessions(file_path: str,
                                    pattern: str) ->\
        (list, list):
    """Extracts the subject ID's and sessions from the filenames in subdirectories.

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
    unique_subject_ids = []
    unique_sessions = []

    # Walk through all subdirectories
    for root, dirs, files in os.walk(file_path):
        for filename in files:
            match = re.match(pattern, filename)
            if match:
                subject_id = int(match.group(1))
                session_number = int(match.group(2))
                unique_subject_ids.append(subject_id)
                unique_sessions.append(session_number)

    unique_subject_ids = list(set(unique_subject_ids))
    unique_sessions = list(set(unique_sessions))
    return unique_subject_ids, unique_sessions


def list_files_with_date_and_subject_id(file_path: str,
                                        unique_subject_ids: list = [],
                                        unique_sessions: list = [],
                                        selected_pattern: str = 'behavioural_output',
                                        print_output = False) -> list:
    """This will create a list of the most recent files of every subject and every session.

    Parameters
    ----------
    file_path : str
        Path to the experiment output folder.
    unique_subject_ids : list(Int64)
        A list containing all subject IDs found in the folder.
    unique_sessions : list(Int64)
        A list containing all sessions found in the folder.
    selected_pattern : str
        Either 'joystick_output' or 'behavioural_output'.
    print_output : bool
        If True, the list of recent files will be printed to the console.

    Returns
    -------
    recent_files : list
        A list of the most recent files of every subject and every session.
    """
    # Choose the pattern to look for
    if selected_pattern == 'joystick_output':
        pattern = re.compile(r'joystick_output_sub-(\d{3})_session-(\d{2})_.*\.csv$')
    elif selected_pattern == 'speakup':
        pattern = re.compile(r'sub-(\d{2})_d(\d{1})_rlt_behavioural_output.csv$')
    elif selected_pattern == 'africa':
        pattern = re.compile(r'sub-(\d{2})_ses(\d{1})_rlt_behavioural_output.csv$')
    else:
        pattern = re.compile(r'behavioural_output_sub-(\d{3})_session-(\d{2})_.*\.csv$')

    # Single walk through the directory tree
    file_dict = defaultdict(list)

    for root, dirs, files in os.walk(file_path):
        # Filter files that start with the right selected_pattern first (quick string check)
        for file in files:
            #if file.startswith(selected_pattern) and file.endswith('.csv'):
            match = pattern.match(file)
            if match:
                subject_id = int(match.group(1))
                session_num = int(match.group(2))

                # If specific subjects/sessions are requested, filter here
                if unique_subject_ids and subject_id not in unique_subject_ids:
                    continue
                if unique_sessions and session_num not in unique_sessions:
                    continue

                full_path = os.path.join(root, file)
                file_dict[(subject_id, session_num)].append(full_path)

    # If no specific subjects/sessions were provided, use all found
    if not unique_subject_ids and not unique_sessions:
        if not file_dict:
            raise Exception('No files found')
        unique_subject_ids = sorted(set(key[0] for key in file_dict.keys()))
        unique_sessions = sorted(set(key[1] for key in file_dict.keys()))

    # Build the result list with the most recent file for each combination
    recent_files = []
    for subject_id in unique_subject_ids:
        for session_number in unique_sessions:
            files = file_dict.get((subject_id, session_number), [])
            if files:
                # Get the most recent file (lexicographically last)
                recent_file = max(files)
                recent_files.append(recent_file)
            else:
                print(f'sub-{subject_id:03d} did not complete session-{session_number:02d}')

    if not recent_files:
        raise Exception('No files found')
    if print_output:
        print(recent_files)

    return recent_files


def combine_result_files(recent_results: list) -> pd.DataFrame:
    """ This function takes a list of csv's and combines them into one big dataframe.

    Parameters
    ----------
    recent_results : list
        This list should contain the location of the to be imported CSV's with the full path.
        The filenames of each CSV should adhere to one of the following formats:
        - sub-<id>_d<session>_rlt_behavioural_output.csv  (speakup/africa datasets)
        - behavioural_output_sub-<id>_session-<session>_*.csv  (TUS/pilot datasets)

    Returns
    -------
    combined_results_dataframe : pd.DataFrame
        A dataframe containing the results of all files listed in recent_results.
    """
    try:
        if not isinstance(recent_results, list) or not all(isinstance(item, str) for item in recent_results):
            raise ValueError('Input must be a list of strings')
    except ValueError as error:
        print(f'error: {error}')

    patterns = [
        re.compile(r'sub-(\d+)_(?:d|ses)(\d+)_rlt_behavioural_output\.csv$'),       # speakup/africa
        re.compile(r'behavioural_output_sub-(\d+)_session-(\d+)_.*\.csv$'),  # TUS/pilot
    ]

    combined_results_dataframe = pd.DataFrame()
    for list_number, value in enumerate(recent_results):
        result_dataframe = pd.read_csv(recent_results[list_number], sep=';')
        recent_result_basename = os.path.basename(recent_results[list_number])

        subject_id, session = None, None
        for pattern in patterns:
            match = pattern.search(recent_result_basename)
            if match:
                subject_id = match.group(1)
                session = match.group(2)
                break

        if subject_id is None:
            raise ValueError(f'Could not parse subject_id/session from filename: {recent_result_basename}')

        result_dataframe['subject_id'] = int(subject_id)
        result_dataframe['session'] = int(session)
        combined_results_dataframe = pd.concat([combined_results_dataframe, result_dataframe], ignore_index=True)

    return combined_results_dataframe


def combine_joystick_with_results(dataframe: pd.DataFrame,
                                  joystick_filenames: list,
                                  print_output = False) -> (
        pd.DataFrame):
    """ This function takes a dataframe containing the results and a dataframe containing the joystick data and combines them.

    Parameters
    ----------
    dataframe : pd.DataFrame
        A dataframe containing the results of the experiment.
    joystick_filenames : list
        A list of file locations of the joystick data.
    print_output : bool
        If True, the first 100 rows of the combined dataframe will be printed to the console.

    Returns
    -------
    joystick_dataframe : pd.DataFrame
        A dataframe containing the results of all files listed in recent_results.
    """
    # First, combine the joystick data into one big dataframe
    try:
        if not isinstance(joystick_filenames, list) or not all(isinstance(item, str) for item in joystick_filenames):
            raise ValueError('Input must be a list of strings')
    except ValueError as error:
        print(f'error: {error}')

    joystick_dataframe_combined = pd.DataFrame()
    joystick_pattern = re.compile(r'joystick_output_sub-(\d+)_session-(\d+)_.*\.csv$')
    for list_number, value in enumerate(joystick_filenames):
        joystick_dataframe_single = pd.read_csv(joystick_filenames[list_number], sep=';')
        joystick_dataframe_single['joystick_location_difference'] = joystick_dataframe_single['location_y'].diff()
        joystick_dataframe_single['joystick_time_difference'] = joystick_dataframe_single['timepoint'].diff()
        joystick_dataframe_single['joystick_acceleration'] = joystick_dataframe_single['location_y'].diff() / joystick_dataframe_single['timepoint'].diff()
        recent_result_basename = os.path.basename(joystick_filenames[list_number])
        joystick_match = joystick_pattern.search(recent_result_basename)
        if joystick_match is None:
            raise ValueError(f'Could not parse subject_id/session from filename: {recent_result_basename}')
        joystick_dataframe_single['subject_id'] = int(joystick_match.group(1))
        joystick_dataframe_single['session'] = int(joystick_match.group(2))
        joystick_dataframe_combined = pd.concat([joystick_dataframe_combined, joystick_dataframe_single], ignore_index=True)

    # Remove the first row of every trial since the acceleration can be very large
    joystick_dataframe_combined = joystick_dataframe_combined[joystick_dataframe_combined['trial'] == joystick_dataframe_combined['trial'].shift(1)]

    # Rename some columns in the joystick dataframe
    joystick_dataframe_combined = joystick_dataframe_combined.rename(columns={'datapoint': 'joystick_datapoint', 'location_y': 'joystick_location', 'timepoint': 'joystick_timepoint'})
    if print_output:
        print(joystick_dataframe_combined.head(100))

    # Then, combine it with the results dataframe
    dataframe_with_joystick_data = pd.merge(
        dataframe,
        joystick_dataframe_combined,
        on=['subject_id', 'session', 'trial'],
        how='left'
    )

    return dataframe_with_joystick_data


def remove_invalid_files(recent_files: list,
                         raw_output_path: str):
    """ This function removes the invalid files from the list of recent files.
    Parameters
    ----------
    recent_files : list
        A list of strings containing the most recent files of every subject and every session.
    Returns
    -------
    recent_files : list
        A list of strings containing the most recent files of every subject and every session, excluding the invalid files.
    """
    # Read the CSV file to determine what has to be filtered out
    invalid_data = pd.read_csv(f'{raw_output_path}/../incomplete_data.csv', delimiter=';')
    combinations = {
        f"sub-{row['subject-id']:03}_session-{row['session-number']:02}"
        for _, row in invalid_data[invalid_data['datatype'] == 'beh'].iterrows()
    }
    print(f'These participants will be excluded: {combinations}\n')

    patterns = [re.compile(re.escape(combo)) for combo in combinations]
    # Filter the list: remove any string that contains one of the combinations
    recent_files = [
        item for item in recent_files
        if not any(pattern.search(item) for pattern in patterns)
    ]
    return recent_files


def flip_joystick_data(dataframe: pd.DataFrame) -> pd.DataFrame:
    # List of subject_session combinations to update
    match_list = ['4_4']

    # Create a new column that combines subject_id and session in the same format as the list.
    dataframe['sub_session'] = dataframe['subject_id'].astype(str) + '_' + \
                                                dataframe['session'].astype(str)

    # Create a mask for rows that match any of the combinations in match_list.
    mask = dataframe['sub_session'].isin(match_list)

    # For 'probability_condition', swap 80 with 20 and vice versa.
    dataframe.loc[mask, 'probability_condition'] = (
        dataframe.loc[mask, 'probability_condition']
        .map({80: 20, 20: 80})
    )

    # For 'response', swap 'avoid' with 'approach' and vice versa.
    dataframe.loc[mask, 'response'] = (
        dataframe.loc[mask, 'response']
        .map({'avoid': 'approach', 'approach': 'avoid'})
    )

    # Optionally, drop the helper column
    dataframe.drop(columns='sub_session', inplace=True)

    return(dataframe)


def check_congruency(row,
                     binary_output: bool = False):
    """ Functions that reads a row and sees whether the conditions are congruent or not.
    So here, we code the most rewarding movement being where you have to push the joystick away from you for happy faces as incongruent.

    Parameters
    ----------
    row : pd.DataFrame.row
    binary_output : bool

    Returns
    -------
    condition : str
        A string containing the congruency condition for the given row.
    """
    if (row['probability_condition'] > 50 and row['stimuli_type'] == 1) or (
                row['probability_condition'] < 50 and row['stimuli_type'] == 2):
        if binary_output:
            condition = 1
        else:
            condition = 'congruent'
    elif (row['probability_condition'] < 50 and row['stimuli_type'] == 1) or (
                row['probability_condition'] > 50 and row['stimuli_type'] == 2):
        if binary_output:
            condition = -1
        else:
            condition = 'incongruent'
    else:
        if binary_output:
            condition = 0
        else:
            condition = 'undefined'

    return condition


def check_valence(row,
                  binary_output: bool = False):
    """ Functions that reads a row and notes the valence.

    Parameters
    ----------
    row : pd.DataFrame.row
    binary_output : bool

    Returns
    -------
    condition : str
        A string containing the valence for the given row.
    """
    if row['stimuli_type'] == 1:
        if binary_output:
            emotional_valence = -1
        else:
            emotional_valence = 'angry'
    elif row['stimuli_type'] == 2:
        if binary_output:
            emotional_valence = 1
        else:
            emotional_valence = 'happy'
    else:
        if binary_output:
            emotional_valence = 0
        else:
            emotional_valence = 'no_emotion'

    return emotional_valence


def check_most_rewarding_response(row,
                        binary_output: bool = False):
    """ Functions that reads a row and notes the response that would have resulted in the highest chance of a reward.

    Parameters
    ----------
    row : pd.DataFrame.row
    binary_output : bool

    Returns
    -------
    condition : str
        A string containing the valence for the given row.
    """
    if row['probability_condition'] > 50:
        if binary_output:
            most_rewarding_response = -1
        else:
            most_rewarding_response = 'avoid'
    elif row['probability_condition'] < 50:
        if binary_output:
            most_rewarding_response = 1
        else:
            most_rewarding_response = 'approach'
    else:
        if binary_output:
            most_rewarding_response = 0
        else:
            most_rewarding_response = 'no_most_rewarding_response'

    return most_rewarding_response


def check_volatility(dataframe: pd.DataFrame,
                     binary_output: bool = False) -> (
        pd.DataFrame):
    """ Functions that reads a row and sees whether it belongs to a block that is volatile or stable.
    WARNING: the definition between a stable and volatile period is hard-coded at 15. Change is necessary.

    Parameters
    ----------
    dataframe : pd.DataFrame

    Returns
    -------
    dataframe : pd.DataFrame
        The same dataframe containing the new column info.
    """

    # Think about changing this to count trials from both variables as trials since reversal since they switch together

    # This differentiates between a stable and volatile block
    stable_cutoff = 24

    # Initialize the new column with empty strings
    dataframe['volatility'] = ''
    if binary_output:
        previous_label = -1
    else:
        previous_label = 'volatile'

    # Sort based on stimuli_types
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'],
                                      ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    # Variables to track the current streak
    start_index = 0

    # Iterate over the rows of the dataframe
    for index in range(1, len(dataframe)):
        # Check if 'probability_condition', 'subject_id', or 'stimuli_type' changes
        if (dataframe.loc[index, 'probability_condition'] != dataframe.loc[start_index, 'probability_condition'] or
                dataframe.loc[index, 'subject_id'] != dataframe.loc[start_index, 'subject_id'] or
                dataframe.loc[index, 'stimuli_type'] != dataframe.loc[start_index, 'stimuli_type'] or
                dataframe.loc[index, 'session'] != dataframe.loc[start_index, 'session'] or
                index == len(dataframe)-1):

            # Calculate the streak length
            streak_length = index - start_index

            # Determine if the streak is 'short' or 'long'
            if binary_output:
                label = 1 if streak_length < stable_cutoff else -1
                starting_label = 1
            else:
                label = 'volatile' if streak_length < stable_cutoff else 'stable'
                starting_label = 'volatile'

            # Assign the label to the 'volatility' column for the streak
            ## First part ensures that the last short block is labelled correctly
            if index == len(dataframe)-1:
                dataframe.loc[start_index:index, 'volatility'] = previous_label
            elif (dataframe.loc[index, 'subject_id'] != dataframe.loc[start_index, 'subject_id'] or
                dataframe.loc[index, 'stimuli_type'] != dataframe.loc[start_index, 'stimuli_type'] or
                dataframe.loc[index, 'session'] != dataframe.loc[start_index, 'session']):
                dataframe.loc[start_index:index - 1, 'volatility'] = previous_label
            ## Ensures that the first block for every participant is labelled as 'starting_label'
            elif (dataframe.loc[index, 'subject_id'] != dataframe.loc[max(start_index - 1, 0), 'subject_id'] or
                dataframe.loc[index, 'stimuli_type'] != dataframe.loc[max(start_index - 1, 0), 'stimuli_type'] or
                dataframe.loc[index, 'session'] != dataframe.loc[max(start_index -1, 0), 'session']):
                dataframe.loc[start_index:start_index+10 - 1, 'volatility'] = starting_label
                dataframe.loc[start_index+10:index - 1, 'volatility'] = label
            ## Ensures that the first 10 trials or block of a new volatile and stable period are labelled as the previous block
            elif label == 'stable' and previous_label == 'volatile' or label == -1 and previous_label == 1:
                dataframe.loc[start_index:start_index+10 - 1, 'volatility'] = previous_label
                dataframe.loc[start_index+10:index - 1, 'volatility'] = label
            else:
            ## Ensures that the blocks after the first 10 trials are labelled as the previous block
                dataframe.loc[start_index:index - 1, 'volatility'] = previous_label

            # Update the current_value and start_index for the next streak
            previous_label = label
            start_index = index

    # Reset the original order of the dataframe
    dataframe = dataframe.sort_values(by=['subject_id','session','trial'], ascending=[True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    return dataframe

def check_trials_since_reversal_combined_learning(dataframe, min_gap=6):
    """Compute trials since reversal, treating both stimuli_types as one stream.
    Reversals occurring within min_gap rows of each other are merged."""
    dataframe = dataframe.reset_index(drop=True)
    counts = np.zeros(len(dataframe), dtype=int)

    for _, group in dataframe.groupby(['subject_id', 'session'], sort=False):
        is_reversal = (
            group.groupby('stimuli_type')['probability_condition']
            .transform(lambda x: x.ne(x.shift()).fillna(True))
            .values
        )
        kept = np.zeros_like(is_reversal, dtype=bool)
        last_kept = -min_gap
        for i, ch in enumerate(is_reversal):
            if ch and (i - last_kept) >= min_gap:
                kept[i] = True
                last_kept = i
        block_id = kept.cumsum()
        cumcount = pd.Series(block_id).groupby(block_id).cumcount().values

        counts[group.index.values] = cumcount

    return counts


def check_stimulation_condition(row,
                                randomisation_list: pd.DataFrame,
                                binary_output: bool = False):
    """ Reads a row and returns the stimulation condition by looking it up
    in the randomisation list.

    Parameters
    ----------
    row : pd.DataFrame.row
    randomisation_list : pd.DataFrame
        Dataframe loaded from the randomisation CSV.
    binary_output : bool

    Returns
    -------
    stimulation_condition : str or int
        The stimulation condition (e.g. 'target_1') or an integer (1/2/3)
        if binary_output is True. Returns 'no_stimulation' / 0 for session 1.
    """
    subject_id = f'sub-{int(row["subject_id"]):03d}'
    session_col = f'ses-mri{int(row["session"]):02d}'

    if session_col not in randomisation_list.columns:
        return 0 if binary_output else 'no_stimulation'

    subject_row = randomisation_list[randomisation_list['subject-id'] == subject_id]

    if subject_row.empty:
        raise ValueError(f'Subject {subject_id} not found in randomisation list.')

    target = subject_row[session_col].values[0]

    if binary_output:
        return int(target.split('_')[1])

    target_mapping = {'target_1': 'amygdala', 'target_2': 'dacc', 'target_3': 'sham'}
    return target_mapping.get(target, target)


def add_WSLS_columns(dataframe: pd.DataFrame) -> (
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
        A dataframe containing the new columns previous_outcome, previous_response and WSLS.
    """

    # Takes the values from 'subjectively_correct' and shifts them by one to look back at a previous trial
    dataframe['previous_outcome'] = dataframe.groupby(['subject_id', 'session', 'stimuli_type'])['subjectively_correct'].shift(1)
    mapping = {'True': 1, 'False': -1}
    dataframe['previous_outcome'] = dataframe['previous_outcome'].map(mapping).fillna(0).astype('Int64')

    # Determine whether participants stuck with their choices
    dataframe['previous_response'] = dataframe.groupby(['subject_id', 'session', 'stimuli_type'])['response'].shift(1)
    invalid_strings = ['late']
    mask = (
            ~dataframe['response'].isin(invalid_strings)
            & ~dataframe['previous_response'].isin(invalid_strings)
            & dataframe['response'].notna()
            & dataframe['previous_response'].notna()
    )
    dataframe['stay'] = (dataframe['response'] == dataframe['previous_response'])
    mapping = {True: 1, False: 0}
    dataframe['stay'] = dataframe['stay'].map(mapping)
    dataframe['stay'] = dataframe['stay'].where(mask, pd.NA).astype('Int64')

    # Determine Win-Stay
    post_win_mask = mask & (dataframe['previous_outcome'] == 1)
    dataframe['win-stay'] = pd.Series(pd.NA, index=dataframe.index, dtype='Int64')
    dataframe.loc[post_win_mask, 'win-stay'] = dataframe.loc[post_win_mask, 'stay']

    # Determine lose-stay
    post_loss_mask = mask & (dataframe['previous_outcome'] == -1)
    dataframe['lose-stay'] = pd.Series(pd.NA, index=dataframe.index, dtype='Int64')
    dataframe.loc[post_loss_mask, 'lose-stay'] = dataframe.loc[post_loss_mask, 'stay']

    return dataframe


def main(raw_output_path,
         unique_subject_ids,
         unique_sessions,
         dataset='TUS',
         binary_output=False,
         remove_reversals=False,
         remove_invalid_trials=True,
         print_output=False,
         fmri_analysis=False) -> pd.DataFrame:
    """ Main function that runs the import functions.

    Parameters
    ----------
    raw_output_path : str
        Path to the experiment output folder.
    unique_subject_ids : list('Int64')
        A list containing all subject IDs found in the folder.
    unique_sessions : list('Int64')
        A list containing all sessions found in the folder.
    dataset : string
        Since some datasets use older naming skemes, some columns have to be adjusted.
    binary_output : bool
        If True, the output will be in binary format.
    remove_reversals : bool
        If True, trials where a reversal occurred will be removed.
    remove_invalid_trials : bool
        If True, invalid files will be removed from the analysis.
    block_isolated : str
        If 'block_2', only block 2 will be analysed. If 'block_3', only block 3 will be analysed.
    print_output : bool
        If True, the dataframe will be printed to the console.
    fmri_analysis : bool
        If True, trials that would've normally been removed, now get an extra boolean column.
    selected_pattern : str
        Allows you to select the pattern of the output files.

    Returns
    -------
    dataframe_with_joystick_data : pd.DataFrame
        A dataframe containing the results of all files listed in recent_results.
    """

    # First, get a list of the behavioural datafiles
    recent_files = list_files_with_date_and_subject_id(raw_output_path, unique_subject_ids, unique_sessions, dataset, print_output)

    # Remove the invalid files
    if remove_invalid_trials:
        recent_files = remove_invalid_files(recent_files, raw_output_path)

    # Then, import all behavioural datasets and combine them into 1
    dataframe = combine_result_files(recent_files)

    # Change responses to approach and avoid
    mapping = {'up': 'avoid', 'down': 'approach'}
    dataframe['response'] = dataframe['response'].map(mapping)

    # Restructure the columns
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'],
                                      ascending=[True, True, True, True])

    # If we're analysing the pilot data, make some changes to ensure backwards compatibility of the analysis
    if dataset=='speakup' or dataset=='africa':
        dataframe.rename(columns={'iti': 'trial_duration'}, inplace=True)
        dataframe['stimuli_type'] = dataframe['stimuli_type'].replace(3, 2)

    if dataset=='pilot':
        dataframe = dataframe[dataframe['trial'].isin(range(0, 451))]

    # Checks if and compensates for when the joystick was flipped for any of the sessions
    dataframe = flip_joystick_data(dataframe)

    # Turns the performance values into boolean ones
    mapping = {'True': 1, 'False': 0, 'Even': 0, 'Late': 0}
    dataframe['objectively_correct'] = dataframe['objectively_correct'].astype(str)
    dataframe['objectively_correct_boolean'] = dataframe['objectively_correct'].map(mapping)
    dataframe['objectively_correct_boolean'] = dataframe['objectively_correct_boolean'].astype('Int64')
    dataframe['subjectively_correct'] = dataframe['subjectively_correct'].astype(str)
    dataframe['subjectively_correct_boolean'] = dataframe['subjectively_correct'].map(mapping)
    dataframe['subjectively_correct_boolean'] = dataframe['subjectively_correct_boolean'].astype('Int64')
    dataframe['subjectively_correct_boolean_one_back'] = dataframe['subjectively_correct_boolean'].shift(1)

    # Make congruency and hidden congruency columns
    dataframe['congruency'] = dataframe.apply(check_congruency, args=(binary_output,), axis=1)
    if print_output:
        print(dataframe[['stimuli_type', 'probability_condition', 'congruency']])

    # Make valence column
    dataframe['valence'] = dataframe.apply(check_valence, args=(binary_output,), axis=1)
    if print_output:
        print(dataframe[['stimuli_type', 'valence']])

    # Add WSLS column before removing trials
    dataframe = add_WSLS_columns(dataframe)

    # Create an untouched copy of the dataframe just before any of the trials are removed
    if fmri_analysis:
        dataframe_copy = dataframe.copy()

    # Make volatility column
    dataframe = dataframe[dataframe['probability_condition'] != 50]
    dataframe = dataframe.groupby('stimuli_type', group_keys=False).apply(lambda x: check_volatility(x, binary_output))
    if print_output:
        print(dataframe[['subject_id', 'session', 'stimuli_type', 'probability_condition', 'volatility']])

    # Make stimulation condition column
    if dataset in ('TUS', 'pilot'):
        randomisation_list = pd.read_csv('/Volumes/project/3025011.02/TUS_simulations/segmentation_data/dummy_randomisation_list.csv', sep=';')
        dataframe['stimulation_condition'] = dataframe.apply(check_stimulation_condition, args=(randomisation_list, binary_output,), axis=1)
        if print_output:
            print(dataframe[['subject_id', 'session', 'stimulation_condition']])
    elif dataset in ('speakup'):
        randomisation_list = pd.read_csv('/Volumes/4kenneth/190526/stimulation_condition.csv', sep=';')
        dataframe = dataframe.merge(randomisation_list, on='subject_id', how='left')
        if print_output:
            print(dataframe[['subject_id', 'session', 'stimulation_condition']])
    elif dataset in ('africa'):
        randomisation_list = pd.read_csv('/Volumes/4kenneth/RL_task-speakup_version_martin_southafrica/uwb_condition.csv', sep=';')
        dataframe = dataframe.merge(randomisation_list, on='subject_id', how='left')
        if print_output:
            print(dataframe[['subject_id', 'session', 'stimulation_condition']])

    # Add a column for the most rewarding response
    dataframe['most_rewarding_response'] = dataframe.apply(check_most_rewarding_response, args=(binary_output,), axis=1)
    # Make binary response column
    #mapping = {'avoid': 1, 'approach': -1}
    #dataframe['response_boolean'] = dataframe['response'].map(mapping)
    #dataframe['most_rewarding_response_boolean'] = dataframe['most_rewarding_response'].map(mapping)

    # Add a column that indicates how many trials ago the last reversal occurred
    group_change = (
            (dataframe['probability_condition'] != dataframe['probability_condition'].shift()) |
            (dataframe['subject_id'] != dataframe['subject_id'].shift()) |
            (dataframe['session'] != dataframe['session'].shift()) |
            (dataframe['stimuli_type'] != dataframe['stimuli_type'].shift())
    ).cumsum()

    dataframe['trials_since_reversal_separate_learning'] = (
        dataframe.groupby(group_change).cumcount()
    )

    # Reset order of dataframe
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'trial'], ascending=[True, True, True]).reset_index(drop=True)

    # Compute combined reversal counter (treats both stimuli_types together)
    dataframe['trials_since_reversal_combined_learning'] = check_trials_since_reversal_combined_learning(dataframe)

    # Caries on the valence at a reversal to determine whether people only learn from one cue or from both
    dataframe['valence_at_reversal'] = (
        dataframe['valence']
        .where(dataframe['trials_since_reversal_combined_learning'] == 0)
        .ffill()
    )
    dataframe['valence_at_reversal'] = dataframe['valence_at_reversal'].replace({
        'angry': 'angry_reverses_first',
        'happy': 'happy_reverses_first'
    })

    # Only remove the trials where the reversal occurred if the flag is set to True
    if remove_reversals:
        dataframe = dataframe[dataframe['trials_since_reversal_separate_learning'] != 0]

    if remove_invalid_trials:
        # Remove trials where RT < 50ms, please note that this number is arbitrary and can be changed
        dataframe = dataframe[dataframe['RT_s'] >= 0.05]

        # Remove late trials
        dataframe = dataframe[dataframe['objectively_correct'] != 'Late']

    # Now re-introduce the removed rows
    if fmri_analysis:
        unique_trial_identifiers = ['subject_id', 'session', 'trial']
        existing_trials = dataframe.set_index(unique_trial_identifiers).index
        removed_trials = dataframe_copy[~dataframe_copy.set_index(unique_trial_identifiers).index.isin(existing_trials)]
        removed_trials['removed_trial'] = 'removed_trial'
        dataframe['removed_trial'] = 'non-removed_trial'
        dataframe = pd.concat([dataframe, removed_trials]).sort_values(unique_trial_identifiers).reset_index(drop=True)

    return dataframe


if __name__ == '__main__':
    print('This is a module and should not be run directly.')