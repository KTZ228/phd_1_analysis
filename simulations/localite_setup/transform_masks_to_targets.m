% Clean house
clc; clear; close all;

%% Script to translate the masks in MNI space to coordinates in subject space
% First the masks need to be translated to subject space before a coordinate can be selected

subject_id = 6;

masks_folder = '/project/3025011.02/localite/masks/';
anatomical_folder = sprintf('/project/3025011.02/bids/sub-%03d/ses-mri01/anat', subject_id);
output_location_subject = sprintf('/project/3025011.02/localite/sub-%03d/', subject_id);

raw_dacc = ('payam_raw_dACC_mask_resampled.nii.gz');
raw_dacc_location = fullfile(masks_folder, raw_dacc);
left_dacc = ('left_hemisphere_mask.nii.gz');
left_dacc_location = fullfile(masks_folder, left_dacc);
right_dacc = ('right_hemisphere_mask.nii.gz');
right_dacc_location = fullfile(masks_folder, right_dacc);

%% Navigate to subject_folder and create masks
cd (sprintf('/project/3025011.02/localite/sub-%03d/tmp', subject_id))

subject_t1 = fullfile(anatomical_folder, sprintf('sub-%03d*mprage_T1w.nii.gz', subject_id));
subject_t1 = fullfile(anatomical_folder, dir(subject_t1).name);
subject_t1_skullstriped = sprintf('sub-%03d_T1w_bet.nii.gz', subject_id);
subject_aff_trans = sprintf('sub-%03d_affine_transformation_matrix.mat', subject_id);

%% Strip skull from subject_t1
system(sprintf('bet %s %s -R -f 0.5', subject_t1, subject_t1_skullstriped));

%% Linear affine registration (T1 > MNI)
system(sprintf('flirt -in %s -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -omat subj2MNI_aff.mat -dof 12', subject_t1_skullstriped));

system(sprintf('convert_xfm -omat MNI2subj.mat -inverse subj2MNI_aff.mat'))

system(sprintf('flirt -in %s -ref %s -applyxfm -init MNI2subj.mat -out ../sub-%03d_payam_left_dacc_mask_new.nii.gz -interp nearestneighbour', left_dacc_location, subject_t1_skullstriped, subject_id))
system(sprintf('flirt -in %s -ref %s -applyxfm -init MNI2subj.mat -out ../sub-%03d_payam_right_dacc_mask_new.nii.gz -interp nearestneighbour', right_dacc_location, subject_t1_skullstriped, subject_id))