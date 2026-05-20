import os
import glob
import re
import pandas as pd
import numpy as np
from scipy.stats import zscore


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
    # Chose the files to look for
    if selected_pattern == 'joystick_output':
        pattern = r'joystick_output_sub-(\d{3})_session-(\d{2})_.*\.csv$'
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


def replace_strings_with_integers(dataframe: pd.DataFrame,
                                  mapping: dict,
                                  old_column: str,
                                  new_column: str,
                                  new_column_type: str = 'int') -> (
        pd.DataFrame):
    """Simple function to replace a column using mapping.

    Parameters
    ----------
    dataframe : pd.DataFrame
        To be transformed dataframe.
    mapping: dict
        Contains the old and new values.
    old_column : str
        Name of the old column.
    new_column : str
        Name of the new column. Can be the same if you want to replace it.
    new_column_type: str
        Optionally change the format of the new column to anything other than an int.

    Returns
    -------
    dataframe : pd.DataFrame
        Dataframe that contains the new column
    """

    dataframe[new_column] = dataframe[old_column].replace(mapping)
    dataframe[new_column] = dataframe[new_column].astype(new_column_type)

    return dataframe


def check_congruency(row,
                     binary_output: bool = False):
    """ Functions that reads a row and sees whether the conditions are congruent or not.
    So here, we code the movement where you push the joystick away from you for happy faces as incongruent.

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
            condition = 0
        else:
            condition = 'incongruent'
    else:
        if binary_output is True:
            condition = -1
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
            emotional_valence = 0
        else:
            emotional_valence = 'angry'
    elif row['stimuli_type'] == 2:
        if binary_output is True:
            emotional_valence = 1
        else:
            emotional_valence = 'happy'
    else:
        if binary_output is True:
            emotional_valence = -1
        else:
            emotional_valence = 'no_emotion'

    return emotional_valence


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
        previous_label = 0
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
                label = 1 if streak_length < stable_cutoff else 0
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
            elif label == 'stable' and previous_label == 'volatile' or label == 0 and previous_label == 1:
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


def separate_reversals(dataframe: pd.DataFrame) -> (
    pd.DataFrame):
    """ Function that first detects the reversals and then divides them up into reversals and non-reversals

    Parameters
    ----------
    dataframe : pd.DataFrame
        A dataframe that needs to have the columns subject_id, session, stimuli_type, trial and probability_condition.

    Returns
    -------
    dataframe : pd.DataFrame
        A dataframe that contains the new columns all_reversals and all_reversals
    """

    # Orders the dataframe on the four following columns so that we can compare trials of the same stimuli condition
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    dataframe['all_reversals'] = dataframe['probability_condition'].diff().ne(0)

    # Filter out trials with 50% reward probability or a late response
    dataframe_without_unpredictive_blocks = dataframe.drop(dataframe[(dataframe.probability_condition == 50) |
                                                                     (dataframe.objectively_correct == 'Late')].index,inplace=False)

    dataframe_without_unpredictive_blocks['reversals'] = dataframe_without_unpredictive_blocks['probability_condition'].diff().ne(0)
    dataframe_without_unpredictive_blocks['non-reversals'] = dataframe_without_unpredictive_blocks['all_reversals'] != dataframe_without_unpredictive_blocks['reversals']
    dataframe_without_unpredictive_blocks = dataframe_without_unpredictive_blocks.reset_index(drop=True)

    # Conditions and choices for the new column
    conditions = [
        (dataframe_without_unpredictive_blocks['reversals'] & ~dataframe_without_unpredictive_blocks['non-reversals']),
        (~dataframe_without_unpredictive_blocks['reversals'] & dataframe_without_unpredictive_blocks['non-reversals']),
        (~dataframe_without_unpredictive_blocks['reversals'] & ~dataframe_without_unpredictive_blocks['non-reversals'])
    ]
    choices = [
        1,  # 'reversals' is True
        2,  # 'non-reversals' is True
        0  # Both are False
    ]

    # Create the third column using numpy.select
    dataframe_without_unpredictive_blocks['all_reversals'] = np.select(conditions, choices, default=np.nan)

    # Drop the working columns reversals and non_reversals
    dataframe = dataframe_without_unpredictive_blocks.drop(columns=['reversals', 'non-reversals'])

    dataframe = dataframe.sort_values(by=['trial'], ascending=[True])
    dataframe = dataframe.reset_index(drop=True)

    return dataframe


def trials_before_stabilisation(dataframe: pd.DataFrame,
                                stability_level: int,
                                bin_range: list,
                                reversal_value: float) -> (
        pd.DataFrame):
    """This function makes a new dataframe that lists all reversals and how long it took to reach a stable level of responses.

    Parameters
    ----------
    dataframe : pd.DataFrame
        A dataframe that can already contain the 'reversals' column but does not have to.
    stability_level : int
        An integer that represents a percentage of objectively correct responses that should be reached before counting as a stable level.
    bin_range : list
        A list of the minimum and maximum value around the reversal that I want to analyse.
    reversal_value : float
        The column value indicating whether we want to look at reversals or non-reversals.

    Returns
    -------
    dataframe : pd.DataFrame
        A dataframe with just the participant, session and reversal numbers plus the time it took since the reversal.
    """
    # In case you haven't run the separate_reversals function
    if 'all_reversals' not in dataframe.columns:
        dataframe = separate_reversals(dataframe)

    # Create an emtpy list to fill with results instead of appending to the dataframe for performance reasons
    results = []
    # Order by all four of these so that the trials around a reversal can be subtracted
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)
    # Create an object containing the indexes of all reversals
    reversals = dataframe[dataframe['all_reversals'] == reversal_value].index

    for index in reversals:
        subject_id = dataframe.loc[index, 'subject_id']
        session = dataframe.loc[index, 'session']
        stimuli_type = dataframe.loc[index, 'stimuli_type']
        trial = dataframe.loc[index, 'trial']

        # Extract subsequent trials data, limited by the bin_range
        subsequent_data = dataframe.loc[index+min(bin_range):index+max(bin_range)]

        # For some dumb reason, the Pandas developers forgot to develop the opposite of the 'expanding' function so we have to reverse it twice instead
        reversed_dataframe = subsequent_data.iloc[::-1].reset_index(drop=True)

        # Calculate the expanding mean
        reversed_dataframe['expanding_mean'] = reversed_dataframe['objectively_correct_boolean'].expanding().mean()

        # Reverse the result back to the original order
        subsequent_data = reversed_dataframe.iloc[::-1].reset_index(drop=True)

        # Compare to stability level
        cumulative_average = subsequent_data['expanding_mean'].ge(stability_level)

        # Find the first instance where the average is >= stability_level
        if (cumulative_average == True).any():
            stabilisation_index = cumulative_average.idxmax()
        else:
            stabilisation_index = max(bin_range) + 1

        results.append({
            'subject_id': subject_id,
            'session': session,
            'stimuli_type': stimuli_type,
            'trial': trial,
            'number_of_trials_before_stabilising': int(stabilisation_index)
        })

    # Only translating it into a dataframe now to optimise performance
    results = pd.DataFrame(results)

    return results


def bin_responses_for_congruency(dataframe: pd.DataFrame,
                                 bin_range: list,
                                 grouping_factor: str = 'stimuli_type') -> (
        pd.DataFrame):

    # Replace the string responses with ints
    mapping = {'up': 100, 'down': 0, np.NaN: -100}
    dataframe = replace_strings_with_integers(dataframe,
                                              mapping,
                                              'response',
                                              'response_int')

    # In case you haven't run the separate_reversals function
    if 'all_reversals' not in dataframe.columns:
        dataframe = separate_reversals(dataframe)

    # Order by all four of these so that the trials around a reversal can be subtracted
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    # Define the window size
    before = min(bin_range)
    after = max(bin_range)

    # Make a list out of the indexes
    reversal_indices = dataframe.index[dataframe['all_reversals'] == 1.0].tolist()
    print(reversal_indices)

    # Initialize an empty list to collect the new rows
    new_rows = []

    # Process each reversal index
    for reversal_index in reversal_indices:
        start_index = max(reversal_index + before, 0)
        end_index = min(reversal_index + after + 1, len(dataframe))
        trial_window = dataframe.iloc[start_index:end_index]

        # Reset the index to create 'trials_around_reversal'
        trial_window = trial_window.reset_index(drop=True)
        trial_window.index -= (reversal_index - start_index)
        trial_window['trials_around_reversal'] = trial_window.index

        # Get the first and last values of the 'congruency' column
        first_congruency = trial_window['congruency'].iloc[0]
        last_congruency = trial_window['congruency'].iloc[-1]

        # Determine the transition string
        if first_congruency == 'congruent' and last_congruency == 'incongruent':
            transition = 'congruent_to_incongruent'
        elif first_congruency == 'incongruent' and last_congruency == 'congruent':
            transition = 'incongruent_to_congruent'
        else:
            transition = 'no_transition'

        match grouping_factor:
            case 'stimuli_type':
                # Determine emotional valence string
                stimuli_type = trial_window['stimuli_type'].iloc[0]

                if stimuli_type == 1:
                    emotional_valence = 'angry'
                elif stimuli_type == 2:
                    emotional_valence = 'happy'
                else:
                    emotional_valence = 'no_emotion'

                # Collect the necessary columns
                for i, row in trial_window.iterrows():
                    new_rows.append({
                        'trials_around_reversal': row['trials_around_reversal'],
                        'response_int': row['response_int'],
                        'subject_id': row['subject_id'],
                        'session': row['session'],
                        'congruency': row['congruency'],
                        'stimuli_type': row['stimuli_type'],
                        'transition': transition,
                        'emotional_valence': emotional_valence,
                        'emotional_valence_and_transition': emotional_valence + '_' + transition
                    })
            case 'volatility':
                # Determine emotional valence string, this is needed because valence decides the starting point
                stimuli_type = trial_window['stimuli_type'].iloc[0]

                if stimuli_type == 1:
                    emotional_valence = 'angry'
                elif stimuli_type == 2:
                    emotional_valence = 'happy'
                else:
                    emotional_valence = 'no_emotion'

                # Determine emotional valence string
                volatility = trial_window['volatility'].iloc[0]

                if volatility == 'stable':
                    volatility = 'stable'
                elif volatility == 'volatile':
                    volatility = 'volatile'
                else:
                    volatility = 'no_emotion'

                # Collect the necessary columns
                for i, row in trial_window.iterrows():
                    new_rows.append({
                        'trials_around_reversal': row['trials_around_reversal'],
                        'response_int': row['response_int'],
                        'subject_id': row['subject_id'],
                        'session': row['session'],
                        'congruency': row['congruency'],
                        'stimuli_type': row['stimuli_type'],
                        'transition': transition,
                        'volatility': volatility,
                        'emotional_valence': emotional_valence,
                        'emotional_valence_and_transition': emotional_valence + '_' + transition
                    })

    # Create a new DataFrame from the collected rows
    result_df = pd.DataFrame(new_rows)

    return result_df


def find_reversals_in_dataframe(input_dataframe: pd.DataFrame,
                               unique_subject_ids: list,
                               unique_stimuli_types: list,
                               first_grouping_factor: str = 'False',
                               bin_range: list = None,
                               mapping: dict = None,
                               second_grouping_factor: str = 'False') -> (
        pd.DataFrame):

    # Make a list of the range of the bin
    if bin_range is None:
        bin_range = [0, 6]
    bin_list = list(range(bin_range[0], bin_range[1]))

    # Add column that notes if a reversal occurred recently
    input_dataframe = input_dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    input_dataframe.reset_index(drop=True, inplace=True)
    input_dataframe['reversal'] = input_dataframe['probability_condition'].diff().ne(0)

    # Remove 50% rows and rows without responses
    input_dataframe = input_dataframe.drop(input_dataframe[(input_dataframe.probability_condition == 50)].index, inplace=False)# |
                                                          #(input_dataframe.objectively_correct == 'Late')].index, inplace=False)

    # First reversal for each participant should be removed
    ## First do so for the very first row
    if len(input_dataframe) > 0:
        input_dataframe.loc[input_dataframe.index[0], 'reversal'] = False
    ## And then for all other points where the subject_id or stimuli_type changes
    change_mask = ((input_dataframe['subject_id'] != input_dataframe['subject_id'].shift()) |
                   (input_dataframe['stimuli_type'] != input_dataframe['stimuli_type'].shift()))
    input_dataframe.loc[change_mask, 'reversal'] = False

    # Add reversals to a list
    reversals_per_group = input_dataframe.index[input_dataframe['reversal'] == True].tolist()

    # Make column names
    if second_grouping_factor == 'False' and first_grouping_factor == 'False':
        print(input_dataframe[['subject_id', 'trial', 'stimuli_type', 'probability_condition', 'reversal']])
        nested_list_for_dataframe = [['subject_id', 'stimuli_type'] + bin_list]
    elif second_grouping_factor == 'False':
        print(input_dataframe[['subject_id', 'trial', 'stimuli_type', 'probability_condition', 'reversal', first_grouping_factor]])
        nested_list_for_dataframe = [['subject_id', 'stimuli_type', first_grouping_factor] + bin_list]
    else:
        print(input_dataframe[['subject_id', 'trial', 'stimuli_type', 'probability_condition', 'reversal', first_grouping_factor, second_grouping_factor]])
        nested_list_for_dataframe = [['subject_id', 'stimuli_type', first_grouping_factor, second_grouping_factor] + bin_list]

    for index, index_in_dataframe in enumerate(reversals_per_group):
        current_subject_id = input_dataframe.loc[index_in_dataframe, 'subject_id']
        current_stimuli_type = input_dataframe.loc[index_in_dataframe, 'stimuli_type']

        # Get the integer position of the index label
        start_pos = input_dataframe.index.get_loc(index_in_dataframe)

        # Get the next 6 rows starting from the start_label
        objectively_correct_answers_within_bin = (input_dataframe.iloc[start_pos + bin_range[0]:start_pos + bin_range[1]]['objectively_correct_boolean']).tolist()

        if second_grouping_factor != 'False' and first_grouping_factor != 'False':
            current_first_grouping_factor = input_dataframe.loc[index_in_dataframe, first_grouping_factor]
            current_second_grouping_factor = input_dataframe.loc[index_in_dataframe, second_grouping_factor]

            current_factors =  [current_subject_id, current_stimuli_type, current_first_grouping_factor, current_second_grouping_factor]
            current_row = current_factors + objectively_correct_answers_within_bin
            nested_list_for_dataframe.append(current_row)
        elif first_grouping_factor != 'False' and second_grouping_factor == 'False':
            current_first_grouping_factor = input_dataframe.loc[index_in_dataframe, first_grouping_factor]

            current_factors = [current_subject_id, current_stimuli_type, current_first_grouping_factor]
            current_row = current_factors + objectively_correct_answers_within_bin
            nested_list_for_dataframe.append(current_row)
        else:
            current_factors = [current_subject_id, current_stimuli_type]
            current_row = current_factors + objectively_correct_answers_within_bin
            nested_list_for_dataframe.append(current_row)

    # Turn nested list into output dataframe
    output_dataframe = pd.DataFrame(nested_list_for_dataframe)
    output_dataframe.columns = output_dataframe.iloc[0]
    output_dataframe = output_dataframe[1:]

    return output_dataframe


def find_reversals_in_dataframe_separate_reversals(input_dataframe: pd.DataFrame,
                                                  unique_subject_ids: list,
                                                  unique_stimuli_types: list,
                                                  bin_range: list = None,
                                                  mapping: dict = None) -> (
        pd.DataFrame):
    if bin_range is None:
        bin_range = [0, 12]

    reversals_all_stimuli_types = pd.DataFrame()

    for index_stimuli in unique_stimuli_types:
        for index_subject_id in unique_subject_ids:
            dataframe_single_group = input_dataframe[(input_dataframe['stimuli_type'] == index_stimuli) &
                                                     (input_dataframe['subject_id'] == index_subject_id)]

            # Add column that notes if a reversal occurred recently
            dataframe_single_group['all_reversals'] = dataframe_single_group['probability_condition'].diff().ne(0)

            # Filter out trials with 50% reward probability
            dataframe_for_reversals = dataframe_single_group
            dataframe_for_reversals = dataframe_for_reversals.drop(dataframe_for_reversals
                                                                 [(dataframe_for_reversals.probability_condition == 50) |
                                                                  (
                                                                              dataframe_for_reversals.objectively_correct == 'Late')].index,
                                                                 inplace=False)

            dataframe_for_reversals['reversals'] = dataframe_for_reversals['probability_condition'].diff().ne(0)
            dataframe_for_reversals['non-reversals'] = dataframe_for_reversals['all_reversals'] != dataframe_for_reversals[
                'reversals']
            dataframe_for_reversals = dataframe_for_reversals.reset_index(drop=True)

            # Conditions and choices for the new column
            conditions = [
                (dataframe_for_reversals['reversals'] & ~dataframe_for_reversals['non-reversals']),
                (~dataframe_for_reversals['reversals'] & dataframe_for_reversals['non-reversals']),
                (~dataframe_for_reversals['reversals'] & ~dataframe_for_reversals['non-reversals'])
            ]
            choices = [
                1,  # 'reversals' is True
                2,  # 'non-reversals' is True
                0  # Both are False
            ]

            # Create the third column using numpy.select
            dataframe_for_reversals['all_reversals'] = np.select(conditions, choices, default=np.nan)

            # Add reversals to a list
            reversals_list = dataframe_for_reversals.index[(dataframe_for_reversals['all_reversals'] == 1) |
                                                          (dataframe_for_reversals['all_reversals'] == 2)].tolist()

            for index_reversals, values in enumerate(reversals_list):
                reversals_dataframe = dataframe_for_reversals.iloc[
                                     values + min(bin_range):values + max(bin_range) + 1]
                reversal_condition = dataframe_for_reversals.iloc[values]
                bin_around_reversal = [index_subject_id, index_stimuli, reversal_condition['all_reversals']]
                bin_around_reversal.extend(reversals_dataframe['objectively_correct_boolean'].tolist())
                bin_around_reversal_dataframe = pd.DataFrame([bin_around_reversal])
                reversals_all_stimuli_types = pd.concat(
                    [reversals_all_stimuli_types, bin_around_reversal_dataframe])

    reversals_all_stimuli_types.rename(mapping, axis=1, inplace=True)

    reversals_all_stimuli_types = reversals_all_stimuli_types.reset_index(drop=True)
    return reversals_all_stimuli_types


def calculate_IES(dataframe,
                  extra_grouping_columns=None):
    """
    Function that calculates the Inverse Efficiency Score (IES) for each subject and session.
    Parameters
    ----------
    dataframe: pd.DataFrame
    extra_grouping_columns: list

    Returns
    -------
    dataframe: pd.DataFrame
    """
    # Add extra grouping columns if provided
    grouping_columns = ['subject_id', 'session']
    if extra_grouping_columns:
        grouping_columns += extra_grouping_columns

    # Calculate average RT for correct answers only
    dataframe_RT = (
        dataframe[dataframe['objectively_incorrect_boolean'] == 0]
        .groupby(grouping_columns, as_index=False)['RT_ms']
        .mean()
    )

    # Calculate overall accuracy
    dataframe_PE = (
        dataframe
        .groupby(grouping_columns, as_index=False)['objectively_incorrect_boolean']
        .mean()
    )

    # Combine the two
    dataframe = pd.merge(dataframe_RT, dataframe_PE, on=grouping_columns, how='outer')

    # Create Inverse Efficiency Score
    dataframe['IES'] = dataframe['RT_ms'] / (1 - dataframe['objectively_incorrect_boolean'])
    print(dataframe)

    return dataframe


def calculate_BIS(dataframe,
                  extra_grouping_columns=None):
    """
    Function that calculates the Balanced Integration Score (BIS) for each
    subject × session (× condition) cell.

    BIS = z(PC) − z(RT), with z-scores computed across the entire sample
    of cells (Liesefeld & Janczyk, 2019). Higher BIS means better
    performance (faster and/or more accurate).

    Parameters
    ----------
    dataframe: pd.DataFrame
        Trial-level data containing 'RT_ms' and 'objectively_incorrect_boolean'.
    extra_grouping_columns: list, optional
        Additional condition columns (e.g. ['congruency', 'volatility']) to
        define the cells over which performance is aggregated and standardised.

    Returns
    -------
    dataframe: pd.DataFrame
        One row per subject × session (× extra condition) with mean RT,
        accuracy, their z-scores, and BIS.
    """
    # Build grouping
    grouping_columns = ['subject_id', 'session']
    if extra_grouping_columns:
        grouping_columns = grouping_columns + extra_grouping_columns

    # Aggregate to one row per cell
    aggregated = (
        dataframe
        .groupby(grouping_columns, as_index=False)
        .agg(
            RT_ms_mean=('RT_ms', 'mean'),
            error_rate=('objectively_incorrect_boolean', 'mean')
        )
    )
    aggregated['accuracy'] = 1 - aggregated['error_rate']

    # Sample-wide standardisation, across all cells in the resulting frame
    aggregated['z_RT'] = zscore(aggregated['RT_ms_mean'], nan_policy='omit')
    aggregated['z_accuracy'] = zscore(aggregated['accuracy'], nan_policy='omit')

    # BIS = z(PC) − z(RT)
    aggregated['BIS'] = aggregated['z_accuracy'] - aggregated['z_RT']

    return aggregated