function bch_spm12(subject_m)
%--------------------------------------------------------------------------
%% Evaluate the code below to add the correct paths for this experiment:
% This file is adapted for SPM 8 preprocessing of ME data Copyright (C)
% 2010, Lennart Verhagen L.Verhagen@donders.ru.nl version 2010-01-01
%
% Adaptation for SPM 12 by Reinoud Kaldewaij
% Adapted for SPM 12 by Vaibhav Arya
% Adapted for TCG analyses in SPM12 by Saskia Koch

%% Setting up paths for SPM and Scripts

addpath(fullfile(filesep,'project','3025003.01','code','software','spm12'));
addpath(fullfile(filesep,'project','3025003.01','code','software','spm12','matlabbatch'));
script_path = fullfile(filesep,'project','3025003.01','code','fMRI' );
subjm_path = fullfile(filesep,'project','3025003.01','bids','subject_mfiles');
addpath(genpath(script_path)); addpath(genpath(subjm_path));
addpath /home/common/matlab/fieldtrip/qsub; % for submitting jobs via matlab directly

%% Basics
%----------------------------------------
dir_root_analysis  = [filesep,fullfile('project', '3025003.01', 'derivatives')];
bach_root          = [filesep,fullfile('project', '3025003.01', 'code','fMRI')];

%% defining subjects and tasks
eval(subject_m);
settask = {'prep_all','orient_all','spike_check','combine_echoes','phase_correct','realign_unwarp_write', 'coreg_est','segmentation','normalization', 'smoothing', 'organize'};%'prep','spike_check','combine_echoes', 'phase_correct', 'realign_unwarp_write', 'coreg_est','segmentation','normalization', 'smoothing', 'organize'};

%% orignal set task variables

% NOTE on PHASE CORRECTION:
% if phase correction is applied, echoes need to be combined before
% phase correction. Phase correction is applied during the realignment process (unwarp)
% Order: combine_echoes, phase_correct, realign_unwarp_write, coreg_est...

% For multi-band multi-echo data (TR = 1.5 sec) no slice timing correction is needed

% settask options:  'prep'                      - moves images from bids format to right location and creates working directory
%                   'spike_check'               - checks for spikes
%                   'combine_echos'            - combines multi-echo data
%                   'phase_correct'             - applies phase correction with field-map
%                   'realign_unwarp_write'      - estimate and write realignment paramaters and apply field-map correction in one go (unwarping)
%                   'coreg_est'                 - further preprocessing
%                   'segmentation'              - further preprocessing
%                   'normalization'             - further preprocessing
%                   'smoothing'                 - further preprocessing
%% processing
%----------------------------------------
% basic configuration

cfg             = [];
cfg.save        = 'yes';
cfg.dir.batch   = 'batches';
cfg.func        = 'mri/func';
cfg.struc       = 'mri/anat';
cfg.fmap        = 'mri/fmap';
cfg.work        = 'work';
cfg.orig        = 'orig';

