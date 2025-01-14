clc; clear; close all;

%% Ensure Simnibs paths are removed to resolve repelem.m issues
cd /home/affneu/kenvdzee/.conda/envs/
rmpath(genpath('simnibs_env'))

%% Change path to PRESTUS folder
cd /home/affneu/kenvdzee/Documents/PRESTUS

% add paths
addpath('functions')
addpath(genpath('toolboxes')) 
addpath('/home/common/matlab/fieldtrip/qsub')
masks_location = '/project/3025011.02/localite/masks/';
config_location = '/home/affneu/kenvdzee/Documents/phd_1_analysis/simulations/configs/';

plotting_target = 'right_amygdala';

if strcmp(plotting_target, 'left_anterior_dacc')
    parameters = load_parameters('config_kenneth_phd_1_dACC_PCD15287_01001_left_45mm.yaml', config_location);
    parameters.results_filename_affix = '_target_left_anterior_dacc';
    maskname = 'payam_left_dacc_mask.nii.gz';
    slice_axis = 'x';
elseif strcmp(plotting_target, 'right_anterior_dacc')
    parameters = load_parameters('config_kenneth_phd_1_dACC_PCD15287_01002_right_45mm.yaml', config_location);
    parameters.results_filename_affix = '_target_right_anterior_dacc';
    maskname = 'payam_right_dacc_mask.nii.gz';
    slice_axis = 'x';
elseif strcmp(plotting_target, 'left_medial_dacc')
    parameters = load_parameters('config_kenneth_phd_1_dACC_PCD15287_01001_left_45mm.yaml', config_location);
    parameters.results_filename_affix = '_target_left_medial_dacc';
    maskname = 'payam_left_dacc_mask.nii.gz';
    slice_axis = 'x';
elseif strcmp(plotting_target, 'right_medial_dacc')
    parameters = load_parameters('config_kenneth_phd_1_dACC_PCD15287_01002_right_45mm.yaml', config_location);
    parameters.results_filename_affix = '_target_right_medial_dacc';
    maskname = 'payam_right_dacc_mask.nii.gz';
    slice_axis = 'x';
elseif strcmp(plotting_target, 'left_posterior_dacc')
    parameters = load_parameters('config_kenneth_phd_1_dACC_PCD15287_01001_left_45mm.yaml', config_location);
    parameters.results_filename_affix = '_target_left_posterior_dacc';
    maskname = 'payam_left_dacc_mask.nii.gz';
    slice_axis = 'x';
elseif strcmp(plotting_target, 'right_posterior_dacc')
    parameters = load_parameters('config_kenneth_phd_1_dACC_PCD15287_01002_right_45mm.yaml', config_location);
    parameters.results_filename_affix = '_target_right_posterior_dacc';
    maskname = 'payam_right_dacc_mask.nii.gz';
    slice_axis = 'x';
elseif strcmp(plotting_target, 'left_amygdala')
    parameters = load_parameters('config_kenneth_phd_1_amygdala_PCD15287_01002_left_90mm.yaml', config_location);
    parameters.results_filename_affix = '_target_left_amygdala';
    maskname = 'juelich_probability_atlas_left_amygdala_laterobasal_threshold-85_bin.nii.gz';
    slice_axis = 'y';
elseif strcmp(plotting_target, 'right_amygdala')
    parameters = load_parameters('config_kenneth_phd_1_amygdala_PCD15287_01002_right_90mm.yaml', config_location);
    parameters.results_filename_affix = '_target_right_amygdala';
    maskname = 'juelich_probability_atlas_right_amygdala_laterobasal_threshold-85_bin.nii.gz';
    slice_axis = 'y';
elseif strcmp(plotting_target, 'left_sham')
    parameters = load_parameters('config_kenneth_phd_1_sham_PCD15287_01001_left.yaml', config_location);
    parameters.results_filename_affix = '_target_left_sham';
    maskname = 'payam_raw_dACC_mask_resampled.nii.gz';
    slice_axis = 'y';
elseif strcmp(plotting_target, 'right_sham')
    parameters = load_parameters('config_kenneth_phd_1_sham_PCD15287_01002_right.yaml', config_location);
    parameters.results_filename_affix = '_target_right_sham';
    maskname = 'payam_raw_dACC_mask_resampled.nii.gz';
    slice_axis = 'y';
else
    disp('Please select a plotting_target')
    return
end

% if output is in an alternate location
parameters.output_location = '/project/3025011.02/TUS_simulations/planning/intensity_35W/amygdala_90mm/';
parameters.temp_output_dir = '/project/3025011.02/TUS_simulations/planning/intensity_35W/amygdala_90mm/';

% Extract list of participants
files = struct2table(dir(parameters.data_path));
subject_list_table = files(logical(contains(files.name, 'sub') .* ~contains(files.name, 'm2m')),:);
subject_list = str2double((extract(subject_list_table{:,1}, digitsPattern))');
subject_list = 702;

% Load ROI
mask_location = fullfile(masks_location, maskname);
mask = niftiread(mask_location);

%% Start script
create_group_MNI_plots_fixed(subject_list, parameters, 'ROI_MNI_mask', mask,...
    'plot_max_intensity', 1, 'add_FWHM_boundary', 1, 'brightness_correction', 1,...
    'plot_heating', 0, 'slice_label', slice_axis)

% This is just here to go back to the script's directory
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));