% Clean house
clc; clear;

% Add simnibs to the path
cd /home/affneu/kenvdzee/.conda/envs/
addpath(genpath('simnibs_env'))

% Add PRESTUS to the path
cd /home/affneu/kenvdzee/Documents/PRESTUS_old/
addpath('functions')
addpath(genpath('toolboxes')) 
addpath('/home/common/matlab/fieldtrip/qsub')

%% The following options can be altered
which_sims = 'dacc_sequential'; 
run_layered_sims = 1;
test_pipeline = 1;
heating_sims = 1;
heatrise_optimised = 0;
localite_coordinates = 0;
pilot_simulations = 1;
interactive_or_slurm = 'slurm'; % qsub or slurm

% Add an integer or list of the subjects you want to simulate
subject_list = 702;
session_number = 1;
 
% Set config files and export location
if strcmp(which_sims, 'amygdala')
    config_left_transducer = 'config_kenneth_phd_1_amygdala_PCD15287_01001_left_90mm.yaml';
    config_right_transducer = 'config_kenneth_phd_1_amygdala_PCD15287_01002_right_90mm.yaml';
    stimulation_target_left = 'left_amygdala';
    stimulation_target_right = 'right_amygdala';
elseif strcmp(which_sims, 'dacc')
    config_left_transducer = 'config_kenneth_phd_1_dACC_PCD15287_01001_left_45mm.yaml';
    config_right_transducer = 'config_kenneth_phd_1_dACC_PCD15287_01002_right_45mm.yaml';
    stimulation_target_left = 'left_anterior_dacc';
    stimulation_target_right = 'right_anterior_dacc';
    %stimulation_target_left = 'left_medial_dacc';
    %stimulation_target_right = 'right_medial_dacc';
    %stimulation_target_left = 'left_posterior_dacc';
    %stimulation_target_right = 'right_posterior_dacc';
elseif strcmp(which_sims, 'sham_defocussed')
    config_left_transducer = 'config_kenneth_phd_1_sham_defocussed_PCD15287_01001_left.yaml';
    config_right_transducer = 'config_kenneth_phd_1_sham_defocussed_PCD15287_01002_right.yaml';
    stimulation_target_left = 'left_sham_defocussed';
    stimulation_target_right = 'right_sham_defocussed';
elseif strcmp(which_sims, 'sham_focussed')
    config_left_transducer = 'config_kenneth_phd_1_sham_focussed_PCD15287_01001_left.yaml';
    config_right_transducer = 'config_kenneth_phd_1_sham_focussed_PCD15287_01002_right.yaml';
    stimulation_target_left = 'left_sham_focussed';
    stimulation_target_right = 'right_sham_focussed';
elseif strcmp(which_sims, 'dacc_sequential')
    config_left_transducer = 'config_kenneth_phd_1_dACC_1_PCD15287_01001_45mm.yaml';
    config_right_transducer = 'config_kenneth_phd_1_dACC_1_PCD15287_01001_45mm.yaml';
    stimulation_target_left = 'target_2_1';
    stimulation_target_right = 'inactive';
end

% Config location
config_location = '/home/affneu/kenvdzee/Documents/phd_1_analysis/simulations/configs/';
localite_location = '/project/3025011.02/localite/sub-x%03d/ses-%02d/InstrumentMarkers/';

%% These parameters and functions should not be changed. Additional changes can be made in the config files
% Add string of simulation medium as input
if run_layered_sims == 1
    layered_simulations = 'layered';
else
    layered_simulations = 'water';
end

% Sets overwrite parameters and reference to transducer distance
overwrite_option = 'always';
interactive_option = 0;

