function [cfg] = bch_copy_ppi_cons(cfg)
%--------------------------------------------------------------------------
% BCH_ORG_CP_CONS copies the contrast images from the first level analyses
% of each subject to a subfolder con_images in the group_analysis
% directory. Can't go wrong, right?
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2008-4-3
% adapted by Inge, 2012 for PPI analysis
%--------------------------------------------------------------------------

ana_dir = fullfile(cfg.dir.root, cfg.subj,cfg.dir.ana, cfg.model1,'ppi',['VOI_' cfg.voi.spec.names{1}],cfg.ppi.name);
%ana_dir = fullfile(cfg.dir.root,cfg.subj,cfg.dir.ana,cfg.model1);
groupana_dir = strrep(cfg.dir.groupana,cfg.model1,'');
%groupana_dir = strrep(cfg.dir.groupana,cfg.design2,'');
load(fullfile(ana_dir,'SPM.mat'));
ncon = 0;
for c = 1:length(SPM.xCon)
    if strcmp(SPM.xCon(c).STAT,'T')
        ncon = ncon + 1;
        con_name{ncon} = corrdirname(SPM.xCon(c).name);
        con_str{ncon} = sprintf('con_%0.4d',c);
        con_dir{ncon} = fullfile(cfg.dir.root,groupana_dir,cfg.model1,'ppi',['VOI_' cfg.voi.spec.names{1}],cfg.ppi.name,'con_images_group',[con_name{ncon}]);
        if ~exist(con_dir{ncon},'dir')
            mkdir(con_dir{ncon});
        end
    end
end

for c = 1:ncon
    con_image = dir(fullfile(ana_dir,[con_str{c},'.*']));
    for i = 1:length(con_image)
        ext = con_image(i).name(end-3:end);
        %new_con_image = [con_str{c},' - ',con_name{c},' - ',INFO.subjects{s},ext];
        new_con_image = [cfg.grouptype, ' - ', cfg.subj,' - ', con_str{c},' - ',con_name{c},ext];
        %new_con_image = [cfg.subj,' - ', con_str{c},' - ',con_name{c},ext];
        new_con_image = fullfile(con_dir{c},new_con_image);
        copyfile(fullfile(ana_dir,con_image(i).name),new_con_image);
    end
end

%--------------------------------------------------------------------------