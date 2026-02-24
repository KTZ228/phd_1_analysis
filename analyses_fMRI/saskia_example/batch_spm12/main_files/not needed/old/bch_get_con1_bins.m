function [cfg] = bch_get_con1_bins(cfg)
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
spm_file = fullfile(cfg.fmri.root, cfg.subj, 'first_level', 'SPM.mat');

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

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 1  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([1; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 2  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([2; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 3  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([3; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 4  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([4; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 5  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([5; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 6  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([6; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 7  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([7; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 8  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([8; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 9  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([9; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 10  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([10; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Known - block 11  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([11; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 1  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([12; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 2  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([13; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 3  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([14; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 4  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([15; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 5  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([16; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 6  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([17; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 7  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([18 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 8  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([19; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 9  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([20; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Sender Novel - block 10  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([21; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 1  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([22; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 2  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([23; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 3  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([24; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 4  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([25; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 5  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([26; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 6  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([27; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 7  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([28; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 8  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([29; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 9  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([30; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 10  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([31; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Known - block 11  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([32; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 1  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([33; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 2  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([34; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 3  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([35; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 4  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([36; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 5  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([37; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 6  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([38; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 7  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([39; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 8  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([40; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 9  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([41; 1],nr,bf);

matlabbatch{1}.spm.stats.con.consess{end+1}.tcon.name = 'Receiver Novel - block 10  (T)';
matlabbatch{1}.spm.stats.con.consess{end}.tcon.convec = bch_constr_tcon([42; 1],nr,bf);

fname = [cfg.preproc '_' cfg.subj '.mat'];
cfg.jobname = fullfile(cfg.fmri.root,cfg.subj,cfg.dir.batch,fname);
save(fullfile(cfg.fmri.root,cfg.subj,cfg.dir.batch,fname), 'matlabbatch');

%==========================================================================