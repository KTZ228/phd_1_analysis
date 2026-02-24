function [cfg] = bch_me_copy_mocopar(cfg)
%--------------------------------------------------------------------------
% BCH_ME_COPY_MOCOPAR copies the estimated realignment parameters stored in the
% nii header (either the .hdr file for a .img/.hdr pair or the .nii itself)
% from the echo that was used to estimate motion to all other echoes
% 
% this function is only used when data has been acquired in multi-echo mode
% the pipeline for processing multi-echo data is as follows:

%   1. estimate motion for one of the echoes as defined in the
%      INFO.me section in bch_info_exp
%   2. copy estimated realignment parameters from this echo to all others
%   3. realign all echoes
%   4. combine echoes using (pre-)PAID or other method
%   5. continue as usual
%   
%   *** NOTE to developer: it might be better to keep one of the echoes
%   ***   (Pieter Buur)    or the 'mean' echo aside for estimation of normalisation
%   ***                    and/or coregistration parameters rather than doing this
%   ***                    on the combined data but this has to be investigated
%
%   created by Pieter Buur, March 2008
%   p.buur@fcdonders.ru.nl
%   version 1.0 2008-03-25
%
%   Adapted for SPM8 multiecho wrapper by Inge Volman, august 2010.

warning off all % prevents spm_get_space from complaining about Analyze orientation

disp('************ COPYING REALIGNMENT PARAMETERS TO ALL ECHOES ************')

func_dir = fullfile(cfg.dir.func);

src_dir = fullfile(func_dir, [cfg.me.dir_prefix,sprintf('%02d',cfg.me.echo_mp)]);

src_img = cellstr(spm_select('List',src_dir,strcat('^',cfg.prefix.func',cfg.prefix.img)));

for ee = setdiff(1:cfg.me.nechoes,cfg.me.echo_mp)
    dst_dir = fullfile(func_dir, [cfg.me.dir_prefix,sprintf('%02d',ee)]);
    dst_img = cellstr(spm_select('List',dst_dir,strcat('^',cfg.prefix.func',cfg.prefix.img)));
    
    for ii=1:length(src_img)
        disp(sprintf('src img: %s\ndst img: %s', src_img{ii},dst_img{ii}))
        orientation = spm_get_space(fullfile(src_dir,src_img{ii}));
        spm_get_space(fullfile(dst_dir,dst_img{ii}),orientation);
    end % images
    disp(sprintf('copied subject %s / echo %02d', cfg.subj{1}, ee))
end % echoes
