% Translate Verena's results to mimic the structure of mine
clc; clear; close all

session_length = 160;

for subject_id = 1:45
    file_path = sprintf('/home/affneu/kenvdzee/Documents/Verena_Task/verena_behavioral/Experiment/Task/subj%02d', subject_id);
    
    restructured_results = table();
    for session_number = 1:3
        
        % trial
        current_session_end = session_length * session_number;
        current_session_beginning = current_session_end - 159;
        trial = (current_session_beginning:current_session_end)';
        restructured_results_temp = array2table(trial);
        
        % Load original results
        verenas_results = load(sprintf('%s/anx_subj%02d_s%01d_results.mat', file_path, subject_id, session_number));
        
        % emotional_cue_time
        emotional_cue_time = (verenas_results.results.tm.cue)';
        restructured_results_temp.emotional_cue_time = emotional_cue_time;
    
        % response
        response = (verenas_results.results.go)';
        response_cell = repmat({'down'}, size(response));
        response_cell(response == 1) = {'up'};
        restructured_results_temp.response = response_cell;
    
        % response_time
        response_time = (verenas_results.results.tm.go)';
        restructured_results_temp.response_time = response_time;
    
        % RT_s
        reaction_time = (verenas_results.results.RT)';
        restructured_results_temp.RT_s = reaction_time;
        
        % probability_condition
        full_probability_sequence = (verenas_results.results.prep.probabilitySeq)';
        probability_sequence = full_probability_sequence(trial);
        restructured_results_temp.probability_condition = probability_sequence;
    
        % stimuli_type
        stimuli_type = (verenas_results.results.allStims)';
        restructured_results_temp.stimuli_type = stimuli_type;
    
        % iti
        iti = (verenas_results.results.iti)';
        restructured_results_temp.iti = iti;
        
        % face_type
        full_face_type = (verenas_results.results.prep.face)';
        face_type = full_face_type(trial);
        restructured_results_temp.face_type = face_type;
    
        % objectively_correct
        restructured_results_temp.objectively_correct = repmat({'Even'}, height(restructured_results_temp.probability_condition), 1);
        % Set 'True' for the specific conditions
        restructured_results_temp.objectively_correct((restructured_results_temp.probability_condition == 20 & strcmp(restructured_results_temp.response, 'down')) | ...
                  (restructured_results_temp.probability_condition == 80 & strcmp(restructured_results_temp.response, 'up'))) = {'True'};
        
        % Set 'False' for the specific conditions
        restructured_results_temp.objectively_correct((restructured_results_temp.probability_condition == 20 & strcmp(restructured_results_temp.response, 'up')) | ...
                  (restructured_results_temp.probability_condition == 80 & strcmp(restructured_results_temp.response, 'down'))) = {'False'};
    
        % subjectively_correct
        subjectively_correct = (verenas_results.results.outcome)';
        subjectively_correct_cell = repmat({'False'}, size(subjectively_correct));
        subjectively_correct_cell(response == 1) = {'True'};
        restructured_results_temp.subjectively_correct = subjectively_correct_cell;
        
        restructured_results = [restructured_results; restructured_results_temp];
    end
    
    writetable(restructured_results, sprintf('%s/experiment_output_sub-%03d_session-01_2024-04-10_13:37:11.csv', file_path, subject_id), 'Delimiter',';');
end