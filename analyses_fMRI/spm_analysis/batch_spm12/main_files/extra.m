% these are the SPM5 based INFO data.


%%%%%% folder structure %%%%%%%%%%%

INFO.dir.func           = 'func';
INFO.dir.sessions       = {fullfile('sess_affect'),fullfile('sess_colour')};

INFO.dir.orig           = 'orig';                           % directory with the original images, these stay untouched and are copied to the working directory before the preprocessing
INFO.dir.preproc.prprc  = 'preproc';
INFO.dir.preproc.work   = fullfile('preproc','work');       % temporary working directory for preprocessing, needs to be stated
INFO.dir.preproc.rlgn   = fullfile('preproc','realign');    % I don't reslice after the realignment estimation, so I don't need this one
INFO.dir.preproc.st     = fullfile('preproc','slicetime');  % I have no use for the images of this in-between-step, so I throw them away
INFO.dir.preproc.norm   = fullfile('preproc','norm');       % I use these images to estimate my global intensity regressor (see int_regr_spm5.m)
INFO.dir.preproc.smth   = fullfile('preproc','smooth');     % Since this is my last preproc step, I need to keep at least these images!
INFO.dir.info.info      = 'info';
INFO.dir.info.dummy     = fullfile('info','dummy_images');
INFO.dir.info.mean      = fullfile('info','mean_images');
INFO.dir.info.segm      = fullfile('info','segment_images');
INFO.dir.info.log       = 'behavioral';
INFO.dir.ana            = fullfile('analysis',INFO.model1);
INFO.dir.struct         = 'struc';
INFO.dir.groupana       = fullfile(INFO.dir.root,'Group',INFO.model2);

% Prefixes for filenames
% If all your images are called S01_, S02_, etc, you could use 'S' as a
% prefix. Other peoples use 'f' for their functional images for example.
% Adding a prefix is not specifically necessary, but if your preprocessing
% crashes while running it will make it easy to start over from where you
% left of instead of doing it all again.
INFO.prefix.func        = 'f';          % functional images: e.g. 'f' (functional)
INFO.prefix.struc       = 's';        % structural images: e.g. 'str' (structural)
INFO.prefix.log         = 'log';        % logfile of experiment (from Presentation for example)
INFO.prefix.behav       = 'behav';      % your behavioural data is saved in vectors which can be used to setup your first level model
INFO.prefix.cond        = 'cond';       % after specifying your model, the condition onsets and durations are saved with this prefix.
INFO.prefix.regr        = 'regr';       % your head motion (and compartment signal) regressors are saved with this prefix.
%INFO.prefix.img         = '.*\.img$';  % select if you use the new .nii files or the classic .hdr and .img files. The * and \ are mandatory, since this prefix is feeded directly to SPM5 spm_select.
INFO.prefix.img         = '.*\.nii$';   % select if you use the new .nii files or the classic .hdr and .img files. The * and \ are mandatory, since this prefix is feeded directly to SPM5 spm_select.
INFO.prefix.combined = 'rf'; % when using combined ME data to do a spike check.

INFO.nr_dummies = 4;                    % number of dummy images in functional dataset

%--------------------------------------------------------------------------


%% Settings for multi-echo data acquisition
%----------------------------------------------------
% bch_copy_mocopar
% bch_job_preproc_exp (/ bch_run_job / bch_expand_job)
% bch_combine_echoes  %% pfb -- this function name will change when options other than combining echoes become available

INFO.me.medata             = true;
INFO.me.dir_prefix         = 'E';
INFO.me.nechoes            = 5;
INFO.me.echo_mp            = 1; % set this to value < 0 if NOT using ME data!!!
INFO.me.combine_method     = 'paid-v1'; % 'sum'/'paid-v1'/'paid-v2'/'paid-v3'/'pre-paid'
INFO.me.echotimes          = [9.4 21 33 44 56]';
INFO.me.pre_vols           = 30;
INFO.me.dir.PAIDweight     = 'PAIDweight';

% settings necessary when using d2ngui for ME data
INFO.me.d2nsessions = {'sess_affect', 'sess_colour'};

%% Settings for data quality checks
%----------------------------------------------------
% bch_check_signal
% bch_check_spike
% bch_check_movie

INFO.check.signal.do_plot   = true;         % plot the global and slice signals?

INFO.check.spike.mode       = 'remove';      % mode: 'check' or 'remove' spikes
INFO.check.spike.threshold  = 0.3;          % threshold: fractional deviation of slice mean that qualifies as a 'spike' e.g. 0.1 = 10%
INFO.check.spike.dir        = 'spike_check';% directory that contains spike mask image and original images with spikes - appended after info (after sessions)
INFO.check.spike.combined.dir = 'spike_check_combined';% directory that contains spike mask image and original images with spikes - appended after info (after sessions)
INFO.check.spike.prefix     = '';           % prefix to be prepended before filename after spike removal. Beware, this might mess up your functional prefix!

