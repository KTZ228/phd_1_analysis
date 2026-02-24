
% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'DARTEL: Normalize to MNI' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'DARTEL: Normalize to MNI', create 4 subjects - these will correspond to the 4 types of images
% which will be warped to the (1) subj's flow field. Enter the gaussian kernel [0 0 0]. 
% Save this as 'dartel_norm' in cfg.dir.root.

% Anna Tyborowska (2013)


function [cfg] = bch_vbm_dartel_norm(cfg)

if ~exist(cfg.dir.vbm, 'dir'); mkdir(cfg.dir.vbm); end


load(fullfile(cfg.dir.root,cfg.preproc));

dir = fullfile(cfg.dir.struc,[cfg.dartel.flow_prefix, cfg.prefix.struc,cfg.subj,'.nii']);

% fill in name subject/func directory
matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.vbm}};

%select template
dir_t = fullfile(cfg.dartel.dir, cfg.dartel.temp);
matlabbatch{3}.spm.tools.dartel.mni_norm.template = {dir_t};

%select grey matter image 
dirc1 = fullfile(cfg.dir.struc, cfg.dartel.seg,[cfg.prefix.seg.grey,cfg.prefix.struc,cfg.subj,'.nii']); 
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,1).flowfield = {dir};
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(1,1).images = {dirc1}; 


fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.vbm,fname), 'matlabbatch');


