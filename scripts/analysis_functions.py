import os
import glob
import pandas as pd


def unique_subject_ids_and_sessions(file_path):
    # Extracts the subject ID's and sessions from the filenames
    unique_subject_ids = set()
    unique_sessions = set()
    for file_name in os.listdir(file_path):
        if "experiment_output" in file_name and ".csv" in file_name:
            subject_id = file_name.split('_')[2]
            unique_subject_ids.add(subject_id)
            session_number = file_name.split('_')[3]
            unique_sessions.add(session_number)
    return unique_subject_ids, unique_sessions


def list_files_with_date_and_subject_id(file_path: str) -> list:
    # Creates a list of the most recent results for each subject ID and session
    unique_subject_ids, unique_sessions = unique_subject_ids_and_sessions(file_path)

    # Temporary list of subjects and sessions, this is hardcoded so will cause issues in the future
    unique_subject_ids = list(range(1, 46))#[20,27,40]
    unique_sessions = [1]

    # Loop through subject ID's and sessions and pick the most recent result for each of them
    recent_files = []
    for subject_id, value in enumerate(unique_subject_ids):
        for session_number, value in enumerate(unique_sessions):
            file_structure_filtered = os.path.join(file_path, f'*sub-{unique_subject_ids[subject_id]:003}_session-{unique_sessions[session_number]:02}*')
            list_files_filtered = glob.glob(file_structure_filtered)
            try:
                recent_file = max(list_files_filtered)
                recent_files.append(recent_file)
            except ValueError:
                print(f'sub-{unique_subject_ids[subject_id]:003} did not complete session-{unique_sessions[session_number]:02}')

    return recent_files


def combine_result_files(recent_results: list) -> pd.DataFrame:
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
