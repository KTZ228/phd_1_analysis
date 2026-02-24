function [cfg] = bch_run_job_norm_write_func(cfg)

%job = [cfg.preproc '_func_' cfg.subj '_' cfg.sess.current '.mat'];
job = strcat(cfg.preproc, '_func_', cfg.subj, '_.mat');
%job = cfg.jobname;
cfg_util('run',fullfile(cfg.dir.func,job));
