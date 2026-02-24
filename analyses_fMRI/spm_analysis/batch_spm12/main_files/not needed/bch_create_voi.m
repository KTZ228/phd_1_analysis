function [cfg] = bch_create_voi(cfg)

% Open SPM8 and select volume of interest.   
% Do not change anything and save this as 'voi' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in the spm model
spm_file = fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana, cfg.model1,'SPM.mat');
matlabbatch{1}.spm.util.voi.spmmat = {spm_file};

% fill in rest of batch
matlabbatch{1}.spm.util.voi.adjust = cfg.voi.spec.con;
matlabbatch{1}.spm.util.voi.session = cfg.voi.spec.sess;
matlabbatch{1}.spm.util.voi.name = cfg.voi.spec.names{1};

% fill in roi's
% first ROI: F contrast with threshold
roi{1}.spm.spmmat = {spm_file};
roi{1}.spm.contrast = cfg.voi.select.con;
roi{1}.spm.conjunction = 1;
roi{1}.spm.threshdesc = cfg.voi.select.cor;
roi{1}.spm.thresh = cfg.voi.select.th;
roi{1}.spm.extent = cfg.voi.minvox;
%mask.contrast = {};
%mask.thresh = {};
%mask.mtype = {};
%roi{1}.spm.mask = mask;

if strcmp(cfg.voi.spec.def,'sphere')
    roi{2}.sphere.centre = cfg.voi.spec.coords{1};
    roi{2}.sphere.radius = cfg.voi.spec.r;
    roi{2}.sphere.move.fixed = 1;
elseif strcmp(cfg.voi.spec.def,'mask')
    roi{2}.mask.image = {cfg.voi.spec.mask};
    roi{2}.mask.threshold = 0.5;
end

matlabbatch{1}.spm.util.voi.roi = roi;

% expression for combining roi's
matlabbatch{1}.spm.util.voi.expression = 'i1&i2';


fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana,fname), 'matlabbatch');
