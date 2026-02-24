function [cfg] = bch_setup_nuisance_regr_ITI(cfg)
%--------------------------------------------------------------------------
% BCH_SETUP_NUISANCE_REGR will add nuisance regressors to your first level
% model. Two possible types of nuisance regressors can be added, head
% motion regressors and compartment signal regressors. The head motion
% regressors are common practive nowadays (Friston et al, 1996; 1998), but
% the compartment signal regressors are not so common in the outside world.
% In the Intention and Action group at the F.C.Donders Centre for Cognitive
% Neuroimaging they have been applied with considerable succes since 2004.
%
% In BCH_INFO_EXP you can select which regressors you would like to use for
% your head motion (translation: 'trans', rotation: 'rot') and compartment
% signal regressors (white matter: 'WM', cerebral spinal fluid 'CSF',\
% out of brain: 'OOB').
%
% Also you can choose which expansion you would like to use for your
% nuisance regressors (rp = realignment parameters; sig = compartment
% signal parameters) You can choose from the basic regressors, the first
% and second order derivatives, and the one scan shifted regressor (Friston
% et al, 1996; 1998: to account for spin-history effects) and all their
% quadratic and cubic Volterra expansions (Lund et al, 2005). Of course you
% can also choose to refrain from using any nuisance regressors all
% together.
%
% Volterra expansion omptions:
% 'linear','quadratic','cubic'
% 'deriv1','deriv1_quadratic','deriv1_cubic'
% 'deriv2','deriv2_quadratic','deriv2_cubic'
% 'spinhist','spinhist_quadratic','spinhist_cubic'
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2008-02-14
%
% adapted for SPM8 wrapper by Inge Volman, April 2011.
%--------------------------------------------------------------------------

ITI = {'ITI_0','ITI_2-4','ITI_2-6','ITI_4-6','ITI_4-8'};


for t = 1:length(ITI)
    
subj_name = cfg.subj;
%regr_dir = fullfile(cfg.fmri.root, cfg.subj, cfg.dir.regr);
mov_dir = fullfile(cfg.fmri.root, cfg.subj, cfg.dir.mov);

regr_dir = fullfile('/project/3011123.05/Synergy/TCG/Pilot/bids/derivatives/results/ITI', ITI{t}, cfg.subj,'regressors');

% Realignment parameters
try
    rp_file = dir(fullfile(mov_dir,[cfg.prefix.regr,'*rp_*']));
    load(fullfile(mov_dir,rp_file(1).name));
catch
    try
        %fprintf('Reading: %s ... ',motionfile(1).name);
        rp_file = dir(fullfile(mov_dir,'rp_*.txt'));
        fid = fopen(fullfile(mov_dir,rp_file(1).name),'r');
        rp = fscanf(fid,' %e %e %e %e %e %e',[6,inf])';
        fclose(fid);
        %fprintf('done\n');
    catch
        warning('LENVER:NoRP','No realignment parameters (regressors) found.');
        regr.rp.names = {};
    end
end
if isfield(cfg,'me')
    rp = rp(cfg.me.pre_vols+1:end,:);
end
regr.rp = get_regr_rp(rp,cfg);

% Compartment signal regressors (comp_sig_spm.m)
try
    sig_file = dir(fullfile(regr_dir,[cfg.prefix.regr,'*sig_*']));
    load(fullfile(regr_dir,sig_file(1).name));
    regr.sig = get_regr_sig(sig,cfg);
catch
    disp('No compartment signal regressors found.');
    regr.sig.names = {};
end

% Sort regressors for SPM8 first level model
if isempty(regr.rp.names) && isemtpy(regr.sig.names)
    regressors = {};
else
    for r = 1:length(regr.rp.names)
        regressors(r).name = regr.rp.names{r};
        regressors(r).val = regr.rp.val(:,r);
    end
    for r = 1:length(regr.sig.names)
        regressors(length(regr.rp.names)+r).name = regr.sig.names{r};
        regressors(length(regr.rp.names)+r).val = regr.sig.val(:,r);
    end
end

save(fullfile(regr_dir,[cfg.prefix.regr,'_',subj_name]),'regressors');

end

    
%==========================================================================

%% function - get_regr_rp
%----------------------------------------------------
function regr_rp = get_regr_rp(rp,cfg)

