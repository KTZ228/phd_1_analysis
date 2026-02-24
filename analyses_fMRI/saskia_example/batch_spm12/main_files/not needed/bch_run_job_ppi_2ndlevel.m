function [cfg] = bch_run_job_ppi_2ndlevel(cfg)

job = [cfg.preproc '.mat'];

job_dir = fullfile(cfg.dir.root, cfg.dir.groupana, cfg.model1, cfg.dir.ppi);
cfg_util('run',fullfile(job_dir,job));