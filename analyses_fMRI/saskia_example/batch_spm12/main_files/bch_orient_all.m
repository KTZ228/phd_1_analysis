function [cfg] = bch_orient_all(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'segmentation' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'segment' do not enter the files! Further adjust the settings to your own liking.
% Save this as 'segment' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

% Added to the spm12 preprocessing steps by Saskia koch 2024

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% load basic matlab batch of SPM12
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs{1,1} = {cfg.dir.struc};

% get structural image
struc_prefix = ['^',cfg.prefix.struc,cfg.prefix.img];
struc = cfg_getfile('FPList',cfg.dir.struc,'any',struc_prefix);
matlabbatch{1,3}.spm.spatial.autoreor.image = struc;

% get functional images
func_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
for ee = 1:cfg.me.nechoes 
    echo_dir = fullfile(cfg.dir.func, ['E', num2str(ee, '%02d')]);
    func(ee) = cfg_getfile('FPList',echo_dir,'any',func_prefix);
end

% get fieldmaps
fmap_prefix = ['^',cfg.prefix.fmap,cfg.prefix.img];
fmap = cfg_getfile('FPList',cfg.dir.fmap,'any',fmap_prefix);

% combine functional images and fieldmaps in one data array
data = [func'; fmap];

matlabbatch{1, 3}.spm.spatial.autoreor.other = data;

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
if ~exist(cfg.dir.batches, 'dir'); mkdir(cfg.dir.batches); end
save(fullfile(cfg.dir.batches,fname), 'matlabbatch');

