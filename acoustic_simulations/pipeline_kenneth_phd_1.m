% Clean house
clc; clear; close all;

% Add simnibs to the path
cd /home/affneu/kenvdzee/.conda/envs/
addpath(genpath('simnibs_env'))

% Add PRESTUS to the path
cd /home/affneu/kenvdzee/Documents/PRESTUS/
addpath('functions')
addpath(genpath('toolboxes')) 
addpath('/home/common/matlab/fieldtrip/qsub')

%% The following options can be altered
target_list = [2,3];
test_pipeline = 0;
localite_coordinates = 1;
include_mask = 0;
% Should include which t1 and t2 to use based on cut-off

heating_sims = 1;
heatrise_optimised = 1;

interactive_or_slurm = 'slurm'; % interactive or slurm

% Add an integer or list of the subjects you want to simulate
subject_list = [55];%52,53,54,57];

% Config location
config_location = '/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/configs/';
localite_location = '/project/3025011.02/raw/sub-%03d/ses-mri%02d/localite/';

% Sets overwrite parameters and reference to transducer distance
overwrite_option = 'always';
interactive_option = 0;

% Read stimulation intensity table
stimulation_intensity_table = readtable('/project/3025011.02/TUS_simulations/planning/stimulation_intensity_list.csv');

% Loop through stimulation targets
for stimulation_target_group = target_list

    % Change target to string
    stimulation_target_group = sprintf('target_%d', stimulation_target_group);
    
    % Set config files and export location
    if strcmp(stimulation_target_group, 'target_1')
        config_sequential = 'config_kenneth_phd_1_amygdala_1_PCD15287_01001_90mm.yaml';
    elseif strcmp(stimulation_target_group, 'target_2')
        config_sequential = 'config_kenneth_phd_1_dACC_1_PCD15287_01001_45mm.yaml';
    elseif strcmp(stimulation_target_group, 'target_3')
        config_sequential = 'config_kenneth_phd_1_defocussed_1_PCD15287_01001.yaml';
    elseif strcmp(stimulation_target_group, 'target_4')
        config_sequential = 'config_kenneth_phd_1_focussed_1_PCD15287_01001.yaml';
    end

    % Loop through subject_id's
    for subject_id = subject_list
        
        %% Read stimulation intensity from table
        subject_and_target_index = stimulation_intensity_table.subject_id == subject_id & strcmp(stimulation_intensity_table.stimulation_target, stimulation_target_group);
        stimulation_strength = sprintf(('strength_%i'), stimulation_intensity_table.intensity_level(subject_and_target_index));
        duty_cycle = stimulation_intensity_table.duty_cycle(subject_and_target_index);
    
        %% for consecutive simulations, you create multiple configs within one structure
        parameters = load_parameters(config_sequential, config_location);
    
        if isfield(parameters, 'subsequent_heating_config') && test_pipeline == 1 && ~strcmp(stimulation_target_group, 'target_2') && localite_coordinates ~= 1
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
            if strcmp(stimulation_target_group, 'target_1') || strcmp(stimulation_target_group, 'target_2')
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
    
            if strcmp(interactive_or_slurm = 'interactive')
                parameters.interactive = 1;
            else
                parameters.interactive = 0;
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
    
            %% Load the subject mask
            if isfield(parameters,'mask_name') && include_mask == 1
                parameters.ROI_mask_location = sprintf('/project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-%03d/sub-%03d_%s.nii.gz', subject_id, subject_id, parameters.mask_name);
            end
        
            %% Load coordinates
            if localite_coordinates == 1
                %% Change output folder to post-hoc
                parameters.output_location = strrep(parameters.output_location, 'planning', 'post-hoc');
                parameters.sim_path = strrep(parameters.sim_path, 'planning', 'post-hoc');
    
                %% Load coordinates from Localite
                % First check if any of the instrument_markers are named incorrectly
                incorrectly_named_instrument_markers = readtable('/project/3025011.02/localite/instrument_marker_name_correction.csv');
                incorrectly_named_instrument_markers = incorrectly_named_instrument_markers(incorrectly_named_instrument_markers.subject_id == subject_id, :);
        
                % Loop through the filtered rows to find the 
                for i = 1:height(incorrectly_named_instrument_markers)
                    % Check if 'stimulation_target' matches any 'intended_name'
                    if any(strcmp(stimulation_target_coordinates, incorrectly_named_instrument_markers.intended_name))
                        % Find the row where it matches and replace with 'original_name'
                        match_row = strcmp(incorrectly_named_instrument_markers.intended_name, stimulation_target_coordinates);
                        trigger_marker_name = incorrectly_named_instrument_markers.original_name{match_row};
                    else
                        trigger_marker_name = stimulation_target_coordinates;
                    end
                end
    
                %% Then determine which session number is coupled to which target
                randomisation_list_location = '/project/3025011.02/O5.Randomisation_list_AmydACC.csv';
                
                % Read the CSV file with semicolon delimiter
                randomisation_list = readtable(randomisation_list_location, 'Delimiter', ';');
                
                % Create the subject ID string in the format 'sub-X'
                subject_str = sprintf('sub-%03d', subject_id);
                
                % Find the row matching the subject ID
                row_idx = strcmp(randomisation_list.subject_id, subject_str);
                
                if ~any(row_idx)
                    warning('Subject ID %d not found in the file', subject_id);
                    session_number = NaN;
                    return;
                end
                
                % Extract the row for this subject
                subject_row = randomisation_list(row_idx, :);
                
                % Search through sessions 1-4 for the matching which_sims
                session_number = NaN;
                for sess = 2:4
                    session_col = sprintf('ses_mri%02d', sess);
                    if strcmp(subject_row.(session_col){1}, stimulation_target_group)
                        session_number = sess;
                        break;
                    end
                end
                
                if isnan(session_number)
                    warning('which_sims "%s" not found for subject %d', stimulation_target_group, subject_id);
                end
        
                %% Now load the coordinates into subject space
                % Set expected_focal_distance_mm
                t1_grid_step_mm = t1_header.PixelDimensions(1);
                focal_distance_t1 = norm(parameters.focus_pos_t1_grid - parameters.transducer.pos_t1_grid);
                parameters.expected_focal_distance_mm = focal_distance_t1 * t1_grid_step_mm;
        
                % To compensate for the offset between the center of the reference and the edge of the bowl
                coupler_to_transducer_distance = 11.6;
                reference_to_transducer_distance = -(parameters.transducer.curv_radius_mm - parameters.transducer.dist_to_plane_mm) - coupler_to_transducer_distance;
                
                % Load the most recent trigger mark file
                extract_dt = @(x) datetime(x.name(end-20:end-4),'InputFormat','yyyyMMddHHmmssSSS');
                localite_file_name_and_location = sprintf('/project/3025011.02/raw/sub-%03d/ses-mri%02d/localite', subject_id, session_number);
                trig_mark_files = dir(localite_file_name_and_location);
                if isempty(trig_mark_files)
                    error('Localite file `%s` cannot be found', localite_file_name_and_location)
                end
        
                % Filter out files that are not InstrumentMarker files
                trig_mark_files = trig_mark_files(contains({trig_mark_files.name}, 'GUMMarkers'));
                
                % Select and open the most recent xml file
                [~,idx] = sort([arrayfun(extract_dt,trig_mark_files)],'descend');
                trig_mark_files = trig_mark_files(idx);
                recent_trig_mark_file = xml2struct(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name));

                % Select the correct instrument markers
                % --- Find cells with a non-empty InstrumentMarker ---
                idx = find(cellfun(@(c) isstruct(c) && isfield(c,'InstrumentMarker') ...
                                        && ~isempty(c.InstrumentMarker), ...
                                   recent_trig_mark_file.GUMMarkerList.Element));
                
                % --- Extract uid for each ---
                uids = arrayfun(@(k) recent_trig_mark_file.GUMMarkerList.Element{k}.InstrumentMarker.Attributes.uid, ...
                                idx, 'UniformOutput', false);
                
                % --- Sort by uid (assumes uid is stored as a string/char) ---
                uidNum = str2double(uids);
                [~, order] = sort(uidNum);
                sortedIdx = idx(order);
                
                % --- Loop ---
                % consecutive_simulation_number runs 1, 2, 3, ...
                assert(consecutive_simulation_number <= numel(sortedIdx), ...
                       'consecutive_simulation_number (%d) exceeds number of markers (%d).', ...
                       consecutive_simulation_number, numel(sortedIdx));
                
                thisElement = recent_trig_mark_file.GUMMarkerList.Element{sortedIdx(consecutive_simulation_number)};
                thisMarker  = thisElement.InstrumentMarker;
    
                % Load the trigger markers and turn them into doubles
                trigger_markers = thisMarker.Matrix4D.Attributes;
                trigger_marker_fieldnames = fieldnames(trigger_markers);
                for i = 1:length(trigger_marker_fieldnames)
                    trigger_markers.(trigger_marker_fieldnames{i}) = str2double(trigger_markers.(trigger_marker_fieldnames{i}));
                end
    
                % Reshape the markers
                trigger_markers = struct2cell(trigger_markers);
                trigger_markers = reshape(cell2mat(trigger_markers)', 4, 4)';
    
                % -- Extract and interpret Localite coordinate system:
                %   - coord_matrix(:,4): the position (origin) in RAS mm
                %   - coord_matrix(:,1): coil local X axis, typically pointing from coil center to head
                reference_position = trigger_markers(:, 4);
                reference_vector = trigger_markers(:, 1);
        
                % -- Compute the RAS mm position of the transducer surface
                transducer_pos_ras = reference_position + reference_to_transducer_distance * reference_vector;
                % -- Compute the RAS mm position of the acoustic focal point (forward along vector)
                target_pos_ras = reference_position + parameters.expected_focal_distance_mm * reference_vector;
        
                % -- Convert these world (RAS mm) positions into MRI voxel index space
                parameters.transducer.pos_t1_grid = ras_to_grid(transducer_pos_ras(1:3, :), t1_header);
                parameters.focus_pos_t1_grid = ras_to_grid(target_pos_ras(1:3, :), t1_header);
    
            else
                %% Load coordinates from the exploratory_coordinate_list
                exploratory_coordinate_list = readtable('/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv');
                
                index_subject = exploratory_coordinate_list.subject_id == subject_id;
                index_stimulation_target_left = contains(exploratory_coordinate_list.stimulation_target, stimulation_target_coordinates);
            
                index_coordinates_left = index_subject & index_stimulation_target_left;
            
                row_coordinates_left = exploratory_coordinate_list(index_coordinates_left, :);
            
                parameters.transducer.pos_t1_grid = [row_coordinates_left.pos_t1_grid_x, row_coordinates_left.pos_t1_grid_y, row_coordinates_left.pos_t1_grid_z];
                parameters.focus_pos_t1_grid = [row_coordinates_left.focus_pos_t1_grid_x, row_coordinates_left.focus_pos_t1_grid_y, row_coordinates_left.focus_pos_t1_grid_z];

                % Flip the coordinates around
                parameters.transducer.pos_t1_grid = parameters.transducer.pos_t1_grid';
                parameters.focus_pos_t1_grid = parameters.focus_pos_t1_grid';
            end
        
            %% Preview transducer location
            % Compensate for 1-based indexing in Matlab
            parameters.transducer.pos_t1_grid = parameters.transducer.pos_t1_grid + 1;
            parameters.focus_pos_t1_grid = parameters.focus_pos_t1_grid + 1;
    
            % Makes a different slice depending on the target
            if contains(stimulation_target, 'target_2')
                slice_dim_right_figure = 1;
            else
                slice_dim_right_figure = 3;
            end
            
            figure;
            hImage = imshowpair(...
                plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), parameters.transducer.pos_t1_grid(:,1), parameters.focus_pos_t1_grid(:,1), parameters), ...
                plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), parameters.transducer.pos_t1_grid(:,1), parameters.focus_pos_t1_grid(:,1), parameters, 'slice_dim', slice_dim_right_figure), ...
                'montage');
            hAxes = get(hImage, 'Parent');
            title(hAxes, sprintf('sub-%03d %s [%g; %g; %g]', subject_id, stimulation_target, parameters.transducer.pos_t1_grid(:,1)-1)); % -1 is at the end to remove compensation of 1-based indexing in plot title
            
            %% Simulations
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
            if strcmp(stimulation_target_group, 'target_1') || strcmp(stimulation_target_group, 'target_2')
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
                % We split it between config 2 and the others because 2 has to
                % refer back to the 'first_parameters' instead of
                % 'sequential_configs.config_x'
                if consecutive_simulation_number == 2
                    if isfield(first_parameters,'subject_subfolder') && first_parameters.subject_subfolder == 1
                        first_parameters.output_dir = fullfile(first_parameters.sim_path, sprintf('sub-%03d', subject_id));
                    else 
                        first_parameters.output_dir = first_parameters.sim_path;
                    end
                else
                    if isfield(sequential_configs.(previous_config_field_name),'subject_subfolder') && sequential_configs.(previous_config_field_name).subject_subfolder == 1
                        sequential_configs.(previous_config_field_name).output_dir = fullfile(sequential_configs.(previous_config_field_name).sim_path, sprintf('sub-%03d', subject_id));
                    else 
                        sequential_configs.(previous_config_field_name).output_dir = sequential_configs.(previous_config_field_name).sim_path;
                    end
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
                single_subject_pipeline_with_slurm(subject_id, first_parameters, false, timelimit, memorylimit, 'sequential_configs', sequential_configs);
            end
        end
    end
end

% This is just here to go back to the script's directory
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));