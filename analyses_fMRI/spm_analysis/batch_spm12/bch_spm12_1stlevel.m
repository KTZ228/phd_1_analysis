function bch_spm12_1stlevel(subject_m)

%--------------------------------------------------------------------------
% Evaluate the code below to add the correct paths for this experiment:
% startup('sad','spm8');
%
% Original copyright (C) 2010, Lennart Verhagen
% L.Verhagen@donders.ru.nl
%
% This file is adapted for SPM8 first level modelling by Inge Volman,
% april 2011
%
% Adapted by Reinoud Kaldewaij for SPM12, Okt 2015
% Adapted by Vaibhav Arya for SPM 12. Janurary 2020
%--------------------------------------------------------------------------
%% Setting up paths for SPM and Scripts

addpath(fullfile(filesep,'project','3025003.01','code','software','spm12'));
addpath(fullfile(filesep,'project','3025003.01','code','software','spm12','matlabbatch'));
script_path = fullfile(filesep,'project','3025003.01','code','fMRI' );
subjm_path = fullfile(filesep,'project','3025003.01','bids','subject_mfiles');
addpath(genpath(script_path)); addpath(genpath(subjm_path));
addpath /home/common/matlab/fieldtrip/qsub; % for submitting jobs via matlab directly

%% Basics
%----------------------------------------

dir_root           = [filesep,fullfile('project', '3025003.01', 'derivatives')];
bach_root          = [filesep,fullfile('project', '3025003.01', 'code','fMRI')];
%fmri_root          = [filesep,fullfile('project', '3025003.01', 'derivatives')];
bids_root          = [filesep,fullfile('project', '3025003.01','bids')];

%% Subject and session selection
% % % % ----------------------------------------
eval(subject_m);

settask = {'prep','nuis_reg','spec_model1','create_model1','estimate_model1','con_model1'};

% settask options:  'prep'               - copies tcg logfile in derivatives directory
%                   'nuis_reg'           - define nuisance regressors
%                   'spec_model1'        - specify the first level model
%                   'create_model1'      - create the first level model
%                   'estimate_model1'    - estimate the first level model
%                   'con_model1'         - specify contrasts
%                   'copy'               - copy con images to group directory

%% processing
%----------------------------------------
% basic configuration
cfg             = [];
cfg.exp        	= 'TCG';
cfg.save        = 'yes';

