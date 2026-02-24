function [cfg] = bch_move_rpfile(cfg)

%--------------------------------------------------------------------------
% BCH_COPY_rpfile copies the realignment parameter text file from its original folder
% (preproc/work/E01) to the info folder (info).
% 
% Created by Inge Volman for SPM8 ME wrapper, March 2012
%--------------------------------------------------------------------------

pwd_orig = pwd;

disp('************ MOVING realignment parameter text file ************')


orig_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.preproc.work,cfg.me.estecho);
work_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.info);

movefile(fullfile(orig_dir,'*.txt'),work_dir); 

cd(pwd_orig);
