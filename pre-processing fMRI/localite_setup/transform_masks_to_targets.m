% Clean house
clc; clear; close all;

%% Script to translate the masks in MNI space to coordinates in subject space
% First the masks need to be translated to subject space before a coordinate can be selected

subject_id = 8;

left_amygdala = ('masks/juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz');
right_amygdala = ('masks/juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz');
left_dacc = ('masks/payam_left_dacc_mask.nii.gz');
right_dacc = ('masks/payam_right_dacc_mask.nii.gz');

%% Navigate to subject_folder and create masks

cd '/project/3023001.06/Simulations/kenneth_test/target_coordinate_selection/matlab_test/'

subject_t1 = 'sub-008_ses-mri01_acq-t1mpragesagp20p9iso_run-1_T1w.nii.gz';
subject_t1_post_bet = 'sub-008_T1w_bet.nii.gz';
subject_aff_trans = 'subject_t1_affine_transformation_matrix.mat';

system(sprintf('/opt/fsl/6.0.5/bin/bet %s %s -f 0.55 -R', subject_t1, subject_t1_post_bet));

system(sprintf('/opt/fsl/6.0.5/bin/flirt -in %s -ref /opt/fsl/6.0.5/data/standard/MNI152_T1_2mm_brain.nii.gz -omat %s', subject_t1_post_bet, subject_aff_trans));

system(sprintf('/opt/fsl/6.0.5/bin/fnirt --ref=/opt/fsl/6.0.5/data/standard/MNI152_T1_2mm.nii.gz --in=%s --aff=%s --cout=fslfnirt_native_to_MNI_space_warpcoef --config=T1_2_MNI152_2mm', subject_t1, subject_aff_trans));

system(sprintf('/opt/fsl/6.0.6/bin/invwarp --ref=%s --warp=fslfnirt_native_to_MNI_space_warpcoef.nii.gz --out=fslfnirt_MNI_to_native_space_warpcoef', subject_t1));

%% Warp masks using inverse transformation matrix

% use the inverse warp to warp the M1 and FPL ROIs from MNI_space into the subjects' native_space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz --interp=nn', subject_t1, subject_id));
% binarize mask
system(sprintf('fslmaths sub-%03d_juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz -bin sub-%03d_juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz', subject_id, subject_id));

% use the inverse warp to warp the M1 and FPL ROIs from MNI_space into the subjects' native_space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz --interp=nn', subject_t1, subject_id));
% binarize mask
system(sprintf('fslmaths sub-%03d_juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz -bin sub-%03d_juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz', subject_id, subject_id));

% use the inverse warp to warp the M1 and FPL ROIs from MNI_space into the subjects' native_space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/payam_left_dacc_mask.nii.gz --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_left_dacc_mask.nii.gz --interp=nn', subject_t1, subject_id));
% binarize mask
system(sprintf('fslmaths sub-%03d_payam_left_dacc_mask.nii.gz -bin sub-%03d_payam_left_dacc_mask_bin.nii.gz', subject_id, subject_id));

% use the inverse warp to warp the M1 and FPL ROIs from MNI_space into the subjects' native_space
system(sprintf('/opt/fsl/6.0.6/bin/applywarp --ref=%s --in=masks/payam_right_dacc_mask.nii.gz --warp=fslfnirt_MNI_to_native_space_warpcoef.nii.gz --out=sub-%03d_payam_right_dacc_mask.nii.gz --interp=nn', subject_t1, subject_id));
% binarize mask
system(sprintf('fslmaths sub-%03d_payam_right_dacc_mask.nii.gz -bin sub-%03d_payam_right_dacc_mask_bin.nii.gz', subject_id, subject_id));