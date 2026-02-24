function [cfg] = bch_create_model2(cfg)

% Open SPM8 and select 2st level specification.   
% Do not change anything and save this as 'model1_spec' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get directories
model_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.model2);
if ~exist(model_dir,'dir'); mkdir(model_dir);end

con_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.con);
save_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1);
    
%assign group type
% grouptype = cell(1,length(cfg.subjects));
% grouptype(ismember(cfg.subjects,cfg.boys)) = {'1'};
% grouptype(ismember(cfg.subjects,cfg.girls)) = {'2'};

% setup design
if any(strcmp(cfg.model2,{'Mult_regr_H_A', 'Mult_regr_H_A_gender','Mult_regr_H_A_gender_T_Cor', 'Mult_regr_H_A_gender_TCortRatio'}))
    factors = {'ApprH','ApprA','AvoidH','AvoidA'};
elseif any(strcmp(cfg.model2,{'Mult_regr_H_A_STAIst_T_no66_baseline'})) 
    factors = {'ApprH','ApprA','AvoidH','AvoidA','Baseline'};
end

scans = [];


%group indexes
% idx_boys = find(cfg.gender.gender_cov == 0);
% idx_girls = find(cfg.gender.gender_cov ==1);


for f = 1:length(factors)
    confact_dir = fullfile(con_dir, [factors{f} '  (T)']);
    img_prefix = cfg.prefix.img;
    con_image =  cfg_getfile('FPList',confact_dir,'any',img_prefix);
    
    if any(strcmp(cfg.model2,{'Mult_regr_H_A_gender','Mult_regr_H_A_gender_T_Cor', 'Mult_regr_H_A_gender_TCortRatio'}))
        con_image = [con_image(idx_boys,:);con_image(idx_girls,:)]; %order according to group
        scans = [scans; con_image];
    elseif any(strcmp(cfg.model2,{'Mult_regr_H_A'}))
        scans = [scans; con_image];
    end
    
end

    
% factor covariates
if any (strcmp(cfg.model2,{'Mult_regr_H_A'}))
    
    for f = 1:length(factors)
        mcov(f).c = [zeros((f-1)*length(cfg.subjects),1)' ones(1,length(cfg.subjects)) zeros((length(scans) - (length(cfg.subjects)*f)),1)'];
        mcov(f).cname = [factors{f}];
    end  
% subj factor
    for s = 1:length(cfg.subjects)
        mcov(length(factors)+s).c = repmat([zeros((s-1),1)' ones(1,1) zeros((length(cfg.subjects)-s),1)'],1,length(factors));
        mcov(length(factors)+s).cname = cfg.subjects{s};
    end
   
elseif any(strcmp(cfg.model2,{'Mult_regr_H_A_gender','Mult_regr_H_A_gender_T_Cor' , 'Mult_regr_H_A_gender_TCortRatio'}))
    for f = 1:length(factors)
        mcov(f).c       = [zeros((f-1)*length(cfg.subjects),1)' ones(1,length(idx_boys)) zeros((length(scans)-(length(idx_boys)+((f-1)*length(cfg.subjects)))),1)'];
        mcov(f).cname   = ['B-' factors{f}];
        mcov(length(factors)+f).c = [zeros(length(idx_boys)+((f-1)*length(cfg.subjects)),1)' ones(1,length(idx_girls)) zeros((length(scans)-(length(cfg.subjects)+((f-1)*length(cfg.subjects)))),1)'];
        mcov(length(factors)+f).cname = ['G-' factors{f}];
    end
    % get factor covariates for subjects
    for g = 1:max(str2double(grouptype))
        group = cfg.subjects(strcmp(grouptype,num2str(g)));
        for s = 1:length(group)
            length_prev = length(cfg.subjects(strcmp(grouptype,num2str(g-1))));
            mcov(2*length(factors)+((g-1)*length_prev)+s).c     = repmat([zeros(((g-1)*length_prev)+(s-1),1)' ones(1,1) zeros((length(cfg.subjects)-1-(((g-1)*length_prev)+s-1)),1)'],1,length(factors));
            mcov(2*length(factors)+((g-1)*length_prev)+s).cname = group{s};
        end
    end
end
   %%%% 'Mult_regr_H_A_gender_T_Cor' model - MAKE COVARIATES FOR TESTOSTERONE
   %%%% THAT ARE STANDARDIZED PER GROUP (N=47)

%   cfg.tes_B = cfg.test.Z_log_tes_47(idx_boys,:);
%   cfg.tes_G = cfg.test.Z_log_tes_47(idx_girls,:);
%   cfg.cort_B = cfg.cort.Z_log_cort_47(idx_boys,:);
%   cfg.cort_G = cfg.cort.Z_log_cort_47(idx_girls,:);
  
