% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and '(SPM-Tools-) New Segment' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'New Segment' - select native tissue settings (AT - according to
% Ashburner VBM tutorial)
%
% Save this as 'dartel_segment' in cfg.dir.root.

% Anna Tyborowska (2013)

function [cfg] = bch_dartel_segment(cfg)

load(fullfile(cfg.dir.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}};

%select T1 to be segmented
dir1 = fullfile(cfg.dir.struc,[cfg.prefix.struc,cfg.subj, '.nii']);
matlabbatch{3}.spm.tools.preproc8.channel.vols = {dir1};

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.func,fname), 'matlabbatch');