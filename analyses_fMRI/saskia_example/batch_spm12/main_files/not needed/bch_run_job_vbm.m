function [cfg] = bch_run_job_vbm(cfg)

job = [cfg.preproc '_' cfg.subj '.mat'];

cfg_util('run',fullfile(cfg.dir.vbm,job));