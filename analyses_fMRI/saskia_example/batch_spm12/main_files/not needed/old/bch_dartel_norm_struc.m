
% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'DARTEL: Normalize to MNI' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'DARTEL: Normalize to MNI', create 4 subjects - these will correspond to the 4 types of images
% which will be warped to the (1) subj's flow field. Enter the gaussian kernel [0 0 0]. 
% Save this as 'dartel_norm' in cfg.dir.root.

% Anna Tyborowska (2013)


function [cfg] = bch_dartel_norm_struc(cfg)

load(fullfile(cfg.dir.root,cfg.preproc));

dir = fullfile(cfg.dir.struc,[cfg.dartel.flow_prefix, cfg.prefix.struc,cfg.subj,'.nii']);

% fill in name subject/func directory
matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}};

%select grey matter image 
dirc1 = fullfile(cfg.dir.struc, [cfg.prefix.seg.grey,cfg.prefix.struc,cfg.subj,'.nii']); 
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,1).flowfield = {dir};
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,1).images = {dirc1}; 

%white matter
dirc2 = fullfile(cfg.dir.struc, [cfg.prefix.seg.white,cfg.prefix.struc,cfg.subj,'.nii']); 
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,2).flowfield = {dir};
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,2).images = {dirc2}; 

% csf
dirc3 = fullfile(cfg.dir.struc, [cfg.prefix.seg.csf,cfg.prefix.struc,cfg.subj,'.nii']); 
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,3).flowfield = {dir};
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,3).images = {dirc3}; 

%struc
dir_s = fullfile(cfg.dir.struc,[cfg.prefix.struc,cfg.subj, '.nii']);
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,4).flowfield = {dir};
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,4).images = {dir_s}; 

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.func,fname), 'matlabbatch');


