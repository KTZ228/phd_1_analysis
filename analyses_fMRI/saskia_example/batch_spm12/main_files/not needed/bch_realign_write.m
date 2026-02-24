function [cfg] = bch_realign_write(cfg)

% Create a mat.file using the SPM8 batch option. this file should contain 
% 'Named Directory Selector', 'Change Directory' and 'Realign: Estimate' sections.   
% For the 'Named Directory Selector' - Input name = 'Subject directory', Directories --> add new
% directory selector, but do not enter directory name!
% For the 'Change Directory' - Press 'dependency' and select 'Subject directory (1)'.
% For 'Realign: Estimate' - Add new sessions (amount of sessions you have),
% but do not enter the files! Further adjust the settings to your own liking.
% Save this as 'realign_estimate' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];

% load basic matlab batch of SPM8
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
% matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}};
%matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; 
matlabbatch{1,1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {{cfg.dir.func}}; % SPM12
% fill in nifti's for both sessions & all echo's
write_images = [];


% for ss = 1:length(cfg.dir.sessions)
if cfg.me.medata == true
    for ee = 1:cfg.me.nechoes
        direc = fullfile(cfg.dir.func,cfg.sess.current,cfg.dir.preproc.work,[cfg.me.dir_prefix,sprintf('%02d', ee)]);
        %run = cfg_getfile('ExtFPList',direc,img_prefix);
        run = cfg_getfile('FPList',direc,'any',img_prefix); % SPM12
        write_images = [write_images; run];
    end
else
    direc = fullfile(cfg.dir.func,cfg.sess.current,cfg.dir.preproc.work);
    %run = cfg_getfile('ExtFPList',direc,img_prefix);
    run = cfg_getfile('FPList',direc,'any',img_prefix); % SPM12
    write_images = [write_images; run];
end
% end
     
matlabbatch{1,3}.spm.spatial.realign.write.data = write_images;

fname = [cfg.preproc '_' cfg.subj '_' cfg.sess.current '.mat'];
cfg.jobname = fullfile(cfg.dir.func,fname);
save(fullfile(cfg.dir.func,fname), 'matlabbatch');


