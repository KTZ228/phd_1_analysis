% Clean house
clc; clear; close all;

%% Script to translate the masks in MNI space to coordinates in subject space
% First the masks need to be translated to subject space before a coordinate can be selected

subject_id = 14;

left_amygdala = ('juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz');
right_amygdala = ('juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz');
mask_left_hemisphere = 'payam_left_hemisphere_mask.nii.gz';
mask_right_hemisphere = 'payam_right_hemisphere_mask.nii.gz';
left_dacc = ('payam_left_dacc_mask.nii.gz');
right_dacc = ('payam_right_dacc_mask.nii.gz');
raw_dacc = ('payam_raw_dACC_mask_resampled.nii.gz');

%% Navigate to subject_folder and create masks

cd '/project/3023001.06/Simulations/kenneth_test/target_coordinate_selection/'

subject_t1 = sprintf('sub-%03d_ses-mri01_acq-t1mpragesagp20p9iso_run-1_T1w.nii.gz', subject_id);
subject_t1_post_bet = sprintf('sub-%03d_T1w_bet.nii.gz', subject_id);
subject_aff_trans = sprintf('sub-%03d_affine_transformation_matrix.mat', subject_id);

%% Resample MNI mask to dACC mask
system(sprintf('flirt -in $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz -ref masks/%s -out masks/MNI_mask_resampled.nii.gz -applyxfm -usesqform', raw_dacc));

%% Split dACC mask
% Make hemisphere masks
system(sprintf('fslmaths masks/MNI_mask_resampled.nii.gz -roi 0 45 0 -1 0 -1 0 -1 masks/%s', mask_left_hemisphere));
system(sprintf('fslmaths masks/MNI_mask_resampled.nii.gz -roi 46 45 0 -1 0 -1 0 -1 masks/%s', mask_right_hemisphere));

% Multiply said masks with the complete dACC mask
dacc_mask = niftiread(sprintf('masks/%s', raw_dacc));
info = niftiinfo(sprintf('masks/%s', raw_dacc));

left_mask = niftiread(sprintf('masks/%s', mask_left_hemisphere));
right_mask = niftiread(sprintf('masks/%s', mask_right_hemisphere));

left_dacc_mask = left_mask .* dacc_mask;
right_dacc_mask = right_mask .* dacc_mask;

niftiwrite(left_dacc_mask, sprintf('masks/%s', left_dacc), info);
niftiwrite(right_dacc_mask, sprintf('masks/%s', right_dacc), info);

%% Make the transformation matrix
system(sprintf('/opt/fsl/6.0.5/bin/bet %s %s -f 0.55 -R', subject_t1, subject_t1_post_bet));

system(sprintf('/opt/fsl/6.0.5/bin/flirt -in %s -ref /opt/fsl/6.0.5/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s', subject_t1_post_bet, subject_aff_trans));

system(sprintf('/opt/fsl/6.0.5/bin/fnirt --ref=/opt/fsl/6.0.5/data/standard/MNI152_T1_2mm.nii.gz --in=%s --aff=%s --cout=fslfnirt_native_to_MNI_space_warpcoef --config=T1_2_MNI152_2mm', subject_t1, subject_aff_trans));

system(sprintf('/opt/fsl/6.0.6/bin/invwarp --ref=%s --warp=fslfnirt_native_to_MNI_space_warpcoef.nii.gz --out=fslfnirt_MNI_to_native_space_warpcoef', subject_t1));

%% Warp masks using inverse transformation matrix
% Use the inverse warp to transform the masks to subject space

% Transform the raw dACC mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_raw_dacc_mask.nii.gz --interp=nn', subject_t1, raw_dacc, subject_id));
% Transform the left dACC mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_left_dacc_mask.nii.gz --interp=nn', subject_t1, left_dacc, subject_id));
% Transform the right dACC mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_right_dacc_mask.nii.gz --interp=nn', subject_t1, right_dacc, subject_id));


% Transform left amygdala mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_amygdala_left_jeulich_85_mask.nii.gz --interp=nn', subject_t1, left_amygdala, subject_id));
% Transform right amygdala mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_amygdala_right_jeulich_85_mask.nii.gz --interp=nn', subject_t1, right_amygdala, subject_id));