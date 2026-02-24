%copies normalized image to vbm directory


function [cfg] = bch_mv_vbm_norm(cfg)

pwd_orig = pwd;

disp('************ COPYING grey matter image ************')


orig_dir = fullfile(cfg.dir.struc,cfg.dartel.seg);
work_dir = cfg.dir.vbm;

movefile(fullfile(orig_dir,[cfg.prefix.dartel_norm, cfg.prefix.seg.grey,cfg.prefix.struc,'*.nii']),work_dir);

cd(pwd_orig);