[px,py] = gradient(rp);
[qx,qy] = gradient(py);

% First order
rp_lin = rp;
rp_deriv1 = py;
rp_deriv2 = qy;
rp_spinhist = [zeros(1,6); rp(1:end-1,:)];

% Second order
rp_sq = rp.^2;
rp_deriv1_sq = rp_deriv1.^2;
rp_deriv2_sq = rp_deriv2.^2;
rp_spinhist_sq = rp_spinhist.^2;

% Third order
rp_cu = rp.^3;
rp_deriv1_cu = rp_deriv1.^3;
rp_deriv2_cu = rp_deriv2.^3;
rp_spinhist_cu = rp_spinhist.^3;

regr_rp.names = {};
regr_rp.val =[];    
for r = 1:length(cfg.regr.rp.exp)
    
    for i = 1:length(cfg.regr.rp.which)
    if strcmpi(cfg.regr.rp.which{i},'trans')
        n = {'x','y','z'};
        idx = 1:3;
    elseif strcmpi(cfg.regr.rp.which{i},'rot')
        n = {'pitch','roll','yaw'};
        idx = 4:6;
    end
        
        
        switch lower(cfg.regr.rp.exp{r})
            case 'none'
            case 'linear'
                regr_rp.names = {regr_rp.names{:},n{1},n{2},n{3}};
                regr_rp.val = [regr_rp.val rp_lin(:,idx)];
            case 'quadratic'
                regr_rp.names = {regr_rp.names{:},[n{1},'^2'],[n{2},'^2'],[n{3},'^2']};
                regr_rp.val = [regr_rp.val rp_sq(:,idx)];
            case 'cubic'
                regr_rp.names = {regr_rp.names{:},[n{1},'^3'],[n{2},'^3'],[n{3},'^3']};
                regr_rp.val = [regr_rp.val rp_cu(:,idx)];
                
            case 'deriv1'
                regr_rp.names = {regr_rp.names{:},['deriv1_',n{1}],['deriv1_',n{2}],['deriv1_',n{3}]};
                regr_rp.val = [regr_rp.val rp_deriv1(:,idx)];
            case 'deriv1_quadratic'
                regr_rp.names = {regr_rp.names{:},['deriv1_',n{1},'^2'],['deriv1_',n{2},'^2'],['deriv1_',n{3},'^2']};
                regr_rp.val = [regr_rp.val rp_deriv1_sq(:,idx)];
            case 'deriv1_cubic'
                regr_rp.names = {regr_rp.names{:},['deriv1_',n{1},'^3'],['deriv1_',n{2},'^3'],['deriv1_',n{3},'^3']};
                regr_rp.val = [regr_rp.val rp_deriv1_cu(:,idx)];
                
            case 'deriv2'
                regr_rp.names = {regr_rp.names{:},['deriv2_',n{1}],['deriv2_',n{2}],['deriv2_',n{3}]};
                regr_rp.val = [regr_rp.val rp_deriv2(:,idx)];
            case 'deriv2_quadratic'
                regr_rp.names = {regr_rp.names{:},['deriv2_',n{1},'^2'],['deriv2_',n{2},'^2'],['deriv2_',n{3},'^2']};
                regr_rp.val = [regr_rp.val rp_deriv2_sq(:,idx)];
            case 'deriv2_cubic'
                regr_rp.names = {regr_rp.names{:},['deriv2_',n{1},'^3'],['deriv2_',n{2},'^3'],['deriv2_',n{3},'^3']};
                regr_rp.val = [regr_rp.val rp_deriv2_cu(:,idx)];
                
            case 'spinhist'
                regr_rp.names = {regr_rp.names{:},['spinhist_',n{1}],['spinhist_',n{2}],['spinhist_',n{3}]};
                regr_rp.val = [regr_rp.val rp_spinhist(:,idx)];
            case 'spinhist_quadratic'
                regr_rp.names = {regr_rp.names{:},['spinhist_',n{1},'^2'],['spinhist_',n{2},'^2'],['spinhist_',n{3},'^2']};
                regr_rp.val = [regr_rp.val rp_spinhist_sq(:,idx)];
            case 'spinhist_cubic'
                regr_rp.names = {regr_rp.names{:},['spinhist_',n{1},'^3'],['spinhist_',n{2},'^3'],['spinhist_',n{3},'^3']};
                regr_rp.val = [regr_rp.val rp_spinhist_cu(:,idx)];
                
            otherwise
                warning('LENVER:NoRP','%s: This type of head motion regressors is not recognized.',cfg.regr.rp.exp{r});
        end

    end
       
