% Clean house
clc; clear; close all;

% Add simnibs to the path
cd /home/affneu/kenvdzee/.conda/envs/
addpath(genpath('simnibs_env'))

% Add PRESTUS to the path
cd /home/affneu/kenvdzee/Documents/PRESTUS_old/
addpath('functions')
addpath(genpath('toolboxes')) 
addpath('/home/common/matlab/fieldtrip/qsub')

%% The following options can be altered
which_sims = 'target_3';
test_pipeline = 0;
localite_coordinates = 0;

heating_sims = 1;
heatrise_optimised = 0;

interactive_or_slurm = 'slurm'; % interactive or slurm

% Add an integer or list of the subjects you want to simulate
subject_list = [14];
session_number = 1;
 
% Set config files and export location
if strcmp(which_sims, 'target_1')
    config_sequential = 'config_kenneth_phd_1_amygdala_1_PCD15287_01001_90mm.yaml';
elseif strcmp(which_sims, 'target_2')
    config_sequential = 'config_kenneth_phd_1_dACC_1_PCD15287_01001_45mm.yaml';
elseif strcmp(which_sims, 'target_3')
    config_sequential = 'config_kenneth_phd_1_defocussed_1_PCD15287_01001.yaml';
elseif strcmp(which_sims, 'target_4')
    config_sequential = 'config_kenneth_phd_1_focussed_1_PCD15287_01001.yaml';
end

% Config location
config_location = '/home/affneu/kenvdzee/Documents/phd_1_analysis/simulations/configs/';
localite_location = '/project/3025011.02/localite/sub-x%03d/ses-%02d/InstrumentMarkers/';

% Sets overwrite parameters and reference to transducer distance
overwrite_option = 'always';
interactive_option = 0;

