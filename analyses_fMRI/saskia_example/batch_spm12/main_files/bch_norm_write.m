function [cfg] = bch_norm_write(cfg)

%%% ReiKal adapted for SPM12

%%% AnnTyb adjusted - for "mean" variable

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'segmentation' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'norm_write' enter a 'new subject', but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'norm_write' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% define directory where to save batches
batch_dir=cfg.dir.batches;
if ~exist(batch_dir, 'dir'); mkdir(batch_dir); end

% load basic matlab batch of SPM12
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12

% Write functional images (voxel size: 2x2x2 mm)
run_all = [];
direc = fullfile(cfg.dir.func);
img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
run = cfg_getfile('FPList',direc,'any',img_prefix);

mean_prefix = ['^',cfg.prefix.mean,cfg.prefix.img];
mean_func = cfg_getfile('FPList',direc,'any',mean_prefix);
run_all = [run_all; run; mean_func];

param_prefix = ['^',cfg.prefix.param];
param = cfg_getfile('FPList',cfg.dir.struc,'any',param_prefix);

matlabbatch{1,3}.spm.spatial.normalise.write.subj = struct('def',{param}, 'resample',{run_all});% SPM12
matlabbatch{1,3}.spm.spatial.normalise.write.woptions.vox = [2 2 2]; % changed from .roptions

fname = char(strcat(cfg.preproc, '_func_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

% Write structural image (voxel size: 1x1x1 mm)
struc_prefix = ['^',cfg.prefix.struc,cfg.prefix.img];
struc = cfg_getfile('FPList',cfg.dir.struc, struc_prefix);

matlabbatch{1,3}.spm.spatial.normalise.write.subj = struct('def',{param}, 'resample',{struc});
matlabbatch{1,3}.spm.spatial.normalise.write.woptions.vox = [1 1 1]; % changed from .roptions

fname = char(strcat(cfg.preproc, '_struc_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');
end
