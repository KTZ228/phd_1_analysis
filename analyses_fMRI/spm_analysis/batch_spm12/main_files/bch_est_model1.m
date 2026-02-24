function [cfg] = bch_est_model1(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'estimation' section.   
% Do not change anything and save this as 'model1_estimate' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in reference to model.
model_dir = fullfile(cfg.dir.preproc, cfg.subj, 'ses-tcg/mri/first_level_half'); %first_level

matlabbatch{1}.spm.stats.fmri_est.spmmat = {fullfile(model_dir,'SPM.mat')};
        
fname = [cfg.preproc '_' cfg.subj '.mat'];
cfg.jobname = fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.batch,fname);
save(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.batch,fname), 'matlabbatch');



