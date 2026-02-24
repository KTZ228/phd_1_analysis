function [cfg] = bch_norm_write_func(cfg)

%%% ReiKal adapted for SPM12

%%% AnnTyb adjusted - for "mean" variable

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'segmentation' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'norm_write' enter a 'new subject', but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'norm_write' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
% matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}}; SPM8
% matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12
%func_dir = fullfile('C:\Users\saskoc\Documents\AuditoryAAT\Data',cfg.subj,'func');
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12

% Write functional images (voxel size: 2x2x2 mm)
run_all = [];
% for ss = 1:length(cfg.dir.sessions)
direc = fullfile(cfg.dir.func,cfg.sess.current,cfg.dir.preproc.work);
img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
%run = cfg_getfile('ExtFPList',direc{ss},img_prefix);%SPM8
run = cfg_getfile('FPList',direc{ss},'any',img_prefix);% SPM12

%     if strcmp(cfg.dir.sessions{ss},'sess_affect')||strcmp(cfg.dir.sessions{ss},'sess_affect1')
%         mean_prefix = ['^',cfg.prefix.mean,cfg.prefix.img];
%         mean = cfg_getfile('ExtFPList',direc{ss},mean_prefix);
%     end

mean_prefix = ['^',cfg.prefix.mean,cfg.prefix.img];
%mean_func = cfg_getfile('ExtFPList',direc{ss},mean_prefix); % SPM8
mean_func = cfg_getfile('FPList',direc,'any',mean_prefix); % SPM8
run_all = [run_all; run; mean_func];
% end

%matlabbatch{3}.spm.spatial.normalise.write.subj =
%struct('matname',{param}, 'resample',{run_all});SPM8

%matlabbatch{3}.spm.spatial.normalise.write.subj = struct('def',{param}, 'resample',{run_all});%SPM12

matlabbatch{1,3}.spm.spatial.normalise.estwrite.subj.resample = run_all;%SPM12
%matlabbatch{3}.spm.spatial.normalise.estwrite.subj = struct('resample',{run_all}); %SPM12

%matlabbatch{3}.spm.spatial.normalise.write.roptions.vox = [2 2 2];
matlabbatch{1,3}.spm.spatial.normalise.estwrite.woptions.vox = [2 2 2];


fname = [cfg.preproc '_' cfg.subj '_' cfg.sess.current '.mat'];
%save(fullfile(cfg.dir.func,fname), 'matlabbatch');
cfg.jobname = fname;
save(fullfile(cfg.dir.func,fname), 'matlabbatch');