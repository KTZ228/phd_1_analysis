function mask_transformation(subject_name)

    %% Run the segmentation pipelines?
    run_segmentation_pipelines = 'False';
    
    %% Remove SimNIBS path
    % To mitigate any conflicts with repelem.m
    cd /home/affneu/kenvdzee/.conda/envs/
    rmpath(genpath('simnibs_env'));

    %% Add participant rows to coordinate and intensity csv's
    

    %% Run SimNIBS segmentation
    % Add PRESTUS to the path
    cd /home/affneu/kenvdzee/Documents/PRESTUS/
    addpath('functions')
    addpath(genpath('toolboxes'))
    addpath('/home/common/matlab/fieldtrip/qsub')

    subject_id = str2double(regexp(subject_name, '\d+', 'match'));
    parameters = load_parameters('config_kenneth_phd_1_simnibs_segmentation.yaml', '/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/configs/');
    if strcmp(run_segmentation_pipelines, 'True')
        %single_subject_pipeline(subject_id, parameters);
        %pause(180);
    end

    %% Remove SimNIBS path again
    % To mitigate any conflicts with repelem.m
    cd /home/affneu/kenvdzee/.conda/envs/
    rmpath(genpath('simnibs_env'));

    %% Set folder names for segmentation
    % Set input names
    input_location = sprintf('/project/3025011.02/bids/%s/ses-mri01/anat', subject_name);
    input_t1_name_and_location = fullfile(input_location, (sprintf('%s*mprage_T1w.nii.gz', subject_name)));
    input_t1_name_and_location = fullfile(input_location, dir(input_t1_name_and_location).name);
    input_t2_name_and_location = fullfile(input_location, (sprintf('%s*sagisop2ellscan_T2w.nii.gz', subject_name)));
    input_t2_name_and_location = fullfile(input_location, dir(input_t2_name_and_location).name);
    masks_folder = '/project/3025011.02/localite/masks/';
    segmentation_folder = sprintf('/project/3025011.02/TUS_simulations/segmentation_data/m2m_%s', subject_name);

    addpath('/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/localite_setup');

    if ~isfile(input_t1_name_and_location)
        error('File "%s" does not exist', input_t1_name_and_location)
    elseif ~isfile(input_t2_name_and_location)
        error('File "%s" does not exist', input_t2_name_and_location)
    end
    
    % Set output names
    output_location = '/project/3025011.02/localite';
    output_location_subject = fullfile(output_location, subject_name);
    output_location_subject_tmp = sprintf('%s/tmp', output_location_subject);

    % Load correct version of freesurfer
    system('source /opt/freesurfer/7.3.2/SetUpFreeSurfer.sh')
    system('module load freesurfer')

    % Make output folders if they don't exist yet
    if ~isfolder(output_location_subject_tmp)
        mkdir(output_location_subject_tmp)
    end

    % Send output location to freesurfer
    setenv('SUBJECTS_DIR', output_location_subject_tmp)

    %% Run Freesurfer
    if strcmp(run_segmentation_pipelines, 'True')
        % Start the recon-all pipeline from freesurfer
        system(sprintf('recon-all -i %s -s %s -T2 %s -T2pial -all -cw256', input_t1_name_and_location, subject_name, input_t2_name_and_location))
    
        % Segment subregions
        system(sprintf('segment_subregions hippo-amygdala --cross %s', subject_name))

        % Create MNI transform
        system(sprintf('mni152reg --s %s', subject_name))
    else
        disp('Freesurfer wont be used');
    end

    % First, make sure you can reach the freesurfer subfolders
    output_location_subject_tmp = sprintf('%s/%s', output_location_subject_tmp, subject_name);

    %% Extract binary masks and convert them to nifti's
    % Then extract binary masks for the Amygdala
    system(sprintf('mri_binarize --i %s/mri/lh.hippoAmygLabels.CA.FSvoxelSpace.mgz --match 7001 7003 --o %s/amygdala_left.mgz', output_location_subject_tmp, output_location_subject_tmp))
    system(sprintf('mri_binarize --i %s/mri/rh.hippoAmygLabels.CA.FSvoxelSpace.mgz --match 7001 7003 --o %s/amygdala_right.mgz', output_location_subject_tmp, output_location_subject_tmp))

    % And for Freesurfer's dACC (so not Payam's, I use this as a comparison)
    system(sprintf('mri_binarize --i %s/mri/aparc+aseg.mgz --match 1002 --o %s/anatomical_dacc_left.mgz', output_location_subject_tmp, output_location_subject_tmp))
    system(sprintf('mri_binarize --i %s/mri/aparc+aseg.mgz --match 2002 --o %s/anatomical_dacc_right.mgz', output_location_subject_tmp, output_location_subject_tmp))
    
    % Convert the freesurfer masks to nifti's
    amygdala_freesurfer_left_location = sprintf('%s/%s_amygdala_left.nii.gz', output_location_subject_tmp, subject_name);
    amygdala_freesurfer_right_location = sprintf('%s/%s_amygdala_right.nii.gz', output_location_subject_tmp, subject_name);
    amygdala_scanner_left_location = sprintf('%s/%s_amygdala_left.nii.gz', segmentation_folder, subject_name);
    amygdala_scanner_right_location = sprintf('%s/%s_amygdala_right.nii.gz', segmentation_folder, subject_name);

    system(sprintf('mri_convert %s/amygdala_left.mgz %s', output_location_subject_tmp, amygdala_freesurfer_left_location))
    system(sprintf('mri_convert %s/amygdala_right.mgz %s', output_location_subject_tmp, amygdala_freesurfer_right_location))
    system(sprintf('mri_convert %s/anatomical_dacc_left.mgz %s/%s_anatomical_dacc_left.nii.gz', output_location_subject_tmp, output_location_subject_tmp, subject_name))
    system(sprintf('mri_convert %s/anatomical_dacc_right.mgz %s/%s_anatomical_dacc_right.nii.gz', output_location_subject_tmp, output_location_subject_tmp, subject_name))

    %% Now also translate the Amygdala masks (freesurfer T1 > original T1)
    system(sprintf('mri_vol2vol --mov %s --targ %s --regheader --o %s --interp nearest --no-save-reg' ,amygdala_freesurfer_left_location, input_t1_name_and_location, amygdala_scanner_left_location));
    system(sprintf('mri_vol2vol --mov %s --targ %s --regheader --o %s --interp nearest --no-save-reg' ,amygdala_freesurfer_right_location, input_t1_name_and_location, amygdala_scanner_right_location));
    
    %% Translate Payam's dACC mask for simulations (MNI > original T1)
    dacc_left = ('payam_dacc_left_mask.nii.gz');
    dacc_left_location = fullfile(masks_folder, dacc_left);
    dacc_right = ('payam_dacc_right_mask.nii.gz');
    dacc_right_location = fullfile(masks_folder, dacc_right);
    dacc_coordinates_MNI = ('payam_dacc_coordinates.csv');
    dacc_coordinates_MNI_location = fullfile(masks_folder, dacc_coordinates_MNI);
    dacc_coordinates_subject = sprintf('%s_payam_dacc_coordinates.csv', subject_name);
    dacc_coordinates_subject_location = fullfile(output_location_subject_tmp, dacc_coordinates_subject);

    % Navigate to subject folder and create masks
    cd (output_location_subject_tmp)

    % Use SimNIBS' pipeline for nonlinear transformation and place the
    % output in subject space (place them in both the localite and
    % segmentation folder)
    system(sprintf('module -s load anaconda3 && unset LD_LIBRARY_PATH && source activate simnibs_env && mni2subject -i %s -m %s -o %s/%s_payam_dacc_left_mask.nii.gz --interp 0', dacc_left_location, segmentation_folder, segmentation_folder, subject_name));
    system(sprintf('module -s load anaconda3 && unset LD_LIBRARY_PATH && source activate simnibs_env && mni2subject -i %s -m %s -o %s/%s_payam_dacc_right_mask.nii.gz --interp 0', dacc_right_location, segmentation_folder, segmentation_folder, subject_name));
    system(sprintf('module -s load anaconda3 && unset LD_LIBRARY_PATH && source activate simnibs_env && mni2subject -i %s -m %s -o %s/%s_payam_dacc_left_mask.nii.gz --interp 0', dacc_left_location, segmentation_folder, output_location_subject_tmp, subject_name));
    system(sprintf('module -s load anaconda3 && unset LD_LIBRARY_PATH && source activate simnibs_env && mni2subject -i %s -m %s -o %s/%s_payam_dacc_right_mask.nii.gz --interp 0', dacc_right_location, segmentation_folder, output_location_subject_tmp, subject_name));
    % Translate MNI coordinates
    system(sprintf('module -s load anaconda3 && unset LD_LIBRARY_PATH && source activate simnibs_env && mni2subject_coords -m %s -s %s -o %s', segmentation_folder, dacc_coordinates_MNI_location, dacc_coordinates_subject_location));

    %% Extract anatomical center from Amygdala masks
    % Create centroid mask for the amygdala
    amygdala_mask = sprintf('%s/%s_amygdala_mask.nii', output_location_subject, subject_name);
    [~, cmdout] = system(sprintf('/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/localite_setup/create_centroids_amygdala.sh %s %s %s', amygdala_scanner_left_location, amygdala_scanner_right_location, amygdala_mask));
    
    % Extract centroid coordinates
    left_amygdala_coordinates = regexp(cmdout, 'CENTROID1:\s+(\d+)\s+(\d+)\s+(\d+)', 'tokens');
    right_amygdala_coordinates = regexp(cmdout, 'CENTROID2:\s+(\d+)\s+(\d+)\s+(\d+)', 'tokens');
    
    % Convert to doubles and store in matrix (rows = amygdalae, columns = x,y,z)
    amygdala_coordinates = [str2double(left_amygdala_coordinates{1}); 
                            str2double(right_amygdala_coordinates{1})];

    %% Translate the personalised dACC coordinates to a binary mask
    % Create centroid mask for the dACC
    dacc_mask = sprintf('%s/%s_dacc_mask.nii', output_location_subject, subject_name);
    [~, cmdout] = system(sprintf('/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/localite_setup/create_centroids_dacc.sh %s %s %s', dacc_coordinates_subject_location, input_t1_name_and_location, dacc_mask));

    % Extract centroid coordinates
    % Parse all target coordinates
    % The output will be in format: TARGET_1: x y z
    target_pattern = 'TARGET_(\d+):\s+(\d+)\s+(\d+)\s+(\d+)';
    matches = regexp(cmdout, target_pattern, 'tokens');
    
    % Extract coordinates for each target
    num_targets = length(matches);
    dacc_coordinates = zeros(num_targets, 3);  % Preallocate as double matrix
    
    for i = 1:num_targets
        dacc_coordinates(i, 1) = str2double(matches{i}{2});  % x
        dacc_coordinates(i, 2) = str2double(matches{i}{3});  % y
        dacc_coordinates(i, 3) = str2double(matches{i}{4});  % z
    end

    %% Calculate the middle between the amygdala and dacc for sham
    % Separate coordinates
    x1 = amygdala_coordinates(1,1);
    y1 = amygdala_coordinates(1,2);
    z1 = amygdala_coordinates(1,3);
    x2 = dacc_coordinates(3,1);
    y2 = dacc_coordinates(3,2);
    z2 = dacc_coordinates(3,3);
    x3 = amygdala_coordinates(2,1);
    y3 = amygdala_coordinates(2,2);
    z3 = amygdala_coordinates(2,3);
    x4 = dacc_coordinates(4,1);
    y4 = dacc_coordinates(4,2);
    z4 = dacc_coordinates(4,3);

    % Create centroid mask for the sham condition
    sham_mask = sprintf('%s/%s_sham_mask.nii', output_location_subject, subject_name);
    [~, cmdout] = system(sprintf('/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/localite_setup/create_centroids_sham.sh %d %d %d %d %d %d %d %d %d %d %d %d %s %s', x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, input_t1_name_and_location, sham_mask));
    
    % Extract centroid coordinates
    left_sham_coordinates = regexp(cmdout, 'CENTROID1:\s+(\d+)\s+(\d+)\s+(\d+)', 'tokens');
    right_sham_coordinates = regexp(cmdout, 'CENTROID2:\s+(\d+)\s+(\d+)\s+(\d+)', 'tokens');
    sham_coordinates = [str2double(left_sham_coordinates{1}); 
                            str2double(right_sham_coordinates{1})];

    %% Save these coordinates into the planning coordinates csv
    % Load coordinates into matrix
    focus_coords = [
        amygdala_coordinates(1,1), amygdala_coordinates(1,2), amygdala_coordinates(1,3);
        amygdala_coordinates(2,1), amygdala_coordinates(2,2), amygdala_coordinates(2,3);
        amygdala_coordinates(1,1), amygdala_coordinates(1,2), amygdala_coordinates(1,3);
        amygdala_coordinates(2,1), amygdala_coordinates(2,2), amygdala_coordinates(2,3);
        amygdala_coordinates(1,1), amygdala_coordinates(1,2), amygdala_coordinates(1,3);
        amygdala_coordinates(2,1), amygdala_coordinates(2,2), amygdala_coordinates(2,3);
        dacc_coordinates(1,1), dacc_coordinates(1,2), dacc_coordinates(1,3);
        dacc_coordinates(2,1), dacc_coordinates(2,2), dacc_coordinates(2,3);
        dacc_coordinates(3,1), dacc_coordinates(3,2), dacc_coordinates(3,3);
        dacc_coordinates(4,1), dacc_coordinates(4,2), dacc_coordinates(4,3);
        dacc_coordinates(5,1), dacc_coordinates(5,2), dacc_coordinates(5,3);
        dacc_coordinates(6,1), dacc_coordinates(6,2), dacc_coordinates(6,3);
        sham_coordinates(1,1), sham_coordinates(1,2), sham_coordinates(1,3);
        sham_coordinates(2,1), sham_coordinates(2,2), sham_coordinates(2,3);
        sham_coordinates(1,1), sham_coordinates(1,2), sham_coordinates(1,3);
        sham_coordinates(2,1), sham_coordinates(2,2), sham_coordinates(2,3);
        sham_coordinates(1,1), sham_coordinates(1,2), sham_coordinates(1,3);
        sham_coordinates(2,1), sham_coordinates(2,2), sham_coordinates(2,3);
    ];

    fprintf('\nNew coordinates for %s are saved as:\n', subject_name);
    disp(focus_coords)

    % Convert subject_name to subject_id (numeric)
    subject_id = str2double(regexp(subject_name, '\d+', 'match', 'once'));
    
    % Define target names
    target_names = cell(18, 1);
    idx = 1;
    for group = 1:3
        for target = 1:6
            target_names{idx} = sprintf('target_%d_%d', group, target);
            idx = idx + 1;
        end
    end

    % Read the csv
    planning_coordinate_location = '/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv';
    planning_coordinate_list = readtable(planning_coordinate_location, 'Delimiter', ';');
    
    % Check if subject already exists
    subject_exists = any(planning_coordinate_list.subject_id == subject_id);
    
    if subject_exists
        % Replace existing coordinates
        fprintf('Subject %d already exists. Updating coordinates...\n', subject_id);
        subject_rows = planning_coordinate_list.subject_id == subject_id;
        
        % Update focus coordinates only (keep pos_t1_grid coordinates as they are)
        row_indices = find(subject_rows);
        for i = 1:length(row_indices)
            row_idx = row_indices(i);
            planning_coordinate_list.focus_pos_t1_grid_x(row_idx) = focus_coords(i, 1);
            planning_coordinate_list.focus_pos_t1_grid_y(row_idx) = focus_coords(i, 2);
            planning_coordinate_list.focus_pos_t1_grid_z(row_idx) = focus_coords(i, 3);
        end
        
    else
        % Add new subject
        fprintf('Adding new subject %d...\n', subject_id);
        
        % Create new rows and set pos coordinates to 0
        new_rows = table();
        new_rows.subject_id = repmat(subject_id, 18, 1);
        new_rows.stimulation_target = target_names;
        new_rows.pos_t1_grid_x = zeros(18, 1);
        new_rows.pos_t1_grid_y = zeros(18, 1);
        new_rows.pos_t1_grid_z = zeros(18, 1);
        new_rows.focus_pos_t1_grid_x = focus_coords(:, 1);
        new_rows.focus_pos_t1_grid_y = focus_coords(:, 2);
        new_rows.focus_pos_t1_grid_z = focus_coords(:, 3);
        
        % Append new rows to data
        planning_coordinate_list = [planning_coordinate_list; new_rows];
        
        % Sort by subject_id for organization
        planning_coordinate_list = sortrows(planning_coordinate_list, 'subject_id');
    end
    
    % Write back to CSV
    writetable(planning_coordinate_list, planning_coordinate_location, 'Delimiter', ';');
    
    fprintf('Successfully saved coordinates to %s\n', planning_coordinate_location);

    %% Delete tmp folder
    %system(sprintf('rm -rf %s', fullfile(output_location_subject, ..)));

end
