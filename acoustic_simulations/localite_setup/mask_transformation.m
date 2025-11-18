function mask_transformation(subject_name)
    
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

    run_freesurfer = 'False';
    
    if strcmp(run_freesurfer, 'False')
        disp('Freesurfer wont be used');
    end

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
    if strcmp(run_freesurfer, 'True')
        % Start the recon-all pipeline from freesurfer
        system(sprintf('recon-all -i %s -s %s -T2 %s -T2pial -all -cw256', input_t1_name_and_location, subject_name, input_t2_name_and_location))
    
        % Segment subregions
        system(sprintf('segment_subregions hippo-amygdala --cross %s', subject_name))

        % Create MNI transform
        system(sprintf('mni152reg --s %s', subject_name))
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
    amygdala_left_location = sprintf('%s/%s_amygdala_left.nii.gz', output_location_subject_tmp, subject_name);
    amygdala_right_location = sprintf('%s/%s_amygdala_right.nii.gz', output_location_subject_tmp, subject_name);

    system(sprintf('mri_convert %s/amygdala_left.mgz %s', output_location_subject_tmp, amygdala_left_location))
    system(sprintf('mri_convert %s/amygdala_right.mgz %s', output_location_subject_tmp, amygdala_right_location))
    system(sprintf('mri_convert %s/anatomical_dacc_left.mgz %s/%s_anatomical_dacc_left.nii.gz', output_location_subject_tmp, output_location_subject_tmp, subject_name))
    system(sprintf('mri_convert %s/anatomical_dacc_right.mgz %s/%s_anatomical_dacc_right.nii.gz', output_location_subject_tmp, output_location_subject_tmp, subject_name))

    %% Now also translate the Amygdala masks (freesurfer T1 > original T1)
    system(sprintf('mri_vol2vol --mov %s --targ %s --regheader --o %s/%s_amygdala_left.nii.gz --interp nearest --no-save-reg' ,amygdala_left_location, input_t1_name_and_location, segmentation_folder, subject_name));
    system(sprintf('mri_vol2vol --mov %s --targ %s --regheader --o %s/%s_amygdala_right.nii.gz --interp nearest --no-save-reg' ,amygdala_right_location, input_t1_name_and_location, segmentation_folder, subject_name));
    
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

    % Use FSLmaths to turn the csv into a target mask for the participant
    dacc_mask = sprintf('%s/%s_dacc_mask.nii', output_location_subject, subject_name);
    system(sprintf('/home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/localite_setup/transform_MNI_csv_to_mask.sh %s %s %s', dacc_mask, input_t1_name_and_location, dacc_coordinates_subject_location));

    %% Extract anatomical center from different masks
    % Select which masks to use
    amygdala_left_name = sprintf('%s/%s_amygdala_left.nii.gz', output_location_subject_tmp, subject_name);
    amygdala_right_name = sprintf('%s/%s_amygdala_right.nii.gz', output_location_subject_tmp, subject_name);
    %dacc_left_name = sprintf('%s/%s_payam_dacc_left_mask_nonlinear.nii.gz', output_location_subject_tmp, subject_name);
    %dacc_right_name = sprintf('%s/%s_payam_dacc_right_mask_nonlinear.nii.gz', output_location_subject_tmp, subject_name);

    amygdala_left = niftiread(amygdala_left_name);
    amygdala_right = niftiread(amygdala_right_name);
    %dacc_left = niftiread(dacc_left_name);
    %dacc_right = niftiread(dacc_right_name);

    % Get the coordinates of the non-zero voxels
    [amygdala_left_x, amygdala_left_y, amygdala_left_z] = ind2sub(size(amygdala_left), find(amygdala_left));
    [amygdala_right_x, amygdala_right_y, amygdala_right_z] = ind2sub(size(amygdala_right), find(amygdala_right));
    %{
    [dacc_left_x, dacc_left_y, dacc_left_z] = ind2sub(size(dacc_left), find(dacc_left));
    [dacc_right_x, dacc_right_y, dacc_right_z] = ind2sub(size(dacc_right), find(dacc_right));

    % Split the mask into outer slices
    % Get the outermost coordinates on the z-axis
    max_z_left = max(dacc_left_z);
    min_z_left = min(dacc_left_z);
    max_z_right = max(dacc_right_z);
    min_z_right = min(dacc_right_z);
    
    % Split coordinates by highest and lowest z (including adjacent)
    % Highest z coordinates (left) - includes max_z and max_z-1
    dacc_left_high_idx = (dacc_left_z == max_z_left) | (dacc_left_z == max_z_left - 1) | (dacc_left_z == max_z_left - 2);
    dacc_left_high_x = dacc_left_x(dacc_left_high_idx);
    dacc_left_high_y = dacc_left_y(dacc_left_high_idx);
    dacc_left_high_z = dacc_left_z(dacc_left_high_idx);

    % Highest z coordinates (right) - includes max_z and max_z-1
    dacc_right_high_idx = (dacc_right_z == max_z_right) | (dacc_right_z == max_z_right - 1) | (dacc_right_z == max_z_right - 2);
    dacc_right_high_x = dacc_right_x(dacc_right_high_idx);
    dacc_right_high_y = dacc_right_y(dacc_right_high_idx);
    dacc_right_high_z = dacc_right_z(dacc_right_high_idx);
    
    % Lowest z coordinates (left) - includes min_z and min_z+1
    dacc_left_low_idx = (dacc_left_z == min_z_left) | (dacc_left_z == min_z_left + 1) | (dacc_left_z == min_z_left + 2);
    dacc_left_low_x = dacc_left_x(dacc_left_low_idx);
    dacc_left_low_y = dacc_left_y(dacc_left_low_idx);
    dacc_left_low_z = dacc_left_z(dacc_left_low_idx);
    
    % Lowest z coordinates (right) - includes min_z and min_z+1
    dacc_right_low_idx = (dacc_right_z == min_z_right) | (dacc_right_z == min_z_right + 1) | (dacc_right_z == min_z_right + 2);
    dacc_right_low_x = dacc_right_x(dacc_right_low_idx);
    dacc_right_low_y = dacc_right_y(dacc_right_low_idx);
    dacc_right_low_z = dacc_right_z(dacc_right_low_idx);
    
    % Calculate the centers
    % The offset is there to account for the fact that the dACC is not aligned perfectly along the z-axis
    dacc_y_offset = 4; 
    %}

    translation_offset = 0;

    % The '+1' is there to account for the discrepancy in indexing between matlab and freesurfer
    amygdala_left_center = round([mean(amygdala_left_x), mean(amygdala_left_y), mean(amygdala_left_z)]) + translation_offset;
    amygdala_right_center = round([mean(amygdala_right_x), mean(amygdala_right_y), mean(amygdala_right_z)]) + translation_offset;
    %dacc_left_anterior = round([mean(dacc_left_high_x), mean(dacc_left_high_y), max(dacc_left_high_z)]) + translation_offset;
    %dacc_right_anterior = round([mean(dacc_right_high_x), mean(dacc_right_high_y), max(dacc_right_high_z)]) + translation_offset;
    %dacc_left_center = round([mean(dacc_left_x), mean(dacc_left_y), mean(dacc_left_z)]) + translation_offset;
    %dacc_right_center = round([mean(dacc_right_x), mean(dacc_right_y), mean(dacc_right_z)]) + translation_offset;
    %dacc_left_posterior = round([mean(dacc_left_low_x), mean(dacc_left_low_y), min(dacc_left_low_z)]) + translation_offset;
    %dacc_right_posterior = round([mean(dacc_right_low_x), mean(dacc_right_low_y), min(dacc_right_low_z)]) + translation_offset;
    sham_left_center = round(mean([amygdala_left_center; dacc_left_center], 1));
    sham_right_center = round(mean([amygdala_right_center; dacc_right_center], 1));

    %% Create new masks based on centers
    amygdala_mask = sprintf('%s/%s_amygdala_mask', output_location_subject, subject_name);
    %dacc_mask = sprintf('%s/%s_dacc_mask', output_location_subject, subject_name);
    sham_mask = sprintf('%s/%s_sham_mask', output_location_subject, subject_name);

    % Get nii info from the original mask
    mask_size = size(amygdala_left);
    mask_info = niftiinfo(amygdala_left_name);
    % Make an empty mask based on the amygdala mask size
    empty_matrix = zeros(mask_size(1), mask_size(2), mask_size(3), 'int32');

    % Make amygdala mask (centroids)
    amygdala_mask_matrix = empty_matrix;
    amygdala_mask_matrix(amygdala_left_center(1), amygdala_left_center(2), amygdala_left_center(3)) = 1;
    amygdala_mask_matrix(amygdala_right_center(1), amygdala_right_center(2), amygdala_right_center(3)) = 1;
    niftiwrite(amygdala_mask_matrix, amygdala_mask, mask_info);

    % Get nii info from the original mask
    mask_size = size(amygdala_left);
    mask_info = niftiinfo(amygdala_left_name);
    % Make an empty mask based on the amygdala mask size
    empty_matrix = zeros(mask_size(1), mask_size(2), mask_size(3), 'int32');

    % Make dACC masks
    %{
    dacc_mask_matrix = empty_matrix;
    dacc_mask_matrix(dacc_left_anterior(1), dacc_left_anterior(2), dacc_left_anterior(3)) = 1;%pca_results_left.front_centroid(1), pca_results_left.front_centroid(2), pca_results_left.front_centroid(3)) = 1;%
    dacc_mask_matrix(dacc_right_anterior(1), dacc_right_anterior(2), dacc_right_anterior(3)) = 1;%pca_results_right.front_centroid(1), pca_results_right.front_centroid(2), pca_results_right.front_centroid(3)) = 1;%
    dacc_mask_matrix(dacc_left_center(1), dacc_left_center(2), dacc_left_center(3)) = 1;%pca_results_left.centroid(1), pca_results_left.centroid(2), pca_results_left.centroid(3)) = 1;%
    dacc_mask_matrix(dacc_right_center(1), dacc_right_center(2), dacc_right_center(3)) = 1;%pca_results_right.centroid(1), pca_results_right.centroid(2), pca_results_right.centroid(3)) = 1;%
    dacc_mask_matrix(dacc_left_posterior(1), dacc_left_posterior(2), dacc_left_posterior(3)) = 1;%pca_results_left.back_centroid(1), pca_results_left.back_centroid(2), pca_results_left.back_centroid(3)) = 1;%
    dacc_mask_matrix(dacc_right_posterior(1), dacc_right_posterior(2), dacc_right_posterior(3)) = 1;%pca_results_right.back_centroid(1), pca_results_left.back_centroid(2), pca_results_left.back_centroid(3)) = 1;%
    niftiwrite(dacc_mask_matrix, dacc_mask, mask_info);
    %}

    % Make sham mask
    sham_mask_matrix = empty_matrix;
    sham_mask_matrix(sham_left_center(1), sham_left_center(2), sham_left_center(3)) = 1;
    sham_mask_matrix(sham_right_center(1), sham_right_center(2), sham_right_center(3)) = 1;
    niftiwrite(sham_mask_matrix, sham_mask, mask_info);

    %% Now find the same coordinates for the masks that will be used for simulations
    % Extract center from different masks
    amygdala_left = niftiread(sprintf('%s/%s_amygdala_left.nii.gz', segmentation_folder, subject_name));
    amygdala_right = niftiread(sprintf('%s/%s_amygdala_right.nii.gz', segmentation_folder, subject_name));
    dacc_left = niftiread(sprintf('%s/%s_payam_dacc_left_mask_nonlinear.nii.gz', segmentation_folder, subject_name));
    dacc_right = niftiread(sprintf('%s/%s_payam_dacc_right_mask_nonlinear.nii.gz', segmentation_folder, subject_name));

    % Get the coordinates of the non-zero voxels
    [amygdala_left_x, amygdala_left_y, amygdala_left_z] = ind2sub(size(amygdala_left), find(amygdala_left));
    [amygdala_right_x, amygdala_right_y, amygdala_right_z] = ind2sub(size(amygdala_right), find(amygdala_right));
    [dacc_left_x, dacc_left_y, dacc_left_z] = ind2sub(size(dacc_left), find(dacc_left));
    [dacc_right_x, dacc_right_y, dacc_right_z] = ind2sub(size(dacc_right), find(dacc_right));

    % Split the mask into outer slices
    % Get the outermost coordinates on the z-axis
    max_z_left = max(dacc_left_z);
    min_z_left = min(dacc_left_z);
    max_z_right = max(dacc_right_z);
    min_z_right = min(dacc_right_z);
    
    % Split coordinates by highest and lowest z (including adjacent)
    % Highest z coordinates (left) - includes max_z and max_z-1
    dacc_left_high_idx = (dacc_left_z == max_z_left) | (dacc_left_z == max_z_left - 1) | (dacc_left_z == max_z_left - 2);
    dacc_left_high_x = dacc_left_x(dacc_left_high_idx);
    dacc_left_high_y = dacc_left_y(dacc_left_high_idx);
    dacc_left_high_z = dacc_left_z(dacc_left_high_idx);

    % Highest z coordinates (right) - includes max_z and max_z-1
    dacc_right_high_idx = (dacc_right_z == max_z_right) | (dacc_right_z == max_z_right - 1) | (dacc_right_z == max_z_right - 2);
    dacc_right_high_x = dacc_right_x(dacc_right_high_idx);
    dacc_right_high_y = dacc_right_y(dacc_right_high_idx);
    dacc_right_high_z = dacc_right_z(dacc_right_high_idx);
    
    % Lowest z coordinates (left) - includes min_z and min_z+1
    dacc_left_low_idx = (dacc_left_z == min_z_left) | (dacc_left_z == min_z_left + 1) | (dacc_left_z == min_z_left + 2);
    dacc_left_low_x = dacc_left_x(dacc_left_low_idx);
    dacc_left_low_y = dacc_left_y(dacc_left_low_idx);
    dacc_left_low_z = dacc_left_z(dacc_left_low_idx);
    
    % Lowest z coordinates (right) - includes min_z and min_z+1
    dacc_right_low_idx = (dacc_right_z == min_z_right) | (dacc_right_z == min_z_right + 1) | (dacc_right_z == min_z_right + 2);
    dacc_right_low_x = dacc_right_x(dacc_right_low_idx);
    dacc_right_low_y = dacc_right_y(dacc_right_low_idx);
    dacc_right_low_z = dacc_right_z(dacc_right_low_idx);
    
    % Calculate the centers
    % The offset is there to account for the fact that the dACC is not aligned perfectly along the z-axis
    dacc_y_offset = 4; 

    % The '+1' is there to account for the discrepancy in indexing between matlab and freesurfer
    amygdala_left_center = round([mean(amygdala_left_x), mean(amygdala_left_y), mean(amygdala_left_z)]) + translation_offset;
    amygdala_right_center = round([mean(amygdala_right_x), mean(amygdala_right_y), mean(amygdala_right_z)]) + translation_offset;
    dacc_left_anterior = round([mean(dacc_left_high_x), mean(dacc_left_high_y), max(dacc_left_high_z)]) + translation_offset;
    dacc_right_anterior = round([mean(dacc_right_high_x), mean(dacc_right_high_y), max(dacc_right_high_z)]) + translation_offset;
    dacc_left_center = round([mean(dacc_left_x), mean(dacc_left_y), mean(dacc_left_z)]) + translation_offset;
    dacc_right_center = round([mean(dacc_right_x), mean(dacc_right_y), mean(dacc_right_z)]) + translation_offset;
    dacc_left_posterior = round([mean(dacc_left_low_x), mean(dacc_left_low_y), min(dacc_left_low_z)]) + translation_offset;
    dacc_right_posterior = round([mean(dacc_right_low_x), mean(dacc_right_low_y), min(dacc_right_low_z)]) + translation_offset;
    sham_left_center = round(mean([amygdala_left_center; dacc_left_center], 1));
    sham_right_center = round(mean([amygdala_right_center; dacc_right_center], 1));

    %% Save these coordinates into the planning coordinates csv
    % Load coordinates into matrix
    focus_coords = [
        amygdala_left_center;
        amygdala_right_center;
        amygdala_left_center;
        amygdala_right_center;
        amygdala_left_center;
        amygdala_right_center;
        dacc_left_anterior;
        dacc_right_anterior;
        dacc_left_center;
        dacc_right_center;
        dacc_left_posterior;
        dacc_right_posterior;
        sham_left_center;
        sham_right_center;
        sham_left_center;
        sham_right_center;
        sham_left_center;
        sham_right_center;
    ];

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
    %writetable(planning_coordinate_list, planning_coordinate_location, 'Delimiter', ';');
    
    fprintf('Successfully saved coordinates to %s\n', planning_coordinate_location);

    %% Delete tmp folder
    %system(sprintf('rm -rf %s', fullfile(output_location_subject, ..)));

end
