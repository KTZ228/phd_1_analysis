%for functional images (voxel size [2 2 2])

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'Dartel: Normalize to MNI' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Normalize to MNI' select 0.5 gaussian kernel for minimal smoothing (pure "normalization without smoothing will lead to black holes in images).
% Save this as 'dartel_norm_func' in cfg.dir.root.



% Anna Tyborowska (2013)

function [cfg] = bch_dartel_norm_func(cfg)

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