function [cfg] = bch_run_job_coreg(cfg)

job = strcat(cfg.preproc, '_', cfg.subj, '_struc.mat');
cfg_util('run',fullfile(cfg.dir.batches,job));

job = strcat(cfg.preproc, '_', cfg.subj, '_func.mat');
cfg_util('run',fullfile(cfg.dir.batches,job));

job = strcat(cfg.preproc, '_', cfg.subj, '.mat');
cfg_util('run',fullfile(cfg.dir.batches,job));

end