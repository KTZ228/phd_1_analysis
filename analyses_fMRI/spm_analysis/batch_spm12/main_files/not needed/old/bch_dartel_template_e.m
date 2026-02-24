%%% creates flow fields to existing dartel template

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'DARTEL: Existing Template' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'DARTEL: Existing Template', create 2 image channels; and enter templates 1 - 6 (starting from the
% lowest)
% Save this as 'dartel_exist_template' in cfg.dir.root.
%
% Anna Tyborowska (2013)


function [cfg] = bch_dartel_template_e(cfg)

load(fullfile(cfg.dir.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}};

%select imported grey matter image
dir1 = fullfile(cfg.dir.struc, [cfg.prefix.seg.igrey,cfg.prefix.struc,cfg.subj,'.nii']);
matlabbatch{3}.spm.tools.dartel.warp1.images{1,1} = {dir1};
%select imported white matter image
dir2 = fullfile(cfg.dir.struc, [cfg.prefix.seg.iwhite,cfg.prefix.struc,cfg.subj,'.nii']);
matlabbatch{3}.spm.tools.dartel.warp1.images{1,2} = {dir2};

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.func,fname), 'matlabbatch');