for t = 1:length(settask)
    switch lower(settask{t})
        case 'prep'
            cfg.task = {'copy_beh'};
            cfg.dir.beh                = 'beh';
            cfg.dir.log                = subj.tcglog;

            %% nuisance regressors
        case 'nuis_reg'

            cfg.task                = {'check_motion', 'comp_signal', 'add_cov'};
            % task options:           check_motion    % collects head motion parameters from rp*.txt
            %                         comp_signal     % creates regressors describing the average signal of non-grey-matter compartments (WM, CSF and out-of-brain)
            %                         add_cov         % adds a covariate to exclude badd volumes, due to excessive movement (resulting in stripes) or spikes
            % directory settings
            cfg.dir.info.info       = 'info';
            cfg.dir.mov             = 'info/movement';
            cfg.dir.regr            = 'info/regressors';
            %cfg.dir.func            = 'func';
            %cfg.dir.struct          = 'anat';
            cfg.dir.segm            = 'segment_images';
            cfg.dir.mean            = 'info/mean';
            %cfg.dir.preproc.norm    = fullfile('preproc','norm');  % smoothed with 0.5 kernel dartel
            % prefix
            cfg.prefix.regr         = 'regr';       % your head motion (and compartment signal) regressors are saved with this prefix.
            % prior settings for segmentation
            cfg.preproc.segm.source     = 'str';
            % compartment signal settings
            cfg.compsig.OOBmax          = 'median';  % should the OOB mask consist of voxels below the 1) 'mean', 2) 'median', or 3) 'max' of the "residual"-compartment (what is left out of GM && WM && CSF)
            cfg.compsig.thres.WM        = 0.99;      % the threshold of the WM probability mask (a value between 0 and 1)
            cfg.compsig.thres.CSF       = 0.98;      % the threshold of the CSF probability mask (a value between 0 and 1)
            if strcmpi(cfg.preproc.segm.source,'str')
                cfg.compsig.thres.OOB   = 0.25; % the threshold of the OOB probability mask (a value between 0 and 1)
            else
                cfg.compsig.thres.OOB   = 0.5;  % the threshold of the OOB probability mask (a value between 0 and 1)
            end

            % Choose which regressors you would like to use for your head motion
            cfg.regr.rp.which      = {'trans','rot'};
            % and compartment signal regressors: (white matter: 'WM', cerebral spinal fluid 'CSF', out of brain: 'OOB').
            cfg.regr.sig.which     = {'WM','CSF','OOB'}; %{'WM','CSF','OOB'};
            % derivatives for nuisance regressors
            cfg.regr.rp.exp     = {'linear','deriv1','deriv2','quadratic','cubic'}; % deriv1_quadratic','deriv2_quadratic',,'deriv1_cubic','deriv2_cubic'
            cfg.regr.sig.exp    = {'linear'};

            %% Specify first level model
        case 'spec_model1'

            cfg.task = {'setup_model1_tcg','setup_nuisance_regr'};
            % directory settings
            cfg.dir.mov             = 'info/movement';
            cfg.dir.regr            = 'info/regressors';
            cfg.dir.info.info       = 'info';
            cfg.dir.func            = 'func';
            cfg.dir.beh             = 'beh';
            % prefix
            cfg.prefix.cond         = 'cond';       % after specifying your model, the condition onsets and durations are saved with this prefix.
            cfg.prefix.regr         = 'regr';       % your head motion (and compartment signal) regressors are saved with this prefix.
            % prior me settings.
            cfg.me.pre_vols         = 0;
            % TR
            cfg.preproc.st.TR       = 1.50;
            % Choose which regressors you would like to use for your head motion
            cfg.regr.rp.which      = {'trans','rot'};  %{'trans','rot'};
            % and compartment signal regressors:
            cfg.regr.sig.which     = {'WM','CSF','OOB'}; %(white matter: 'WM', cerebral spinal fluid 'CSF', out of brain: 'OOB').
            % derivatives for nuisance regressors
            cfg.regr.rp.exp     = {'linear','deriv1','deriv2','quadratic','cubic'}; % Extra possibilities: deriv1_quadratic','deriv2_quadratic',,'deriv1_cubic','deriv2_cubic'
            cfg.regr.sig.exp    = {'linear'};

            %% Create first level model
        case 'create_model1'
            cfg.task = {'create_model1', 'run_job'};
            cfg.preproc             = 'model1_spec';
            cfg.TR                  = 1.5;
            cfg.micro_res           = 36;  % microtime resolutio (number of time bins)
            cfg.micro_ons           = 25;  % microtime onset (reference slice)
            cfg.mthresh             = 0.5; % reikal = 0.5
            cfg.expmask             = {'/project/3025003.01/code/fMRI/masks/mask20_no_eyeballs.nii,1'}; %{'/project/3023003.01/PIA/reikal/AAT/MASKS/mask20_no_eyeballs_roi/mask20_no_eyeballs.nii'}; % default is none {''}
            % directory settings
            cfg.dir.info.info       = 'info';
            cfg.dir.regr            = 'info/regressors';
            cfg.dir.ana             = 'analysis';
            cfg.dir.batch           = 'info/batches';
            % prefix
            cfg.prefix.func         = 'swrf';       % 'swarf'
            cfg.prefix.cond         = 'cond';       % after specifying your model, the condition onsets and durations are saved with this prefix.
            cfg.prefix.regr         = 'regr';       % your head motion (and compartment signal) regressors are saved with this prefix.

            %% Estimate first level model
        case 'estimate_model1'
            cfg.task = {'est_model1', 'run_job'};
            cfg.preproc             = 'model1_estimate';
            % directory settings
            cfg.dir.ana             = 'analysis';
            cfg.dir.batch           = 'info/batches';

        case 'con_model1'
            cfg.task = {'get_con1','run_job'}; % con images for time modulation
            cfg.preproc             = 'model1_con';
            % directory settings
            cfg.dir.ana             = 'analysis';
            cfg.dir.batch           = 'info/batches';

    end

    %% execute task set
    %----------------------------------------

    % general settings
    cfg.dir.preproc         = dir_root;
    cfg.prefix.img          = '.*\.nii$';                       % select if you use the new .nii files or the classic .hdr and .img files. The * and \ are mandatory, since this prefix is feeded directly to SPM5 spm_select.
    cfg.bch.root            = bach_root;
    cfg.bids.root           = bids_root;

    % loop over subjects
    cfg.subj            = subj.sub;
    cfg.dir.func        = fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri/func');
    cfg.dir.struc       = fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri/anat');

    bch_dotask(cfg);

end
