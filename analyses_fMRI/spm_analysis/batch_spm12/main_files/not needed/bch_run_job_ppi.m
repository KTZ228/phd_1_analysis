function [cfg] = bch_run_job_ppi(cfg)

job = [cfg.preproc '_' cfg.subj '.mat'];

cfg_util('run',fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana,job));