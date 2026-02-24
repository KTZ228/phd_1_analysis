function [cfg] = bch_run_job_2ndlevel(cfg)

job = [cfg.preproc '.mat'];

job_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1);
cfg_util('run',fullfile(job_dir,job));