function [cfg] = bch_get_ppi_con1(cfg)
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
% manager, don't change anything, but save it as model1_ppi_con.
%--------------------------------------------------------------------------

subj_dir = fullfile(cfg.dir.root,cfg.subj);

% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in reference to model.
ppimodel_dir = fullfile(subj_dir, cfg.dir.ana, cfg.model1,'ppi',['VOI_' cfg.voi.spec.names{1}],cfg.ppi.name);
spm_file = fullfile(ppimodel_dir,'SPM.mat');
matlabbatch{1}.spm.stats.con.spmmat = {spm_file};

% load model
load(spm_file);

% model_dir = fullfile();


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
matlabbatch{1}.spm.stats.con.consess = get_con(cfg.model1,nr,bf,subj);

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(subj_dir,cfg.dir.ana,fname), 'matlabbatch');
%==========================================================================


%% function - build the first level contrasts
function consess = get_con(model,nr,bf,subj)

if nargin < 2; nr = {[NaN NaN 1]}; end
if nargin < 3; bf = 1; end
incl = true;

switch model
    
    case {'Resp_Affect6_motregr_info_RT'}
        
        % T-contrasts
        nr{1}(3) = 1;
        
        consess{1}.tcon.name = 'ppi  (T)';
            consess{1}.tcon.convec = bch_constr_tcon(1,nr,bf);
        consess{end+1}.tcon.name = 'P  (T)';
            consess{end}.tcon.convec = bch_constr_tcon(2,nr,bf);
        consess{end+1}.tcon.name = 'Y  (T)';
            consess{end}.tcon.convec = bch_constr_tcon(3,nr,bf);
                
    case {'None','none'}
        
        fprintf(1,'No model was selected.\nAre you sure? Press any key to continue.\n');
        pause
        
    otherwise
        
        %warning('BCH:NoModel','This model (%s) is not supported yet.',model);
        error('This model (%s) is not supported yet.',model);   
end
%==========================================================================
