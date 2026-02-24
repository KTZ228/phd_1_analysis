function [cfg] = bch_est_ppi_model1(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'estimation' section.   
% Do not change anything and save this as 'model1_ppi_estimate' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subj_dir = fullfile(cfg.dir.root,cfg.subj);

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in reference to model.
ppimodel_dir = fullfile(subj_dir, cfg.dir.ana, cfg.model1,'ppi',['VOI_' cfg.voi.spec.names{1}],cfg.ppi.name);
matlabbatch{1}.spm.stats.fmri_est.spmmat = {fullfile(ppimodel_dir,'SPM.mat')};
        
fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(subj_dir,cfg.dir.ana,fname), 'matlabbatch');



