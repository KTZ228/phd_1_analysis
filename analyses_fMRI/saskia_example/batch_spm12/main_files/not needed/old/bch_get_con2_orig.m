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
model_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.model2);
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
save_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1);
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

% switch design
%     
%     case {'Mult_regr_H_A','Mult_regr_H_A_compN'}
%         
%            % F-contrasts
%            nr{1}(3) = 1;
%            
% %             fcon.name = 'Effects of Interest (F)';
% % %             %fcon.convec = {bch_constr_fcon(1:8),105,1,incl};
% %             fcon.convec = {bch_constr_fcon(2:9,nr,bf)};
% %             %fcon.convec = {bch_constr_fcon(2:9,{[44 0 1]},bf,incl)};
% %             consess{1}.fcon = fcon;
% 
%             % T-contrasts
%              nr{1}(3) = 1; 
%             
%             tcon.name = 'Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{1}.tcon = tcon;            
%             tcon.name = 'C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ap>Av';
%             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Av>Ap';
%             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
 
%     case 'Mult_regr_H_A_gender_T_Cort'
            % F-contrasts
            nr{1}(3) = 1;
            fcon.name = 'Effects of Interest (F)';
% % %             %fcon.convec = {bch_constr_fcon(1:8),105,1,incl};
              fcon.convec = {bch_constr_fcon(2:72,nr,bf)};
% %             %fcon.convec = {bch_constr_fcon(2:9,{[44 0 1]},bf,incl)};
            consess{1}.fcon = fcon;
        
            % T-contrasts
             nr{1}(3) = 1; 
            
            tcon.name = 'Inc>C';
            tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
            consess{1}.tcon = tcon;            
            tcon.name = 'C>Inc';
            tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'B: Inc>C';
            tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'B: C>Inc';
            tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G: Inc>C';
            tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G: C>Inc';
            tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Inc>C';
            tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'G>B: C>Inc';
            tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            
            tcon.name = 'B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;  
%             
            tcon.name = 'G>B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;  
            
%             tcon.name = 'B: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'B: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'G: Hap>Ang';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'G: Ang>Hap';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Hap>Ang';
            tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Ang>Hap';
            tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'B: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'B: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'G: Ap>Av';
