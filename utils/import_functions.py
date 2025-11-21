import os
import glob
import re
import pandas as pd
import numpy as np
import utils


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


def list_files_with_date_and_subject_id_old(file_path: str,
                                        unique_subject_ids: list = [],
                                        unique_sessions: list = [],
                                        selected_pattern: str = 'behavioural_output') -> list:
    """This will create a list of the most recent files of every subject and every session.

    Parameters
    ----------
    file_path : str
        Path to the experiment output folder.
    unique_subject_ids : list(int)
        A list containing all subject IDs found in the folder.
    unique_sessions : list(int)
        A list containing all sessions found in the folder.

    Returns
    -------
    recent_files : list
        A list of the most recent files of every subject and every session.
    """
    # Choose the files to look for
    if selected_pattern == 'joystick_output':
        pattern = r'joystick_output_sub-(\d{3})_session-(\d{2})_.*\.csv$'
    elif selected_pattern == 'speakup':
        pattern = r'sub-(\d{2})_d(\d{1})_.*\behavioural_output.csv$'
    else:
        pattern = r'behavioural_output_sub-(\d{3})_session-(\d{2})_.*\.csv$'

    # If no subject IDs or sessions were provided, extract them using the helper function.
    if not unique_subject_ids and not unique_sessions:
        unique_subject_ids, unique_sessions = unique_subject_ids_and_sessions(file_path, pattern)

    recent_files = []
    # Iterate through each subject and session combination.
    for subject_id in unique_subject_ids:
        for session_number in unique_sessions:
            # Build a recursive search pattern that looks in all subfolders.
            if selected_pattern == 'joystick_output':
                file_structure_filtered = os.path.join(
                    file_path, '**', f'joystick_output_sub-{subject_id:03}_session-{session_number:02}*.csv'
                )
            else:
                file_structure_filtered = os.path.join(
                    file_path, '**', f'behavioural_output_sub-{subject_id:03}_session-{session_number:02}*.csv'
                )
            list_files_filtered = glob.glob(file_structure_filtered, recursive=True)
            try:
                # Choose the most recent file (assuming lexicographical order corresponds to recency).
                recent_file = max(list_files_filtered)
                recent_files.append(recent_file)
            except ValueError:
                print(f'sub-{subject_id:03} did not complete session-{session_number:02}')

    if not recent_files:
        raise Exception('No files found')
    print(recent_files)

    return recent_files

# This function uses the walk function instead. It was made using Claude so needs to be checked.
from collections import defaultdict


def list_files_with_date_and_subject_id(file_path: str,
                                        unique_subject_ids: list = [],
                                        unique_sessions: list = [],
                                        selected_pattern: str = 'behavioural_output') -> list:
    """This will create a list of the most recent files of every subject and every session.

    Parameters
    ----------
    file_path : str
        Path to the experiment output folder.
    unique_subject_ids : list(int)
        A list containing all subject IDs found in the folder.
    unique_sessions : list(int)
        A list containing all sessions found in the folder.
    selected_pattern : str
        Either 'joystick_output' or 'behavioural_output'.

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
    print(recent_files)

    return recent_files


def combine_result_files(recent_results: list) -> pd.DataFrame:
    """ This function takes a list of csv's and combines them into one big dataframe.

    Parameters
    ----------
    recent_results : list
        This list should contain the location of the to be imported CSV's with the full path.
        The filenames of each CSV should adhere to the format [experiment_output_sub-001_session-01*.csv].

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

    combined_results_dataframe = pd.DataFrame()
    for list_number, value in enumerate(recent_results):
        result_dataframe = pd.read_csv(recent_results[list_number], sep=';')
        recent_result_basename = os.path.basename(recent_results[list_number])
        result_dataframe['subject_id'] = recent_result_basename.split('_')[2]
        result_dataframe['session'] = recent_result_basename.split('_')[3]
        combined_results_dataframe = pd.concat([combined_results_dataframe, result_dataframe], ignore_index=True)

    return combined_results_dataframe


