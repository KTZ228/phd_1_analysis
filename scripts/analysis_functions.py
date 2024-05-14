import os
import glob
import re
import pandas as pd
import numpy as np


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
    pattern = r'experiment_output_sub-(\d{3})_session-(\d{2})_.*\.csv$'
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


def list_files_with_date_and_subject_id(file_path: str,
                                        unique_subject_ids: list = [],
                                        unique_sessions: list = []) -> (
        list):
    """This will create a list of the most recent files of every subject and every session.

    Parameters
    ----------
    file_path : str
        path to the experiment output folder.
    unique_subject_ids : list(int)
        A list containing all subject ID's found in the folder.
    unique_sessions : list(int)
        A list containing all sessions found in the folder.

    Returns
    -------
    recent_files : list
        A list of all the most recent files of every subject and every session.
    """
    if len(unique_subject_ids) == 0 and len(unique_sessions) == 0:
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


def check_congruency(row):
    """ Functions that reads a row and sees whether the conditions are congruent or not.

    Parameters
    ----------
    row : pd.DataFrame.row

    Returns
    -------
    condition : str
        A string containing the congruency condition for the given row.
    """
    if (row['probability_condition'] == 80 and row['stimuli_type'] in [3, 4]) or (
            row['probability_condition'] == 20 and row['stimuli_type'] in [1, 2]):
        condition = 'congruent'
    elif (row['probability_condition'] == 20 and row['stimuli_type'] in [3, 4]) or (
            row['probability_condition'] == 80 and row['stimuli_type'] in [1, 2]):
        condition = 'incongruent'
    else:
        condition = 'undefined'

    return condition


def separate_reversals(dataframe: pd.DataFrame) -> (
    pd.DataFrame):
    """ Function that first detects the switches and then divides them up into reversals and non-reversals

    Parameters
    ----------
    dataframe : pd.DataFrame
        A dataframe that needs to have the columns subject_id, session, stimuli_type, trial and probability_condition.

    Returns
    -------
    dataframe : pd.DataFrame
        A dataframe that contains the new columns all_switches and all_reversals
    """

    # Orders the dataframe on the four following columns so that we can compare trials of the same stimuli condition
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)

    dataframe['all_switches'] = dataframe['probability_condition'].diff().ne(0)

    # Filter out trials with 50% reward probability or a late response
    dataframe_without_unpredictive_blocks = dataframe.drop(dataframe[(dataframe.probability_condition == 50) |
                                                                     (dataframe.objectively_correct == 'Late')].index,inplace=False)

    dataframe_without_unpredictive_blocks['reversals'] = dataframe_without_unpredictive_blocks['probability_condition'].diff().ne(0)
    dataframe_without_unpredictive_blocks['non-reversals'] = dataframe_without_unpredictive_blocks['all_switches'] != dataframe_without_unpredictive_blocks['reversals']
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
                                switch_value: float) -> (
        pd.DataFrame):
    """This function makes a new dataframe that lists all switches and how long it took to reach a stable level of responses.

    Parameters
    ----------
    dataframe : pd.DataFrame
        A dataframe that can already contain the 'reversals' column but does not have to.
    stability_level : int
        An integer that represents a percentage of objectively correct responses that should be reached before counting as a stable level.
    bin_range : list
        A list of the minimum and maximum value around the switch that I want to analyse.
    switch_value : float
        The column value indicating whether we want to look at reversals or non-reversals.

    Returns
    -------
    dataframe : pd.DataFrame
        A dataframe with just the participant, session and switch numbers plus the time it took since the switch.
    """
    # In case you haven't run the separate_reversals function
    if 'all_reversals' not in dataframe.columns:
        dataframe = separate_reversals(dataframe)

    # Create an emtpy list to fill with results instead of appending to the dataframe for performance reasons
    results = []
    # Order by all four of these so that the trials around a switch can be subtracted
    dataframe = dataframe.sort_values(by=['subject_id', 'session', 'stimuli_type', 'trial'], ascending=[True, True, True, True])
    dataframe = dataframe.reset_index(drop=True)
    # Create an object containing the indexes of all reversals
    switches = dataframe[dataframe['all_reversals'] == switch_value].index

    for index in switches:
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