%The mean of the factors of each groups should be 0.
if any(strcmp(cfg.model2,{'Mult_regr_H_A_gender_T_Cor'}))
    % assign hormones
    hormones.name = {'Test','Cort'};
    hormones.B.val{1} = cfg.tes_B';
    hormones.G.val{1} = cfg.tes_G';
    hormones.B.val{2} = cfg.cort_B';
    hormones.G.val{2} = cfg.cort_G';
        
    for h = 1:length(hormones.name)
        for f = 1:length(factors)
            mcov(f+h*2*length(factors)+length(cfg.subjects)).c       = [zeros((f-1)*length(cfg.subjects),1)' hormones.B.val{h}...
                    zeros((length(scans)-(length(idx_boys)+((f-1)*length(cfg.subjects)))),1)'];
                mcov(f+h*2*length(factors)+length(cfg.subjects)).cname   = ['B_' hormones.name{h} '_' factors{f}];
                mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).c = [zeros(length(idx_boys)+((f-1)*length(cfg.subjects)),1)'...
                    hormones.G.val{h} zeros((length(scans)-(length(cfg.subjects)+((f-1)*length(cfg.subjects)))),1)'];
                mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).cname = ['G_' hormones.name{h} '_' factors{f}];
          
        end
    end
end

% test/cortisol ratio model
% cfg.tescort_B = cfg.tcort_ratio.Z_log_tcort_ratio_47(idx_boys,:);
% cfg.tescort_G = cfg.tcort_ratio.Z_log_tcort_ratio_47(idx_girls,:);

if any(strcmp(cfg.model2,{'Mult_regr_H_A_gender_TCortRatio'}))
    % assign hormones
    hormones.name = {'TCort_ratio'};
    hormones.B.val{1} = cfg.tescort_B';
    hormones.G.val{1} = cfg.tescort_G';
    
        
    for h = 1:length(hormones.name)
        for f = 1:length(factors)
            mcov(f+h*2*length(factors)+length(cfg.subjects)).c       = [zeros((f-1)*length(cfg.subjects),1)' hormones.B.val{h}...
                    zeros((length(scans)-(length(idx_boys)+((f-1)*length(cfg.subjects)))),1)'];
                mcov(f+h*2*length(factors)+length(cfg.subjects)).cname   = ['B_' hormones.name{h} '_' factors{f}];
                mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).c = [zeros(length(idx_boys)+((f-1)*length(cfg.subjects)),1)'...
                    hormones.G.val{h} zeros((length(scans)-(length(cfg.subjects)+((f-1)*length(cfg.subjects)))),1)'];
                mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).cname = ['G_' hormones.name{h} '_' factors{f}];
          
        end
    end
end



% if any(strcmp(cfg.model2,{'Mult_regr_H_A_T_no66','Mult_regr_H_A_T_no51_no66'}))
%     % assign hormones
%     hormones.name = {'Test'};
%     hormones.C.val{1} = cfg.C_test';
%     hormones.P.val{1} = cfg.P_test';
%     if any(strcmp(cfg.model2,{'Mult_regr_H_A_T_no51_no66'}))
%        hormones.P.val{1} = hormones.P.val{1}(2:end);
%     end
%     
%     for h = 1:length(hormones.name)
%         for f = 1:length(factors)
%             mcov(f+h*2*length(factors)+length(cfg.subjects)).c       = [zeros((f-1)*length(cfg.subjects),1)' hormones.C.val{h}...
%                     zeros((length(scans)-(nr_controls+((f-1)*length(cfg.subjects)))),1)'];
%                 mcov(f+h*2*length(factors)+length(cfg.subjects)).cname   = ['C_' hormones.name{h} '_' factors{f}];
%                 mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).c = [zeros(nr_controls+((f-1)*length(cfg.subjects)),1)'...
%                     hormones.P.val{h} zeros((length(scans)-(length(cfg.subjects)+((f-1)*length(cfg.subjects)))),1)'];
%                 mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).cname = ['P_' hormones.name{h} '_' factors{f}];
%           
%         end
%     end
% end

% load basic matlab batch of SPM12
load(fullfile(cfg.dir.root,cfg.preproc));

% fill matlabbatch
matlabbatch{1}.spm.stats.factorial_design.dir = {model_dir};
matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = scans;
matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov = mcov;
% if any(strcmp(cfg.model2,{'BothSess_H_A_Cort_T_40_gender'}))
%     matlabbatch{1}.spm.stats.factorial_design.cov = cov;
% end

fname = [cfg.preproc '.mat'];
save(fullfile(save_dir,fname), 'matlabbatch');



