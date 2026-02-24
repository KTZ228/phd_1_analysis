function [cfg] = bch_create_ppi_model2(cfg)

% Open SPM8 and select 2st level specification.   
% Do not change anything and save this as 'model1_spec' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get directories
model_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi, cfg.model2);
if ~exist(model_dir,'dir'); mkdir(model_dir);end

save_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi);
    
% assign group type
grouptype = cell(1,length(cfg.subjects));
grouptype(ismember(cfg.subjects,cfg.controls)) = {'1'};
grouptype(ismember(cfg.subjects,cfg.patients)) = {'2'};

% setup design
if any(strcmp(cfg.model2,{'Mult_regr_H_A_T'}))
    factors = {'happy','angry'};
    con_dir{1} = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi, 'Hap_IncvsC', cfg.dir.con);
    con_dir{2} = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi, 'Ang_IncvsC', cfg.dir.con);
end

scans = [];
for f = 1:length(factors)
    confact_dir = fullfile(con_dir{f}, 'ppi  (T)');
     for g = 1:max(str2double(grouptype))
         % create group variables
        %con_name = [grouptype{s}, ' - ', cfg.subjects{s}];
        %con_image = dir(fullfile(confact_dir,[con_name,'*.img']));
        %con_name = [grouptype{s}, ' - ', cfg.subjects{s}];
        group = cfg.subjects(strcmp(grouptype,num2str(g)));
        for s = 1:length(group)
            img_prefix = ['^',[num2str(g)  ' - ', group{s}],cfg.prefix.img];
            con_image = cfg_getfile('ExtFPList',confact_dir,img_prefix);
            %con_image = dir(fullfile(confact_dir,[num2str(g)  ' - ', group{s},'*.img']));
            scans = [scans; con_image];
        end
     end
end

% get factor covariates
nr_controls = sum(ismember(cfg.controls,cfg.subjects));
nr_patients = sum(ismember(cfg.patients,cfg.subjects));

for f = 1:length(factors)
    mcov(f).c       = [zeros((f-1)*length(cfg.subjects),1)' ones(1,nr_controls)...
        zeros((length(scans)-(nr_controls+((f-1)*length(cfg.subjects)))),1)'];
    mcov(f).cname   = ['C-' factors{f}];
    mcov(length(factors)+f).c = [zeros(nr_controls+((f-1)*length(cfg.subjects)),1)'...
        ones(1,nr_patients) zeros((length(scans)-(length(cfg.subjects)+((f-1)*length(cfg.subjects)))),1)'];
    mcov(length(factors)+f).cname = ['P-' factors{f}];
end

% get factor covariates
for g = 1:max(str2double(grouptype))
    group = cfg.subjects(strcmp(grouptype,num2str(g)));
    for s = 1:length(group) 
        length_prev = length(cfg.subjects(strcmp(grouptype,num2str(g-1))));
        mcov(2*length(factors)+((g-1)*length_prev)+s).c     = repmat([zeros(((g-1)*length_prev)+(s-1),1)' ones(1,1) zeros((length(cfg.subjects)-1-(((g-1)*length_prev)+s-1)),1)'],1,length(factors));
        mcov(2*length(factors)+((g-1)*length_prev)+s).cname = group{s};
    end
end

% add regressors for the hormone factors Cortisol and Testosterone
if any(strcmp(cfg.model2,{'Mult_regr_H_A_T'}))
    % assign hormones
    hormones.name = {'Test'};
    hormones.C.val{1} = cfg.test(1:length(cfg.controls))';
    hormones.C.val{1} = hormones.C.val{1}(ismember(cfg.controls,cfg.subjects));
    hormones.P.val{1} = cfg.test(length(cfg.controls)+1:end)';
    hormones.P.val{1} = hormones.P.val{1}(ismember(cfg.patients,cfg.subjects));
    
    for h = 1:length(hormones.name)
        for f = 1:length(factors)
            mcov(f+h*2*length(factors)+length(cfg.subjects)).c       = [zeros((f-1)*length(cfg.subjects),1)' hormones.C.val{h}...
                    zeros((length(scans)-(nr_controls+((f-1)*length(cfg.subjects)))),1)'];
                mcov(f+h*2*length(factors)+length(cfg.subjects)).cname   = ['C_' hormones.name{h} '_' factors{f}];
                mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).c = [zeros(nr_controls+((f-1)*length(cfg.subjects)),1)'...
                    hormones.P.val{h} zeros((length(scans)-(length(cfg.subjects)+((f-1)*length(cfg.subjects)))),1)'];
                mcov(length(factors)+f+h*2*length(factors)+length(cfg.subjects)).cname = ['P_' hormones.name{h} '_' factors{f}];
          
        end
    end
end


% load basic matlab batch of SPM8
load(fullfile(cfg.dir.root,cfg.preproc));

% fill matlabbatch
matlabbatch{1}.spm.stats.factorial_design.dir = {model_dir};
matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = scans;
matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov = mcov;

fname = [cfg.preproc '.mat'];
save(fullfile(save_dir,fname), 'matlabbatch');