end
%==========================================================================


%% function - get_regr_sig
%----------------------------------------------------
function regr_sig = get_regr_sig(sig,cfg)

[px,py] = gradient(sig);
[qx,qy] = gradient(py);

% First order
sig_lin = sig;
sig_deriv1 = py;
sig_deriv2 = qy;
sig_spinhist = [zeros(1,3); sig(1:end-1,:)];

% Second order
sig_sq = sig.^2;
sig_deriv1_sq = sig_deriv1.^2;
sig_deriv2_sq = sig_deriv2.^2;
sig_spinhist_sq = sig_spinhist.^2;

% Third order
sig_cu = sig.^3;
sig_deriv1_cu = sig_deriv1.^3;
sig_deriv2_cu = sig_deriv2.^3;
sig_spinhist_cu = sig_spinhist.^3;

regr_sig.names = {};
regr_sig.val =[];    
for r = 1:length(cfg.regr.sig.exp)
        
    for c = 1:length(cfg.regr.sig.which)
        
        comp = cfg.regr.sig.which{c};
        if strcmpi(comp,'WM')
            i = 1;
        elseif strcmpi(comp,'CSF')
            i = 2;
        elseif strcmpi(comp,'OOB')
            i = 3;
        else
            warning('LENVER:NoRP','%s: This type of compartment signal regressors is not recognized.',comp);
        end
                
        switch lower(cfg.regr.sig.exp{r})
            case 'none'
            case 'linear'
                regr_sig.names = {regr_sig.names{:},comp};
                regr_sig.val = [regr_sig.val sig_lin(:,i)];
            case 'quadratic'
                regr_sig.names = {regr_sig.names{:},[comp,'^2']};
                regr_sig.val = [regr_sig.val sig_sq(:,i)];
            case 'cubic'
                regr_sig.names = {regr_sig.names{:},[comp,'^3']};
                regr_sig.val = [regr_sig.val sig_cu(:,i)];
            
            case 'deriv1'
                regr_sig.names = {regr_sig.names{:},['deriv1_',comp]};
                regr_sig.val = [regr_sig.val sig_deriv1(:,i)];
            case 'deriv1_quadratic'
                regr_sig.names = {regr_sig.names{:},['deriv1_',comp,'^2']};
                regr_sig.val = [regr_sig.val sig_deriv1_sq(:,i)];
            case 'deriv1_cubic'
                regr_sig.names = {regr_sig.names{:},['deriv1_',comp,'^3']};
                regr_sig.val = [regr_sig.val sig_deriv1_cu(:,i)];
                
            case 'deriv2'
                regr_sig.names = {regr_sig.names{:},['deriv2_',comp]};
                regr_sig.val = [regr_sig.val sig_deriv2(:,i)];
            case 'deriv2_quadratic'
                regr_sig.names = {regr_sig.names{:},['deriv2_',comp,'^2']};
                regr_sig.val = [regr_sig.val sig_deriv2_sq(:,i)];
            case 'deriv2_cubic'
                regr_sig.names = {regr_sig.names{:},['deriv2_',comp,'^3']};
                regr_sig.val = [regr_sig.val sig_deriv2_cu(:,i)];
                
            case 'spinhist'
                regr_sig.names = {regr_sig.names{:},['spinhist_',comp]};
                regr_sig.val = [regr_sig.val sig_spinhist(:,i)];
            case 'spinhist_quadratic'
                regr_sig.names = {regr_sig.names{:},['spinhist_',comp,'^2']};
                regr_sig.val = [regr_sig.val sig_spinhist_sq(:,i)];
            case 'spinhist_cubic'
                regr_sig.names = {regr_sig.names{:},['spinhist_',comp,'^3']};
                regr_sig.val = [regr_sig.val sig_spinhist_cu(:,i)];
            
            otherwise
                warning('LENVER:NoRP','%s-%s: This type of compartment signal regressors is not recognized.',comp,cfg.regr.sig.exp{r});
        end

    end
    
end
%==========================================================================