function [cfg] = bch_est_ppi_model2(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'estimation' section.   
% Do not change anything and save this as 'model1_estimate' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in reference to model.
model_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi, cfg.model2);
matlabbatch{1}.spm.stats.fmri_est.spmmat = {fullfile(model_dir,'SPM.mat')};
        
fname = [cfg.preproc '.mat'];
save_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi);
save(fullfile(save_dir,fname), 'matlabbatch');



