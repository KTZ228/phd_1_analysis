function [cfg] = bch_get_con2_RK(cfg)
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
%
%
% Adapted for PIA Reinoud Kaldewaij July 2016
%
%--------------------------------------------------------------------------

model = cfg.model1;
design = cfg.model2;

% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill in reference to model.
model_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.model2);
spm_file = fullfile(model_dir,'SPM.mat');
matlabbatch{1}.spm.stats.con.spmmat = {spm_file};

% load model
load(spm_file);
nr{1} = [length(SPM.xX.name) 0 1];
matlabbatch{1}.spm.stats.con.consess = get_con(model,design,nr,1);

fname = [cfg.preproc '.mat'];
save_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1);
save(fullfile(save_dir,fname), 'matlabbatch');

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
    
    case {'Mult_regr_H_A','Mult_regr_H_A_T','Mult_regr_H_A_T_Cor','Mult_regr_H_A_T_Cor_simple'}
        
        % F-contrasts
        %         nr{1}(3) = 1;
        %
        %         fcon.name = 'Effects of Interest (F)';
        %         %fcon.convec = {bch_constr_fcon(1:8),105,1,incl};
        %         fcon.convec = {bch_constr_fcon(2:5,nr,bf)};
        %         %fcon.convec = {bch_constr_fcon(1:5,nr,bf)};
        %         %fcon.convec = {bch_constr_fcon(2:9,{[44 0 1]},bf,incl)};
        %         consess{1}.fcon = fcon;
        
        % T-contrasts
        nr{1}(3) = 1;
        if strcmp(design,{'Mult_regr_H_A_T'})
            test_cons = (nr{1}(1) - 3):nr{1}(1);
        elseif strcmp(design,{'Mult_regr_H_A_T_Cor'})
            test_cons = (nr{1}(1) - 7):(nr{1}(1) - 4);
            cort_cons = (nr{1}(1) - 3):nr{1}(1);
        elseif strcmp(design,{'Mult_regr_H_A_T_Cor_simple'})
            test_cons = nr{1}(1) - 1;
            cort_cons = nr{1}(1);
        end
        
        
        tcon.name = 'Inc>C';
        tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
        consess{1}.tcon = tcon;
        tcon.name = 'C>Inc';
        tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        
        tcon.name = 'Hap: Inc>C';
        tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'Hap: C>Inc';
        tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'Ang: Inc>C';
        tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'Ang: C>Inc';
        tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
        consess{end+1}.tcon = tcon;
        
        if any(strcmp(design,{'Mult_regr_H_A_T','Mult_regr_H_A_T_Cor'}))
            
            tcon.name = 'Test: Inc>C';
            tcon.convec = bch_constr_tcon([test_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: C>Inc';
            tcon.convec = bch_constr_tcon([test_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            tcon.name = 'Test: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([test_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([test_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([test_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([test_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
        end
        
        if strcmp(design,{'Mult_regr_H_A_T_Cor'})
            
            tcon.name = 'Cort: Inc>C';
            tcon.convec = bch_constr_tcon([cort_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: C>Inc';
            tcon.convec = bch_constr_tcon([cort_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            tcon.name = 'Cort: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([cort_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([cort_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([cort_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([cort_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            
        end
        
        %         if strcmp(design,{'Mult_regr_H_A_T_Cor_simple'})
        %
        %             tcon.name = 'Test';
        %             tcon.convec = bch_constr_tcon([test_cons;1],nr,bf);
        %             consess{end+1}.tcon = tcon;
        %
        %             tcon.name = 'Cort';
        %             tcon.convec = bch_constr_tcon([cort_cons;1],nr,bf);
        %             consess{end+1}.tcon = tcon;
        %         end
        
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
        
        
        
        
    case {'Mult_regr_H_A_gender','Mult_regr_H_A_gender_T_Cor','Mult_regr_H_A_gender_QuestScore'}
        
        
        % F-contrasts
        %            nr{1}(3) = 1;
        %            fcon.name = 'Effects of Interest (F)';
        %            fcon.convec = {bch_constr_fcon(2:5)};
        %fcon.convec = {bch_constr_fcon(1:8),105,1,incl};
        %fcon.convec = {bch_constr_fcon(2:72,nr,bf)};
        %fcon.convec = {bch_constr_fcon(2:9,{[44 0 1]},bf,incl)};
        %            consess{1}.fcon = fcon;
        
        % T-contrasts
        nr{1}(3) = 1;
             
        tcon.name = 'Inc>C';
        tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 1 1 -1],nr,bf);
        consess{1}.tcon = tcon;
        tcon.name = 'C>Inc';
        tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 -1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: Inc>C';
        tcon.convec = bch_constr_tcon([2:5;-1 1 1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: C>Inc';
        tcon.convec = bch_constr_tcon([2:5;1 -1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Inc>C';
        tcon.convec = bch_constr_tcon([6:9;-1 1 1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: C>Inc';
        tcon.convec = bch_constr_tcon([6:9;1 -1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F>M: Inc>C';
        tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 -1 1 1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F>M: C>Inc';
        tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 1 -1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        
        tcon.name = 'M: Hap: Inc>C';
        tcon.convec = bch_constr_tcon([2:5;-1 0 1 0],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: Hap: C>Inc';
        tcon.convec = bch_constr_tcon([2:5;1 0 -1 0],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: Ang: Inc>C';
        tcon.convec = bch_constr_tcon([2:5;0 1 0 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: Ang: C>Inc';
        tcon.convec = bch_constr_tcon([2:5;0 -1 0 1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Hap: Inc>C';
        tcon.convec = bch_constr_tcon([6:9;-1 0 1 0],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Hap: C>Inc';
        tcon.convec = bch_constr_tcon([6:9;1 0 -1 0],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Ang: Inc>C';
        tcon.convec = bch_constr_tcon([6:9;0 1 0 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Ang: C>Inc';
        tcon.convec = bch_constr_tcon([6:9;0 -1 0 1],nr,bf);
        consess{end+1}.tcon = tcon;
        
        %     tcon.name = 'G>B: Hap: Inc>C';
        %     tcon.convec = bch_constr_tcon([2:9;1 0 -1 0 -1 0 1 0],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %     tcon.name = 'G>B: Hap: C>Inc';
        %     tcon.convec = bch_constr_tcon([2:9;-1 0 1 0 1 0 -1 0],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %     tcon.name = 'G>B: Ang: Inc>C';
        %     tcon.convec = bch_constr_tcon([2:9;0 -1 0 1 0 1 0 -1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %     tcon.name = 'G>B: Ang: C>Inc';
        %     tcon.convec = bch_constr_tcon([2:9;0 1 0 -1 0 -1 0 1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        
        tcon.name = 'M: Hap>Ang';
        tcon.convec = bch_constr_tcon([2:5;1 -1 1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: Ang>Hap';
        tcon.convec = bch_constr_tcon([2:5;-1 1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Hap>Ang';
        tcon.convec = bch_constr_tcon([6:9;1 -1 1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Ang>Hap';
        tcon.convec = bch_constr_tcon([6:9;-1 1 -1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        
        %     tcon.name = 'G>B: Hap>Ang';
        %     tcon.convec = bch_constr_tcon([2:9;-1 1 -1 1 1 -1 1 -1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %     tcon.name = 'G>B: Ang>Hap';
        %     tcon.convec = bch_constr_tcon([2:9;1 -1 1 -1 -1 1 -1 1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        
        
        tcon.name = 'M: Ap>Av';
        tcon.convec = bch_constr_tcon([2:5;1 1 -1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'M: Av>Ap';
        tcon.convec = bch_constr_tcon([2:5;-1 -1 1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Ap>Av';
        tcon.convec = bch_constr_tcon([6:9;1 1 -1 -1],nr,bf);
        consess{end+1}.tcon = tcon;
        tcon.name = 'F: Av>Ap';
        tcon.convec = bch_constr_tcon([6:9;-1 -1 1 1],nr,bf);
        consess{end+1}.tcon = tcon;
        %     tcon.name = 'G>B: Ap>Av';
        %     tcon.convec = bch_constr_tcon([2:9;-1 -1 1 1 1 1 -1 -1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %     tcon.name = 'G>B: Av>Ap';
        %     tcon.convec = bch_constr_tcon([2:9;1 1 -1 -1 -1 -1 1 1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        
        %     tcon.name = 'B: Inc>C; G: Av>Ap';
        %     tcon.convec = bch_constr_tcon([2:9;-1 1 1 -1 -1 -1 1 1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %     tcon.name = 'B: C>Inc; G: Ap>Av';
        %     tcon.convec = bch_constr_tcon([2:9;1 -1 -1 1 1 1 -1 -1],nr,bf);
        %     consess{end+1}.tcon = tcon;
        %
        
        
        if any(strcmp(design,{'Mult_regr_H_A_gender_T_Cor'}))
            
            test_B_cons = (nr{1}(1) - 15):(nr{1}(1) - 12);
            test_G_cons = (nr{1}(1) - 11):(nr{1}(1) - 8);
            cort_B_cons = (nr{1}(1) - 7) :(nr{1}(1) - 4);
            cort_G_cons = (nr{1}(1) - 3) : nr{1}(1);
            
            
            tcon.name = 'Test: Inc>C';
            tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];-1 1 1 -1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: C>Inc';
            tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];1 -1 -1 1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: Inc>C';
            tcon.convec = bch_constr_tcon([test_B_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: C>Inc';
            tcon.convec = bch_constr_tcon([test_B_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Inc>C';
            tcon.convec = bch_constr_tcon([test_G_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: C>Inc';
            tcon.convec = bch_constr_tcon([test_G_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G>B: Inc>C';
            tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];1 -1 -1 1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G>B: C>Inc';
            tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];-1 1 1 -1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            tcon.name = 'Test: B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([test_B_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([test_B_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([test_B_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([test_B_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([test_G_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([test_G_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([test_G_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([test_G_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            %     tcon.name = 'Test: G>B: Hap: Inc>C';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];1 0 -1 0 -1 0 1 0],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Hap: C>Inc';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];-1 0 1 0 1 0 -1 0],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Ang: Inc>C';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];0 -1 0 1 0 1 0 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Ang: C>Inc';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];0 1 0 -1 0 -1 0 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            
            tcon.name = 'Test: B: Hap>Ang';
            tcon.convec = bch_constr_tcon([test_B_cons,;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: Ang>Hap';
            tcon.convec = bch_constr_tcon([test_B_cons,;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Hap>Ang';
            tcon.convec = bch_constr_tcon([test_G_cons;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Ang>Hap';
            tcon.convec = bch_constr_tcon([test_G_cons;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Hap>Ang';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];-1 1 -1 1 1 -1 1 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Ang>Hap';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];1 -1 1 -1 -1 1 -1 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %
            
            tcon.name = 'Test: B: Ap>Av';
            tcon.convec = bch_constr_tcon([test_B_cons;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: B: Av>Ap';
            tcon.convec = bch_constr_tcon([test_B_cons;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Ap>Av';
            tcon.convec = bch_constr_tcon([test_G_cons;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Test: G: Av>Ap';
            tcon.convec = bch_constr_tcon([test_G_cons;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Ap>Av';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];-1 -1 1 1 1 1 -1 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: G>B: Av>Ap';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];1 1 -1 -1 -1 -1 1 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            
            %     tcon.name = 'Test: B: Inc>C; G: Av>Ap';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];-1 1 1 -1 -1 -1 1 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Test: B: C>Inc; G: Ap>Av';
            %     tcon.convec = bch_constr_tcon([[test_B_cons,test_G_cons];1 -1 -1 1 1 1 -1 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            
            tcon.name = 'Cort: Inc>C';
            tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];-1 1 1 -1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: C>Inc';
            tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];1 -1 -1 1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: Inc>C';
            tcon.convec = bch_constr_tcon([cort_B_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: C>Inc';
            tcon.convec = bch_constr_tcon([cort_B_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Inc>C';
            tcon.convec = bch_constr_tcon([cort_G_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: C>Inc';
            tcon.convec = bch_constr_tcon([cort_G_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G>B: Inc>C';
            tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];1 -1 -1 1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G>B: C>Inc';
            tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];-1 1 1 -1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            tcon.name = 'Cort: B: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([cort_B_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([cort_B_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([cort_B_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([cort_B_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([cort_G_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([cort_G_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([cort_G_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([cort_G_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            %     tcon.name = 'Cort: G>B: Hap: Inc>C';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];1 0 -1 0 -1 0 1 0],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Hap: C>Inc';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];-1 0 1 0 1 0 -1 0],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Ang: Inc>C';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];0 -1 0 1 0 1 0 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Ang: C>Inc';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];0 1 0 -1 0 -1 0 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            
            tcon.name = 'Cort: B: Hap>Ang';
            tcon.convec = bch_constr_tcon([cort_B_cons;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: Ang>Hap';
            tcon.convec = bch_constr_tcon([cort_B_cons;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Hap>Ang';
            tcon.convec = bch_constr_tcon([cort_G_cons;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Ang>Hap';
            tcon.convec = bch_constr_tcon([cort_G_cons;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Hap>Ang';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];-1 1 -1 1 1 -1 1 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Ang>Hap';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];1 -1 1 -1 -1 1 -1 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            
            
            tcon.name = 'Cort: B: Ap>Av';
            tcon.convec = bch_constr_tcon([cort_B_cons;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: B: Av>Ap';
            tcon.convec = bch_constr_tcon([cort_B_cons;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Ap>Av';
            tcon.convec = bch_constr_tcon([cort_G_cons;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Cort: G: Av>Ap';
            tcon.convec = bch_constr_tcon([cort_G_cons;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Ap>Av';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];-1 -1 1 1 1 1 -1 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: G>B: Av>Ap';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];1 1 -1 -1 -1 -1 1 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            
            %     tcon.name = 'Cort: B: Inc>C; G: Av>Ap';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];-1 1 1 -1 -1 -1 1 1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %     tcon.name = 'Cort: B: C>Inc; G: Ap>Av';
            %     tcon.convec = bch_constr_tcon([[cort_B_cons,cort_G_cons];1 -1 -1 1 1 1 -1 -1],nr,bf);
            %     consess{end+1}.tcon = tcon;
            %
            
        end
        
        if any(strcmp(design,{'Mult_regr_H_A_gender_QuestScore'}))
            
            Quest_M_cons = (nr{1}(1) - 7) :(nr{1}(1) - 4);
            Quest_F_cons = (nr{1}(1) - 3) : nr{1}(1);
            
            tcon.name = 'Quest: Inc>C';
            tcon.convec = bch_constr_tcon([[Quest_M_cons,Quest_F_cons];-1 1 1 -1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: C>Inc';
            tcon.convec = bch_constr_tcon([[Quest_M_cons,Quest_F_cons];1 -1 -1 1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: Inc>C';
            tcon.convec = bch_constr_tcon([Quest_M_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: C>Inc';
            tcon.convec = bch_constr_tcon([Quest_M_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Inc>C';
            tcon.convec = bch_constr_tcon([Quest_F_cons;-1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: C>Inc';
            tcon.convec = bch_constr_tcon([Quest_F_cons;1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F>M: Inc>C';
            tcon.convec = bch_constr_tcon([[Quest_M_cons,Quest_F_cons];1 -1 -1 1 -1 1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F>M: C>Inc';
            tcon.convec = bch_constr_tcon([[Quest_M_cons,Quest_F_cons];-1 1 1 -1 1 -1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            tcon.name = 'Quest: M: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([Quest_M_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([Quest_M_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([Quest_M_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([Quest_M_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Hap: Inc>C';
            tcon.convec = bch_constr_tcon([Quest_F_cons;-1 0 1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Hap: C>Inc';
            tcon.convec = bch_constr_tcon([Quest_F_cons;1 0 -1 0],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Ang: Inc>C';
            tcon.convec = bch_constr_tcon([Quest_F_cons;0 1 0 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Ang: C>Inc';
            tcon.convec = bch_constr_tcon([Quest_F_cons;0 -1 0 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
            tcon.name = 'Quest: M: Hap>Ang';
            tcon.convec = bch_constr_tcon([Quest_M_cons;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: Ang>Hap';
            tcon.convec = bch_constr_tcon([Quest_M_cons;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Hap>Ang';
            tcon.convec = bch_constr_tcon([Quest_F_cons;1 -1 1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Ang>Hap';
            tcon.convec = bch_constr_tcon([Quest_F_cons;-1 1 -1 1],nr,bf);
            consess{end+1}.tcon = tcon;
                        
            tcon.name = 'Quest: M: Ap>Av';
            tcon.convec = bch_constr_tcon([Quest_M_cons;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: M: Av>Ap';
            tcon.convec = bch_constr_tcon([Quest_M_cons;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Ap>Av';
            tcon.convec = bch_constr_tcon([Quest_F_cons;1 1 -1 -1],nr,bf);
            consess{end+1}.tcon = tcon;
            tcon.name = 'Quest: F: Av>Ap';
            tcon.convec = bch_constr_tcon([Quest_F_cons;-1 -1 1 1],nr,bf);
            consess{end+1}.tcon = tcon;
            
        
        end    
        
        
end

end

%==========================================================================
