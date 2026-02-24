function [cfg] = bch_create_ppi_model1(cfg)

% Open SPM8 and select 1st level specification.
% Do not change anything and save this as 'model1_ppi_spec' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subj_dir = fullfile(cfg.dir.root,cfg.subj);

% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in name subject/func directory
ppimodel_dir = fullfile(subj_dir, cfg.dir.ana, cfg.model1,'ppi',['VOI_' cfg.voi.spec.names{1}],cfg.ppi.name);
if ~exist(ppimodel_dir,'dir'); disp('directory does not exist');end

matlabbatch{1}.spm.stats.fmri_spec.dir = {ppimodel_dir};

matlabbatch{1}.spm.stats.fmri_spec.timing.RT = cfg.TR;

if length(cfg.dir.sessions) > 1 % Was commented
    for i = 1:length(cfg.dir.sessions)
        matlabbatch{1}.spm.stats.fmri_spec.sess(i)= matlabbatch{1}.spm.stats.fmri_spec.sess(1);
    end
end

try
    tm = matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond.tmod;
catch
    tm = 0;
end

for i = 1:length(cfg.dir.sessions)
    direc_func = fullfile(subj_dir,cfg.dir.func,cfg.dir.sessions{i},cfg.dir.preproc.smooth);
    direc_info = fullfile(cfg.dir.func,cfg.dir.sessions{i},cfg.dir.info.info);
    
    img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
    %run = cfg_getfile('ExtFPList',direc_func,img_prefix);
    run = cfg_getfile('FPList',direc_func,'any',img_prefix);
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).scans = run;
    %
    %     img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
    %     run = cfg_getfile('FPList',direc_func,'any',img_prefix);
    %     matlabbatch{1}.spm.stats.fmri_spec.sess(i).scans = run;
    %
    load(fullfile(ppimodel_dir,['PPI_' cfg.ppi.name]));
    
    regressors_p(1).name = 'ppi';
    regressors_p(1).val = PPI.ppi;
    regressors_p(2).name = 'P';
    regressors_p(2).val = PPI.P;
    regressors_p(3).name = 'Y';
    regressors_p(3).val = PPI.Y;
    
    %load(fullfile(subj_dir,cfg.dir.func, cfg.dir.info, [cfg.prefix.regr,cfg.subj]))
    load(fullfile(direc_info,[cfg.prefix.cond,cfg.subj,cfg.dir.sessions{i}]));
    
    regressors_p(4) = regressors(1,1);
    regressors_p(5) = regressors(1,2);
    regressors_p(6) = regressors(1,3);
    regressors_p(7) = regressors(1,4);
    regressors_p(8) = regressors(1,5);
    regressors_p(9) = regressors(1,6);
    
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).regress = regressors_p; 
end

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(subj_dir,cfg.dir.ana,fname), 'matlabbatch');