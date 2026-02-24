function [cfg] = bch_add_cov(cfg)

% find motion file for the number of scans
subj = cfg.subj;
mov_dir = fullfile(cfg.dir.preproc, cfg.subj,'ses-tcg/mri',cfg.dir.mov);

motionfile = dir(fullfile(mov_dir,'rp_*.txt'));
fid = fopen(fullfile(mov_dir,motionfile(1).name),'r');
rp = fscanf(fid,' %e %e %e %e %e %e',[6,inf])';
fclose(fid);

regr_dir = fullfile(cfg.dir.preproc, cfg.subj, 'ses-tcg/mri', cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

% add extra covariate to exclude volumes due to movement/spikes
if strcmp(subj, 'sub-074') % exclude these volumes due to stripes (excessive movement)
    extra_cov = ones(size(rp,1),1);
    extra_cov(1:7,1) = 0;
    extra_cov(30:31,1) = 0;
    extra_cov(90:92,1) = 0;
    extra_cov(99:100,1) = 0;
    extra_cov(202,1) = 0;
    extra_cov(313:314,1) = 0;
    extra_cov(329:330,1) = 0;
    extra_cov(541:542,1) = 0;
    extra_cov(1112,1) = 0;
    extra_cov(1366:1367,1) = 0;
    % save extra_cov in .mat file
    save(fullfile(regr_dir,[cfg.prefix.regr,'_cov_',subj]),'extra_cov');
elseif strcmp(subj,'sub-157') % spike check
    extra_cov = ones(size(rp,1),1);
    extra_cov(2,1) = 0;
    extra_cov(4:5,1) = 0;
    extra_cov(8,1) = 0;
    extra_cov(10,1) = 0;
    extra_cov(12:14,1) = 0;
    extra_cov(16,1) = 0;
    extra_cov(18:21,1) = 0;
    extra_cov(24,1) = 0;
    extra_cov(26,1) = 0;
    extra_cov(28:29,1) = 0;
    extra_cov(31:32,1) = 0;
    extra_cov(36:40,1) = 0;
    extra_cov(339:341,1) = 0;
    extra_cov(382:386,1) = 0;
    % save extra_cov in .mat file
    save(fullfile(regr_dir,[cfg.prefix.regr,'_cov_',subj]),'extra_cov');
elseif strcmp(subj,'sub-162') % exclude these volumes due to stripes (excessive movement)
    extra_cov = ones(size(rp,1),1);
    extra_cov(1:4,1) = 0;
    extra_cov(143:144,1) = 0;
    extra_cov(158:159,1) = 0;
    extra_cov(252:253,1) = 0;
    extra_cov(577,1) = 0;
    extra_cov(1017:1018,1) = 0;
    extra_cov(1211,1) = 0;
    % save extra_cov in .mat file
    save(fullfile(regr_dir,[cfg.prefix.regr,'_cov_',subj]),'extra_cov');
end
