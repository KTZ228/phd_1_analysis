function [cfg] = bch_move_func(cfg)
%--------------------------------------------------------------------------
% BCH_move_func moves all the functional images to their corresponding
% directories (these will be deleted from original directory).
%
% Created by Inge Volman for SPM8 ME wrapper, April 2011
%--------------------------------------------------------------------------

    orig_dir  = fullfile(cfg.dir.func);
    
    info_dir  = fullfile(cfg.dir.analysis, cfg.subj, cfg.info.info);
    mean_dir  = fullfile(cfg.dir.analysis, cfg.subj, cfg.info.info,cfg.dir.mean);
    mov_dir   = fullfile(cfg.dir.analysis, cfg.subj, cfg.info.info,cfg.dir.mov);
    phase_dir = fullfile(cfg.dir.analysis, cfg.subj, cfg.info.info,cfg.dir.phase);
    
    %  
    if ~exist(info_dir,'dir');  mkdir(info_dir);  end
    if ~exist(mean_dir,'dir');  mkdir(mean_dir);  end
    if ~exist(mov_dir,'dir');   mkdir(mov_dir);   end
    if ~exist(phase_dir,'dir'); mkdir(phase_dir); end
    
    mean = dir(fullfile(orig_dir,[cfg.prefix.mean,'*.nii']));
    wmean = dir(fullfile(orig_dir,[cfg.prefix.wmean,'*.nii']));
    rparam = dir(fullfile(orig_dir,['rp','*.txt']));
    spm_output = dir(fullfile(orig_dir,['spm','*.ps']));
    mag_output = dir(fullfile(orig_dir, [cfg.prefix.mag, '*.nii']));
    phase_output = dir(fullfile(orig_dir, [cfg.prefix.phase, '*.nii']));
    matfiles = dir(fullfile(orig_dir, '*.mat'));
       
    if strmatch(exist(fullfile(orig_dir, mean.name)),2); movefile(fullfile(orig_dir,mean.name),mean_dir); end
    if strmatch(exist(fullfile(orig_dir, wmean.name)),2); movefile(fullfile(orig_dir,wmean.name),mean_dir); end
    if strmatch(exist(fullfile(orig_dir, rparam.name)),2); movefile(fullfile(orig_dir,rparam.name),mov_dir); end 
    if strmatch(exist(fullfile(orig_dir, spm_output.name)),2); movefile(fullfile(orig_dir,spm_output.name),info_dir); end
    if strmatch(exist(fullfile(orig_dir, mag_output.name)),2); movefile(fullfile(orig_dir,mag_output.name),phase_dir); end
    if strmatch(exist(fullfile(orig_dir, phase_output.name)),2); movefile(fullfile(orig_dir, phase_output.name),phase_dir); end
    
    for m = 1:length(matfiles)
        delete(fullfile(orig_dir,matfiles(m).name))
    end