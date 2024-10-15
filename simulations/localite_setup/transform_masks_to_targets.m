% Clean house
clc; clear; close all;

%% Script to translate the masks in MNI space to coordinates in subject space
% First the masks need to be translated to subject space before a coordinate can be selected

subject_id = 14;

left_amygdala = ('juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz');
right_amygdala = ('juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz');
left_dacc = ('masks/payam_left_dacc_mask.nii.gz');
right_dacc = ('masks/payam_right_dacc_mask.nii.gz');
raw_dacc = ('masks/payam_raw_dACC_mask.nii');

%% Navigate to subject_folder and create masks

cd '/project/3023001.06/Simulations/kenneth_test/target_coordinate_selection/'

subject_t1 = sprintf('sub-%03d_ses-mri01_acq-t1mpragesagp20p9iso_run-1_T1w.nii.gz', subject_id);
subject_t1_post_bet = sprintf('sub%03d_T1w_bet.nii.gz', subject_id);
subject_aff_trans = sprintf('sub%03d_affine_transformation_matrix.mat', subject_id);

%% Split dACC mask
dacc_mask = niftiread(raw_dacc);
info = niftiinfo(statistical_map_name);

left_mask = niftiread('masks/payam_left_hemisphere_mask.nii.gz');
right_mask = niftiread('masks/payam_right_hemisphere_mask.nii.gz');

left_dacc_mask = left_mask .* dacc_mask;
right_dacc_mask = right_mask .* dacc_mask;

niftiwrite(left_dacc_mask, 'masks/payam_left_dacc_mask.nii', info);
niftiwrite(right_dacc_mask, 'masks/payam_right_dacc_mask.nii', info);

%% Make the transformation matrix
system(sprintf('/opt/fsl/6.0.5/bin/bet %s %s -f 0.55 -R', subject_t1, subject_t1_post_bet));

system(sprintf('/opt/fsl/6.0.5/bin/flirt -in %s -ref /opt/fsl/6.0.5/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s', subject_t1_post_bet, subject_aff_trans));

system(sprintf('/opt/fsl/6.0.5/bin/fnirt --ref=/opt/fsl/6.0.5/data/standard/MNI152_T1_2mm.nii.gz --in=%s --aff=%s --cout=fslfnirt_native_to_MNI_space_warpcoef --config=T1_2_MNI152_2mm', subject_t1, subject_aff_trans));

system(sprintf('/opt/fsl/6.0.6/bin/invwarp --ref=%s --warp=fslfnirt_native_to_MNI_space_warpcoef.nii.gz --out=fslfnirt_MNI_to_native_space_warpcoef', subject_t1));

%% Warp masks using inverse transformation matrix
% Use the inverse warp to transform the masks to subject space

% Transform the left dACC mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/payam_raw_dACC_mask_resampled.nii.gz --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_raw_dacc_mask.nii.gz --interp=nn', subject_t1, subject_id));
% Transform the left dACC mask to subject space
%system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/payam_raw_dACC_mask_resampled.nii.gz --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_raw_dacc_mask.nii.gz --interp=nn', subject_t1, subject_id));

% Transform left amygdala mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_amygdala_left_jeulich_85_mask.nii.gz --interp=nn', subject_t1, left_amygdala, subject_id));
% Transform right amygdala mask to subject space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/%s --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_amygdala_right_jeulich_85_mask.nii.gz --interp=nn', subject_t1, right_amygdala, subject_id));