function [cfg] = bch_copy_vbm_scans(cfg)
%--------------------------------------------------------------------------
% copies the modualted and normalized images from subj folder to analysis folder
%


if ~exist(cfg.group.vbm, 'dir'); mkdir(cfg.group.vbm); end
if ~exist(fullfile(cfg.group.vbm, cfg.group.vbm_scans), 'dir'); mkdir(fullfile(cfg.group.vbm, cfg.group.vbm_scans)); end


pwd_orig = pwd;

disp('************ COPYING VBM files ************')


orig_dir = cfg.dir.vbm;
work_dir = fullfile(cfg.group.vbm, cfg.group.vbm_scans);

copyfile(fullfile(orig_dir,[cfg.prefix.dartel_norm '*nii']),work_dir);

cd(pwd_orig);