function mask_transformation(subject_name)
    arguments
        subject_name string
    end
    
    %% Set folder names for segmentation
    % Set input names
    input_location = sprintf('/project/3025011.02/bids/%s/ses-mri01/anat', subject_name);
    input_t1_name_and_location = fullfile(input_location, (sprintf('%s*mprage_T1w.nii.gz', subject_name)));
    input_t1_name_and_location = fullfile(input_location, dir(input_t1_name_and_location).name);
    input_t2_name_and_location = fullfile(input_location, (sprintf('%s*sagisop2ellscan_T2w.nii.gz', subject_name)));
    input_t2_name_and_location = fullfile(input_location, dir(input_t2_name_and_location).name);
    masks_folder = '/project/3025011.02/localite/masks/';
    segmentation_folder = sprintf('/project/3025011.02/TUS_simulations/segmentation_data/m2m_%s', subject_name);

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
    % Start the recon-all pipeline from freesurfer
    %system(sprintf('recon-all -i %s -s %s -T2 %s -T2pial -all -cw256', input_t1_name_and_location, subject_name, input_t2_name_and_location))

    % Segment subregions
    system(sprintf('segment_subregions hippo-amygdala --cross %s', subject_name))

    % Extract the amygdala's
    % First, make sure it can reach the subject subfolders
    output_location_subject_tmp = sprintf('%s/%s', output_location_subject_tmp, subject_name);
    % Then extract binary masks for the Amygdala
    system(sprintf('mri_binarize --i %s/mri/lh.hippoAmygLabels.CA.FSvoxelSpace.mgz --match 7001 7003 --o %s/amygdala_left.mgz', output_location_subject_tmp, output_location_subject_tmp))
    system(sprintf('mri_binarize --i %s/mri/rh.hippoAmygLabels.CA.FSvoxelSpace.mgz --match 7001 7003 --o %s/amygdala_right.mgz', output_location_subject_tmp, output_location_subject_tmp))

    % And for Freesurfer's dACC
    system(sprintf('mri_binarize --i %s/mri/aparc+aseg.mgz --match 1002 --o %s/dacc_left.mgz', output_location_subject_tmp, output_location_subject_tmp))
    system(sprintf('mri_binarize --i %s/mri/aparc+aseg.mgz --match 2002 --o %s/dacc_right.mgz', output_location_subject_tmp, output_location_subject_tmp))
    
    % Convert the freesurfer masks to nifti's
    left_amygdala_location = sprintf('%s/%s_amygdala_left.nii.gz', output_location_subject_tmp, subject_name);
    right_amygdala_location = sprintf('%s/%s_amygdala_right.nii.gz', output_location_subject_tmp, subject_name);
    system(sprintf('mri_convert %s/amygdala_left.mgz %s', output_location_subject_tmp, left_amygdala_location))
    system(sprintf('mri_convert %s/amygdala_right.mgz %s', output_location_subject_tmp, right_amygdala_location))
    system(sprintf('mri_convert %s/dacc_left.mgz %s/%s_dacc_left.nii.gz', output_location_subject_tmp, output_location_subject_tmp, subject_name))
    system(sprintf('mri_convert %s/dacc_right.mgz %s/%s_dacc_right.nii.gz', output_location_subject_tmp, output_location_subject_tmp, subject_name))
    
    %% Translate Payam's dACC mask for simulations
    left_dacc = ('payam_left_dacc_mask.nii.gz');
    left_dacc_location = fullfile(masks_folder, left_dacc);
    right_dacc = ('payam_right_dacc_mask.nii.gz');
    right_dacc_location = fullfile(masks_folder, right_dacc);

    % Navigate to subject folder and create masks
    cd (output_location_subject_tmp)

    input_t1_skullstriped = sprintf('%s_T1w_bet.nii.gz', subject_name);
    transformation_matrix_linear = 'subj2MNI_lin_aff.mat';
    transformation_matrix_linear_inverted = 'MNI2subj_lin_aff.mat';
    transformation_matrix_nonlinear = 'subj2MNI_nonlin_aff';
    transformation_matrix_nonlinear_inverted = 'MNI2subj_nonlin_aff';

    % Strip skull from the original subject T1
    system(sprintf('/opt/fsl/6.0.7/bin/bet %s %s -R -f 0.5', input_t1_name_and_location, input_t1_skullstriped));

    % Create a linear affine transformation matrix (T1 > MNI)
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s -dof 12', input_t1_skullstriped, transformation_matrix_linear));

    % Invert the affine transformation matrixes from (T1 > MNI) to (MNI > T1)
    system(sprintf('/opt/fsl/6.0.7/bin/convert_xfm -omat %s -inverse %s', transformation_matrix_linear_inverted, transformation_matrix_linear));

    % Apply the inverted affine transformation matrix to Payam's dACC masks
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -applyxfm -init %s -out %s/%s_payam_left_dacc_mask_linear.nii.gz -interp nearestneighbour', left_dacc_location, input_t1_skullstriped, transformation_matrix_linear_inverted, segmentation_folder, subject_name))
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -applyxfm -init %s -out %s/%s_payam_right_dacc_mask_linear.nii.gz -interp nearestneighbour', right_dacc_location, input_t1_skullstriped, transformation_matrix_linear_inverted, segmentation_folder, subject_name))
    
    %% Convert freesurfers T1 to nii and move to localite folder, and repeat conversion steps again
    freesurfer_mri_location = sprintf('/project/3025011.02/localite/%s/tmp/%s/mri/', subject_name, subject_name);
    freesurfer_mri_t1_name_and_location = fullfile(freesurfer_mri_location, 'T1.mgz');
    freesurfer_mri_t2_name_and_location = fullfile(freesurfer_mri_location, 'T2.mgz');

    input_location = sprintf('/project/3025011.02/localite/%s', subject_name);
    freesurfer_t1_name_and_location = fullfile(input_location, sprintf('%s_T1w.nii', subject_name));
    freesurfer_t2_name_and_location = fullfile(input_location, sprintf('%s_T2w.nii', subject_name));

    system(sprintf('mri_convert %s %s', freesurfer_mri_t1_name_and_location, freesurfer_t1_name_and_location))
    system(sprintf('mri_convert %s %s', freesurfer_mri_t2_name_and_location, freesurfer_t2_name_and_location))

    %% Now also translate the Amygdala masks
    % Strip skull from the original subject T1
    system(sprintf('/opt/fsl/6.0.7/bin/bet %s %s -R -f 0.5', freesurfer_t1_name_and_location, input_t1_skullstriped));

    % Create a linear affine transformation matrix (T1 > MNI)
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -omat %s -dof 12', input_t1_skullstriped, input_t1_name_and_location, transformation_matrix_linear));

    % Invert the affine transformation matrixes from (T1 > MNI) to (MNI > T1)
    system(sprintf('/opt/fsl/6.0.7/bin/convert_xfm -omat %s -inverse %s', transformation_matrix_linear_inverted, transformation_matrix_linear));

    % Apply the inverted affine transformation matrix to Freesurfer's Amygdala masks
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -applyxfm -init %s -out %s/%s_left_amygdala.nii.gz -interp nearestneighbour', left_amygdala_location, input_t1_skullstriped, transformation_matrix_linear_inverted, segmentation_folder, subject_name))
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -applyxfm -init %s -out %s/%s_right_amygdala.nii.gz -interp nearestneighbour', right_amygdala_location, input_t1_skullstriped, transformation_matrix_linear_inverted, segmentation_folder, subject_name))

    %% Use freesurfer's anatomical files from now on
    input_t1_name_and_location = freesurfer_t1_name_and_location;
    input_t2_name_and_location = freesurfer_t2_name_and_location;

    %% Strip skull from freesurfer's subject T1
    system(sprintf('/opt/fsl/6.0.7/bin/bet %s %s -R -f 0.5', input_t1_name_and_location, input_t1_skullstriped));

    %% Create a linear affine transformation matrix as a starting point for the non-linear transformation (T1 > MNI)
    % Only fnirt needs a skullstriped brain, flirt does not
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s -dof 12', input_t1_skullstriped, transformation_matrix_linear));

    %% Create a non-linear affine transformation matrix with the linear transformation matrix as a starting point (T1 > MNI)
    system(sprintf('/opt/fsl/6.0.7/bin/fnirt --ref=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz --in=%s --aff=%s --cout=%s --config=T1_2_MNI152_2mm', input_t1_name_and_location, transformation_matrix_linear, transformation_matrix_nonlinear));

    %% Invert the affine transformation matrixes from (T1 > MNI) to (MNI > T1)
    system(sprintf('/opt/fsl/6.0.7/bin/convert_xfm -omat %s -inverse %s', transformation_matrix_linear_inverted, transformation_matrix_linear));
    system(sprintf('/opt/fsl/6.0.7/bin/invwarp --ref=%s --warp=%s.nii.gz --out=%s', input_t1_name_and_location, transformation_matrix_nonlinear, transformation_matrix_nonlinear_inverted));

    %% Apply the inverted affine transformation matrix to Payam's dACC masks
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -applyxfm -init %s -out %s/%s_payam_left_dacc_mask_linear.nii.gz -interp nearestneighbour', left_dacc_location, input_t1_skullstriped, transformation_matrix_linear_inverted, output_location_subject_tmp, subject_name))
    system(sprintf('/opt/fsl/6.0.7/bin/flirt -in %s -ref %s -applyxfm -init %s -out %s/%s_payam_right_dacc_mask_linear.nii.gz -interp nearestneighbour', right_dacc_location, input_t1_skullstriped, transformation_matrix_linear_inverted, output_location_subject_tmp, subject_name))
    system(sprintf('/opt/fsl/6.0.7/bin/applywarp --ref=%s --in=%s --warp=%s.nii.gz --out=%s/%s_payam_left_dacc_mask_nonlinear.nii.gz --interp=nn', input_t1_name_and_location, left_dacc_location, transformation_matrix_nonlinear_inverted, output_location_subject_tmp, subject_name))
    system(sprintf('/opt/fsl/6.0.7/bin/applywarp --ref=%s --in=%s --warp=%s.nii.gz --out=%s/%s_payam_right_dacc_mask_nonlinear.nii.gz --interp=nn', input_t1_name_and_location, right_dacc_location, transformation_matrix_nonlinear_inverted, output_location_subject_tmp, subject_name))

    %% Extract center from different masks
    left_amygdala = niftiread(sprintf('%s/%s_amygdala_left.nii.gz', output_location_subject_tmp, subject_name));
    right_amygdala = niftiread(sprintf('%s/%s_amygdala_right.nii.gz', output_location_subject_tmp, subject_name));
    left_dacc = niftiread(sprintf('%s/%s_payam_left_dacc_mask_linear.nii.gz', output_location_subject_tmp, subject_name));
    right_dacc = niftiread(sprintf('%s/%s_payam_right_dacc_mask_linear.nii.gz', output_location_subject_tmp, subject_name));

    % Get nii info from the amygdala mask (should be same for dACC)
    mask_size = size(left_amygdala);
    mask_info = niftiinfo(sprintf('%s/%s_amygdala_left.nii.gz', output_location_subject_tmp, subject_name));

    % Get the coordinates of the non-zero voxels
    [left_amygdala_x, left_amygdala_y, left_amygdala_z] = ind2sub(size(left_amygdala), find(left_amygdala));
    [right_amygdala_x, right_amygdala_y, right_amygdala_z] = ind2sub(size(right_amygdala), find(right_amygdala));
    [left_dacc_x, left_dacc_y, left_dacc_z] = ind2sub(size(left_dacc), find(left_dacc));
    [right_dacc_x, right_dacc_y, right_dacc_z] = ind2sub(size(right_dacc), find(right_dacc));
    
    % Calculate the centers, the plus one is there to account for the
    % discrepancy in indexing between matlab and nifti
    dacc_y_offset = 4; % There to account for the fact that the dACC is not aligned perfectly along the z-axis

    left_amygdala_center = round([mean(left_amygdala_x), mean(left_amygdala_y), mean(left_amygdala_z)]) + 1;
    right_amygdala_center = round([mean(right_amygdala_x), mean(right_amygdala_y), mean(right_amygdala_z)]) + 1;
    left_dacc_anterior = round([mean(left_dacc_x), mean(left_dacc_y) + dacc_y_offset, max(left_dacc_z)]) + 1;
    right_dacc_anterior = round([mean(right_dacc_x), mean(right_dacc_y) + dacc_y_offset, max(right_dacc_z)]) + 1;
    left_dacc_center = round([mean(left_dacc_x), mean(left_dacc_y), mean(left_dacc_z)]) + 1;
    right_dacc_center = round([mean(right_dacc_x), mean(right_dacc_y), mean(right_dacc_z)]) + 1;
    left_dacc_posterior = round([mean(left_dacc_x), mean(left_dacc_y) - dacc_y_offset, min(left_dacc_z)]) + 1;
    right_dacc_posterior = round([mean(right_dacc_x), mean(right_dacc_y) - dacc_y_offset, min(right_dacc_z)]) + 1;
    left_sham_center = round(mean([left_amygdala_center; left_dacc_center], 1)) + 1;
    right_sham_center = round(mean([right_amygdala_center; right_dacc_center], 1)) + 1;

    %% Create new masks based on centers
    amygdala_mask = sprintf('%s/%s_amygdala_mask', output_location_subject, subject_name);
    dacc_mask = sprintf('%s/%s_dacc_mask', output_location_subject, subject_name);
    sham_mask = sprintf('%s/%s_sham_mask', output_location_subject, subject_name);
    
    % Make an empty mask based on the amygdala mask size
    empty_matrix = zeros(mask_size(1), mask_size(2), mask_size(3), 'int32');

    % Make amygdala mask
    amygdala_mask_matrix = empty_matrix;
    amygdala_mask_matrix(left_amygdala_center(1), left_amygdala_center(2), left_amygdala_center(3)) = 1;
    amygdala_mask_matrix(right_amygdala_center(1), right_amygdala_center(2), right_amygdala_center(3)) = 1;
    niftiwrite(amygdala_mask_matrix, amygdala_mask, mask_info);

    % Make dACC mask
    dacc_mask_matrix = empty_matrix;
    dacc_mask_matrix(left_dacc_anterior(1), left_dacc_anterior(2), left_dacc_anterior(3)) = 1;
    dacc_mask_matrix(right_dacc_anterior(1), right_dacc_anterior(2), right_dacc_anterior(3)) = 1;
    dacc_mask_matrix(left_dacc_center(1), left_dacc_center(2), left_dacc_center(3)) = 1;
    dacc_mask_matrix(right_dacc_center(1), right_dacc_center(2), right_dacc_center(3)) = 1;
    dacc_mask_matrix(left_dacc_posterior(1), left_dacc_posterior(2), left_dacc_posterior(3)) = 1;
    dacc_mask_matrix(right_dacc_posterior(1), right_dacc_posterior(2), right_dacc_posterior(3)) = 1;
    niftiwrite(dacc_mask_matrix, dacc_mask, mask_info);

    % Make sham mask
    sham_mask_matrix = empty_matrix;
    sham_mask_matrix(left_sham_center(1), left_sham_center(2), left_sham_center(3)) = 1;
    sham_mask_matrix(right_sham_center(1), right_sham_center(2), right_sham_center(3)) = 1;
    niftiwrite(sham_mask_matrix, sham_mask, mask_info);

    %% Now find the same coordinates for the simulations masks
    % Extract center from different masks
    left_amygdala = niftiread(sprintf('%s/%s_amygdala_left.nii.gz', segmentation_folder, subject_name));
    right_amygdala = niftiread(sprintf('%s/%s_amygdala_right.nii.gz', segmentation_folder, subject_name));
    left_dacc = niftiread(sprintf('%s/%s_payam_left_dacc_mask_linear.nii.gz', segmentation_folder, subject_name));
    right_dacc = niftiread(sprintf('%s/%s_payam_right_dacc_mask_linear.nii.gz', segmentation_folder, subject_name));

    % Get the coordinates of the non-zero voxels
    [left_amygdala_x, left_amygdala_y, left_amygdala_z] = ind2sub(size(left_amygdala), find(left_amygdala));
    [right_amygdala_x, right_amygdala_y, right_amygdala_z] = ind2sub(size(right_amygdala), find(right_amygdala));
    [left_dacc_x, left_dacc_y, left_dacc_z] = ind2sub(size(left_dacc), find(left_dacc));
    [right_dacc_x, right_dacc_y, right_dacc_z] = ind2sub(size(right_dacc), find(right_dacc));
    
    % Calculate the centers, the plus one is there to account for the
    % discrepancy in indexing between matlab and nifti
    dacc_y_offset = 4; % There to account for the fact that the dACC is not aligned perfectly along the z-axis

    left_amygdala_center = round([mean(left_amygdala_x), mean(left_amygdala_y), mean(left_amygdala_z)]) + 1;
    right_amygdala_center = round([mean(right_amygdala_x), mean(right_amygdala_y), mean(right_amygdala_z)]) + 1;
    left_dacc_anterior = round([mean(left_dacc_x), mean(left_dacc_y) + dacc_y_offset, max(left_dacc_z)]) + 1;
    right_dacc_anterior = round([mean(right_dacc_x), mean(right_dacc_y) + dacc_y_offset, max(right_dacc_z)]) + 1;
    left_dacc_center = round([mean(left_dacc_x), mean(left_dacc_y), mean(left_dacc_z)]) + 1;
    right_dacc_center = round([mean(right_dacc_x), mean(right_dacc_y), mean(right_dacc_z)]) + 1;
    left_dacc_posterior = round([mean(left_dacc_x), mean(left_dacc_y) - dacc_y_offset, min(left_dacc_z)]) + 1;
    right_dacc_posterior = round([mean(right_dacc_x), mean(right_dacc_y) - dacc_y_offset, min(right_dacc_z)]) + 1;
    left_sham_center = round(mean([left_amygdala_center; left_dacc_center], 1)) + 1;
    right_sham_center = round(mean([right_amygdala_center; right_dacc_center], 1)) + 1;

    % Load coordinates into matrix
    focus_coords = [
        left_amygdala_center;
        right_amygdala_center;
        left_amygdala_center;
        right_amygdala_center;
        left_amygdala_center;
        right_amygdala_center;
        left_dacc_anterior;
        right_dacc_anterior;
        left_dacc_center;
        right_dacc_center;
        left_dacc_posterior;
        right_dacc_posterior;
        left_sham_center;
        right_sham_center;
        left_sham_center;
        right_sham_center;
        left_sham_center;
        right_sham_center;
    ];

    % Convert subject_id to numeric
    subject_id = str2double(regexp(subject_name, '\d+', 'match', 'once'));
    
    % Validate focus_coords, not sure this is necessary
    if size(focus_coords, 1) ~= 18
        error('focus_coords must have 18 rows (one for each target)');
    end
    if size(focus_coords, 2) ~= 3
        error('focus_coords must have 3 columns [x, y, z]');
    end
    
    % Read the CSV file using semicolon as delimiter
    planning_coordinate_location = '/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv';
    planning_coordinate_list = readtable(planning_coordinate_location, 'Delimiter', ';');
    
    % Define target names (18 targets: 6 per group × 3 groups)
    target_names = cell(18, 1);
    idx = 1;
    for group = 1:3
        for target = 1:6
            target_names{idx} = sprintf('target_%d_%d', group, target);
            idx = idx + 1;
        end
    end
    
    % Check if subject already exists
    subject_exists = any(planning_coordinate_list.subject_id == subject_id);
    
    if subject_exists
        % Update existing subject
        fprintf('Subject %d already exists. Updating coordinates...\n', subject_id);
        subject_rows = planning_coordinate_list.subject_id == subject_id;
        
        % Update focus coordinates (keep pos_t1_grid coordinates as they are)
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
        
        % Create new rows for the subject
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
    %system(sprintf('rm -rf %s', sprintf('%s/tmp', output_location_subject)));

end
