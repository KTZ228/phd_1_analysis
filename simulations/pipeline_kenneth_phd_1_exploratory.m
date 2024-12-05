% Clean house
clc; clear;

% Add simnibs to the path
cd /home/affneu/kenvdzee/SimNIBS-4.0/
addpath(genpath('simnibs_env'))

% Add PRESTUS to the path
cd /home/affneu/kenvdzee/Documents/PRESTUS/
addpath('functions')
addpath(genpath('toolboxes')) 
addpath('/home/common/matlab/fieldtrip/qsub')

%% The following options can be altered
run_amygdala_sims = 1;
run_layered_sims = 1;
test_pipeline = 1;
heating_sims = 1;
localite_coordinates = 1;
pilot_simulations = 1;

% Add an integer or list of the subjects you want to simulate
stimulation_depth_list = "90mm";
subject_list = 3;
session_number = 1;

for stimulation_depth = stimulation_depth_list
    
    % Set config files and export location
    if run_amygdala_sims == 1
        config_left_transducer = sprintf('config_kenneth_phd_1_amygdala_exploratory_PCD15287_01002_left_%s.yaml', stimulation_depth);
        config_right_transducer = sprintf('config_kenneth_phd_1_amygdala_exploratory_PCD15287_01002_right_%s.yaml', stimulation_depth);
        stimulation_target_left = 'left_amygdala';
        stimulation_target_right = 'right_amygdala';
    else
        config_left_transducer = sprintf('config_kenneth_phd_1_dACC_exploratory_PCD15287_01002_left_%s.yaml', stimulation_depth);
        config_right_transducer = sprintf('config_kenneth_phd_1_dACC_exploratory_PCD15287_01002_right_%s.yaml', stimulation_depth);
        stimulation_target_left = 'left_posterior_dacc';
        stimulation_target_right = 'right_posterior_dacc';
        %stimulation_target_left = 'left_medial_dacc';
        %stimulation_target_right = 'right_medial_dacc';
        %stimulation_target_left = 'left_anterior_dacc';
        %stimulation_target_right = 'right_anterior_dacc';
    end
    
    % Config location
    config_location = '/home/affneu/kenvdzee/Documents/phd_1_analysis/simulations/configs/';
    
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
        end

        %% Setting folder locations for structural data
        filename_t1 = dir(sprintf(fullfile(parameters_left.data_path,parameters_left.t1_path_template), subject_id));
        t1_header = niftiinfo(fullfile(filename_t1.folder,filename_t1.name));
        t1_image = niftiread(fullfile(filename_t1.folder,filename_t1.name));
    
        %% Load coordinates
        if localite_coordinates == 1
            %% Load coordinates from Localite
            % Set expected_focal_distance_mm
            t1_grid_step_mm = t1_header.PixelDimensions(1);
            focal_distance_t1 = norm(parameters_left.focus_pos_t1_grid - parameters_left.transducer.pos_t1_grid);
            parameters_left.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;
            parameters_right.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;

            % Left transducer
            reference_to_transducer_distance = -(parameters_left.transducer.curv_radius_mm - parameters_left.transducer.dist_to_plane_mm);
            extract_dt = @(x) datetime(x.name(end-20:end-4),'InputFormat','yyyyMMddHHmmssSSS');
            
            % Load the trigger mark file
            if pilot_simulations == 1
                localite_file_name_and_location = sprintf('%ssub-x%03d/ses-mri%02d/other/localite_sub-x%03d_ses-mri%02d_left*.xml',parameters_left.data_path, subject_id, session_number, subject_id, session_number);
            else
                localite_file_name_and_location = sprintf('%ssub-%03d/ses-mri%02d/other/localite_sub-%03d_ses-mri%02d_left*.xml',parameters_left.data_path, subject_id, session_number, subject_id, session_number);
            end
            trig_mark_files = dir(localite_file_name_and_location);
            if isempty(trig_mark_files)
                error('Localite file `%s` cannot be found', localite_file_name_and_location)
            end
            
            % Select the most recent file
            [~,idx] = sort([arrayfun(extract_dt,trig_mark_files)],'descend');
            trig_mark_files = trig_mark_files(idx);
            
            % Translate transducer trigger markers to raster positions
            [left_trans_ras_pos, left_focus_ras_pos] = get_trans_pos_from_trigger_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), 5, ...
                reference_to_transducer_distance, parameters_left.expected_focal_distance_mm);
            parameters_left.transducer.pos_t1_grid = ras_to_grid(left_trans_ras_pos, t1_header);
            parameters_left.focus_pos_t1_grid = ras_to_grid(left_focus_ras_pos, t1_header);
    
            % Right transducer
            reference_to_transducer_distance = -(parameters_right.transducer.curv_radius_mm - parameters_right.transducer.dist_to_plane_mm);
            
            % Load the trigger mark file
            if pilot_simulations == 1
                localite_file_name_and_location = sprintf('%ssub-x%03d/ses-mri%02d/other/localite_sub-x%03d_ses-mri%02d_right*.xml',parameters_left.data_path, subject_id, session_number, subject_id, session_number);
            else
                localite_file_name_and_location = sprintf('%ssub-%03d/ses-mri%02d/other/localite_sub-%03d_ses-mri%02d_right*.xml',parameters_left.data_path, subject_id, session_number, subject_id, session_number);
            end
            trig_mark_files = dir(localite_file_name_and_location);
            if isempty(trig_mark_files)
                error('Localite file `%s` is not found', localite_file_name_and_location)
            end
            
            % Select the most recent file
            [~,idx] = sort([arrayfun(extract_dt,trig_mark_files)],'descend');
            trig_mark_files = trig_mark_files(idx);
            
            % Translate transducer trigger markers to raster positions
            [right_trans_ras_pos, right_focus_ras_pos] = get_trans_pos_from_trigger_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), 5, ...
                reference_to_transducer_distance, parameters_right.expected_focal_distance_mm);
            parameters_right.transducer.pos_t1_grid = ras_to_grid(right_trans_ras_pos, t1_header);
            parameters_right.focus_pos_t1_grid = ras_to_grid(right_focus_ras_pos, t1_header);
        else
            %% Load coordinates from the exploratory_coordinate_list
            exploratory_coordinate_list = readtable('/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv');
            
            index_subject = exploratory_coordinate_list.subject_id == subject_id;
            index_stimulation_target_left = strcmp(exploratory_coordinate_list.stimulation_target, stimulation_target_left);
            index_stimulation_target_right = strcmp(exploratory_coordinate_list.stimulation_target, stimulation_target_right);
        
            index_coordinates_left = index_subject & index_stimulation_target_left;
            index_coordinates_right = index_subject & index_stimulation_target_right;
        
            row_coordinates_left = exploratory_coordinate_list(index_coordinates_left, :);
            row_coordinates_right = exploratory_coordinate_list(index_coordinates_right, :);
        
            parameters_left.transducer.pos_t1_grid = [row_coordinates_left.pos_t1_grid_x, row_coordinates_left.pos_t1_grid_y, row_coordinates_left.pos_t1_grid_z];
            parameters_left.focus_pos_t1_grid = [row_coordinates_left.focus_pos_t1_grid_x, row_coordinates_left.focus_pos_t1_grid_y, row_coordinates_left.focus_pos_t1_grid_z];
            parameters_right.transducer.pos_t1_grid = [row_coordinates_right.pos_t1_grid_x, row_coordinates_right.pos_t1_grid_y, row_coordinates_right.pos_t1_grid_z];
            parameters_right.focus_pos_t1_grid = [row_coordinates_right.focus_pos_t1_grid_x, row_coordinates_right.focus_pos_t1_grid_y, row_coordinates_right.focus_pos_t1_grid_z];
        end
        
        %% Label transducer and focus locations
        transducers = [parameters_left.transducer.pos_t1_grid' parameters_right.transducer.pos_t1_grid'];
        focus = [parameters_left.focus_pos_t1_grid' parameters_right.focus_pos_t1_grid'];
    
        %% Preview transducer locations
        % Makes a different slice depending on the target
        if run_amygdala_sims == 1
            slice_dim_right_figure = 3;
        else
            slice_dim_right_figure = 1;
        end
    
        figure(1);
        imshowpair(plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,1), focus(:,1), parameters_left), ...
            plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,1), focus(:,1), parameters_left, 'slice_dim', slice_dim_right_figure),'montage');
        title('Left target')
    
        figure(2);
        imshowpair(plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,2), focus(:,2), parameters_left), ...
            plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), transducers(:,2), focus(:,2), parameters_left, 'slice_dim', slice_dim_right_figure),'montage');
        title('Right target');
        
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
    
        % Send job to qsub (if not in testing mode)
        if test_pipeline == 0
            single_subject_pipeline_with_slurm(subject_id, parameters_left, timelimit, memorylimit);
        end
    
        %% Simulations for right target
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
    
        % Send job to qsub (if not in testing mode)
        if test_pipeline == 0
            single_subject_pipeline_with_slurm(subject_id, parameters_right, timelimit, memorylimit);
        end
    end
end

% This is just here to go back to the script's directory
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));