for subject_id = subject_list
    
    %% Load configs for each transducer coordinate
    parameters_left = load_parameters(config_left_transducer, config_location);
    parameters_right = load_parameters(config_right_transducer, config_location);
    if pilot_simulations == 1
        parameters_left.t1_path_template = strrep(parameters_left.t1_path_template, 'sub-%1$03d', 'sub-x%1$03d');
        parameters_left.t2_path_template = strrep(parameters_left.t2_path_template, 'sub-%1$03d', 'sub-x%1$03d');
        parameters_right.t1_path_template = strrep(parameters_right.t1_path_template, 'sub-%1$03d', 'sub-x%1$03d');
        parameters_right.t2_path_template = strrep(parameters_right.t2_path_template, 'sub-%1$03d', 'sub-x%1$03d');
        localite_location = strrep(localite_location, 'sub-%03d', 'sub-x%03d');
    end

    %% Setting folder locations for structural data
    filename_t1 = dir(sprintf(fullfile(parameters_left.data_path, parameters_left.t1_path_template), subject_id));
    t1_header = niftiinfo(fullfile(filename_t1.folder, filename_t1.name));
    t1_image = niftiread(fullfile(filename_t1.folder, filename_t1.name));

    %% Load coordinates
    if localite_coordinates == 1
        %% Load coordinates from Localite
        % First check if any of the instrument_markers are named incorrectly
        incorrectly_named_instrument_markers = readtable('/project/3025011.02/localite/instrument_marker_name_correction.csv');
        incorrectly_named_instrument_markers = incorrectly_named_instrument_markers(incorrectly_named_instrument_markers.subject_id == subject_id, :);

        % Loop through the filtered rows to find the 
        for i = 1:height(incorrectly_named_instrument_markers)
            % Check if 'stimulation_target_left' matches any 'intended_name'
            if any(strcmp(stimulation_target_left, incorrectly_named_instrument_markers.intended_name))
                % Find the row where it matches and replace with 'original_name'
                match_row = strcmp(incorrectly_named_instrument_markers.intended_name, stimulation_target_left);
                trigger_marker_left = incorrectly_named_instrument_markers.original_name{match_row};
            else
                trigger_marker_left = stimulation_target_left;
            end
        
            % Check if 'stimulation_target_right' matches any 'intended_name'
            if any(strcmp(stimulation_target_right, incorrectly_named_instrument_markers.intended_name))
                % Find the row where it matches and replace with 'original_name'
                match_row = strcmp(incorrectly_named_instrument_markers.intended_name, stimulation_target_right);
                trigger_marker_right = incorrectly_named_instrument_markers.original_name{match_row};
            else
                trigger_marker_right = stimulation_target_right;
            end
        end

        % Set expected_focal_distance_mm
        t1_grid_step_mm = t1_header.PixelDimensions(1);
        focal_distance_t1 = norm(parameters_left.focus_pos_t1_grid - parameters_left.transducer.pos_t1_grid);
        parameters_left.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;
        parameters_right.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;

        % To compensate for potential offsets between the center of the reference and the edge of the bowl
        reference_to_transducer_distance = -(parameters_left.transducer.curv_radius_mm - parameters_left.transducer.dist_to_plane_mm) - 7;
        
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
            reference_to_transducer_distance, parameters_left.expected_focal_distance_mm);
        parameters_left.transducer.pos_t1_grid = ras_to_grid(left_trans_ras_pos, t1_header);
        parameters_left.focus_pos_t1_grid = ras_to_grid(left_focus_ras_pos, t1_header);

        % Translate right transducer trigger markers to raster positions
        [right_trans_ras_pos, right_focus_ras_pos] = get_trans_pos_from_instrument_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), trigger_marker_right, 5, ...
            reference_to_transducer_distance, parameters_right.expected_focal_distance_mm);
        parameters_right.transducer.pos_t1_grid = ras_to_grid(right_trans_ras_pos, t1_header);
        parameters_right.focus_pos_t1_grid = ras_to_grid(right_focus_ras_pos, t1_header);

        %% Label transducer and focus locations
        transducers = [parameters_left.transducer.pos_t1_grid parameters_right.transducer.pos_t1_grid];
        focus = [parameters_left.focus_pos_t1_grid parameters_right.focus_pos_t1_grid];
    else
        %% Load coordinates from the exploratory_coordinate_list
        exploratory_coordinate_list = readtable('/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv');
        
        index_subject = exploratory_coordinate_list.subject_id == subject_id;
        index_stimulation_target_left = contains(exploratory_coordinate_list.stimulation_target, stimulation_target_left);
        index_stimulation_target_right = contains(exploratory_coordinate_list.stimulation_target, stimulation_target_right);
    
        index_coordinates_left = index_subject & index_stimulation_target_left;
        index_coordinates_right = index_subject & index_stimulation_target_right;
    
        row_coordinates_left = exploratory_coordinate_list(index_coordinates_left, :);
        row_coordinates_right = exploratory_coordinate_list(index_coordinates_right, :);
    
        parameters_left.transducer.pos_t1_grid = [row_coordinates_left.pos_t1_grid_x, row_coordinates_left.pos_t1_grid_y, row_coordinates_left.pos_t1_grid_z];
        parameters_left.focus_pos_t1_grid = [row_coordinates_left.focus_pos_t1_grid_x, row_coordinates_left.focus_pos_t1_grid_y, row_coordinates_left.focus_pos_t1_grid_z];
        parameters_right.transducer.pos_t1_grid = [row_coordinates_right.pos_t1_grid_x, row_coordinates_right.pos_t1_grid_y, row_coordinates_right.pos_t1_grid_z];
        parameters_right.focus_pos_t1_grid = [row_coordinates_right.focus_pos_t1_grid_x, row_coordinates_right.focus_pos_t1_grid_y, row_coordinates_right.focus_pos_t1_grid_z];
    
        %% Label transducer and focus locations
        transducers = [parameters_left.transducer.pos_t1_grid' parameters_right.transducer.pos_t1_grid'];
        focus = [parameters_left.focus_pos_t1_grid' parameters_right.focus_pos_t1_grid'];
    end

    %% Preview transducer locations
    % Makes a different slice depending on the target
    if contains(stimulation_target_left, 'dacc') || contains(stimulation_target_left, 'target_2')
        slice_dim_right_figure = 1;
    else
        slice_dim_right_figure = 3;
    end

    figure(1);
    imshowpair(plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,1), focus(:,1), parameters_left), ...
        plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,1), focus(:,1), parameters_left, 'slice_dim', slice_dim_right_figure),'montage');
    title('Left target')

    if ~strcmp(stimulation_target_right, 'inactive')
        figure(2);
        imshowpair(plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,2), focus(:,2), parameters_right), ...
            plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,2), focus(:,2), parameters_right, 'slice_dim', slice_dim_right_figure),'montage');
        title('Right target');
    end
    
    %% Simulations for the left target
    % Load additional parameters into config
    parameters_left.overwrite_files = overwrite_option;
    parameters_left.interactive = interactive_option;
    parameters_left.simulation_medium = layered_simulations;
    parameters_left.run_heating_sims = heating_sims;

    % Adjust timelimit if heating simulations are to be run
    if isfield(parameters_left,'run_heating_sims') && parameters_left.run_heating_sims == 1
        timelimit = '24:00:00';
        memorylimit = 64;
    else
        timelimit = '04:00:00';
        memorylimit = 40;
    end

    % Set filename
    parameters_left.results_filename_affix = sprintf('_target_%s', stimulation_target_left);

    % Set starting temperatures
    if heatrise_optimised == 0
        parameters_left.thermal.temp_0.water = 37;
        parameters_left.thermal.temp_0.skull = 37;
        parameters_left.thermal.temp_0.brain = 37;
        parameters_left.thermal.temp_0.skin = 37;
        parameters_left.thermal.temp_0.skull_trabecular = 37;
        parameters_left.thermal.temp_0.skull_cortical = 37;
    else
        parameters_left.thermal.temp_0.water = 37;
        parameters_left.thermal.temp_0.skull = 36;
        parameters_left.thermal.temp_0.brain = 37;
        parameters_left.thermal.temp_0.skin = 35;
        parameters_left.thermal.temp_0.skull_trabecular = 37;
        parameters_left.thermal.temp_0.skull_cortical = 36;
    end

    % Send job to qsub (if not in testing mode)
    if test_pipeline == 0
        if strcmp(interactive_or_slurm, 'interactive')
            single_subject_pipeline(subject_id, parameters_left)
        else
            single_subject_pipeline_with_slurm(subject_id, parameters_left, timelimit, memorylimit);%false, timelimit, memorylimit);
        end
    end

    %% Simulations for right target
    % Only run this if we don't use sequential simulations
    if ~strcmp(stimulation_target_right, 'inactive')

        % Load additional parameters into config
        parameters_right.overwrite_files = overwrite_option;
        parameters_right.interactive = interactive_option;
        parameters_right.simulation_medium = layered_simulations;
        parameters_right.run_heating_sims = heating_sims;
    
        % Adjust timelimit if heating simulations are to be run
        if isfield(parameters_right,'run_heating_sims') && parameters_right.run_heating_sims == 1
            timelimit = '24:00:00';
            memorylimit = 64;
        else
            timelimit = '04:00:00';
            memorylimit = 40;
        end
    
        % Set filename 
        parameters_right.results_filename_affix = sprintf('_target_%s', stimulation_target_right);

                % Set starting temperatures
        if heatrise_optimised == 0
            parameters_right.thermal.temp_0.water = 37;
            parameters_right.thermal.temp_0.skull = 37;
            parameters_right.thermal.temp_0.brain = 37;
            parameters_right.thermal.temp_0.skin = 37;
            parameters_right.thermal.temp_0.skull_trabecular = 37;
            parameters_right.thermal.temp_0.skull_cortical = 37;
        else
            parameters_right.thermal.temp_0.water = 37;
            parameters_right.thermal.temp_0.skull = 36;
            parameters_right.thermal.temp_0.brain = 37;
            parameters_right.thermal.temp_0.skin = 35;
            parameters_right.thermal.temp_0.skull_trabecular = 37;
            parameters_right.thermal.temp_0.skull_cortical = 36;
        end

        % Send job to qsub (if not in testing mode)
        if test_pipeline == 0
            if strcmp(interactive_or_slurm, 'interactive')
                single_subject_pipeline(subject_id, parameters_right)
            else
                single_subject_pipeline_with_slurm(subject_id, parameters_right, timelimit, memorylimit);%false, timelimit, memorylimit);
            end
        end
    end
end

% This is just here to go back to the script's directory
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));