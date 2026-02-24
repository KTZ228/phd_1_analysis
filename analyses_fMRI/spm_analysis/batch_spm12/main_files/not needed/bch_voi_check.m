function [cfg] = bch_voi_check(cfg)

VOIcheck_dir = fullfile(cfg.dir.root,cfg.dir.groupana,'VOIcheck');
if ~exist(VOIcheck_dir,'dir'); mkdir(VOIcheck_dir); end

for v = 1:length(cfg.voi.spec.names)
    clear VOIcheck;
    
    for s = 1:length(cfg.subjects)
        
        if exist(fullfile(cfg.dir.root,cfg.subjects{s},cfg.dir.ana,cfg.model1,['VOI_' cfg.voi.spec.names{v} '_1.mat']),'file')
            load(fullfile(cfg.dir.root,cfg.subjects{s},cfg.dir.ana,cfg.model1,['VOI_' cfg.voi.spec.names{v} '_1']));
            
            VOIcheck.xyz(s,:) = xY.xyz;
            VOIcheck.XYZmm{s}(:,:) = xY.XYZmm;
            VOIcheck.n(s,1) = length(xY.XYZmm);
            if VOIcheck.n(s,1)>=cfg.voi.jump.minvox
                VOIcheck.ok(s,1) = 1;
            else
                VOIcheck.ok(s,1) = 0;
                disp([cfg.subjects{s} ' does not contain the required amount of voxels']);
            end
            VOIcheck.v{s}(:,:) = xY.v;
            VOIcheck.s{s}(:,:) = xY.s;
            
            disp(['the VOI of ' cfg.subjects{s} ' contains ' mat2str(VOIcheck.n(s,:)) ' voxels']);
            
        else
            disp(['no file available for ' cfg.subjects{s}]);
        end
    end
    VOIcheck_file = fullfile(VOIcheck_dir,['VOIcheck_' cfg.voi.spec.names{v} '.mat']);
    save(VOIcheck_file,'VOIcheck');
end