def find_switches_in_dataframe(input_dataframe: pd.DataFrame,
                               unique_subject_ids: list,
                               unique_stimuli_types: list,
                               additional_grouping_factor: str = 'False',
                               bin_range: list = None,
                               mapping: dict = None) -> (
        pd.DataFrame):
    if bin_range is None:
        bin_range = [0, 12]
    switches_all_stimuli_types = pd.DataFrame()

    if additional_grouping_factor == 'False':
        for index_stimuli in unique_stimuli_types:
            for index_subject_id in unique_subject_ids:
                dataframe_single_group = input_dataframe[(input_dataframe['stimuli_type'] == index_stimuli) &
                                                         (input_dataframe['subject_id'] == index_subject_id)]

                # Add column that notes if a switch occurred recently
                dataframe_single_group['switch'] = dataframe_single_group['probability_condition'].diff().ne(0)
                # Filter out trials with 50% reward probability
                dataframe_for_switches = dataframe_single_group  #.reset_index()
                dataframe_for_switches = dataframe_for_switches.drop(dataframe_for_switches
                                                                     [(
                                                                              dataframe_for_switches.probability_condition == 50) |
                                                                      (
                                                                              dataframe_for_switches.objectively_correct == 'Late')].index,
                                                                     inplace=False)

                # Add switches to a list
                switches_per_stimuli_type = dataframe_for_switches.index[
                    dataframe_for_switches['switch'] == True].tolist()

                # Add list to dataframe
                switches_per_stimuli_type = [index_stimuli, index_subject_id] + switches_per_stimuli_type
                switches_per_stimuli_type = pd.DataFrame([switches_per_stimuli_type])
                switches_all_stimuli_types = pd.concat([switches_all_stimuli_types, switches_per_stimuli_type])
        switches_all_stimuli_types.rename(mapping, axis=1, inplace=True)

    else:
        try:
            input_dataframe[additional_grouping_factor]
        except KeyError as error:
            print(f'error: {error}')

        for index_stimuli in unique_stimuli_types:
            for index_subject_id in unique_subject_ids:
                dataframe_single_group = input_dataframe[(input_dataframe['stimuli_type'] == index_stimuli) &
                                                         (input_dataframe['subject_id'] == index_subject_id)]

                # Add column that notes if a switch occurred recently
                dataframe_single_group['switch'] = dataframe_single_group['probability_condition'].diff().ne(0)

                # Filter out trials with 50% reward probability
                dataframe_for_switches = dataframe_single_group
                dataframe_for_switches = dataframe_for_switches.drop(dataframe_for_switches
                                                                     [(
                                                                              dataframe_for_switches.probability_condition == 50) |
                                                                      (
                                                                              dataframe_for_switches.objectively_correct == 'Late')].index,
                                                                     inplace=False)

                unique_groups = dataframe_for_switches[additional_grouping_factor].unique()

                for index_grouping_factor in unique_groups:
                    dataframe_grouping_factor = dataframe_for_switches[
                        (dataframe_for_switches[additional_grouping_factor] == index_grouping_factor)]
                    dataframe_grouping_factor = dataframe_grouping_factor.reset_index(drop=True)

                    # Add switches to a list
                    switches_per_group = dataframe_grouping_factor.index[
                        dataframe_grouping_factor['switch'] == True].tolist()

                    for index_switches, values in enumerate(switches_per_group):
                        switches_dataframe = dataframe_grouping_factor.iloc[
                                             values + min(bin_range):values + max(bin_range) + 1]
                        bin_around_switch = [index_subject_id, index_stimuli, index_grouping_factor]
                        bin_around_switch.extend(switches_dataframe['objectively_correct_boolean'].tolist())
                        bin_around_switch_dataframe = pd.DataFrame([bin_around_switch])
                        switches_all_stimuli_types = pd.concat(
                            [switches_all_stimuli_types, bin_around_switch_dataframe])

        switches_all_stimuli_types.rename(mapping, axis=1, inplace=True)

    switches_all_stimuli_types = switches_all_stimuli_types.reset_index(drop=True)
    return switches_all_stimuli_types


def find_switches_in_dataframe_separate_reversals(input_dataframe: pd.DataFrame,
                                                  unique_subject_ids: list,
                                                  unique_stimuli_types: list,
                                                  bin_range: list = None,
                                                  mapping: dict = None) -> (
        pd.DataFrame):
    if bin_range is None:
        bin_range = [0, 12]

    switches_all_stimuli_types = pd.DataFrame()

    for index_stimuli in unique_stimuli_types:
        for index_subject_id in unique_subject_ids:
            dataframe_single_group = input_dataframe[(input_dataframe['stimuli_type'] == index_stimuli) &
                                                     (input_dataframe['subject_id'] == index_subject_id)]

            # Add column that notes if a switch occurred recently
            dataframe_single_group['all_switches'] = dataframe_single_group['probability_condition'].diff().ne(0)

            # Filter out trials with 50% reward probability
            dataframe_for_switches = dataframe_single_group
            dataframe_for_switches = dataframe_for_switches.drop(dataframe_for_switches
                                                                 [(dataframe_for_switches.probability_condition == 50) |
                                                                  (
                                                                              dataframe_for_switches.objectively_correct == 'Late')].index,
                                                                 inplace=False)

            dataframe_for_switches['reversals'] = dataframe_for_switches['probability_condition'].diff().ne(0)
            dataframe_for_switches['non-reversals'] = dataframe_for_switches['all_switches'] != dataframe_for_switches[
                'reversals']
            dataframe_for_switches = dataframe_for_switches.reset_index(drop=True)

            # Conditions and choices for the new column
            conditions = [
                (dataframe_for_switches['reversals'] & ~dataframe_for_switches['non-reversals']),
                (~dataframe_for_switches['reversals'] & dataframe_for_switches['non-reversals']),
                (~dataframe_for_switches['reversals'] & ~dataframe_for_switches['non-reversals'])
            ]
            choices = [
                1,  # 'reversals' is True
                2,  # 'non-reversals' is True
                0  # Both are False
            ]

            # Create the third column using numpy.select
            dataframe_for_switches['all_reversals'] = np.select(conditions, choices, default=np.nan)

            # Add switches to a list
            reversals_list = dataframe_for_switches.index[(dataframe_for_switches['all_reversals'] == 1) |
                                                          (dataframe_for_switches['all_reversals'] == 2)].tolist()

            for index_reversals, values in enumerate(reversals_list):
                switches_dataframe = dataframe_for_switches.iloc[
                                     values + min(bin_range):values + max(bin_range) + 1]
                reversal_condition = dataframe_for_switches.iloc[values]
                bin_around_switch = [index_subject_id, index_stimuli, reversal_condition['all_reversals']]
                bin_around_switch.extend(switches_dataframe['objectively_correct_boolean'].tolist())
                bin_around_switch_dataframe = pd.DataFrame([bin_around_switch])
                switches_all_stimuli_types = pd.concat(
                    [switches_all_stimuli_types, bin_around_switch_dataframe])

    switches_all_stimuli_types.rename(mapping, axis=1, inplace=True)

    switches_all_stimuli_types = switches_all_stimuli_types.reset_index(drop=True)
    return switches_all_stimuli_types
