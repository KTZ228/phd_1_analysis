function mask_transformation(subject_name)
    arguments
        subject_name string
    end
    
    %% Start segmentation
    % Set input names
    input_location = sprintf('/project/3025011.02/bids/%s/ses-mri01/anat', subject_name)
    input_t1_name_and_location = fullfile(input_location, (sprintf('%s*mprage_T1w.nii.gz', subject_name)))
    input_t1_name_and_location = fullfile(input_location, dir(input_t1_name_and_location).name)
    input_t2_name_and_location = fullfile(input_location, (sprintf('%s*sagisop2ellscan_T2w.nii.gz', subject_name)))
    input_t2_name_and_location = fullfile(input_location, dir(input_t2_name_and_location).name)
    masks_folder = '/project/3025011.02/localite/masks/';

    if ~isfile(input_t1_name_and_location)
        error('File "%s" does not exist', input_t1_name_and_location)
    elseif ~isfile(input_t2_name_and_location)
        error('File "%s" does not exist', input_t2_name_and_location)
    end
    
    % Set output names
    output_location = '/project/3025011.02/localite'
    output_location_subject = sprintf('%s/%s', output_location, subject_name)
    output_location_subject_tmp = sprintf('%s/tmp', output_location_subject)
    
    % Load correct version of freesurfer
    system('source /opt/freesurfer/7.3.2/SetUpFreeSurfer.sh')
    system('module load freesurfer')

    % Make output folders if they don't exist yet
    if ~isfolder(output_location_subject_tmp)
        mkdir(output_location_subject_tmp)
    end
    
    % Send output location to freesurfer
    setenv('SUBJECTS_DIR', output_location_subject_tmp)

    %% Start the recon-all pipeline from freesurfer
    system(sprintf('recon-all -i %s -s %s -T2 %s -T2pial -all -cw256', input_t1_name_and_location, subject_name, input_t2_name_and_location))

    %% Segment subregions using freesurfer
    system(sprintf('segment_subregions hippo-amygdala --cross %s', subject_name))
    
    %% Extract the amygdala's and dACC's from the freesurfer output
    % First, make sure it can reach the subject subfolders
    output_location_subject_tmp = sprintf('%s/%s', output_location_subject_tmp, subject_name)
    system(sprintf('mri_binarize --i %s/mri/lh.hippoAmygLabels.mgz --match 7001 7003 --o %s/amygdala_left.mgz', output_location_subject_tmp, output_location_subject_tmp))
    system(sprintf('mri_binarize --i %s/mri/rh.hippoAmygLabels.mgz --match 7001 7003 --o %s/amygdala_right.mgz', output_location_subject_tmp, output_location_subject_tmp))

    system(sprintf('mri_binarize --i %s/mri/aparc+aseg.mgz --match 1002 --o %s/dacc_left.mgz', output_location_subject_tmp, output_location_subject_tmp))
    system(sprintf('mri_binarize --i %s/mri/aparc+aseg.mgz --match 2002 --o %s/dacc_right.mgz', output_location_subject_tmp, output_location_subject_tmp))
    
    
    %% Convert the freesurfer masks to nifti's
    system(sprintf('mri_convert %s/amygdala_left.mgz %s/%s_amygdala_left.nii.gz', output_location_subject_tmp, output_location_subject, subject_name))
    system(sprintf('mri_convert %s/amygdala_right.mgz %s/%s_amygdala_right.nii.gz', output_location_subject_tmp, output_location_subject, subject_name))
    system(sprintf('mri_convert %s/dacc_left.mgz %s/%s_dacc_left.nii.gz', output_location_subject_tmp, output_location_subject, subject_name))
    system(sprintf('mri_convert %s/dacc_right.mgz %s/%s_dacc_right.nii.gz', output_location_subject_tmp, output_location_subject, subject_name))
    
    %% Translate Payam's dACC mask
    left_dacc = ('payam_left_dacc_mask.nii.gz');
    left_dacc_location = fullfile(masks_folder, left_dacc)
    right_dacc = ('payam_right_dacc_mask.nii.gz');
    right_dacc_location = fullfile(masks_folder, right_dacc)

    % Navigate to subject folder and create masks
    cd (output_location_subject_tmp)

    input_t1_skullstriped = sprintf('%s_T1w_bet.nii.gz', subject_name)
    transformation_matrix_linear = 'subj2MNI_lin_aff.mat'
    transformation_matrix_nonlinear = 'subj2MNI_nonlin_aff'
    transformation_matrix_nonlinear_inverted = 'MNI2subj_nonlin_aff'

    % Strip skull from subject T1
    system(sprintf('bet %s %s -R -f 0.5', input_t1_name_and_location, input_t1_skullstriped))

    %% Create a linear affine transformation matrix as a starting point for the non-linear transformation (T1 > MNI)
    % Only fnirt needs a skullstriped brain, flirt does not
    system(sprintf('flirt -in %s -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s -dof 12', input_t1_skullstriped, transformation_matrix_linear));

    %% Create a non-linear affine transformation matrix with the linear transformation matrix as a starting point (T1 > MNI)
    system(sprintf('fnirt --ref=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz --in=%s --aff=%s --cout=%s --config=T1_2_MNI152_2mm', input_t1_name_and_location, transformation_matrix_linear, transformation_matrix_nonlinear));

    %% Invert the affine transformation matrix from (T1 > MNI) to (MNI > T1)
    system(sprintf('invwarp --ref=%s --warp=%s.nii.gz --out=%s', input_t1_name_and_location, transformation_matrix_nonlinear, transformation_matrix_nonlinear_inverted));

    %% Apply the inverted affine transformation matrix to Payam's dACC masks
    system(sprintf('/opt/fsl/6.0.3/bin/applywarp --ref=%s --in=%s --warp=%s.nii.gz --out=%s/%s_payam_left_dacc_mask.nii.gz --interp=nn', input_t1_name_and_location, left_dacc_location, transformation_matrix_nonlinear_inverted, output_location_subject, subject_name));
    system(sprintf('/opt/fsl/6.0.3/bin/applywarp --ref=%s --in=%s --warp=%s.nii.gz --out=%s/%s_payam_right_dacc_mask.nii.gz --interp=nn', input_t1_name_and_location, right_dacc_location, transformation_matrix_nonlinear_inverted, output_location_subject, subject_name));

    %% Delete tmp folder
    system(sprintf('rm -rf %s', output_location_subject_tmp))

end