INFO.check.movie.which      = 'both';       % Indicate which movies should be created ('default', 'contrast', 'both').
INFO.check.movie.contrast   = 98;           % If the 'contrast' movie is selected (see .which): Contrast value of that movie. A value between -100 (lowest contrast) and 100 (highest contrast) with 0 to leave the image as it is. Set to 98 to see the noise clearly.
INFO.check.movie.bright     = 97;           % If the 'contrast' movie is selected (see .which): Brightness value of that movie. A value between -100 (very dark) and 100 (very bright) with 0 to leave the image as it is. Set to 97 to see the noise clearly.
INFO.check.movie.nr_imgs    = 1000;         % The maximum number of images to be read-in at once by bch_check_movie. For a very high number, you run the risk of overloading your memory.
INFO.check.movie.save_temp  = 0;            % Set to "1" if you want to save the movie during it's creation ("0" for not). This will get rid of possible memory problems, but slows down the calculations (especially if nr_imgs is low).
INFO.check.movie.fps        = 6;            % Frames per second.
INFO.check.movie.dir        = 'movie_check';% directory that contains movies that were created - appended after info (after sessions), Inge added this.

%--------------------------------------------------------------------------


%% Settings for motion-behavioural checks
%----------------------------------------------------
% bch_check_motion_behav
% motion_behav_tool

INFO.check.motionbehav.exp = 'vect_ons_Exec';   % name of the variable describing the experimental timing vector (in scans)
INFO.check.motionbehav.filtcutoff = 120;        % the high-pass filter cutoff in seconds
INFO.check.motionbehav.opt = {'en'};            % options for check_motion_behav: 'en'- exp and rp frequency power spectra are normalized before plotting

%--------------------------------------------------------------------------


%% Settings for preprocessing
%----------------------------------------------------
% bch_job_preproc_exp
% bch_run_job
% bch_expand_job

% Slice timing settings: scan repetition time and number of slices
INFO.preproc.st.TR = 2.14;
INFO.preproc.st.nslices = 34;

% The reference image remains stationary. The source image is jiggled
% around to match the reference. You could use the mean ('mean') and
% the structural image ('str') for both the reference and the source.
INFO.preproc.coreg.ref = 'mean';
INFO.preproc.coreg.source = 'str';

% You can choose for an extended coregistration. Meaning that both your
% source and reference images are first coregistered to their respective
% templates before being coregistered with each other. If either the
% reference or the source is a mean EPI image (which is almost always the
% case), then also the functional images are taken along with the
% coregistration of their mean. This function can be important when
% preprocessing patient data, data from subjects with their heads in a
% tilted position, and when the centre of the scanner bore did not match
% the centre of the brain and nifti images are used.
INFO.preproc.coreg.extended = true;

% You could use both the mean ('mean') or the structural image ('str') to
% segment the brain.
INFO.preproc.segm.source = 'str';

% You could use both the mean ('mean') or the structural image ('str') to
% estiate the normalisation parameters.
INFO.preproc.norm.source = 'mean';

% Normalization templates
% FC Donders template of the tilted 8-channel phased-array head coil:
%INFO.preproc.norm.template = [filesep,fullfile('home','common','matlab','spm5','templates','FCDC','FCDC_Trio_8ch_tilt.img')];

% Standard templates from SPM5:
switch lower(INFO.preproc.norm.source)
    case 'str'
        INFO.preproc.norm.template = [filesep,fullfile('home','common','matlab','spm5','templates','T1.nii')];
    case {'mean','epi'}
        INFO.preproc.norm.template = [filesep,fullfile('home','common','matlab','spm5','templates','EPI.nii')];
end

% You could use the normalization parameters from the segmentation ('segm')
% or from an earlier normalization ('norm') estimation step.
INFO.preproc.norm.write = 'segm';

% Smoothing kernel
INFO.preproc.smth.fwhm = [8 8 8]; 

%--------------------------------------------------------------------------


%% Settings for creation of compartment signal nuisance regressors
%----------------------------------------------------
% bch_comp_signal
% comp_signal

INFO.compsig.OOBmax = 'median';    % should the OOB mask consist of voxels below the 1) 'mean', 2) 'median', or 3) 'max' of the "residual"-compartment (what is left out of GM && WM && CSF)
INFO.compsig.thres.WM = 0.99;      % the threshold of the WM probability mask (a value between 0 and 1)
INFO.compsig.thres.CSF = 0.98;      % the threshold of the CSF probability mask (a value between 0 and 1)
if strcmpi(INFO.preproc.segm.source,'str')
    INFO.compsig.thres.OOB = 0.25; % the threshold of the OOB probability mask (a value between 0 and 1)
else
    INFO.compsig.thres.OOB = 0.5;  % the threshold of the OOB probability mask (a value between 0 and 1)
end
%--------------------------------------------------------------------------





