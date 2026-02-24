function [cfg] = bch_run_job_norm_write(cfg)

job = strcat(cfg.preproc, '_func_', cfg.subj, '.mat');
% cfg_util('run',fullfile(cfg.dir.func,job));
cfg_util('run',fullfile(cfg.dir.batches,job));

job = strcat(cfg.preproc, '_struc_', cfg.subj, '.mat');
%cfg_util('run',fullfile(cfg.dir.struc,job));
cfg_util('run',fullfile(cfg.dir.batches,job));
