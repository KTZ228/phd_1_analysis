function [cfg] = bch_slicetiming(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'slicetiming' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Slice Timing' - Add new sessions (amount of sessions you have),
% but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'slicetiming' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];

% fill in nifti's for both sessions
% if length(cfg.dir.sessions) == 3
%     
%     direc1 = fullfile(cfg.dir.func,cfg.dir.sessions{1},cfg.dir.preproc.work);
%     direc2 = fullfile(cfg.dir.func,cfg.dir.sessions{2},cfg.dir.preproc.work);
%     direc3 = fullfile(cfg.dir.func,cfg.dir.sessions{3},cfg.dir.preproc.work);
%     
%     run1 = cfg_getfile('ExtFPList',direc1,img_prefix);
%     run2 = cfg_getfile('ExtFPList',direc2,img_prefix);
%     run3 = cfg_getfile('ExtFPList',direc3,img_prefix);
%     
%     matlabbatch{1,3}.spm.temporal.st.scans = {run1 run2 run3};
%     
% elseif length(cfg.dir.sessions) == 2
%     
%     direc1 = fullfile(cfg.dir.func,cfg.dir.sessions{1},cfg.dir.preproc.work);
%     direc2 = fullfile(cfg.dir.func,cfg.dir.sessions{2},cfg.dir.preproc.work);
% 
%     run1 = cfg_getfile('FPList',direc1,'any',img_prefix); % SPM12
%     run2 = cfg_getfile('FPList',direc2,'any',img_prefix); % SPM12
%     
%     matlabbatch{1,3}.spm.temporal.st.scans = {run1 run2};
%     
%     % fill in nifti's for both sessions

% elseif length(cfg.dir.sessions) == 1
    
direc1 = fullfile(cfg.dir.func,cfg.sess.current,cfg.dir.preproc.work);

run1 = cfg_getfile('FPList',direc1,'any',img_prefix); % SPM12

matlabbatch{1,3}.spm.temporal.st.scans = {run1};
    
% end

fname = [cfg.preproc '_' cfg.subj '_' cfg.sess.current '.mat'];
cfg.jobname = fullfile(cfg.dir.func,fname);
save(fullfile(cfg.dir.func,fname), 'matlabbatch');

