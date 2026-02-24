function [cfg] = bch_create_ppi(cfg)

% Open SPM8 and select PPI.   
% change in psychophysiological interaction and save this as 'ppi' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in the spm model
spm_file = fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana, cfg.model1,'SPM.mat');
matlabbatch{1}.spm.stats.ppi.spmmat = {spm_file};

% fill in type info
voi_file = fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana, cfg.model1,['VOI_' cfg.voi.spec.names{1} '_1.mat']);
matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {voi_file};
if isequal(cfg.ppi.parametric_u,0)
    idx_name = ones(length(cfg.ppi.include_u),1);
matlabbatch{1}.spm.stats.ppi.type.ppi.u = [cfg.ppi.include_u' idx_name cfg.ppi.contrast_u'];
end

% name PPI
matlabbatch{1}.spm.stats.ppi.name = cfg.ppi.name;

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana,fname), 'matlabbatch');



