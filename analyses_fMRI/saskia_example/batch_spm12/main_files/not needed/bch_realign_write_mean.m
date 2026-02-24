function [cfg] = bch_realign_write_mean(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'Realign: Reslice' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Realign: Reslice' - do not enter the files! Further adjust the
% settings to your own liking, but select only write to mean.
% Save this as 'realign_write_mean' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
func_dir = fullfile(cfg.dir.func);
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {cfg.dir.func};

%fill in nifti's for all echo's
write_images = [];
for e = 1:3
    direc = fullfile(cfg.dir.func, ['E0',num2str(e)]);
    run = cfg_getfile('FPList',direc,img_prefix);
    write_images = [write_images; run];
end

matlabbatch{1,3}.spm.spatial.realign.write.data = write_images;

fname = char(strcat(cfg.preproc, '_', cfg.subj, '.mat'));
cfg.jobname = fullfile(cfg.dir.batches,fname);
save(fullfile(cfg.dir.batches{1},fname), 'matlabbatch');

