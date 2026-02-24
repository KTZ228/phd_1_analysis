function [cfg] = bch_phase_correct(cfg)
% phase_correct estimate fieldmap correction parameters

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% define directory where to save batches
batch_dir=cfg.dir.batches;
if ~exist(batch_dir, 'dir'); mkdir(batch_dir); end

% load the basic batch file for VDM estimation
load(fullfile(cfg.bch.root,cfg.preproc));

% navigate to where the fieldmap images are
direc_fmap = fullfile(cfg.dir.fmap);

% if echoes have already been combined, use the combined echo data
direc_func = fullfile(cfg.dir.func);

% select the correct images to input into matlabbatch
phase_img = cfg_getfile('FPList',direc_fmap,'^fieldmap*',cfg.phase.suffix);
%phase_img = cfg_getfile('FPList',direc_fmap,'any',cfg.phase.suffix);
mag_img_name = strcat('magnitude',cfg.mag);
% = cfg_getfile('FPList',direc_fmap,'any',mag_img_name);
mag_img = cfg_getfile('FPList',direc_fmap,'^fieldmap*',mag_img_name);

% input images into matlabbatch
matlabbatch{1,1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = phase_img;
matlabbatch{1,1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = mag_img;

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
func_img = cfg_getfile('FPList',direc_func,img_prefix);

matlabbatch{1,1}.spm.tools.fieldmap.calculatevdm.subj.session.epi = func_img;

% fill in matlabbatch subject's name and directory
% in this batch file, the named directory selector module is at the second position
matlabbatch{1,2}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

end