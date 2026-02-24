function [cfg] = bch_get_con1(cfg)
%--------------------------------------------------------------------------
% BCH_JOB_CON1_EXP creates a job structure for the contrast specification
% and estimation for the first level model. It relies on CONSTR_FCON and
% CONSTR_TCON to create the contrast matrices. Although these functions
% perform simple operations, their input can be quite difficult. Please
% look at the comments for those functions for more information.
%
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%
% Adapted by Inge Volman for SPM8 wrapper, March 2012
%
% Create a SPM8 batch file using the SPM8 batch comment. Select contrast
% manager, don't change anything, but save it as model1_con.
%--------------------------------------------------------------------------

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in reference to model.
spm_file = fullfile(cfg.dir.preproc, cfg.subj, 'ses-tcg/mri/first_level_half', 'SPM.mat'); % first_level

matlabbatch{1}.spm.stats.con.spmmat = {spm_file};

% load model
load(spm_file);

% The number of hrf basis functions (canonical, temporal, dispersion)
% bf = 1 + sum(INFO.jobs.design1{1}.stats{1}.fmri_spec.bases.hrf.derivs);  % collected from the INFO file
bf = SPM.xBF.order;     % Get the bf from the spm.mat

% The number of model and nuisance regressors per session and if this
% session should be included in the contrasts.
% nr = {[7 8 1]}; % You can set the nr of regressors yourself
for ss = 1:length(SPM.Sess)
    i = 0;
    for u = 1:length(SPM.Sess(ss).U)
        i = i + length(SPM.Sess(ss).U(u).name);
    end
    j = length(SPM.Sess(ss).C.name);
    nr{ss} = [i j 1];
end

subj= cfg.subj;
nr{1}(3) = 1;

% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Planning Sender Known  (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([1; 1],nr,bf);

% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Planning Sender Novel  (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([2; 1],nr,bf);

% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Observing Receiver Known  (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([3; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Observing Receiver Novel  (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([4; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Role & Token assignment (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([5; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Moving as Sender (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([6; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Waiting as Sender (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([7; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Observing as Sender (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([8; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Waiting as Receiver (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([9; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Planning as Receiver (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([10; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Moving as Receiver (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([11; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Positive Feedback (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([12; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Negative Feedback (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([13; 1],nr,bf);
% 
% matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Moving (T)';
% matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([6 11;1 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Planning Sender Known  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([1; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Planning Sender Novel - first half  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([2; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Planning Sender Novel - second half (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([3; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Observing Receiver Known  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([4; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Observing Receiver Novel - first half  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([5; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Observing Receiver Novel - second half (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([6; 1],nr,bf);

fname = [cfg.preproc '_' cfg.subj '.mat'];
cfg.jobname = fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.batch,fname);
save(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.batch,fname), 'matlabbatch');

%==========================================================================
