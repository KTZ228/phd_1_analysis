function [cfg] = bch_segment(cfg)

% Adapted for SPM 12 by Reinoud

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'segmentation' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'segment' do not enter the files! Further adjust the settings to your own liking.
% Save this as 'segment' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% load basic matlab batch of SPM12
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.struc}};

% get structural
struc_prefix = ['^',cfg.prefix.struc,cfg.prefix.img];
struc = cfg_getfile('FPList',cfg.dir.struc,'any',struc_prefix);
matlabbatch{1,3}.spm.spatial.preproc.channel.vols = struc;

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