def combine_joystick_with_results(dataframe: pd.DataFrame,
                                  joystick_filenames: list) -> (
        pd.DataFrame):
    """ This function takes a dataframe containing the results and a dataframe containing the joystick data and combines them.

    Parameters
    ----------
    dataframe : pd.DataFrame
        A dataframe containing the results of the experiment.
    joystick_filenames : list
        A list of file locations of the joystick data.

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
    for list_number, value in enumerate(joystick_filenames):
        joystick_dataframe_single = pd.read_csv(joystick_filenames[list_number], sep=';')
        joystick_dataframe_single['joystick_location_difference'] = joystick_dataframe_single['location_y'].diff()
        joystick_dataframe_single['joystick_time_difference'] = joystick_dataframe_single['timepoint'].diff()
        joystick_dataframe_single['joystick_acceleration'] = joystick_dataframe_single['location_y'].diff() / joystick_dataframe_single['timepoint'].diff()
        recent_result_basename = os.path.basename(joystick_filenames[list_number])
        joystick_dataframe_single['subject_id'] = recent_result_basename.split('_')[2]
        joystick_dataframe_single['session'] = recent_result_basename.split('_')[3]
        joystick_dataframe_combined = pd.concat([joystick_dataframe_combined, joystick_dataframe_single], ignore_index=True)

    # Remove the first row of every trial since the acceleration can be very large
    joystick_dataframe_combined = joystick_dataframe_combined[joystick_dataframe_combined['trial'] == joystick_dataframe_combined['trial'].shift(1)]

    # Rename some columns in the joystick dataframe
    joystick_dataframe_combined = joystick_dataframe_combined.rename(columns={'datapoint': 'joystick_datapoint', 'location_y': 'joystick_location', 'timepoint': 'joystick_timepoint'})
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
    match_list = ['sub-004_session-04']

    # Create a new column that combines subject_id and session in the same format as the list.
    dataframe['sub_session'] = dataframe['subject_id'] + '_' + \
                                                dataframe['session']

    # Create a mask for rows that match any of the combinations in match_list.
    mask = dataframe['sub_session'].isin(match_list)

    # For 'probability_condition', swap 80 with 20 and vice versa.
    dataframe.loc[mask, 'probability_condition'] = (
        dataframe.loc[mask, 'probability_condition']
        .replace({80: 20, 20: 80})
    )

    # For 'response', swap 'up' with 'down' and vice versa.
    dataframe.loc[mask, 'response'] = (
        dataframe.loc[mask, 'response']
        .replace({'up': 'down', 'down': 'up'})
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

    Returns
    -------
    condition : str
        A string containing the congruency condition for the given row.
    """
    if (row['probability_condition'] > 50 and row['stimuli_type'] == 1) or (
                row['probability_condition'] < 50 and row['stimuli_type'] == 2):
        if binary_output is True:
            condition = 1
        else:
            condition = 'congruent'
    elif (row['probability_condition'] < 50 and row['stimuli_type'] == 1) or (
                row['probability_condition'] > 50 and row['stimuli_type'] == 2):
        if binary_output is True:
            condition = -1
        else:
            condition = 'incongruent'
    else:
        if binary_output is True:
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

    Returns
    -------
    condition : str
        A string containing the valence for the given row.
    """
    if row['stimuli_type'] == 1:
        if binary_output is True:
            emotional_valence = -1
        else:
            emotional_valence = 'angry'
    elif row['stimuli_type'] == 2:
        if binary_output is True:
            emotional_valence = 1
        else:
            emotional_valence = 'happy'
    else:
        if binary_output is True:
            emotional_valence = 0
        else:
            emotional_valence = 'no_emotion'

    return emotional_valence


def check_correct_response(row,
                        binary_output: bool = False):
    """ Functions that reads a row and notes the response that would have resulted in the highest chance of a reward.

    Parameters
    ----------
    row : pd.DataFrame.row

    Returns
    -------
    condition : str
        A string containing the valence for the given row.
    """
    if row['probability_condition'] == 80:
        if binary_output is True:
            correct_response = 1
        else:
            correct_response = 'up'
    elif row['probability_condition'] == 20:
        if binary_output is True:
            correct_response = -1
        else:
            correct_response = 'down'
    else:
        if binary_output is True:
            correct_response = 0
        else:
            correct_response = 'no_correct_response'

    return correct_response


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

    # This differentiates between a stable and volatile block
    stable_cutoff = 15

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


def check_stimulation_condition(row,
                  binary_output: bool = False):
    """ Functions that reads a row and notes the stimulation condition.

    Parameters
    ----------
    row : pd.DataFrame.row

    Returns
    -------
    stimulation_condition : str
        A string containing the stimulation condition for the given row.
    """
    if row['session'] == 'session-02':
        if binary_output is True:
            stimulation_condition = 1
        else:
            stimulation_condition = 'amygdala'
    elif row['session'] == 'session-03':
        if binary_output is True:
            stimulation_condition = 2
        else:
            stimulation_condition = 'dacc'
    elif row['session'] == 'session-04':
        if binary_output is True:
            stimulation_condition = 3
        else:
            stimulation_condition = 'sham'
    else:
        if binary_output is True:
            stimulation_condition = 0
        else:
            stimulation_condition = 'no_stimulation'

    return stimulation_condition


def main(raw_output_path,
         unique_subject_ids,
         unique_sessions,
         pilot_analysis=False,
         binary_output=False,
         remove_reversals=False,
         remove_invalid_trials=True,
         selected_pattern='behavioural_output') -> pd.DataFrame:
    """ Main function that runs the import functions.

    Parameters
    ----------
    raw_output_path : str
        Path to the experiment output folder.
    unique_subject_ids : list(int)
        A list containing all subject IDs found in the folder.
    unique_sessions : list(int)
        A list containing all sessions found in the folder.
    pilot_analysis : bool
        If True, only the first 10 subjects will be used for analysis.
    binary_output : bool
        If True, the output will be in binary format.
    remove_reversals : bool
        If True, trials where a reversal occurred will be removed.
    remove_invalid_trials : bool
        If True, invalid files will be removed from the analysis.
    selected_pattern : str
        Allows you to select the pattern of the output files.

    Returns
    -------
    dataframe_with_joystick_data : pd.DataFrame
        A dataframe containing the results of all files listed in recent_results.
    """

    # First, get a list of the behavioural datafiles
    recent_files = list_files_with_date_and_subject_id(raw_output_path, unique_subject_ids, unique_sessions, selected_pattern)

    # Remove the invalid files
    #if remove_invalid_trials:
        #recent_files = remove_invalid_files(recent_files, raw_output_path)

    # Then, import all behavioural datasets and combine them into 1
    dataframe = combine_result_files(recent_files)

    # Extract one of the blocks for exclusion

    # If we're analysing the pilot data, make some changes to ensure backwards compatibility of the analysis
    if pilot_analysis:
        dataframe.rename(columns={'iti': 'trial_duration'}, inplace=True)
        dataframe['stimuli_type'] = dataframe['stimuli_type'].replace(3, 2)

    # Checks if and compensates for when the joystick was flipped for any of the sessions
    dataframe = flip_joystick_data(dataframe)

    # Turns the performance values into boolean ones
    mapping = {'True': 1, 'False': 0, 'Even': 0, 'Late': 0}
    dataframe['objectively_correct_boolean'] = dataframe['objectively_correct'].replace(mapping)
    dataframe['objectively_correct_boolean'] = dataframe['objectively_correct_boolean'].astype('int')
    dataframe['subjectively_correct_boolean'] = dataframe['subjectively_correct'].replace(mapping)
    dataframe['subjectively_correct_boolean'] = dataframe['subjectively_correct_boolean'].astype('int')
    dataframe['subjectively_correct_boolean_one_back'] = dataframe['subjectively_correct_boolean'].shift(1)

    # Convert performance to errors
    dataframe['objective_errors'] = 1 - dataframe['objectively_correct_boolean']
    dataframe['subjective_errors'] = 1 - dataframe['subjectively_correct_boolean']

    # Make congruency and hidden congruency columns
    dataframe['congruency'] = dataframe.apply(check_congruency, args=(binary_output,), axis=1)
    print(dataframe[['stimuli_type', 'probability_condition', 'congruency']])

    # Make valence column
    dataframe['valence'] = dataframe.apply(check_valence, args=(binary_output,), axis=1)
    print(dataframe[['stimuli_type', 'valence']])

    # Add WSLS column before removing trials
    dataframe = utils.learning_models.add_WSLS_column(dataframe)
    mapping = {1: 1, -1: 0}
    dataframe['stay_shift'] = dataframe['same_response_as_one_back'].replace(mapping)
    dataframe['stay_shift'] = dataframe['stay_shift'].astype('int')

    # Make volatility column
    dataframe = dataframe[dataframe['probability_condition'] != 50]
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.groupby('stimuli_type', group_keys=False).apply(lambda x: check_volatility(x, binary_output))
    print(dataframe[['subject_id', 'session', 'stimuli_type', 'probability_condition', 'volatility']])

    # Make stimulation condition column
    dataframe['stimulation_condition'] = dataframe.apply(check_stimulation_condition, args=(binary_output,), axis=1)
    print(dataframe[['subject_id', 'session', 'stimulation_condition']])

    # Add a column for the most rewarding response
    dataframe['correct_response'] = dataframe.apply(check_correct_response, args=(binary_output,), axis=1)
    # Make binary response column
    mapping = {'up': 1, 'down': -1}
    dataframe['response_boolean'] = dataframe['response'].replace(mapping)
    dataframe['correct_response_boolean'] = dataframe['correct_response'].replace(mapping)

    # Add a column that indicates how many trials ago the last reversal occurred
    dataframe['trials_since_reversal'] = (
        dataframe.groupby((dataframe['probability_condition'] != dataframe['probability_condition'].shift()).cumsum())
        .cumcount()
    )

    # Only remove the trials where the reversal occurred if the flag is set to True
    if remove_reversals:
        dataframe = dataframe[dataframe['trials_since_reversal'] != 0]

    if remove_invalid_trials:
        # Remove trials where RT < 50ms, please note that this number is arbitrary and can be changed
        dataframe = dataframe[dataframe['RT_s'] >= 0.05]

        # Remove late trials
        dataframe = dataframe[dataframe['objectively_correct'] != 'Late']

    # Reset order of dataframe
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'trial'], ascending=[True, True, True])

    # Add columns containing integers for the subject_id and session number
    if binary_output:
        dataframe['subject_id'] = dataframe['subject_id'].str.replace('sub-', '').astype(int)
        dataframe['session'] = dataframe['session'].str.replace('session-', '').astype(int)

    return dataframe


if __name__ == '__main__':
    print('This is a module and should not be run directly.')