function [cfg] = bch_realign_unwarp_write(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'Realign: Estimate' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Realign: Estimate' - Add new sessions (amount of sessions you have),
% but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'realign_estimate' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];

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

direc = fullfile(cfg.dir.func);

run = cfg_getfile('FPList',direc,'any',img_prefix); % SPM12

%direc_fmap = fullfile(cfg.dir.func,cfg.dir.preproc.work, cfg.dir.fmap);
direc_fmap = fullfile(cfg.dir.fmap);
pmap_img = cfg_getfile('FPList',direc_fmap,'any','vdm');

matlabbatch{1,3}.spm.spatial.realignunwarp.data.scans = run;
matlabbatch{1,3}.spm.spatial.realignunwarp.data.pmscan = pmap_img;

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