for t = 1:length(settask)
    switch lower(settask{t})
        %% preparation - reorganize folders
        case 'prep_all'

            cfg.task                       = {'bids_organize'};        % copies original funct/struc files from bids into analysis folder recognized by this script

            % directory settings
            cfg.dir.orig                    = 'orig';
            cfg.dir.info.dummy              = fullfile('info','dummy_images');
            % prefixcoreg_est
            cfg.prefix.func                 = 'f';                      % functional images: e.g. 'f' (functional)
            cfg.prefix.fmap                 = 'fmap';
            % multi echo settings
            cfg.me.medata                   = true;                     % should be true for multi-echo data
            cfg.me.dir_prefix               = 'E';
            cfg.me.nechoes                  =  3;

        case 'orient_all'
            cfg.task                       = {'orient_all','run_job'};
            % preprocessing settings
            cfg.preproc                     = 'auto_reorient_all';
            % prefix
            cfg.prefix.struc                = 's'; % structural image: e.g. 's' (structural)
            cfg.prefix.func                 = 'f';
            cfg.prefix.fmap                 = 'fieldmap';
            cfg.me.nechoes                  =  3;

            %% spike check
        case 'spike_check'

            cfg.task                        = {'extract_3D','check_spike_me'};% ,'extract_3D', %,checks for (and removes) spikes in multiecho data.
            % directory settings
            cfg.dir.orig                    = 'orig';
            cfg.dir.info.dummy              = fullfile('info','dummy_images');
            % prefixcoreg_est
            cfg.prefix.func                 = 'f';                      % functional images: e.g. 'f' (functional)
            cfg.prefix.fmap                 = 'fmap';
            % multi echo settings
            cfg.me.medata                   = true;                     % should be true for multi-echo data
            cfg.me.dir_prefix               = 'E';
            cfg.me.nechoes                  =  3;
            % spike check settings
            cfg.check.signal.do_plot        = true;                     % plot the global and slice signals?
            cfg.check.spike.mode            = 'check';                  % mode: 'check' or 'remove' spikes
            cfg.check.spike.threshold       = 0.3;                      % threshold: fractional deviation of slice mean that qualifies as a 'spike' e.g. 0.1 = 10%
            cfg.check.spike.dir             = 'spike_check';            % directory that contains spike mask image and original images with spikes - appended after info (after sessions)
            cfg.check.spike.combined.dir    = 'spike_check_combined';   % directory that contains spike mask image and original images with spikes - appended after info (after sessions)
            cfg.check.spike.prefix          = '';                       % prefix to be prepended before filename after spike removal. Beware, this might mess up your functional prefix

            %% combine echo's
        case 'combine_echoes'
            % note: files need to be in 3D format for echo combination. If
            % they are in 4D format, run task 'extract_3D' before echo
            % combination (this is usually done before spike checking)

            cfg.task                        = {'me_combine_echoes','cmbecho_to_4D'}; % combines echoes, and merges 3D files to 4D format {'extract_3D' 'me_combine_echoes', 'cmbecho_to_4D'}
            % directory settings
            cfg.dir.orig                    = 'orig';
            % multi echo settings
            cfg.me.dir_prefix               = 'E';
            cfg.me.nechoes                  = 3;
            cfg.me.combine_method           = 'paid-v1';                % options: 'sum'/'paid-v1'/'paid-v2'/'paid-v3'/'pre-paid' (usually used 'paid-v1')
            cfg.prefix.func                 = 'f';
            cfg.me.echotimes                = [13.4; 34.8; 56.2];
            cfg.me.pre_vols                 = 30;
            cfg.me.dir.PAIDweight           = 'PAIDweight';

            %% phase correction with fieldmap
        case 'phase_correct'
            cfg.task            = {'phase_correct','run_job'};

            cfg.phase.suffix    = {'phasediff'};
            cfg.mag             = {'1'};                                % choose which magnitude image you want to use for correction: 1 or 2
            cfg.preproc         = 'phase_correct';
            cfg.me.estecho      = 'E01';
            cfg.prefix.func     = 'f';

            %% Preprocessing - estimate and write realignment parameters on combined echoes and apply fieldmap correction (unwarp) (use this if fieldmap correction is applied)
        case 'realign_unwarp_write'

            cfg.task                 = {'realign_unwarp_write','run_job','plot_movparam'}; % realign_unwarp_write creates job, run_job runs the job, plot_movparam plots the movement parameters
            % prefix
            cfg.prefix.func          = 'f';                              % functional images: e.g. 'f' (functional)
            % preprocessing settings
            cfg.preproc              = 'realign_unwarp_write';

            %% Preprocessing - estimation of coregistration
        case 'coreg_est'

            cfg.task                = {'coreg_est','run_job_coreg'};
            % prefix
            cfg.prefix.func         = 'rf';%'f';
            cfg.prefix.mean         = 'meanrf';%'meanf';
            cfg.prefix.struc        = 's';
            % preprocessing settings
            cfg.preproc             = 'coreg_estimate';
            cfg.ref                 = 'struc';
            % SPM12 templates
            cfg.template.T1         = {[filesep,fullfile('home','common','matlab','spm8','templates','T1.nii,1')]};
            cfg.template.EPI        = {[filesep,fullfile('home','common','matlab','spm8','templates','EPI.nii,1')]};

            %% Preprocessing - segmentation
        case 'segmentation'

            cfg.task                        = {'segment','run_job'};
            % preprocessing settings
            cfg.preproc                     = 'segment';
            % prefix
            cfg.prefix.struc                = 's'; % structural image: e.g. 's' (structural)

            %% Preprocessing - normalization
        case 'normalization'

            cfg.task                        = {'norm_write','run_job_norm_write'};
            % preprocessing settings
            cfg.preproc                     = 'norm_write';
            % directory settings
            cfg.dir.struc_name              = 'anat';
            % prefix
            cfg.prefix.func                 = 'rf';             % functional images: e.g. 'f' (functional)
            cfg.prefix.mean                 = 'meanrf';         % mean images
            cfg.prefix.struc                = 's';              % structural image: e.g. 'ss' (structural)
            cfg.prefix.param                = 'y';              % segmentation parameters

            %% Preprocessing - smoothing
        case 'smoothing'

            cfg.task                        = {'smoothing','run_job'};%'smoothing','run_job'
            % preprocessing settings
            cfg.preproc                     = 'smooth';
            % prefix
            cfg.prefix.func                 = 'wrf';%'wf';           % functional images: e.g. 'f' (functional)

            %% Rearrange all the images/jobs/figures of different steps into seperate folders
        case 'organize'

            cfg.task                        = {'move_func','move_struc'}; % 'move_struc','move the structural segmented images and info to folders
            % directory settings
            cfg.dir.mov                     = 'movement';
            cfg.dir.mean                    = 'mean';
            cfg.dir.phase                   = 'phase';
            cfg.dir.struc_name              = 'anat';
            cfg.dir.segm                    = 'segment_images';
            cfg.dir.jobs                    = 'jobs';
            % prefix
            cfg.prefix.orig                  = 'f';             % functional images: e.g. 'f' (functional)
            cfg.prefix.mag                  = 'wfmag';
            cfg.prefix.phase                = 'uf';
            cfg.prefix.mean                 = 'meanrf';         % mean images
            cfg.prefix.wmean                = 'wmeanrf';        % normalized mean images
            cfg.prefix.param                = 'y';              % segmentation parameters
            cfg.prefix.segm                 = 'c';              % segmented image
    end

    %% execute task set
    %----------------------------------------

    %% general settings
    % directory settings
    cfg.dir.analysis        = dir_root_analysis;
    cfg.bch.root            = bach_root;
    cfg.prefix.img          = '.*\.nii$';
    % session of structural T1
    cfg.ses.T1              = subj.T1_ses;
    % session and run of functional images
    cfg.ses.TCG             = subj.ses_tcg;
    cfg.run.TCG             = subj.tcgrun;
    % session and run of fieldmaps
    cfg.ses.fmap            = subj.ses_fmap;
    cfg.run.fmap            = subj.fmaprun;
    % info directory settings
    cfg.info.info           = fullfile(subj.ses_tcg,'mri/info');
    cfg.info.batch          = fullfile(subj.ses_tcg,'mri/info/batches');

    cfg.subj            = subj.sub;
    cfg.dir.batches     = fullfile(cfg.dir.analysis,cfg.subj,cfg.info.batch);

    if strcmp(settask{t},'prep_t1') || strcmp(settask{t}, 'prep_all')
        cfg.dir.struc   = subj.T1;
        cfg.dir.func    = subj.tcgfmri;
        cfg.dir.fmap    = subj.fmap;
    else
        cfg.dir.struc   = fullfile(cfg.dir.analysis,cfg.subj,cfg.ses.TCG, cfg.struc);
        cfg.dir.func    = fullfile(cfg.dir.analysis,cfg.subj,cfg.ses.TCG, cfg.func);
        cfg.dir.fmap    = fullfile(cfg.dir.analysis,cfg.subj,cfg.ses.TCG, cfg.fmap);
    end

    bch_dotask(cfg);

end
end
