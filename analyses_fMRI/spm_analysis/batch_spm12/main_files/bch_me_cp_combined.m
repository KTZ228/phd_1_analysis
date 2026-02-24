function [cfg] = bch_me_cp_combined(cfg)
%--------------------------------------------------------------------------
% BCH_ME_CP_COMBINED copies the combined multi echo data to the orig
% directory (all files in this directory will be deleted).
%
% Created by Pieter Buur, March 2008
% Adapted by Lennart Verhagen, April 2008
% p.buur@fcdonders.ru.nl
% version 1.1 2008-04-30
%
% Adapted by Inge Volman for SPM8 ME wrapper, august 2010
%--------------------------------------------------------------------------

% work_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.orig);
% orig_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.preproc.work);
% PAID_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.orig,cfg.me.dir.PAIDweight);

work_dir = fullfile(cfg.dir.func{1},cfg.dir.orig);
orig_dir = fullfile(cfg.dir.func{1},cfg.dir.preproc.work);
PAID_dir = fullfile(cfg.dir.func{1},cfg.dir.orig,cfg.me.dir.PAIDweight);

% if exist(work_dir,'dir')
%     delete(fullfile(work_dir,'*.*'));
% else
%     mkdir(work_dir);
% end

if ~exist(PAID_dir,'dir')
    mkdir(PAID_dir);
end

if ~isempty(strfind(cfg.prefix.img,'img'))
    % move volumes which were used for the PAID weighting estimation
    % to a different directory.
    PAIDhdrs = dir(fullfile(orig_dir,['r','*.hdr']));
    PAIDimgs = dir(fullfile(orig_dir,['r','*.img']));
    for v = 1:cfg.me.pre_vols
        movefile(fullfile(orig_dir,PAIDhdrs(v).name),PAID_dir);
        movefile(fullfile(orig_dir,PAIDimgs(v).name),PAID_dir);
    end
    % copyfile cannot take more than 2000 files at once. Therefore the
    % header and image files are copied separately...
    copyfile(fullfile(orig_dir,['r','*.hdr']),work_dir);
    copyfile(fullfile(orig_dir,['r','*.img']),work_dir);
    
elseif  ~isempty(strfind(cfg.prefix.img,'nii'))
    % move volumes which were used for the PAID weighting estimation
    % to a different directory.
    %PAIDniis = dir(fullfile(orig_dir,['r','*.nii']));
    PAIDniis = dir(fullfile(orig_dir,['f','*.nii']));
    for v = 1:cfg.me.pre_vols
        movefile(fullfile(orig_dir,PAIDniis(v).name),PAID_dir);
    end
    %copyfile(fullfile(orig_dir,['r','*.nii']),work_dir);
    copyfile(fullfile(orig_dir,['f','*.nii']),work_dir);
else
    % move volumes which were used for the PAID weighting estimation
    % to a different directory.
    PAIDimgs = dir(fullfile(orig_dir,['r','*.*']));
    for v = 1:INFO.me.pre_vols
        movefile(fullfile(orig_dir,PAIDimgs(v).name),PAID_dir);
    end
    
    copyfile(fullfile(orig_dir,['r','*.*']),work_dir);
end

