function [cfg] = bch_copy_ppi(cfg)
%--------------------------------------------------------------------------
% BCH_COPY_PPI creates a PPI folder and copies the ppi.mat file from its original folder
% (ana) to the new folder (ppi).
% 
%

pwd_orig = pwd;

disp('************ COPYING PPI.mat ************')

orig_dir = fullfile(cfg.dir.root,cfg.subj,cfg.dir.ana,cfg.model1);
work_dir = fullfile(orig_dir,'ppi',['VOI_' cfg.voi.spec.names{1}],cfg.ppi.name);

if ~exist(work_dir,'dir'); mkdir(work_dir); end

copyfile(fullfile(orig_dir,['PPI_' cfg.ppi.name '.mat']),work_dir);

cd(pwd_orig);
