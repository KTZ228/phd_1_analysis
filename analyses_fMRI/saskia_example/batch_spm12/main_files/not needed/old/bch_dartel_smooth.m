% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'DARTEL: Normalize to MNI' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'DARTEL: Normalize to MNI' enter the gaussian kernel. Further adjust the settings to your own liking.
% Save this as 'dartel_smooth' in cfg.dir.root.
%
% normalization and smoothing are not sequential in dartel but done at the
% same time!

% Anna Tyborowska (2013)

function [cfg] = bch_dartel_smooth(cfg)

load(fullfile(cfg.dir.root,cfg.preproc));

data = [];

% fill in name subject/func directory
matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}};
% select dartel template
matlabbatch{3}.spm.tools.dartel.mni_norm.template = {cfg.dartel.temp};
%enter flow field for subj
dir_flow = fullfile(cfg.dir.struc,[cfg.dartel.flow_prefix, cfg.prefix.struc,cfg.subj,'.nii']);
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj.flowfield = {dir_flow};

%select images to be warped
dir = fullfile(cfg.dir.func, cfg.dir.preproc.work);
img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
run = cfg_getfile('ExtFPList',dir,img_prefix);

data = [data;run];
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj.images = data;


fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.func,fname), 'matlabbatch');