function [cfg] = bch_get_con2(cfg)
%--------------------------------------------------------------------------
% BCH_JOB_CON2_EXP creates a job structure for the contrast specification
% and estimation for the second level model. It relies on CONSTR_FCON and
% CONSTR_TCON to create the contrast matrices. Although these functions
% perform simple operations, their input can be quite difficult. Please
% look at the comments for those functions for more information.
%
% Below I added a few examples of a list of contrasts for my models. Please
% make the appropriate changes, but keep in mind that all 'fcon' and 'tcon'
% fields have a 'name' and a 'convec' subfield;
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%--------------------------------------------------------------------------

model = cfg.model1;
design = cfg.model2;
%jobs = get_con(model,design);

% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in reference to model.
model_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi, cfg.model2);
spm_file = fullfile(model_dir,'SPM.mat');
matlabbatch{1}.spm.stats.con.spmmat = {spm_file};

% load model
 load(spm_file);
% The number of regressors to be included in the contrasts.
% nr = {[7 8 1]}; % You can set the nr of regressors yourself
%for ss = 1:length(SPM.Sess)
%     i = 0;
%     for u = 1:length(SPM.Sess(ss).U)
%         i = i + length(SPM.Sess(ss).U(u).name);
%     end
%     j = length(SPM.Sess(ss).C.name);
    nr{1} = [length(SPM.xX.name) 0 1];
%end
matlabbatch{1}.spm.stats.con.consess = get_con(model,design,nr,1);
%jobs{1}.stats{1}.con.spmmat = {fullfile(INFO.dir.root,INFO.dir.groupana,'SPM.mat')};

% job_file = fullfile(strrep(INFO.dir.groupana,INFO.design2,''),[INFO.design2 '_cons.mat']);
% save(job_file,'jobs');
fname = [cfg.preproc '.mat'];
save_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi);
save(fullfile(save_dir,fname), 'matlabbatch');
% INFO.jobs.con2 = jobs;
% save(INFO.jobfile.con2,'jobs');
end
%==========================================================================


%% function - get_con
%----------------------------------------------------
function consess = get_con(model,design,nr,bf)
%function consess = get_con(model,design)

if nargin < 2; nr = {[NaN NaN 1]}; end
if nargin < 3; bf = 1; end
incl = true;

switch design
 
    case 'Mult_regr_H_A_T'
        
            % T-contrasts
             nr{1}(3) = 1; 
            
            tcon.name = 'Hap>Ang';
            tcon.convec = bch_constr_tcon([2:5; 1 -1 1 -1],nr,bf);
            consess{1}.tcon = tcon;            
            tcon.name = 'Ang>Hap';
            tcon.convec = bch_constr_tcon([2:5; -1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'C: Hap>Ang';
            tcon.convec = bch_constr_tcon([2:3; 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'C: Ang>Hap';
            tcon.convec = bch_constr_tcon([2:3; -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'P: Hap>Ang';
            tcon.convec = bch_constr_tcon([4:5; 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'P: Ang>Hap';
            tcon.convec = bch_constr_tcon([4:5; -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'P>C: Hap>Ang';
            tcon.convec = bch_constr_tcon([2:5; -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'P>C: Ang>Hap';
            tcon.convec = bch_constr_tcon([2:5; 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            
%             tcon.name = 'C: Hap';
%             tcon.convec = bch_constr_tcon([2; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap_neg';
%             tcon.convec = bch_constr_tcon([2; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang';
%             tcon.convec = bch_constr_tcon([3; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang_neg';
%             tcon.convec = bch_constr_tcon([3; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap';
%             tcon.convec = bch_constr_tcon([4; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap_neg';
%             tcon.convec = bch_constr_tcon([4; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang';
%             tcon.convec = bch_constr_tcon([5; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang_neg';
%             tcon.convec = bch_constr_tcon([5; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
            
%             tcon.name = 'P>C: Hap';
%             tcon.convec = bch_constr_tcon([2:5; -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C>P: Hap';
%             tcon.convec = bch_constr_tcon([2:5; 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang';
%             tcon.convec = bch_constr_tcon([2:5; 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C>P: Ang';
%             tcon.convec = bch_constr_tcon([2:5; 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;  
            
            tcon.name = 'T: Hap>Ang';
            tcon.convec = bch_constr_tcon([39:42; 1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'T: Ang>Hap';
            tcon.convec = bch_constr_tcon([39:42; -1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'T: C: Hap>Ang';
            tcon.convec = bch_constr_tcon([39:40; 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'T: C: Ang>Hap';
            tcon.convec = bch_constr_tcon([39:40; -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'T: P: Hap>Ang';
            tcon.convec = bch_constr_tcon([41:42; 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'T: P: Ang>Hap';
            tcon.convec = bch_constr_tcon([41:42; -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'T: P>C: Hap>Ang';
            tcon.convec = bch_constr_tcon([39:42; -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'T: P>C: Ang>Hap';
            tcon.convec = bch_constr_tcon([39:42; 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            
%             tcon.name = 'T: C: Hap';
%             tcon.convec = bch_constr_tcon([39; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Hap_neg';
%             tcon.convec = bch_constr_tcon([39; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang';
%             tcon.convec = bch_constr_tcon([40; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang_neg';
%             tcon.convec = bch_constr_tcon([40; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap';
%             tcon.convec = bch_constr_tcon([41; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap_neg';
%             tcon.convec = bch_constr_tcon([41; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang';
%             tcon.convec = bch_constr_tcon([42; 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang_neg';
%             tcon.convec = bch_constr_tcon([42; -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
            
%             tcon.name = 'T: P>C: Hap';
%             tcon.convec = bch_constr_tcon([39:42; -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C>P: Hap';
%             tcon.convec = bch_constr_tcon([39:42; 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang';
%             tcon.convec = bch_constr_tcon([39:42; 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C>P: Ang';
%             tcon.convec = bch_constr_tcon([39:42; 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
            
%         otherwise
%             error('LENVER:NoModel','This model (%s) is not supported yet.',model);
    %end
    

end
        
end

%==========================================================================
