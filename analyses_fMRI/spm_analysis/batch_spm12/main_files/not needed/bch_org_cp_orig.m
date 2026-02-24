function [cfg]= bch_org_cp_orig(cfg)
%--------------------------------------------------------------------------
% BCH_ORG_CP_ORIG copies the original functional images to the working
% directory (this working directory will be deleted after the preprocessing
% is done and the preprocessed images are moved to their respective
% directories). This is done to make sure that the original images remain
% untouched. This might be a bit redundant, but hey, at least it is safe.
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%
% adapted by Pieter Buur for ME compatibility, March 2008
% p.buur@fcdonders.ru.nl
% version 1.0 2008-03-25
%
% adapted by Inge Volman for SPM8 batch, August 2010
%--------------------------------------------------------------------------

if cfg.me.medata == true, nechoes = cfg.me.nechoes;
    
else nechoes = 1;
end

for ee = 1:nechoes
   
    orig_dir = fullfile(cfg.dir.analysis, cfg.subj, 'func','orig');
    work_dir = fullfile(cfg.dir.analysis, cfg.subj, 'func','work');
    
    orig_dir = orig_dir{1};
    work_dir = work_dir{1};
    
    fmap_dir = fullfile(work_dir,'fmap');
    
    if ~exist(fmap_dir,'dir'); mkdir(fmap_dir); end
    
    fmap_orig = fullfile(orig_dir,'fmap');
    
    if  ~isempty(strfind(cfg.prefix.img,'nii'))
        copyfile(fullfile(fmap_orig,[cfg.prefix.fmap,'*.nii']),fmap_dir);
    end
    
    if cfg.me.medata == true
        orig_dir = fullfile(orig_dir,[cfg.me.dir_prefix,sprintf('%02d', ee)]);
        work_dir = fullfile(work_dir,[cfg.me.dir_prefix,sprintf('%02d', ee)]);
    end

    info_dir = fullfile(cfg.dir.func,cfg.dir.info.info);
    info_dir = info_dir{1};
    
    if ~exist(info_dir,'dir'); mkdir(info_dir); end
    
    if exist(work_dir,'dir')
        delete(fullfile(work_dir,'*.*'));
    else
        mkdir(work_dir);
    end
    
    if ~isempty(strfind(cfg.prefix.img,'img'))
        % copyfile cannot take more than 2clc000 files at once. Therefore the
        % header and image files are copied separately...
        copyfile(fullfile(orig_dir,[cfg.prefix.func,'*.hdr']),work_dir);
        copyfile(fullfile(orig_dir,[cfg.prefix.func,'*.img']),work_dir);
    elseif  ~isempty(strfind(cfg.prefix.img,'nii'))
        copyfile(fullfile(orig_dir,[cfg.prefix.func,'*.nii']),work_dir);
    else
        copyfile(fullfile(orig_dir,[cfg.prefix.func,'*.*']),work_dir);
    end
end


end % end loop over echoes