for subject_id = subject_list
    
    %% Read stimulation intensity from table
    stimulation_intensity_table = readtable('/project/3025011.02/TUS_simulations/planning/stimulation_intensity_list.csv');
    subject_and_target_index = stimulation_intensity_table.subject_id == subject_id & strcmp(stimulation_intensity_table.stimulation_target, which_sims);
    stimulation_strength = sprintf(('strength_%i'), stimulation_intensity_table.intensity_level(subject_and_target_index));
    duty_cycle = stimulation_intensity_table.duty_cycle(subject_and_target_index);

    %% for consecutive simulations, you create multiple configs within one structure
    parameters = load_parameters(config_sequential, config_location);

    if isfield(parameters, 'subsequent_heating_config') && test_pipeline == 1
        n_consecutive_simulations = 2;
        heating_config_list = parameters.subsequent_heating_config;
    elseif isfield(parameters, 'subsequent_heating_config')
        n_consecutive_simulations = length(parameters.subsequent_heating_config);
        heating_config_list = parameters.subsequent_heating_config;
    else
        n_consecutive_simulations = 1;
        heating_config_list = [config_sequential];
    end

    for consecutive_simulation_number = 1:n_consecutive_simulations
        
        %% Load optional stimulation strenghts for the transducer
        if strcmp(which_sims, 'target_1') || strcmp(which_sims, 'target_2')
            source_amp = parameters.transducer.(stimulation_strength);
            if strcmp(stimulation_strength, 'strength_3')
                phase_angles = 'phases_3';
            elseif strcmp(stimulation_strength, 'strength_2')
                phase_angles = 'phases_2';
            else
                phase_angles = 'phases_1';
            end
            source_phase_deg = parameters.transducer.(phase_angles);

            %% Load configs for each transducer coordinate
            parameters = load_parameters(heating_config_list(consecutive_simulation_number), config_location, 'transducer.source_amp', source_amp, 'transducer.source_phase_deg', source_phase_deg, 'thermal.duty_cycle', duty_cycle);

        else
            parameters = load_parameters(heating_config_list(consecutive_simulation_number), config_location);
        end

        
        % Load the stimulation target and replace the 4 with a 3 since the
        % defocussed and focussed have the same coordinates
        stimulation_target = parameters.stimulation_target;
        if ~isempty(regexp(stimulation_target, '^target_4_.*', 'once'))
            stimulation_target_coordinates = regexprep(stimulation_target, '^target_4_', 'target_3_');
        else
            stimulation_target_coordinates = stimulation_target;
        end

        %% Setting folder locations for structural data
        filename_t1 = dir(sprintf(fullfile(parameters.data_path, parameters.t1_path_template), subject_id));
        t1_header = niftiinfo(fullfile(filename_t1.folder, filename_t1.name));
        t1_image = niftiread(fullfile(filename_t1.folder, filename_t1.name));
    
        %% Load coordinates
        if localite_coordinates == 1
            %% Change output folder to post-hoc
            parameters.output_location = strrep(parameters.t1_path_template, 'planning', 'post-hoc');
            parameters.temp_output_dir = strrep(parameters.t2_path_template, 'planning', 'post-hoc');

            %% Load coordinates from Localite
            % First check if any of the instrument_markers are named incorrectly
            incorrectly_named_instrument_markers = readtable('/project/3025011.02/localite/instrument_marker_name_correction.csv');
            incorrectly_named_instrument_markers = incorrectly_named_instrument_markers(incorrectly_named_instrument_markers.subject_id == subject_id, :);
    
            % Loop through the filtered rows to find the 
            for i = 1:height(incorrectly_named_instrument_markers)
                % Check if 'stimulation_target_left' matches any 'intended_name'
                if any(strcmp(stimulation_target_coordinates, incorrectly_named_instrument_markers.intended_name))
                    % Find the row where it matches and replace with 'original_name'
                    match_row = strcmp(incorrectly_named_instrument_markers.intended_name, stimulation_target_coordinates);
                    trigger_marker_left = incorrectly_named_instrument_markers.original_name{match_row};
                else
                    trigger_marker_left = stimulation_target_coordinates;
                end
            end
    
            % Set expected_focal_distance_mm
            t1_grid_step_mm = t1_header.PixelDimensions(1);
            focal_distance_t1 = norm(parameters.focus_pos_t1_grid - parameters.transducer.pos_t1_grid);
            parameters.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;
            parameters_right.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;
    
            % To compensate for potential offsets between the center of the reference and the edge of the bowl
            reference_to_transducer_distance = -(parameters.transducer.curv_radius_mm - parameters.transducer.dist_to_plane_mm) - 7;
            
            % Load the most recent trigger mark file
            extract_dt = @(x) datetime(x.name(end-20:end-4),'InputFormat','yyyyMMddHHmmssSSS');
            localite_file_name_and_location = sprintf(localite_location, subject_id, session_number);
            trig_mark_files = dir(localite_file_name_and_location);
            if isempty(trig_mark_files)
                error('Localite file `%s` cannot be found', localite_file_name_and_location)
            end
    
            % Filter out files that are not InstrumentMarker files
            trig_mark_files = trig_mark_files(contains({trig_mark_files.name}, 'InstrumentMarker'));
            
            % Select the most recent file
            [~,idx] = sort([arrayfun(extract_dt,trig_mark_files)],'descend');
            trig_mark_files = trig_mark_files(idx);
            
            % Translate left transducer trigger markers to raster positions
            [left_trans_ras_pos, left_focus_ras_pos] = get_trans_pos_from_instrument_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), trigger_marker_left, 5, ...
                reference_to_transducer_distance, parameters.expected_focal_distance_mm);
            parameters.transducer.pos_t1_grid = ras_to_grid(left_trans_ras_pos, t1_header);
            parameters.focus_pos_t1_grid = ras_to_grid(left_focus_ras_pos, t1_header);
    
            % Translate right transducer trigger markers to raster positions
            [right_trans_ras_pos, right_focus_ras_pos] = get_trans_pos_from_instrument_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), trigger_marker_right, 5, ...
                reference_to_transducer_distance, parameters_right.expected_focal_distance_mm);
            parameters_right.transducer.pos_t1_grid = ras_to_grid(right_trans_ras_pos, t1_header);
            parameters_right.focus_pos_t1_grid = ras_to_grid(right_focus_ras_pos, t1_header);
    
            %% Label transducer and focus locations
            transducers = [parameters.transducer.pos_t1_grid parameters_right.transducer.pos_t1_grid];
            focus = [parameters.focus_pos_t1_grid parameters_right.focus_pos_t1_grid];
        else
            %% Load coordinates from the exploratory_coordinate_list
            exploratory_coordinate_list = readtable('/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv');
            
            index_subject = exploratory_coordinate_list.subject_id == subject_id;
            index_stimulation_target_left = contains(exploratory_coordinate_list.stimulation_target, stimulation_target_coordinates);
        
            index_coordinates_left = index_subject & index_stimulation_target_left;
        
            row_coordinates_left = exploratory_coordinate_list(index_coordinates_left, :);
        
            parameters.transducer.pos_t1_grid = [row_coordinates_left.pos_t1_grid_x, row_coordinates_left.pos_t1_grid_y, row_coordinates_left.pos_t1_grid_z];
            parameters.focus_pos_t1_grid = [row_coordinates_left.focus_pos_t1_grid_x, row_coordinates_left.focus_pos_t1_grid_y, row_coordinates_left.focus_pos_t1_grid_z];
        
            %% Label transducer and focus locations
            transducers = parameters.transducer.pos_t1_grid';
            focus = parameters.focus_pos_t1_grid';
        end
    
        %% Preview transducer location
        % Makes a different slice depending on the target
        if contains(stimulation_target, 'target_2')
            slice_dim_right_figure = 1;
        else
            slice_dim_right_figure = 3;
        end
        
        figure;
        hImage = imshowpair(...
            plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,1), focus(:,1), parameters), ...
            plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,1), focus(:,1), parameters, 'slice_dim', slice_dim_right_figure), ...
            'montage');
        hAxes = get(hImage, 'Parent');
        title(hAxes, sprintf('sub-%03d %s [%g; %g; %g]', subject_id, stimulation_target, transducers(:,1)));
        
        %% Simulations for the left target
        % Load additional parameters into config
        parameters.overwrite_files = overwrite_option;
        parameters.interactive = interactive_option;
        parameters.simulation_medium = 'layered';
        parameters.run_heating_sims = heating_sims;
        parameters.heatingvideo = 0;
    
        % Adjust timelimit if heating simulations are to be run
        if isfield(parameters,'run_heating_sims') && parameters.run_heating_sims == 1
            timelimit = '24:00:00';
            memorylimit = 64;
        else
            timelimit = '04:00:00';
            memorylimit = 40;
        end
    
        % Set filename
        if strcmp(which_sims, 'target_1') || strcmp(which_sims, 'target_2')
            parameters.results_filename_affix = sprintf('_%s_dc%i_%s', stimulation_target, duty_cycle*100, stimulation_strength);
        else
            parameters.results_filename_affix = sprintf('_%s', stimulation_target);
        end
    
        % Set starting temperatures
        if heatrise_optimised == 1
            parameters.thermal.temp_0.water = 37;
            parameters.thermal.temp_0.skull = 37;
            parameters.thermal.temp_0.brain = 37;
            parameters.thermal.temp_0.skin = 37;
            parameters.thermal.temp_0.skull_trabecular = 37;
            parameters.thermal.temp_0.skull_cortical = 37;
        else
            parameters.thermal.temp_0.water = 37;
            parameters.thermal.temp_0.skull = 36;
            parameters.thermal.temp_0.brain = 37;
            parameters.thermal.temp_0.skin = 35;
            parameters.thermal.temp_0.skull_trabecular = 37;
            parameters.thermal.temp_0.skull_cortical = 36;
        end

        % Create a structure containing all the configs
        if consecutive_simulation_number ~= 1
            config_field_name = sprintf('config_%d', consecutive_simulation_number);
            previous_config_field_name = sprintf('config_%d', consecutive_simulation_number-1);
            sequential_configs.(config_field_name) = parameters;
            if consecutive_simulation_number == 2
                if isfield(first_parameters,'subject_subfolder') && first_parameters.subject_subfolder == 1
                    first_parameters.output_dir = fullfile(first_parameters.temp_output_dir, sprintf('sub-%03d', subject_id));
                else 
                    first_parameters.output_dir = first_parameters.temp_output_dir;
                end
                sequential_configs.(config_field_name).adopted_heatmap = fullfile(first_parameters.output_dir, sprintf('sub-%03d_final_%s_orig_coord%s',...
                    subject_id, 'heating', first_parameters.results_filename_affix));
            else
                if isfield(sequential_configs.(previous_config_field_name),'subject_subfolder') && sequential_configs.(previous_config_field_name).subject_subfolder == 1
                    sequential_configs.(previous_config_field_name).output_dir = fullfile(sequential_configs.(previous_config_field_name).temp_output_dir, sprintf('sub-%03d', subject_id));
                else 
                    sequential_configs.(previous_config_field_name).output_dir = sequential_configs.(previous_config_field_name).temp_output_dir;
                end
                sequential_configs.(config_field_name).adopted_heatmap = fullfile(sequential_configs.(previous_config_field_name).output_dir, sprintf('sub-%03d_final_%s_orig_coord%s',...
                    subject_id, 'heating', sequential_configs.(previous_config_field_name).results_filename_affix));
            end
        else
            first_parameters = parameters;
            first_parameters.run_posthoc_water_sims = 1;
        end
    end

    % Send job to slurm (if not in testing mode)
    if test_pipeline == 0
        if strcmp(interactive_or_slurm, 'interactive')
            single_subject_pipeline(subject_id, parameters, 'sequential_configs', sequential_configs);
        else
            single_subject_pipeline_with_slurm(subject_id, first_parameters, timelimit, memorylimit, 'sequential_configs', sequential_configs);
        end
    end
end

% This is just here to go back to the script's directory
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));