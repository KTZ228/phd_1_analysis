function [cfg] = bch_comp_signal(cfg)
%--------------------------------------------------------------------------
% BCH_COMP_SIGNAL sets up the function COMP_SIGNAL with all the necessary
% input. COMP_SIGNAL can run outside this batch, but then it will pop up
% many selection windows and you are asked to designate all the necessary
% input by hand (e.g. selecting images and directories).
%
% BCH_COMP_SIGNAL takes the normalized functional images from the
% preprocessing directory and the segmented images from the mean EPI
% segmented in GreyMatter (GM), WhiteMatter (WM) and CerebralSpinalFluid
% (CSF). This means that you must have segmented your mean EPI during
% preprocessing and have kept the normalized images!!!
%
% For more details please take a look at COMP_SIGNAL.
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2008-7-10
%--------------------------------------------------------------------------

CINFO = cfg.compsig;
CINFO.prefix.regr = cfg.prefix.regr;
CINFO.prefix.img = cfg.prefix.img;

    CINFO.subj = cfg.subj;
    CINFO.dir.segm = fullfile(cfg.dir.struc, cfg.dir.segm);
    func_dir = fullfile(cfg.dir.func);
       
    switch lower(cfg.preproc.segm.source)
        case 'mean'
            CINFO.dir.ref = fullfile(cfg.dir.preproc,CINFO.subj,'ses-tcg/mri',cfg.dir.mean);
        case'str'
            CINFO.dir.ref = fullfile(cfg.dir.struc);
    end

        CINFO.dir.info = fullfile(cfg.dir.preproc,CINFO.subj,'ses-tcg/mri',cfg.dir.info.info);
        CINFO.dir.regr = fullfile(cfg.dir.preproc,CINFO.subj,'ses-tcg/mri',cfg.dir.regr);
               
        img_dir = fullfile(func_dir);
        images = cellstr(spm_select('List',img_dir,['^w',CINFO.prefix.img]));
        CINFO.imgs = char(cellstr(strcat(img_dir,filesep,images)));
        
        comp_signal(CINFO);
