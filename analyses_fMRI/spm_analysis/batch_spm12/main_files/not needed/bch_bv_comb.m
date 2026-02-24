%% make empty variable in covariates directory called 'BV' and save as 'brain_vol.mat'. You need to do this each 
% time you run the script - otherwise it will append the new values to the old!



%GM - 1st column, WM, 2nd column
% 
% 
% dir_root           = [filesep,fullfile('home', 'affneu', 'anntyb', 'PHD', 'fMRI_subj_wave14')];
% preproc            = 'brain_vol';
% 
% 
% subjects            = {'002','003','004', '005','010','012','020','021','025','026','033','036','037','040','042',...
%                         '044','045','046','047','051','056','057','058','060', '061','062','065','070',...
%                         '072','077','085','088','094','095','098','103','104','106','112','114','115',...
%                         '118','119','122','123','124','125','905','942'}; 
% 
% subjsel = (1:2);                  
% %subjsel = [1:13 15:33 35:49]; % exclude 040 (no T1) and 095 (cut off brain)
% 
% BV = [];


% for s = subjsel
 %    subj = subjects{s};
 %    cfg.subj = fullfile(dir_root, subj);
 %    cfg.vbm.dir = fullfile(cfg.subj,'VBM');
  
 function [cfg] = bch_bv_comb(cfg)
 
    load(fullfile(cfg.dir.root, 'covariates', [cfg.preproc '.mat']))
    
    load(fullfile(cfg.dir.vbm, [cfg.preproc '_' cfg.subj '.mat']))
    BV(end+1,:) = VM;
 %end

    save(fullfile(cfg.dir.root, 'covariates', cfg.preproc), 'BV')
 end
 