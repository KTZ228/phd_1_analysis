function [cfg] = bch_coreg_est(cfg)

%%%% AnnTyb adjusted

% Create a mat.file using the SPM8 batch option. this file should contain
% 'Named Directory Selector', 'Change Directory' and 'Coregister: Estimate' sections.
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Coregister: Estimate' - Add new sessions (amount of sessions you have),
% but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'coreg_estimate' in cfg.dir.root.


% More information on this can be found in the SPM8 tutorial.

%%%%% From SPM5 batch of LenVer.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The reference image remains stationary. The source image is jiggled
% around to match the reference. You could use the mean ('mean') and
% the structural image ('str') for both the reference and the source.

% You can choose for an extended coregistration. Meaning that both your
% source and reference images are first coregistered to their respective
% templates before being coregistered with each other. If either the
% reference or the source is a mean EPI image (which is almost always the
% case), then also the functional images are taken along with the
% coregistration of their mean. This function can be important when
% preprocessing patient data, data from subjects with their heads in a
% tilted position, and when the centre of the scanner bore did not match
% the centre of the brain and nifti images are used.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% load basic matlab batch of SPM12
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12

data_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
mean_prefix = ['^',cfg.prefix.mean,cfg.prefix.img];
struc_prefix = ['^',cfg.prefix.struc,cfg.prefix.img];
struc = cfg_getfile('FPList',cfg.dir.struc,'any',struc_prefix); %SPM12

data = [];
mean_func = [];

direc = fullfile(cfg.dir.func);
direc_mean =fullfile(cfg.dir.func); % in first echo folder 
mean_func = cfg_getfile('FPList',direc_mean,'any',mean_prefix);  %returns files with full dir % SPM 12
run = cfg_getfile('FPList',direc,'any',data_prefix); % SPM12
data = [data; run];

% structural to MNI T1 template
% reference image
matlabbatch{1,3}.spm.spatial.coreg.estimate.ref = cfg.template.T1;
% source image
matlabbatch{1,3}.spm.spatial.coreg.estimate.source = struc;
% other images
matlabbatch{1,3}.spm.spatial.coreg.estimate.other = {''};

fname = char(strcat(cfg.preproc, '_', cfg.subj, '_struc.mat'));
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

% functional images to MNI EPItemplate
% reference image
matlabbatch{1,3}.spm.spatial.coreg.estimate.ref = cfg.template.EPI;
% source image
matlabbatch{1,3}.spm.spatial.coreg.estimate.source = mean_func;
% other images
matlabbatch{1,3}.spm.spatial.coreg.estimate.other = data;

fname = char(strcat(cfg.preproc, '_', cfg.subj, '_func.mat'));
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

% struc to functionals of subject.
if strcmp(cfg.ref,'mean') % mean functional image to structural image
    % reference image
    matlabbatch{1,3}.spm.spatial.coreg.estimate.ref = mean_func;
    % source image
    matlabbatch{1,3}.spm.spatial.coreg.estimate.source = struc;
    % other images
    matlabbatch{1,3}.spm.spatial.coreg.estimate.other = {''};
elseif strcmp(cfg.ref,'struc') % structural image to mean functional image, applied to all data
    % reference image
    matlabbatch{1,3}.spm.spatial.coreg.estimate.ref = struc;
    % source image
    matlabbatch{1,3}.spm.spatial.coreg.estimate.source = mean_func;
    % other images
    matlabbatch{1,3}.spm.spatial.coreg.estimate.other = data;
end

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

end
