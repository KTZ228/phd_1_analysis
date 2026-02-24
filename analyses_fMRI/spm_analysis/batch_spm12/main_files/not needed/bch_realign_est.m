function [cfg] = bch_realign_est(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'Realign: Estimate' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Realign: Estimate' - Add new sessions (amount of sessions you have),
% but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'realign_estimate' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% define directory where to save batches
batch_dir = cfg.dir.batches{1};
if ~exist(batch_dir, 'dir'); mkdir(batch_dir); end

% load basic matlab batch of SPM12
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {cfg.dir.func}; % SPM12

% fill in nifti's
direc1 = fullfile(cfg.dir.func,cfg.me.estecho);

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];

run1 = cfg_getfile('FPList',direc1,'any',img_prefix);

matlabbatch{1,3}.spm.spatial.realign.estimate.data{1} = run1;

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches{1},fname), 'matlabbatch');