%             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'G: Av>Ap';
%             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Ap>Av';
            tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'G>B: Av>Ap';
            tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'B: Inc>C; G: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'B: C>Inc; G: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
            tcon.name = 'Test: Inc>C';
            tcon.convec = bch_constr_tcon([57:64;-1 1 1 -1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'Test: C>Inc';
            tcon.convec = bch_constr_tcon([57:64;1 -1 -1 1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'Test: B: Inc>C';
            tcon.convec = bch_constr_tcon([57:60;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: B: C>Inc';
            tcon.convec = bch_constr_tcon([57:60;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Inc>C';
            tcon.convec = bch_constr_tcon([61:64;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: C>Inc';
            tcon.convec = bch_constr_tcon([61:64;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Inc>C';
            tcon.convec = bch_constr_tcon([57:64;1 -1 -1 1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'Test: G>B: C>Inc';
            tcon.convec = bch_constr_tcon([57:64;-1 1 1 -1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
%             
            tcon.name = 'Test: B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([57:60;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([57:60;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([57:60;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([57:60;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([61:64;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([61:64;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([61:64;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([61:64;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;  
%             
            tcon.name = 'Test: G>B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([57:64;1 0 -1 0 -1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([57:64;-1 0 1 0 1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([57:64;0 -1 0 1 0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([57:64;0 1 0 -1 0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;  
            
            tcon.name = 'Test: B: Hap>Ang';
            tcon.convec = bch_constr_tcon([57:60;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: B: Ang>Hap';
            tcon.convec = bch_constr_tcon([57:60;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Hap>Ang';
            tcon.convec = bch_constr_tcon([61:64;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Ang>Hap';
            tcon.convec = bch_constr_tcon([61:64;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Hap>Ang';
            tcon.convec = bch_constr_tcon([57:64;-1 1 -1 1 1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Ang>Hap';
            tcon.convec = bch_constr_tcon([57:64;1 -1 1 -1 -1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
                  
%            
            tcon.name = 'Test: B: Ap>Av';
            tcon.convec = bch_constr_tcon([57:60;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: B: Av>Ap';
            tcon.convec = bch_constr_tcon([57:60;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Ap>Av';
            tcon.convec = bch_constr_tcon([61:64;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G: Av>Ap';
            tcon.convec = bch_constr_tcon([61:64;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Ap>Av';
            tcon.convec = bch_constr_tcon([57:64;-1 -1 1 1 1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Test: G>B: Av>Ap';
            tcon.convec = bch_constr_tcon([57:64;1 1 -1 -1 -1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'Test: B: Inc>C; G: Av>Ap';
%             tcon.convec = bch_constr_tcon([57:60;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'Test: B: C>Inc; G: Ap>Av';
%             tcon.convec = bch_constr_tcon([57:60;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
            tcon.name = 'Cort: Inc>C';
            tcon.convec = bch_constr_tcon([65:72;-1 1 1 -1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'Cort: C>Inc';
            tcon.convec = bch_constr_tcon([65:72;1 -1 -1 1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'Cort: B: Inc>C';
            tcon.convec = bch_constr_tcon([65:68;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: B: C>Inc';
            tcon.convec = bch_constr_tcon([65:68;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Inc>C';
            tcon.convec = bch_constr_tcon([69:72;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: C>Inc';
            tcon.convec = bch_constr_tcon([69:72;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Inc>C';
            tcon.convec = bch_constr_tcon([65:72;1 -1 -1 1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;            
            tcon.name = 'Cort: G>B: C>Inc';
            tcon.convec = bch_constr_tcon([65:72;-1 1 1 -1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;            
            
            tcon.name = 'Cort: B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([65:68;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([65:68;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([65:68;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([65:68;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([69:72;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([69:72;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([69:72;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([69:72;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;  
%             
            tcon.name = 'Cort: G>B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([65:72;1 0 -1 0 -1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([65:72;-1 0 1 0 1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([65:72;0 -1 0 1 0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([65:72;0 1 0 -1 0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;  
%             
            tcon.name = 'Cort: B: Hap>Ang';
            tcon.convec = bch_constr_tcon([65:68;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: B: Ang>Hap';
            tcon.convec = bch_constr_tcon([65:68;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Hap>Ang';
            tcon.convec = bch_constr_tcon([69:72;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Ang>Hap';
            tcon.convec = bch_constr_tcon([69:72;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Hap>Ang';
            tcon.convec = bch_constr_tcon([65:72;-1 1 -1 1 1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Ang>Hap';
            tcon.convec = bch_constr_tcon([65:72;1 -1 1 -1 -1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
%                   
%           
            tcon.name = 'Cort: B: Ap>Av';
            tcon.convec = bch_constr_tcon([65:68;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: B: Av>Ap';
            tcon.convec = bch_constr_tcon([65:68;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Ap>Av';
            tcon.convec = bch_constr_tcon([69:72;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G: Av>Ap';
            tcon.convec = bch_constr_tcon([69:72;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Ap>Av';
            tcon.convec = bch_constr_tcon([65:72;-1 -1 1 1 1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;          
            tcon.name = 'Cort: G>B: Av>Ap';
            tcon.convec = bch_constr_tcon([65:72;1 1 -1 -1 -1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon; 
            
%             tcon.name = 'Cort: B: Inc>C; G: Av>Ap';
%             tcon.convec = bch_constr_tcon([65:72;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'Cort: B: C>Inc; G: Ap>Av';
%             tcon.convec = bch_constr_tcon([65:72;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;
            
% case 'Mult_regr_H_A_Cort_T_no66'
%         
%             % T-contrasts
%              nr{1}(3) = 1; 
%             
%             tcon.name = 'Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{1}.tcon = tcon;            
%             tcon.name = 'C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ap>Av';
%             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Av>Ap';
%             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'Cort: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'Cort: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'Cort: C: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: C: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'Cort: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'Cort: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'Cort: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'Cort: C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([44:47;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([44:47;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([48:51;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([48:51;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'Cort: C: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:47;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: C: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:47;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Ap>Av';
%             tcon.convec = bch_constr_tcon([48:51;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P: Av>Ap';
%             tcon.convec = bch_constr_tcon([48:51;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:51;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'Cort: P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:51;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'Cort: C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'Cort: C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'T: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C: Inc>C';
%             tcon.convec = bch_constr_tcon([52:55;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: C>Inc';
%             tcon.convec = bch_constr_tcon([52:55;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'T: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([52:55;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([52:55;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([52:55;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([52:55;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([52:55;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([52:55;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([56:59;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([56:59;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'T: C: Ap>Av';
%             tcon.convec = bch_constr_tcon([52:55;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Av>Ap';
%             tcon.convec = bch_constr_tcon([52:55;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ap>Av';
%             tcon.convec = bch_constr_tcon([56:59;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Av>Ap';
%             tcon.convec = bch_constr_tcon([56:59;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([52:59;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([52:59;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'T: C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'T: C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;
%             
% case {'Mult_regr_H_A_STAIst_T_no66','Mult_regr_H_A_STAIst_T_no66_corr'}
%         
%             % T-contrasts
%              nr{1}(3) = 1; 
%             
%             tcon.name = 'Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{1}.tcon = tcon;            
%             tcon.name = 'C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ap>Av';
%             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Av>Ap';
%             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'S: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'S: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'S: C: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'S: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'S: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'S: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'S: C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([44:47;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([44:47;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([48:51;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([48:51;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'S: C: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:47;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:47;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ap>Av';
%             tcon.convec = bch_constr_tcon([48:51;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Av>Ap';
%             tcon.convec = bch_constr_tcon([48:51;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:51;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:51;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'S: C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'S: C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'T: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C: Inc>C';
%             tcon.convec = bch_constr_tcon([52:55;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: C>Inc';
%             tcon.convec = bch_constr_tcon([52:55;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'T: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([52:55;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([52:55;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([52:55;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([52:55;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([52:59;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([52:59;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([52:55;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([52:55;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([56:59;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([56:59;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'T: C: Ap>Av';
%             tcon.convec = bch_constr_tcon([52:55;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Av>Ap';
%             tcon.convec = bch_constr_tcon([52:55;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ap>Av';
%             tcon.convec = bch_constr_tcon([56:59;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Av>Ap';
%             tcon.convec = bch_constr_tcon([56:59;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([52:59;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([52:59;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'T: C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'T: C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;
%             
% case {'Mult_regr_H_A_T_no66'}
%         
%             % T-contrasts
%              nr{1}(3) = 1; 
%             
%             tcon.name = 'Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{1}.tcon = tcon;            
%             tcon.name = 'C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            
%             tcon.name = 'C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ap>Av';
%             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Av>Ap';
%             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'T: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'T: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([44:47;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([44:47;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([48:51;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([48:51;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([44:51;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([44:51;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([44:47;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([44:47;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([48:51;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([48:51;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                  
%            
%             tcon.name = 'T: C: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:47;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:47;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ap>Av';
%             tcon.convec = bch_constr_tcon([48:51;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Av>Ap';
%             tcon.convec = bch_constr_tcon([48:51;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:51;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:51;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%            
%             tcon.name = 'T: C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'T: C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%            
%             
% case {'Mult_regr_H_A_T_no51_no66'}
%         
%             % T-contrasts
%              nr{1}(3) = 1; 
%             
%             tcon.name = 'Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{1}.tcon = tcon;            
%             tcon.name = 'C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%            
%             tcon.name = 'C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ap>Av';
%             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Av>Ap';
%             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'T: Inc>C';
%             tcon.convec = bch_constr_tcon([43:50;-1 1 1 -1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C>Inc';
%             tcon.convec = bch_constr_tcon([43:50;1 -1 -1 1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C: Inc>C';
%             tcon.convec = bch_constr_tcon([43:46;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: C>Inc';
%             tcon.convec = bch_constr_tcon([43:46;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Inc>C';
%             tcon.convec = bch_constr_tcon([47:50;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: C>Inc';
%             tcon.convec = bch_constr_tcon([47:50;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([43:50;1 -1 -1 1 -1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([43:50;-1 1 1 -1 1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'T: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([43:46;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([43:46;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([43:46;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([43:46;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([47:50;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([47:50;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([47:50;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([47:50;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([43:50;1 0 -1 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([43:50;-1 0 1 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([43:50;0 -1 0 1 0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([43:50;0 1 0 -1 0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([43:46;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([43:46;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap>Ang';
%             tcon.convec = bch_constr_tcon([47:50;1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang>Hap';
%             tcon.convec = bch_constr_tcon([47:50;-1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap>Ang';
%             tcon.convec = bch_constr_tcon([43:50;-1 1 -1 1 1 -1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang>Hap';
%             tcon.convec = bch_constr_tcon([43:50;1 -1 1 -1 -1 1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                  
%             tcon.name = 'T: C: Ap>Av';
%             tcon.convec = bch_constr_tcon([43:46;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Av>Ap';
%             tcon.convec = bch_constr_tcon([43:46;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ap>Av';
%             tcon.convec = bch_constr_tcon([47:50;1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Av>Ap';
%             tcon.convec = bch_constr_tcon([47:50;-1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ap>Av';
%             tcon.convec = bch_constr_tcon([43:50;-1 -1 1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Av>Ap';
%             tcon.convec = bch_constr_tcon([43:50;1 1 -1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%            
%             tcon.name = 'T: C: Inc>C; P: Av>Ap';
%             tcon.convec = bch_constr_tcon([43:50;-1 1 1 -1 -1 -1 1 1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%             tcon.name = 'T: C: C>Inc; P: Ap>Av';
%             tcon.convec = bch_constr_tcon([43:50;1 -1 -1 1 1 1 -1 -1],nr,bf);
%             consess{end+1}.tcon = tcon; 
%            
%             
%  
%     case 'Mult_regr_H_A_STAIst_T_no66_baseline'
%         
%             % T-contrasts
%              nr{1}(3) = 1; 
%             
%             tcon.name = 'Inc>C';
%             tcon.convec = bch_constr_tcon([2:11;-1 1 1 -1 0 -1 1 1 -1 0],nr,bf);
%             consess{1}.tcon = tcon;            
%             tcon.name = 'C>Inc';
%             tcon.convec = bch_constr_tcon([2:11;1 -1 -1 1 0 1 -1 -1 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Inc>C';
%             tcon.convec = bch_constr_tcon([7:10;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: C>Inc';
%             tcon.convec = bch_constr_tcon([7:10;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([2:11;1 -1 -1 1 0 -1 1 1 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([2:11;-1 1 1 -1 0 1 -1 -1 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([7:10;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([7:10;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([7:10;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([7:10;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([2:11;1 0 -1 0 0 -1 0 1 0 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([2:11;-1 0 1 0 0 1 0 -1 0 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([2:11;0 -1 0 1 0 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([2:11;0 1 0 -1 0 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'C: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([2:6;0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'C: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([2:6;0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([7:11;0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([7:11;0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([2:11;0 1 0 1 -2 0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'P>C: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([2:11;0 -1 0 -1 2 0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            % not updated yet!
% %             tcon.name = 'C: Ap>Av';
% %             tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'C: Av>Ap';
% %             tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'P: Ap>Av';
% %             tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'P: Av>Ap';
% %             tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'P>C: Ap>Av';
% %             tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'P>C: Av>Ap';
% %             tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;  
% %             
% %             tcon.name = 'C: Inc>C; P: Av>Ap';
% %             tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon; 
% %             tcon.name = 'C: C>Inc; P: Ap>Av';
% %             tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon; 
%             
%             tcon.name = 'S: Inc>C';
%             tcon.convec = bch_constr_tcon([46:55;-1 1 1 -1 0 -1 1 1 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'S: C>Inc';
%             tcon.convec = bch_constr_tcon([46:55;1 -1 -1 1 0 1 -1 -1 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'S: C: Inc>C';
%             tcon.convec = bch_constr_tcon([46:49;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: C>Inc';
%             tcon.convec = bch_constr_tcon([46:49;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Inc>C';
%             tcon.convec = bch_constr_tcon([51:54;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: C>Inc';
%             tcon.convec = bch_constr_tcon([51:54;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([46:55;1 -1 -1 1 0 -1 1 1 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'S: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([46:55;-1 1 1 -1 0 1 -1 -1 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'S: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([46:49;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([46:49;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([46:49;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([46:49;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([51:54;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([51:54;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([51:54;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([51:54;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'S: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([46:55;1 0 -1 0 0 -1 0 1 0 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([46:55;-1 0 1 0 0 1 0 -1 0 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([46:55;0 -1 0 1 0 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([46:55;0 1 0 -1 0 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'S: C: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([46:50;0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: C: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([46:50;0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([51:55;0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([51:55;0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([46:55;0 1 0 1 -2 0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'S: P>C: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([46:55;0 -1 0 -1 2 0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            % not updated yet
% %             tcon.name = 'S: C: Ap>Av';
% %             tcon.convec = bch_constr_tcon([44:47;1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'S: C: Av>Ap';
% %             tcon.convec = bch_constr_tcon([44:47;-1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'S: P: Ap>Av';
% %             tcon.convec = bch_constr_tcon([48:51;1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'S: P: Av>Ap';
% %             tcon.convec = bch_constr_tcon([48:51;-1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'S: P>C: Ap>Av';
% %             tcon.convec = bch_constr_tcon([44:51;-1 -1 1 1 1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'S: P>C: Av>Ap';
% %             tcon.convec = bch_constr_tcon([44:51;1 1 -1 -1 -1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;  
% %             
% %             tcon.name = 'S: C: Inc>C; P: Av>Ap';
% %             tcon.convec = bch_constr_tcon([44:51;-1 1 1 -1 -1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon; 
% %             tcon.name = 'S: C: C>Inc; P: Ap>Av';
% %             tcon.convec = bch_constr_tcon([44:51;1 -1 -1 1 1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon; 
% %             
%             tcon.name = 'T: Inc>C';
%             tcon.convec = bch_constr_tcon([56:65;-1 1 1 -1 0 -1 1 1 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C>Inc';
%             tcon.convec = bch_constr_tcon([56:65;1 -1 -1 1 0 1 -1 -1 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: C: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Inc>C';
%             tcon.convec = bch_constr_tcon([61:64;-1 1 1 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: C>Inc';
%             tcon.convec = bch_constr_tcon([61:64;1 -1 -1 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Inc>C';
%             tcon.convec = bch_constr_tcon([56:65;1 -1 -1 1 0 -1 1 1 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             tcon.name = 'T: P>C: C>Inc';
%             tcon.convec = bch_constr_tcon([56:65;-1 1 1 -1 0 1 -1 -1 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;            
%             
%             tcon.name = 'T: C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([56:59;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([56:59;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([61:64;-1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([61:64;1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([61:64;0 1 0 -1],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([61:64;0 -1 0 1],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: P>C: Hap: Inc>C';
%             tcon.convec = bch_constr_tcon([56:65;1 0 -1 0 0 -1 0 1 0 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Hap: C>Inc';
%             tcon.convec = bch_constr_tcon([56:65;-1 0 1 0 0 1 0 -1 0 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: Inc>C';
%             tcon.convec = bch_constr_tcon([56:65;0 -1 0 1 0 0 1 0 -1 0],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang: C>Inc';
%             tcon.convec = bch_constr_tcon([56:65;0 1 0 -1 0 0 -1 0 1 0],nr,bf);
%             consess{end+1}.tcon = tcon;  
%             
%             tcon.name = 'T: C: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([56:60;0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: C: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([56:60;0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([61:65;0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([61:65;0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Baseline>Ang';
%             tcon.convec = bch_constr_tcon([56:65;0 1 0 1 -2 0 -1 0 -1 2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%             tcon.name = 'T: P>C: Ang>Baseline';
%             tcon.convec = bch_constr_tcon([56:65;0 -1 0 -1 2 0 1 0 1 -2],nr,bf);
%             consess{end+1}.tcon = tcon;          
%                   
%            % not updated yet
% %             tcon.name = 'T: C: Ap>Av';
% %             tcon.convec = bch_constr_tcon([52:55;1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'T: C: Av>Ap';
% %             tcon.convec = bch_constr_tcon([52:55;-1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'T: P: Ap>Av';
% %             tcon.convec = bch_constr_tcon([56:59;1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'T: P: Av>Ap';
% %             tcon.convec = bch_constr_tcon([56:59;-1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'T: P>C: Ap>Av';
% %             tcon.convec = bch_constr_tcon([52:59;-1 -1 1 1 1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;          
% %             tcon.name = 'T: P>C: Av>Ap';
% %             tcon.convec = bch_constr_tcon([52:59;1 1 -1 -1 -1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon; 
% %             
% %             tcon.name = 'T: C: Inc>C; P: Av>Ap';
% %             tcon.convec = bch_constr_tcon([52:59;-1 1 1 -1 -1 -1 1 1],nr,bf);
% %             consess{end+1}.tcon = tcon; 
% %             tcon.name = 'T: C: C>Inc; P: Ap>Av';
% %             tcon.convec = bch_constr_tcon([52:59;1 -1 -1 1 1 1 -1 -1],nr,bf);
% %             consess{end+1}.tcon = tcon;   
% 
% 
%             %         otherwise
% %             error('LENVER:NoModel','This model (%s) is not supported yet.',model);
%     %end
%     
% 
% end
%         
end

%==========================================================================
